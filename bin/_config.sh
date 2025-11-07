# All of our build recipes, new recipes should be added here.
recipes=(
  "headers"
  "x86"
  "musl"
  "armv6l"
  "x64-glibc-217"
  "x64-pointer-compression"
  "x64-usdt"
  "riscv64-native"  # Native build on riscv64 hardware (replaces riscv64 cross-compile)
  "loong64"
  "x64-debug"
)

# Native build configuration for riscv64
# These can be overridden by environment variables
export RISCV64_REMOTE_HOST="${RISCV64_REMOTE_HOST:-192.168.1.185}"
export RISCV64_REMOTE_USER="${RISCV64_REMOTE_USER:-poddingue}"
export RISCV64_REMOTE_BUILD_DIR="${RISCV64_REMOTE_BUILD_DIR:-nodejs-builds}"


# This should be updated as new versions of nodejs-dist-indexer are released to
# include new assets published here; this is not done automatically for security
# reasons.
dist_indexer_version=v1.7.1

image_tag_pfx=unofficial-build-recipe-

# Location of the recipes directory relative to this script
__dirname="$(CDPATH= cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
recipes_dir="${__dirname}/../recipes"
queuefile="$(realpath "${__dirname}/../../var/build_queue")"

recipe_exists() {
  local recipe=$1
  [ -d "${recipes_dir}/${recipe}" ]
}
