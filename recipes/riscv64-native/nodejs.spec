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

%description
Node.js is a JavaScript runtime built on Chrome's V8 JavaScript engine.
This package provides Node.js v%{version} built natively for RISC-V64
architecture on actual riscv64 hardware (Banana Pi F3).

This is an unofficial build that installs to /opt/nodejs-unofficial/ and
creates symlinks in /usr/local/bin/ to avoid conflicts with system Node.js
packages. Includes node, npm, npx, and corepack.

%prep
%setup -q -n node-v%{version}-linux-riscv64

%build
# No build needed - pre-built binaries

%install
# Create necessary directories
install -d %{buildroot}/opt/nodejs-unofficial/bin
install -d %{buildroot}/opt/nodejs-unofficial/lib/node_modules
install -d %{buildroot}/opt/nodejs-unofficial/include
install -d %{buildroot}/opt/nodejs-unofficial/share/man/man1
install -d %{buildroot}%{_bindir}

# Install to /opt/nodejs-unofficial
install -p -m 0755 bin/node %{buildroot}/opt/nodejs-unofficial/bin/node
install -p -m 0755 bin/npm %{buildroot}/opt/nodejs-unofficial/bin/npm
install -p -m 0755 bin/npx %{buildroot}/opt/nodejs-unofficial/bin/npx
install -p -m 0755 bin/corepack %{buildroot}/opt/nodejs-unofficial/bin/corepack

cp -pr lib/* %{buildroot}/opt/nodejs-unofficial/lib/node_modules/
cp -pr include/* %{buildroot}/opt/nodejs-unofficial/include/
cp -pr share/man/man1/* %{buildroot}/opt/nodejs-unofficial/share/man/man1/

# Create symlinks in /usr/local/bin for PATH
ln -s /opt/nodejs-unofficial/bin/node %{buildroot}%{_bindir}/node
ln -s /opt/nodejs-unofficial/bin/npm %{buildroot}%{_bindir}/npm
ln -s /opt/nodejs-unofficial/bin/npx %{buildroot}%{_bindir}/npx
ln -s /opt/nodejs-unofficial/bin/corepack %{buildroot}%{_bindir}/corepack

%files
%license LICENSE
%doc README.md
/opt/nodejs-unofficial/
%{_bindir}/node
%{_bindir}/npm
%{_bindir}/npx
%{_bindir}/corepack

%changelog
* Wed Nov 13 2025 Bruno Verachten <gounthar@gmail.com> - 24.11.1-1
- Initial RPM packaging for RISC-V64
- Built natively on Banana Pi F3 hardware
- Node.js v24.11.1 with --openssl-no-asm flag
