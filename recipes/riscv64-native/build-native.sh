#!/usr/bin/env bash

# Native riscv64 build script - no Docker required
# This script orchestrates a native build on a remote riscv64 machine via SSH
# Resilient to SSH connection drops for long-running builds (12+ hours)

set -e

# Parse arguments (same as Docker container would receive)
release_urlbase="$1"
disttype="$2"
customtag="$3"
datestring="$4"
commit="$5"
fullversion="$6"
source_url="$7"
source_urlbase="$8"
source_file="$9"
output_dir="${10}"

config_flags="--openssl-no-asm"

# Remote machine configuration
REMOTE_HOST="${RISCV64_REMOTE_HOST:-192.168.1.185}"
REMOTE_USER="${RISCV64_REMOTE_USER:-poddingue}"
REMOTE_BUILD_DIR="${RISCV64_REMOTE_BUILD_DIR:-nodejs-builds}"

# SSH options for non-interactive use with keepalive to prevent timeouts
SSH_OPTS="-o StrictHostKeyChecking=accept-new -o BatchMode=yes -o ConnectTimeout=30 -o ServerAliveInterval=60 -o ServerAliveCountMax=30"

echo "========================================"
echo "Native riscv64 Build for Node.js ${fullversion}"
echo "========================================"
echo "Remote: ${REMOTE_USER}@${REMOTE_HOST}"
echo "Source: ${source_file}"
echo "Output: ${output_dir}"
echo "========================================"

# Verify SSH connection
echo "Testing SSH connection..."
if ! ssh ${SSH_OPTS} "${REMOTE_USER}@${REMOTE_HOST}" "echo 'Connected successfully'"; then
  echo "ERROR: Cannot connect to ${REMOTE_USER}@${REMOTE_HOST}"
  echo "Please ensure SSH key authentication is set up"
  exit 1
fi

# Ensure remote build directory exists
echo "Setting up remote build directory..."
ssh ${SSH_OPTS} "${REMOTE_USER}@${REMOTE_HOST}" "mkdir -p ${REMOTE_BUILD_DIR}/staging ${REMOTE_BUILD_DIR}/ccache ${REMOTE_BUILD_DIR}/logs"

# Copy source tarball to remote machine
echo "Copying source tarball to remote machine..."
rsync -avz --progress -e "ssh ${SSH_OPTS}" \
  "${source_file}" \
  "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_BUILD_DIR}/staging/node.tar.xz"

# Create remote build script that runs detached
cat > /tmp/remote-build-$$.sh <<'REMOTE_SCRIPT'
#!/bin/bash
set -e
set -x

FULLVERSION="$1"
DISTTYPE="$2"
CUSTOMTAG="$3"
DATESTRING="$4"
COMMIT="$5"
RELEASE_URLBASE="$6"
CONFIG_FLAGS="$7"
BUILD_DIR="$8"
LOG_FILE="$9"
PID_FILE="${10}"

cd "${BUILD_DIR}/staging"

# Clean previous build
rm -rf "node-${FULLVERSION}"

# Extract source
echo "Extracting source..."
tar -xf node.tar.xz

cd "node-${FULLVERSION}"

# Set up ccache
export CC="ccache gcc"
export CXX="ccache g++"
export CCACHE_DIR="${BUILD_DIR}/ccache"
export CCACHE_MAXSIZE="5G"

# Show ccache stats before build
echo "=== ccache stats before build ==="
ccache -s || true

# Build Node.js
echo "Starting Node.js build..."
echo "  CPU count: $(nproc)"
echo "  Memory: $(free -h | grep Mem | awk '{print $2}')"
echo "  Config flags: ${CONFIG_FLAGS}"
echo "  Log file: ${LOG_FILE}"
echo "  PID file: ${PID_FILE}"

time make -j$(nproc) binary V= \
  DESTCPU="riscv64" \
  ARCH="riscv64" \
  VARIATION="" \
  DISTTYPE="${DISTTYPE}" \
  CUSTOMTAG="${CUSTOMTAG}" \
  DATESTRING="${DATESTRING}" \
  COMMIT="${COMMIT}" \
  RELEASE_URLBASE="${RELEASE_URLBASE}" \
  CONFIG_FLAGS="${CONFIG_FLAGS}"

# Show ccache stats after build
echo "=== ccache stats after build ==="
ccache -s || true

echo "Build completed successfully!"
ls -lh node-*.tar.?z

# Mark completion
echo "SUCCESS" > "${BUILD_DIR}/logs/build-${FULLVERSION}.status"
REMOTE_SCRIPT

# Copy build script to remote machine
echo "Copying build script to remote machine..."
scp ${SSH_OPTS} /tmp/remote-build-$$.sh "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_BUILD_DIR}/staging/build.sh"
rm /tmp/remote-build-$$.sh

# Define remote paths (relative to REMOTE_BUILD_DIR for cd command)
REMOTE_LOG="logs/build-${fullversion}.log"
REMOTE_PID="logs/build-${fullversion}.pid"
REMOTE_STATUS="logs/build-${fullversion}.status"
# Absolute paths for retrieval
REMOTE_LOG_ABS="${REMOTE_BUILD_DIR}/${REMOTE_LOG}"
REMOTE_PID_ABS="${REMOTE_BUILD_DIR}/${REMOTE_PID}"
REMOTE_STATUS_ABS="${REMOTE_BUILD_DIR}/${REMOTE_STATUS}"

# Clean up any previous status files
echo "Cleaning previous build status..."
ssh ${SSH_OPTS} "${REMOTE_USER}@${REMOTE_HOST}" "rm -f ${REMOTE_STATUS_ABS}"

# Launch build in background with nohup
echo "Launching build in detached mode..."
ssh ${SSH_OPTS} "${REMOTE_USER}@${REMOTE_HOST}" \
  "cd ${REMOTE_BUILD_DIR} && nohup bash staging/build.sh \
    '${fullversion}' \
    '${disttype}' \
    '${customtag}' \
    '${datestring}' \
    '${commit}' \
    '${release_urlbase}' \
    '${config_flags}' \
    '${REMOTE_BUILD_DIR}' \
    '${REMOTE_LOG}' \
    '${REMOTE_PID}' \
    > ${REMOTE_LOG_ABS} 2>&1 & echo \$! > ${REMOTE_PID_ABS}"

# Wait a moment for the build to start
sleep 2

# Get the PID
BUILD_PID=$(ssh ${SSH_OPTS} "${REMOTE_USER}@${REMOTE_HOST}" "cat ${REMOTE_PID_ABS} 2>/dev/null || echo 'unknown'")
echo "Build started with PID: ${BUILD_PID}"
echo "Build running in background on ${REMOTE_HOST}"
echo "You can disconnect safely - build will continue"
echo ""

# Poll for completion
echo "Monitoring build progress..."
echo "(Checking every 60 seconds - this may take 12+ hours for riscv64)"
echo ""

POLL_COUNT=0
while true; do
  # Check if process is still running
  if ssh ${SSH_OPTS} "${REMOTE_USER}@${REMOTE_HOST}" "kill -0 ${BUILD_PID} 2>/dev/null"; then
    POLL_COUNT=$((POLL_COUNT + 1))

    # Show progress every 5 minutes (5 polls)
    if [ $((POLL_COUNT % 5)) -eq 0 ]; then
      ELAPSED=$((POLL_COUNT * 60 / 60))
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] Build still running (${ELAPSED} minutes elapsed)"

      # Show last few lines of log
      echo "Last 3 lines from build log:"
      ssh ${SSH_OPTS} "${REMOTE_USER}@${REMOTE_HOST}" "tail -3 ${REMOTE_LOG_ABS} 2>/dev/null || echo '(no log yet)'"
      echo ""
    fi

    sleep 60
  else
    # Process finished
    echo "Build process completed!"
    break
  fi
done

# Retrieve the full log
echo "Retrieving build log..."
scp ${SSH_OPTS} "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_LOG_ABS}" "${output_dir}/build.log" || echo "Warning: Could not retrieve log"

# Check if build was successful
if ssh ${SSH_OPTS} "${REMOTE_USER}@${REMOTE_HOST}" "[ -f ${REMOTE_STATUS_ABS} ] && grep -q SUCCESS ${REMOTE_STATUS_ABS}"; then
  echo "Build completed successfully!"
else
  echo "ERROR: Build failed or did not complete successfully"
  echo "Check log at: ${output_dir}/build.log"
  exit 1
fi

# Copy built binary back from remote machine
echo "Retrieving built binary from remote machine..."
rsync -avz --progress -e "ssh ${SSH_OPTS}" \
  "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_BUILD_DIR}/staging/node-${fullversion}/node-*.tar.?z" \
  "${output_dir}/"

# Verify the binary was copied
if ! ls "${output_dir}"/node-*.tar.?z >/dev/null 2>&1; then
  echo "ERROR: Failed to retrieve built binary"
  exit 1
fi

echo "========================================"
echo "Native riscv64 build completed successfully!"
echo "Output:"
ls -lh "${output_dir}"/node-*.tar.?z
echo "========================================"
