#!/bin/bash -e

# Test script for native riscv64 builds (no Docker required)

usage() {
  echo "Usage: $0 -v <version> [-h <host>] [-u <user>] [-d <dir>]"
  echo ""
  echo "Options:"
  echo "  -v <version>   Node.js version (e.g., v21.7.0, v20.11.0)"
  echo "  -h <host>      Remote host (default: 192.168.1.185)"
  echo "  -u <user>      Remote user (default: poddingue)"
  echo "  -d <dir>       Remote build dir (default: nodejs-builds)"
  echo ""
  echo "Example:"
  echo "  $0 -v v21.7.0"
  exit 1
}

# Get script directory
__dirname="$(CDPATH= cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
workdir="${__dirname}/../.."

# Default values
REMOTE_HOST="192.168.1.185"
REMOTE_USER="poddingue"
REMOTE_BUILD_DIR="nodejs-builds"
fullversion=""

# Parse arguments
while getopts "v:h:u:d:" opt; do
  case $opt in
    v) fullversion="$OPTARG" ;;
    h) REMOTE_HOST="$OPTARG" ;;
    u) REMOTE_USER="$OPTARG" ;;
    d) REMOTE_BUILD_DIR="$OPTARG" ;;
    *) usage ;;
  esac
done

if [ -z "$fullversion" ]; then
  echo "ERROR: Version required"
  usage
fi

# Export for build script
export RISCV64_REMOTE_HOST="$REMOTE_HOST"
export RISCV64_REMOTE_USER="$REMOTE_USER"
export RISCV64_REMOTE_BUILD_DIR="$REMOTE_BUILD_DIR"

# Source config and version decoder
source "${__dirname}/_config.sh"
source "${__dirname}/_decode_version.sh"

# Decode version
decode "$fullversion"

# Setup directories
stagingdir="${workdir}/staging"
sourcedir="${stagingdir}/src/${fullversion}"
sourcefile="${sourcedir}/node-${fullversion}.tar.xz"
outputdir="${stagingdir}/${disttype_promote}/${fullversion}"

mkdir -p "${sourcedir}"
mkdir -p "${outputdir}"

echo "========================================"
echo "Testing Native riscv64 Build"
echo "========================================"
echo "Version: ${fullversion}"
echo "Source file: ${sourcefile}"
echo "Output dir: ${outputdir}"
echo "Remote: ${REMOTE_USER}@${REMOTE_HOST}"
echo "========================================"

# Check if source file exists, if not download it
if [ ! -f "${sourcefile}" ]; then
  echo "Downloading Node.js source..."

  # Determine source URL based on disttype
  if [ "$disttype" = "release" ]; then
    source_urlbase="https://nodejs.org/dist"
  else
    source_urlbase="https://nodejs.org/download/${disttype}"
  fi

  source_url="${source_urlbase}/${fullversion}/node-${fullversion}.tar.xz"

  echo "  From: ${source_url}"
  curl -f -L -o "${sourcefile}" "${source_url}"

  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to download source"
    exit 1
  fi

  echo "  Downloaded: $(ls -lh ${sourcefile} | awk '{print $5}')"
fi

# Build variables
unofficial_release_urlbase="https://unofficial-builds.nodejs.org/download/${disttype}/"

# Run the native build script
echo "Starting native build..."
"${__dirname}/../recipes/riscv64-native/build-native.sh" \
  "${unofficial_release_urlbase}" \
  "${disttype}" \
  "${customtag}" \
  "${datestring}" \
  "${commit}" \
  "${fullversion}" \
  "${source_url}" \
  "${source_urlbase}" \
  "${sourcefile}" \
  "${outputdir}"

if [ $? -eq 0 ]; then
  echo ""
  echo "========================================"
  echo "BUILD SUCCESSFUL!"
  echo "========================================"
  echo "Output files:"
  ls -lh "${outputdir}"/node-*.tar.*
  echo "========================================"
else
  echo ""
  echo "========================================"
  echo "BUILD FAILED"
  echo "========================================"
  exit 1
fi
