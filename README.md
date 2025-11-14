# Node.js Unofficial Builds - Repository Branch

This branch contains the APT and RPM repository metadata for Node.js RISC-V 64-bit builds.

**Do not commit to this branch directly.** It is automatically managed by GitHub Actions workflows.

## Repository Structure

```
apt-repo/
├── README.md                    # This file
├── KEY.gpg                      # GPG public key for package verification
├── nodejs-unofficial.repo       # YUM/DNF repository configuration
├── conf/                        # APT repository configuration (reprepro)
│   └── distributions            # Distribution configuration
├── dists/                       # APT repository metadata
│   └── trixie/                  # Debian 13 (trixie)
│       ├── InRelease            # GPG-signed combined Release file
│       ├── Release              # Repository release metadata
│       ├── Release.gpg          # GPG signature
│       └── main/
│           └── binary-riscv64/
│               ├── Packages     # Package index
│               └── Packages.gz  # Compressed package index
├── pool/                        # APT package storage
│   └── main/
│       └── n/
│           └── nodejs/
│               └── *.deb        # Debian packages
└── rpm/                         # RPM repository
    └── fedora/
        └── riscv64/
            ├── *.rpm            # RPM packages
            └── repodata/        # Repository metadata
                ├── repomd.xml           # Repository metadata index (signed)
                ├── repomd.xml.asc       # GPG signature
                ├── primary.xml.gz       # Package metadata
                ├── filelists.xml.gz     # File lists
                └── other.xml.gz         # Additional metadata
```

## GitHub Pages

This branch is served via GitHub Pages at:
- **URL**: https://gounthar.github.io/nodejs-unofficial-builds

Users can install Node.js using package managers:

### APT (Debian/Ubuntu)

```bash
# Add GPG key
curl -fsSL https://gounthar.github.io/nodejs-unofficial-builds/KEY.gpg | \
  sudo gpg --dearmor -o /etc/apt/keyrings/nodejs-unofficial.gpg

# Add repository
echo "deb [arch=riscv64 signed-by=/etc/apt/keyrings/nodejs-unofficial.gpg] https://gounthar.github.io/nodejs-unofficial-builds trixie main" | \
  sudo tee /etc/apt/sources.list.d/nodejs-unofficial.list

# Install
sudo apt update
sudo apt install nodejs
```

### DNF/YUM (Fedora/RHEL)

```bash
# Add repository
sudo curl -o /etc/yum.repos.d/nodejs-unofficial.repo \
  https://gounthar.github.io/nodejs-unofficial-builds/nodejs-unofficial.repo

# Install
sudo dnf install nodejs
```

## Automated Updates

This branch is automatically updated by GitHub Actions workflows:

1. **update-apt-repo.yml**: Adds new .deb packages to the APT repository
2. **update-rpm-repo.yml**: Adds new .rpm packages to the RPM repository

Both workflows are triggered when:
- A new release is published on the main branch
- Manually via `workflow_dispatch`

## GPG Signing

All repository metadata is signed with GPG key:
- **Key ID**: 56188341425B007407229B48FB1963FC3575A39D
- **Owner**: Docker RISC-V64 Repository (reused for Node.js)

## Maintenance

If you need to manually update this branch:

1. Never commit directly - use the workflows
2. If you must manually update:
   - Ensure GPG key is imported
   - Use `reprepro` for APT repository
   - Use `createrepo_c` for RPM repository
   - Sign all metadata with GPG

## Additional Information

- **Main Repository**: https://github.com/gounthar/nodejs-unofficial-builds
- **Installation Guide**: See REPOSITORY_INSTALLATION.md in main branch
- **Build Information**: See native-riscv64-build.yml workflow
