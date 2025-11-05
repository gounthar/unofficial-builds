#!/usr/bin/env bash

# Native riscv64 build script - no Docker required
# This script orchestrates a native build on a remote riscv64 machine via SSH

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

# SSH options for non-interactive use
SSH_OPTS="-o StrictHostKeyChecking=accept-new -o BatchMode=yes -o ConnectTimeout=30"

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
ssh ${SSH_OPTS} "${REMOTE_USER}@${REMOTE_HOST}" "mkdir -p ${REMOTE_BUILD_DIR}/{staging,ccache,logs}"

# Copy source tarball to remote machine
echo "Copying source tarball to remote machine..."
rsync -avz --progress -e "ssh ${SSH_OPTS}" \
  "${source_file}" \
  "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_BUILD_DIR}/staging/node.tar.xz"

# Create remote build script
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
REMOTE_SCRIPT

# Copy and execute build script on remote machine
echo "Executing build on remote machine..."
scp ${SSH_OPTS} /tmp/remote-build-$$.sh "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_BUILD_DIR}/staging/build.sh"
rm /tmp/remote-build-$$.sh

# Execute the build with proper quoting
ssh ${SSH_OPTS} "${REMOTE_USER}@${REMOTE_HOST}" \
  "bash ${REMOTE_BUILD_DIR}/staging/build.sh \
    '${fullversion}' \
    '${disttype}' \
    '${customtag}' \
    '${datestring}' \
    '${commit}' \
    '${release_urlbase}' \
    '${config_flags}' \
    '${REMOTE_BUILD_DIR}'" \
  2>&1 | tee "${output_dir}/build.log"

# Check if build succeeded
if [ ${PIPESTATUS[0]} -ne 0 ]; then
  echo "ERROR: Remote build failed"
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
