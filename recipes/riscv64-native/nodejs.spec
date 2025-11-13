Name:           nodejs
Version:        24.11.1
Release:        1%{?dist}
Summary:        Node.js JavaScript runtime - RISC-V 64-bit native build
License:        MIT
URL:            https://github.com/gounthar/unofficial-builds
Source0:        node-v%{version}-linux-riscv64.tar.xz

BuildArch:      riscv64

AutoReqProv:    yes

%description
Node.js is a JavaScript runtime built on Chrome's V8 JavaScript engine.
This package provides Node.js v%{version} built natively for RISC-V64
architecture on actual riscv64 hardware (Banana Pi F3).

%prep
%setup -q -n node-v%{version}-linux-riscv64

%build
# No build needed - pre-built binaries

%install
# Create necessary directories
install -d %{buildroot}%{_bindir}
install -d %{buildroot}%{_libdir}/node_modules
install -d %{buildroot}%{_includedir}/node
install -d %{buildroot}%{_mandir}/man1

# Install binaries
install -p -m 0755 bin/node %{buildroot}%{_bindir}/node
install -p -m 0755 bin/npm %{buildroot}%{_bindir}/npm
install -p -m 0755 bin/npx %{buildroot}%{_bindir}/npx
install -p -m 0755 bin/corepack %{buildroot}%{_bindir}/corepack

# Install library files
cp -pr lib/* %{buildroot}%{_libdir}/node_modules/

# Install includes
cp -pr include/* %{buildroot}%{_includedir}/node/

# Install man pages
cp -pr share/man/man1/* %{buildroot}%{_mandir}/man1/

%files
%license LICENSE
%doc README.md
%{_bindir}/node
%{_bindir}/npm
%{_bindir}/npx
%{_bindir}/corepack
%{_libdir}/node_modules/
%{_includedir}/node/
%{_mandir}/man1/*

%changelog
* Wed Nov 13 2025 Bruno Verachten <gounthar@gmail.com> - 24.11.1-1
- Initial RPM packaging for RISC-V64
- Built natively on Banana Pi F3 hardware
- Node.js v24.11.1 with --openssl-no-asm flag
