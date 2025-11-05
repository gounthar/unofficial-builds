# Native RISC-V 64 Build Setup Guide

This guide explains how to set up and use native RISC-V builds on a remote riscv64 machine.

## Overview

Instead of cross-compiling Node.js for riscv64, this setup builds Node.js natively on actual riscv64 hardware. This provides:

- Better compatibility with native libraries
- Actual hardware testing during build
- Faster builds for platforms where cross-compilation is complex

## Architecture

The `riscv64-native` recipe uses a hybrid approach:

1. **Orchestration Container** (runs on build server):
   - Lightweight Docker container with SSH client
   - Transfers source tarball to remote machine
   - Triggers remote build via SSH
   - Retrieves built binaries

2. **Remote Build Machine** (actual riscv64 hardware):
   - Banana Pi F3 running Debian 13 (trixie)
   - Native gcc 14.2.0 compiler
   - 8 cores, 15GB RAM
   - ccache for faster rebuilds

## Prerequisites

### Remote Machine Setup

The remote riscv64 machine needs:

```bash
# Install build dependencies
sudo apt-get update
sudo apt-get install -y \
  gcc g++ make python3 git \
  ccache xz-utils \
  libssl-dev zlib1g-dev

# Create build directory structure
mkdir -p ~/nodejs-builds/{staging,ccache,logs}
```

### Local Machine Setup

1. **SSH Key Access**: Ensure your SSH key is set up and the remote machine is in known_hosts:
   ```bash
   ssh-add ~/.ssh/id_rsa  # or your key file
   ssh poddingue@192.168.1.185 "echo 'SSH test successful'"
   ```

2. **Docker**: Docker must be available for building the orchestration container:
   - On WSL2: Start Docker Desktop on Windows
   - Or install Docker in WSL: `curl -fsSL https://get.docker.com | sh`

## Testing the Native Build

### Step 1: Build Docker Images

```bash
cd ~/unofficial-builds-home/unofficial-builds

# Build fetch-source image
docker build fetch-source/ -t unofficial-build-recipe-fetch-source \
  --build-arg UID=$(id -u) --build-arg GID=$(id -g)

# Build riscv64-native image
docker build recipes/riscv64-native/ -t unofficial-build-recipe-riscv64-native \
  --build-arg UID=$(id -u) --build-arg GID=$(id -g)
```

### Step 2: Test with a Specific Version

Using the custom wrapper script:

```bash
bin/local_build_native.sh \
  -r riscv64-native \
  -v v21.7.0 \
  -h 192.168.1.185 \
  -u poddingue \
  -d ~/nodejs-builds
```

Or using the standard local_build.sh with manual environment setup:

```bash
# Set remote configuration
export RISCV64_REMOTE_HOST="192.168.1.185"
export RISCV64_REMOTE_USER="poddingue"
export RISCV64_REMOTE_BUILD_DIR="~/nodejs-builds"

# Create workdir
mkdir -p ~/Devel/unofficial-builds-home
cd ~/Devel/unofficial-builds-home

# Run the build
unofficial-builds/bin/local_build.sh -r riscv64-native -v v21.7.0
```

### Step 3: Verify Build Output

After successful build:

```bash
ls -lh ~/Devel/unofficial-builds-home/staging/release/v21.7.0/
```

Expected output: `node-v21.7.0-linux-riscv64.tar.xz`

## Integrating into Production

### Update Recipe Configuration

Add `riscv64-native` to the build recipes in `bin/_config.sh`:

```bash
recipes=(
  "headers"
  "x86"
  "musl"
  "armv6l"
  "x64-glibc-217"
  "x64-pointer-compression"
  "x64-usdt"
  "riscv64-native"    # Replace "riscv64" with this
  "loong64"
  "x64-debug"
)
```

### Production Server Setup

On the unofficial-builds production server:

1. **Add SSH Key**:
   ```bash
   # As nodejs user on production server
   ssh-copy-id poddingue@192.168.1.185
   ssh-add ~/.ssh/id_rsa
   ```

2. **Set Environment Variables** in `/etc/systemd/system/unofficial-builds-periodic.service`:
   ```ini
   [Service]
   Environment="RISCV64_REMOTE_HOST=192.168.1.185"
   Environment="RISCV64_REMOTE_USER=poddingue"
   Environment="RISCV64_REMOTE_BUILD_DIR=/home/poddingue/nodejs-builds"
   ```

3. **Restart Service**:
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl restart unofficial-builds-periodic.service
   ```

## Monitoring Remote Builds

### View Build Progress

On the remote machine:
```bash
ssh poddingue@192.168.1.185 "tail -f ~/nodejs-builds/logs/current-build.log"
```

### Check ccache Statistics

```bash
ssh poddingue@192.168.1.185 "CCACHE_DIR=~/nodejs-builds/ccache ccache -s"
```

## Troubleshooting

### SSH Connection Issues

```bash
# Test SSH connection
ssh -v poddingue@192.168.1.185 "echo test"

# Check SSH agent
ssh-add -l

# Add key if needed
ssh-add ~/.ssh/id_rsa
```

### Build Failures

Check logs on remote machine:
```bash
ssh poddingue@192.168.1.185 "ls -lt ~/nodejs-builds/staging/node-*/out/Release/"
```

### Disk Space Issues

```bash
# Check remote disk space
ssh poddingue@192.168.1.185 "df -h ~"

# Clean old builds
ssh poddingue@192.168.1.185 "rm -rf ~/nodejs-builds/staging/node-*"
```

## Performance Comparison

Expected build times (Node.js v21.7.0):

- **Cross-compilation** (x86_64 with riscv64 toolchain): ~30-45 minutes
- **Native build** (8-core riscv64): ~40-60 minutes

Native builds may be slightly slower but provide:
- Real hardware validation
- Better compatibility
- Easier debugging on actual platform

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `RISCV64_REMOTE_HOST` | `192.168.1.185` | Remote riscv64 machine hostname/IP |
| `RISCV64_REMOTE_USER` | `poddingue` | SSH user on remote machine |
| `RISCV64_REMOTE_BUILD_DIR` | `~/nodejs-builds` | Build directory on remote machine |

## Security Considerations

1. **SSH Keys**: Use dedicated build keys with limited permissions
2. **Network**: Ensure remote machine is on trusted network
3. **Firewall**: Consider restricting SSH access to build server IP only
4. **Backups**: Remote build machine should have build directory backed up
