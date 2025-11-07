#!/bin/bash -e

# Wrapper for local_build.sh that sets up SSH access for native riscv64 builds
# This script handles mounting of SSH keys and configuring the remote host

usage_exit() {
  echo "Usage: $0 -r <recipe> -v <version> [-w <workdir>] [-h <remote-host>] [-u <remote-user>]"
  echo ""
  echo "Options:"
  echo "  -r <recipe>       Recipe name (e.g., riscv64-native)"
  echo "  -v <version>      Node.js version (e.g., v21.0.0)"
  echo "  -w <workdir>      Working directory (default: parent of this repo)"
  echo "  -h <remote-host>  Remote riscv64 host (default: 192.168.1.185)"
  echo "  -u <remote-user>  Remote user (default: poddingue)"
  echo "  -d <remote-dir>   Remote build directory (default: ~/nodejs-builds)"
  exit 1
}

## -- SETUP -- ##

__dirname="$(CDPATH= cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# by default, workdir is the parent directory of the cloned repo
workdir="${workdir:-"${__dirname}/../.."}"

recipe=""
fullversion=""
remote_host="192.168.1.185"
remote_user="poddingue"
remote_dir="~/nodejs-builds"

# parse command line options
while getopts ":w:r:v:h:u:d:" opt; do
  case ${opt} in
    w )
      workdir=$OPTARG
      ;;
    r )
      recipe=$OPTARG
      ;;
    v )
      fullversion=$OPTARG
      ;;
    h )
      remote_host=$OPTARG
      ;;
    u )
      remote_user=$OPTARG
      ;;
    d )
      remote_dir=$OPTARG
      ;;
    \? )
      echo "Invalid option: $OPTARG" 1>&2
      usage_exit
      ;;
    : )
      echo "Invalid option: $OPTARG requires an argument" 1>&2
      usage_exit
      ;;
  esac
done
shift $((OPTIND -1))

if [[ -z "$recipe" ]]; then
  echo "Please supply a recipe name from the recipes directory"
  usage_exit
fi
if [[ -z "$fullversion" ]]; then
  echo "Please supply a Node.js version string"
  usage_exit
fi

# Export remote configuration as environment variables for Docker
export RISCV64_REMOTE_HOST="$remote_host"
export RISCV64_REMOTE_USER="$remote_user"
export RISCV64_REMOTE_BUILD_DIR="$remote_dir"

echo "=== Native riscv64 Build Configuration ==="
echo "Remote host: ${remote_user}@${remote_host}"
echo "Remote build dir: ${remote_dir}"
echo "Node.js version: ${fullversion}"
echo "Recipe: ${recipe}"
echo "=========================================="

# Verify SSH access
echo "Testing SSH connection to remote machine..."
if ! ssh -o ConnectTimeout=5 -o BatchMode=yes "${remote_user}@${remote_host}" "echo 'SSH connection successful'"; then
  echo "ERROR: Cannot connect to ${remote_user}@${remote_host}"
  echo "Please ensure:"
  echo "  1. SSH key is set up in ~/.ssh/ and added to ssh-agent"
  echo "  2. Remote host is accessible"
  echo "  3. SSH key is authorized on remote machine"
  exit 1
fi

# Run the build with SSH key mounting
# We mount ~/.ssh as read-only to provide SSH keys to the container
exec docker run --rm \
  -v "${HOME}/.ssh:/home/node/.ssh:ro" \
  -e "RISCV64_REMOTE_HOST=${remote_host}" \
  -e "RISCV64_REMOTE_USER=${remote_user}" \
  -e "RISCV64_REMOTE_BUILD_DIR=${remote_dir}" \
  -v "$(realpath "$workdir")/staging/src/${fullversion}/node-${fullversion}.tar.xz:/home/node/node.tar.xz:ro" \
  -v "$(realpath "$workdir")/staging/release/${fullversion}:/out" \
  unofficial-build-recipe-${recipe}
