# Native RISC-V 64 Build Recipe

This recipe builds Node.js natively on actual riscv64 hardware instead of cross-compiling.

## Quick Start (No Docker Required)

**Test a build without Docker:**

```bash
# Export configuration
export RISCV64_REMOTE_HOST="192.168.1.185"
export RISCV64_REMOTE_USER="poddingue"
export RISCV64_REMOTE_BUILD_DIR="nodejs-builds"

# Run test build
bin/test_native_build.sh -v v21.7.0
```

## Architecture

### Components

1. **Build Server** (x86_64/WSL2):
   - Orchestrates the build process
   - Downloads Node.js source
   - Transfers source to remote machine via SSH
   - Retrieves built binaries

2. **Remote Machine** (riscv64 - Banana Pi F3):
   - Debian 13 (trixie) on riscv64
   - gcc 14.2.0, 8 cores, 15GB RAM
   - Performs actual native compilation
   - Uses ccache for faster rebuilds

### Two Usage Methods

#### Method 1: Pure Bash (No Docker)

Best for testing and development on WSL2/Windows environments.

```bash
bin/test_native_build.sh -v v21.7.0 -h 192.168.1.185 -u poddingue
```

This script:
- Downloads Node.js source if needed
- Calls `recipes/riscv64-native/build-native.sh`
- Handles all SSH operations
- Outputs to `staging/release/<version>/`

#### Method 2: Docker Integration

Integrates with the existing unofficial-builds Docker-based workflow.

```bash
# Build Docker image
docker build recipes/riscv64-native/ -t unofficial-build-recipe-riscv64-native

# Run via local_build.sh (requires Docker)
bin/local_build.sh -r riscv64-native -v v21.7.0
```

This approach:
- Uses Docker container for orchestration
- Requires SSH keys mounted or SSH agent forwarding
- Compatible with production build server

## Prerequisites

### Remote Machine Setup

```bash
# Install build dependencies
ssh poddingue@192.168.1.185 "sudo apt-get update && sudo apt-get install -y \
  gcc g++ make python3 git ccache xz-utils libssl-dev zlib1g-dev"

# Create build directory
ssh poddingue@192.168.1.185 "mkdir -p ~/nodejs-builds/{staging,ccache,logs}"
```

### Local Machine Setup

```bash
# Ensure SSH key authentication works
ssh-add ~/.ssh/id_rsa  # Add your key
ssh poddingue@192.168.1.185 "echo 'SSH test passed'"
```

## Configuration

Set these environment variables:

```bash
export RISCV64_REMOTE_HOST="192.168.1.185"        # Remote machine IP/hostname
export RISCV64_REMOTE_USER="poddingue"            # SSH user
export RISCV64_REMOTE_BUILD_DIR="nodejs-builds"   # Build directory on remote
```

## Integration with Production Build System

To use native riscv64 builds in production:

### 1. Update Recipe List

Edit `bin/_config.sh`:

```bash
recipes=(
  "headers"
  "x86"
  "musl"
  "armv6l"
  "x64-glibc-217"
  "x64-pointer-compression"
  "x64-usdt"
  "riscv64-native"    # Use native instead of cross-compile
  "loong64"
  "x64-debug"
)
```

### 2. Build Docker Image on Production Server

```bash
cd /home/nodejs/unofficial-builds
bin/prepare-images.sh
```

### 3. Configure SSH Access

```bash
# As nodejs user on production server
ssh-keygen -t ed25519 -f ~/.ssh/id_riscv64_build
ssh-copy-id -i ~/.ssh/id_riscv64_build poddingue@192.168.1.185

# Test connection
ssh -i ~/.ssh/id_riscv64_build poddingue@192.168.1.185 "echo 'Connected'"
```

### 4. Set Environment Variables

Add to systemd service or shell environment:

```bash
export RISCV64_REMOTE_HOST="192.168.1.185"
export RISCV64_REMOTE_USER="poddingue"
export RISCV64_REMOTE_BUILD_DIR="nodejs-builds"
```

### 5. Run Build

```bash
# Queue a build
~/unofficial-builds/bin/queue-push.sh -v v21.7.0
```

## Build Process Flow

1. **Source Download**: Node.js source fetched by fetch-source recipe
2. **Transfer**: Source tarball uploaded to remote machine via rsync
3. **Native Build**: Remote machine extracts and compiles using native gcc
4. **Retrieve**: Built binary downloaded back to build server
5. **Promotion**: Binary moved to download/ directory with SHASUMS

## Performance

### Build Times (Node.js v21.7.0)

- **Cross-compile** (x86_64 → riscv64): ~30-45 minutes
- **Native** (riscv64 hardware): ~40-60 minutes

> **Note on Performance:** Native builds on riscv64 hardware (Banana Pi F3) are currently slower than cross-compilation due to the limited processing power of available riscv64 hardware compared to modern x86_64 build servers. However, native builds are chosen for several important reasons:
> - **Real Hardware Validation**: Ensures binaries work correctly on actual riscv64 systems
> - **Better Compatibility**: Avoids cross-compilation quirks and toolchain issues
> - **Catch Hardware-Specific Issues**: Identifies problems that may not appear in cross-compiled builds
> - **Future-Proof**: As riscv64 hardware improves, build times will naturally decrease

### ccache Benefits

After first build, subsequent builds with ccache:
- Clean build: ~40-60 minutes
- With ccache: ~10-20 minutes (depends on changes)

Check ccache stats:
```bash
ssh poddingue@192.168.1.185 "CCACHE_DIR=~/nodejs-builds/ccache ccache -s"
```

## Troubleshooting

### SSH Connection Fails

```bash
# Test with verbose output
ssh -v poddingue@192.168.1.185

# Check SSH agent
ssh-add -l

# Add key manually
ssh-add ~/.ssh/id_rsa
```

### Build Fails

```bash
# Check remote disk space
ssh poddingue@192.168.1.185 "df -h"

# View build logs
ssh poddingue@192.168.1.185 "tail -100 ~/nodejs-builds/staging/node-*/out/build.log"

# Clean old builds
ssh poddingue@192.168.1.185 "rm -rf ~/nodejs-builds/staging/node-v*"
```

### Remote Machine Unreachable

- Check network connectivity
- Verify SSH service running: `ssh poddingue@192.168.1.185 "systemctl status ssh"`
- Check firewall rules on remote machine
- Ensure remote machine hasn't changed IP (DHCP)

## Advantages of Native Builds

1. **Real Hardware Testing**: Build validated on actual riscv64 platform
2. **Better Compatibility**: No cross-compilation quirks or toolchain issues
3. **Easier Debugging**: Can test and debug directly on target platform
4. **Future-Proof**: As riscv64 hardware improves, builds get faster

## Maintenance

### Regular Tasks

```bash
# Clear ccache periodically
ssh poddingue@192.168.1.185 "CCACHE_DIR=~/nodejs-builds/ccache ccache -C"

# Clean old staging directories
ssh poddingue@192.168.1.185 "find ~/nodejs-builds/staging -name 'node-v*' -mtime +7 -exec rm -rf {} +"

# Update build dependencies
ssh poddingue@192.168.1.185 "sudo apt-get update && sudo apt-get upgrade -y"
```

### Monitoring

```bash
# Watch active build
ssh poddingue@192.168.1.185 "tail -f ~/nodejs-builds/staging/node-*/build.log"

# Check system resources
ssh poddingue@192.168.1.185 "htop"
```

## Files

- `Dockerfile` - Docker image for orchestration (optional)
- `run.sh` - Build script called by Docker or directly
- `build-native.sh` - Standalone bash build script (no Docker)
- `should-build.sh` - Filter for which versions to build
- `README.md` - This file

## Security Notes

- Use dedicated SSH key for builds
- Limit SSH key permissions (no shell access if possible)
- Consider firewall rules restricting SSH to build server IP
- Keep remote machine on trusted network
- Regular security updates on remote machine
