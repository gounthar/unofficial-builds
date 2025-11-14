# Node.js Unofficial Builds - Repository Installation Guide

This guide explains how to install Node.js for RISC-V 64-bit using APT (Debian/Ubuntu) or YUM/DNF (Fedora/RHEL) package repositories.

## Overview

The nodejs-unofficial-builds project provides native RISC-V 64-bit builds of Node.js through two repository types:

- **APT Repository**: For Debian, Ubuntu, and derivatives
- **RPM Repository**: For Fedora, RHEL, and derivatives

Both repositories are hosted on GitHub Pages and automatically updated when new Node.js versions are released.

---

## APT Repository (Debian/Ubuntu)

### Quick Installation

```bash
# Add GPG key
curl -fsSL https://gounthar.github.io/nodejs-unofficial-builds/KEY.gpg | \
  sudo gpg --dearmor -o /etc/apt/keyrings/nodejs-unofficial.gpg

# Add repository
echo "deb [arch=riscv64 signed-by=/etc/apt/keyrings/nodejs-unofficial.gpg] https://gounthar.github.io/nodejs-unofficial-builds trixie main" | \
  sudo tee /etc/apt/sources.list.d/nodejs-unofficial.list

# Update and install
sudo apt update
sudo apt install nodejs
```

### Verify Installation

```bash
node --version
npm --version
npx --version
corepack --version
```

### What Gets Installed

The Node.js package installs to `/usr` with the following binaries:
- `/usr/bin/node`
- `/usr/bin/npm`
- `/usr/bin/npx`
- `/usr/bin/corepack`

### Package Details

- **Package name**: `nodejs`
- **Architecture**: `riscv64`
- **Distribution**: `trixie` (Debian 13)
- **Component**: `main`
- **Dependencies**:
  - `libc6 >= 2.34`
  - `libssl3 >= 3.0.0`
  - `zlib1g >= 1:1.2.11`

### Upgrading Node.js

When new versions are released, simply update your package list and upgrade:

```bash
sudo apt update
sudo apt upgrade nodejs
```

### Listing Available Versions

```bash
# Show all available versions
apt-cache madison nodejs

# Show currently installed version
apt-cache policy nodejs
```

### Uninstalling

```bash
sudo apt remove nodejs
```

---

## RPM Repository (Fedora/RHEL)

### Quick Installation

```bash
# Download and install repository configuration
sudo curl -o /etc/yum.repos.d/nodejs-unofficial.repo \
  https://gounthar.github.io/nodejs-unofficial-builds/nodejs-unofficial.repo

# Install Node.js
sudo dnf install nodejs
```

### Manual Configuration

If you prefer to create the repository configuration manually:

```bash
sudo tee /etc/yum.repos.d/nodejs-unofficial.repo <<EOF
[nodejs-unofficial-riscv64]
name=Node.js Unofficial Builds - RISC-V 64
baseurl=https://gounthar.github.io/nodejs-unofficial-builds/rpm/fedora/riscv64
enabled=1
gpgcheck=1
gpgkey=https://gounthar.github.io/nodejs-unofficial-builds/KEY.gpg
repo_gpgcheck=1
EOF
```

Then install:

```bash
sudo dnf install nodejs
```

### Verify Installation

```bash
node --version
npm --version
npx --version
corepack --version
```

### What Gets Installed

The Node.js package installs to `/usr` with the following binaries:
- `/usr/bin/node`
- `/usr/bin/npm`
- `/usr/bin/npx`
- `/usr/bin/corepack`

### Package Details

- **Package name**: `nodejs`
- **Architecture**: `riscv64`
- **Dependencies** (auto-detected):
  - `glibc >= 2.34`
  - `openssl >= 3.0.0`
  - `zlib`

### Upgrading Node.js

```bash
sudo dnf upgrade nodejs
```

### Listing Available Versions

```bash
# List all available versions
dnf list --showduplicates nodejs

# Show currently installed version
dnf info nodejs
```

### Uninstalling

```bash
sudo dnf remove nodejs
```

---

## Alternative Installation Methods

If you prefer not to use a package repository, you can still install Node.js manually:

### Option 1: Download .deb Package

```bash
VERSION="24.11.0"  # Replace with desired version

curl -LO "https://github.com/gounthar/nodejs-unofficial-builds/releases/download/v${VERSION}/nodejs_${VERSION}-1_riscv64.deb"
sudo dpkg -i "nodejs_${VERSION}-1_riscv64.deb"
```

### Option 2: Download .rpm Package

```bash
VERSION="24.11.0"  # Replace with desired version

curl -LO "https://github.com/gounthar/nodejs-unofficial-builds/releases/download/v${VERSION}/nodejs-${VERSION}-1.riscv64.rpm"
sudo rpm -i "nodejs-${VERSION}-1.riscv64.rpm"
```

### Option 3: Download Tarball

```bash
VERSION="24.11.0"  # Replace with desired version

curl -LO "https://github.com/gounthar/nodejs-unofficial-builds/releases/download/v${VERSION}/node-v${VERSION}-linux-riscv64.tar.xz"
tar -xJf "node-v${VERSION}-linux-riscv64.tar.xz"
sudo cp -r "node-v${VERSION}-linux-riscv64"/* /usr/local/
```

---

## Verifying Package Signatures

### APT Repository

The APT repository is signed with GPG key:
- **Fingerprint**: `56188341425B007407229B48FB1963FC3575A39D`
- **Owner**: Docker RISC-V64 Repository (reused for Node.js)

Signature verification happens automatically when using `apt`. To manually verify:

```bash
# Download and verify Release file
curl -fsSL https://gounthar.github.io/nodejs-unofficial-builds/dists/trixie/InRelease > /tmp/InRelease
gpg --verify /tmp/InRelease
```

### RPM Repository

The RPM repository metadata is signed with the same GPG key. Verification happens automatically when using `dnf` with `gpgcheck=1`.

To manually verify:

```bash
# Download and verify repomd.xml
cd /tmp
curl -fsSL https://gounthar.github.io/nodejs-unofficial-builds/rpm/fedora/riscv64/repodata/repomd.xml > repomd.xml
curl -fsSL https://gounthar.github.io/nodejs-unofficial-builds/rpm/fedora/riscv64/repodata/repomd.xml.asc > repomd.xml.asc
gpg --verify repomd.xml.asc repomd.xml
```

---

## Build Information

All binaries are:
- **Compiled natively** on actual RISC-V 64-bit hardware (Banana Pi F3)
- **Platform**: Debian 13 (trixie)
- **Compiler**: gcc 14.2.0
- **Configuration**: `--openssl-no-asm` (required for RISC-V)
- **Build type**: Native compilation (not cross-compiled)

---

## Supported Distributions

### APT Repository

Tested on:
- Debian 13 (trixie) - riscv64
- Ubuntu 24.04+ - riscv64 (may require glibc >= 2.34)

### RPM Repository

Tested on:
- Fedora 39+ - riscv64
- Other RPM-based distributions with dnf/yum

---

## Troubleshooting

### APT: GPG Key Errors

If you get GPG errors during `apt update`:

```bash
# Re-import the GPG key
curl -fsSL https://gounthar.github.io/nodejs-unofficial-builds/KEY.gpg | \
  sudo gpg --dearmor -o /etc/apt/keyrings/nodejs-unofficial.gpg

# Update and try again
sudo apt update
```

### RPM: GPG Verification Failed

If you get GPG verification errors:

```bash
# Import the GPG key manually
curl -fsSL https://gounthar.github.io/nodejs-unofficial-builds/KEY.gpg | sudo gpg --import

# Or disable GPG checking (not recommended)
sudo dnf install --nogpgcheck nodejs
```

### Dependency Issues

If you encounter dependency issues:

**Debian/Ubuntu**:
```bash
# Install dependencies manually
sudo apt install libc6 libssl3 zlib1g

# Then install Node.js
sudo apt install nodejs
```

**Fedora/RHEL**:
```bash
# Dependencies are usually auto-resolved, but if needed:
sudo dnf install glibc openssl-libs zlib

# Then install Node.js
sudo dnf install nodejs
```

### Repository Not Found (404 Error)

If you get 404 errors, ensure:
1. The `apt-repo` branch exists and is published via GitHub Pages
2. GitHub Pages is enabled for the repository
3. The URL is correct: `https://gounthar.github.io/nodejs-unofficial-builds`

Check GitHub Pages status:
- Go to: https://github.com/gounthar/nodejs-unofficial-builds/settings/pages
- Ensure "Source" is set to "Deploy from a branch"
- Branch should be: `apt-repo` / `/ (root)`

---

## Security Considerations

1. **GPG Signatures**: Always verify GPG signatures are enabled (`gpgcheck=1` for RPM, `signed-by=...` for APT)
2. **HTTPS Only**: Both repositories use HTTPS for secure downloads
3. **Trusted Key**: The GPG key should be verified before first use
4. **Updates**: Keep Node.js updated for security patches

---

## Additional Resources

- **GitHub Repository**: https://github.com/gounthar/nodejs-unofficial-builds
- **Releases**: https://github.com/gounthar/nodejs-unofficial-builds/releases
- **Issues**: https://github.com/gounthar/nodejs-unofficial-builds/issues
- **Official Node.js**: https://nodejs.org
- **Unofficial Builds**: https://unofficial-builds.nodejs.org

---

## License

Node.js is licensed under the MIT License. See https://github.com/nodejs/node/blob/main/LICENSE for details.

---

## Disclaimer

These builds are **experimental** and provided by the community. They may not have the same level of testing as official Node.js releases. Use at your own risk.

For production use, thoroughly test these builds in your environment before deployment.
