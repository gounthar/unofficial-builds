# Node.js for RISC-V 64-bit

Unofficial Node.js Docker images for **RISC-V 64-bit** (`linux/riscv64`) based on Debian Trixie.

These images fill the gap left by the [official Node.js images](https://hub.docker.com/_/node), which don't yet include `linux/riscv64` platform support.

## Quick Start

```bash
docker run --platform linux/riscv64 gounthar/node-riscv64:latest node -e "console.log(process.arch)"
# riscv64
```

## Tags

| Tag | Base Image | Description |
|-----|-----------|-------------|
| `<version>-trixie` | `buildpack-deps:trixie` | Full variant with build tools (gcc, g++, make) |
| `<version>-trixie-slim` | `debian:trixie-slim` | Minimal variant, smaller image size |
| `latest` | `buildpack-deps:trixie` | Latest release, full variant |
| `slim` | `debian:trixie-slim` | Latest release, slim variant |

## Available Versions

- **Node.js 24.x** (Current)
- **Node.js 22.x** (LTS)

Check the [Tags](https://hub.docker.com/r/gounthar/node-riscv64/tags) page for all available versions.

## Usage

### As a base image

```dockerfile
FROM gounthar/node-riscv64:latest
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
CMD ["node", "server.js"]
```

### Interactive shell

```bash
docker run -it --platform linux/riscv64 gounthar/node-riscv64:latest bash
```

## Why?

RISC-V is an open-source instruction set architecture gaining traction in embedded systems, SBCs, and servers. These images let you develop and test Node.js applications for riscv64 today, using QEMU emulation on any host or natively on RISC-V hardware.

## Included Software

- **Node.js** with npm
- **Yarn** 1.22.x (Classic)
- Full variant includes: gcc, g++, make, python3, and other build essentials

## Source

- **GitHub**: [gounthar/unofficial-builds](https://github.com/gounthar/unofficial-builds)
- **Dockerfiles**: [docker/](https://github.com/gounthar/unofficial-builds/tree/main/docker)
- **Binaries**: Built natively on RISC-V hardware (Banana Pi F3)
