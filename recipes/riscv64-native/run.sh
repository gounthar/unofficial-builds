#!/usr/bin/env bash

set -e

release_urlbase="$1"
disttype="$2"
customtag="$3"
datestring="$4"
commit="$5"
fullversion="$6"
# source_url and source_urlbase are passed for interface compatibility with standard recipes
# but not used in native builds (source is in /home/node/node.tar.xz)
source_url="$7"        # Kept for interface compatibility
source_urlbase="$8"    # Kept for interface compatibility
config_flags="--openssl-no-asm"

# Remote machine configuration
REMOTE_HOST="${RISCV64_REMOTE_HOST:-192.168.1.185}"
REMOTE_USER="${RISCV64_REMOTE_USER:-poddingue}"
REMOTE_BUILD_DIR="${RISCV64_REMOTE_BUILD_DIR:-nodejs-builds}"

# SSH options with keepalive to prevent timeouts on long builds
SSH_OPTS="-o StrictHostKeyChecking=accept-new -o BatchMode=yes -o ConnectTimeout=30 -o ServerAliveInterval=60 -o ServerAliveCountMax=30"

echo "========================================"
echo "Native riscv64 Build"
echo "Node.js ${fullversion}"
echo "Remote: ${REMOTE_USER}@${REMOTE_HOST}"
echo "========================================"

# Test connection
if ! ssh ${SSH_OPTS} "${REMOTE_USER}@${REMOTE_HOST}" "echo 'Connected'" 2>&1; then
  echo "ERROR: Cannot connect to ${REMOTE_USER}@${REMOTE_HOST}"
  exit 1
fi

# Ensure remote directories exist
ssh ${SSH_OPTS} "${REMOTE_USER}@${REMOTE_HOST}" "mkdir -p ${REMOTE_BUILD_DIR}/{staging,ccache}"

# Copy source
echo "Uploading source..."
rsync -az -e "ssh ${SSH_OPTS}" /home/node/node.tar.xz "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_BUILD_DIR}/staging/"

# Create and execute build script remotely
echo "Building on remote machine..."
ssh ${SSH_OPTS} "${REMOTE_USER}@${REMOTE_HOST}" bash <<ENDSSH
set -e
cd ${REMOTE_BUILD_DIR}/staging
rm -rf node-${fullversion}
tar -xf node.tar.xz
cd node-${fullversion}

export CC="ccache gcc"
export CXX="ccache g++"
export CCACHE_DIR="${REMOTE_BUILD_DIR}/ccache"
export CCACHE_MAXSIZE="5G"

echo "=== Build Info ==="
echo "CPUs: \$(nproc)"
echo "Memory: \$(free -h | grep Mem | awk '{print \\\$2}')"
echo "=================="

time make -j\$(nproc) binary V= \\
  DESTCPU="riscv64" \\
  ARCH="riscv64" \\
  VARIATION="" \\
  DISTTYPE="$disttype" \\
  CUSTOMTAG="$customtag" \\
  DATESTRING="$datestring" \\
  COMMIT="$commit" \\
  RELEASE_URLBASE="$release_urlbase" \\
  CONFIG_FLAGS="$config_flags"

echo "Build completed"
ls -lh node-*.tar.?z
ENDSSH

# Retrieve binary
echo "Downloading build artifact..."
rsync -az -e "ssh ${SSH_OPTS}" \
  "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_BUILD_DIR}/staging/node-${fullversion}/node-*.tar.?z" \
  /out/

echo "========================================"
echo "Native build complete!"
ls -lh /out/
echo "========================================"
