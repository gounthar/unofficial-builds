Name:           nodejs-unofficial
Version:        24.11.1
Release:        1%{?dist}
Summary:        Node.js JavaScript runtime - RISC-V 64-bit native build (unofficial)
License:        MIT
URL:            https://github.com/gounthar/unofficial-builds
Source0:        node-v%{version}-linux-riscv64.tar.xz

BuildArch:      riscv64

AutoReqProv:    yes

Provides:       nodejs-riscv64
Conflicts:      nodejs-unofficial-old

# Disable debug package generation (pre-built binaries, no debug sources)
%global debug_package %{nil}
%global _enable_debug_package 0
%global _build_id_links none

# Keep the upstream `#!/usr/bin/env node` shebangs. Mangling them to
# /usr/bin/node breaks npm/npx/corepack (node lives in /usr/local/bin) and
# makes auto-requires demand /usr/bin/node and /usr/bin/pwsh.
%global __brp_mangle_shebangs %{nil}

%description
Node.js is a JavaScript runtime built on Chrome's V8 JavaScript engine.
This package provides Node.js v%{version} built natively for RISC-V64
architecture on actual riscv64 hardware (Banana Pi F3).

This is an unofficial build that installs to /opt/nodejs-unofficial/ and
creates symlinks in /usr/local/bin/ to avoid conflicts with system Node.js
packages. Includes node, npm and npx, plus corepack on Node.js releases
that still bundle it (v24 and older).

%prep
%setup -q -n node-v%{version}-linux-riscv64

%build
# No build needed - pre-built binaries

%install
install -d %{buildroot}/opt/nodejs-unofficial
install -d %{buildroot}/usr/local/bin
install -d %{buildroot}/etc/profile.d

# Copy the tree as shipped: bin/npm, bin/npx and bin/corepack are relative
# symlinks into lib/node_modules, so they must stay symlinks and the
# lib/node_modules layout must not change.
cp -a bin lib include share %{buildroot}/opt/nodejs-unofficial/

# Create symlinks in /usr/local/bin for PATH (works in all shell types)
ln -s /opt/nodejs-unofficial/bin/node %{buildroot}/usr/local/bin/node
ln -s /opt/nodejs-unofficial/bin/npm %{buildroot}/usr/local/bin/npm
ln -s /opt/nodejs-unofficial/bin/npx %{buildroot}/usr/local/bin/npx

# Node.js 25+ no longer bundles corepack, so link it only when the tarball has it.
# The generated list always holds the profile.d script: rpmbuild rejects an empty %files -f list.
echo /etc/profile.d/nodejs-unofficial.sh > extra.files
if [ -e bin/corepack ]; then
  ln -s /opt/nodejs-unofficial/bin/corepack %{buildroot}/usr/local/bin/corepack
  echo /usr/local/bin/corepack >> extra.files
fi

# Create profile.d script for MANPATH
cat > %{buildroot}/etc/profile.d/nodejs-unofficial.sh <<'EOF'
#!/bin/sh
# Add Node.js unofficial builds man pages
export MANPATH="/opt/nodejs-unofficial/share/man:${MANPATH:-}"
EOF
chmod 644 %{buildroot}/etc/profile.d/nodejs-unofficial.sh

%files -f extra.files
%license LICENSE
%doc README.md
/opt/nodejs-unofficial/
/usr/local/bin/node
/usr/local/bin/npm
/usr/local/bin/npx

%changelog
* Thu Nov 13 2025 Bruno Verachten <gounthar@gmail.com> - 24.11.1-1
- Initial RPM packaging for RISC-V64
- Built natively on Banana Pi F3 hardware
- Node.js v24.11.1 with --openssl-no-asm flag
