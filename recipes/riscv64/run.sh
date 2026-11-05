#!/usr/bin/env bash

set -e
set -x

release_urlbase="$1"
disttype="$2"
customtag="$3"
datestring="$4"
commit="$5"
fullversion="$6"
source_url="$7"
source_urlbase="$8"
config_flags="--openssl-no-asm"

cd /home/node

tar -xf node.tar.xz
cd "node-${fullversion}"

export CC_host="ccache gcc-13"
export CXX_host="ccache g++-13"
export CC="ccache /usr/bin/riscv64-linux-gnu-gcc-14"
export CXX="ccache /usr/bin/riscv64-linux-gnu-g++-14"
# Required to allow GCC to be able to build on RISC-V
export CXXFLAGS="-DHWY_BROKEN_EMU128=0 -DHWY_BROKEN_TARGETS=HWY_RVV"
# V8 in Node v26 calls the MacroAssembler::FloatMinMaxHelper template from
# maglev-ir-riscv.cc, but the template is only defined in another file, so the
# mksnapshot link fails with an undefined reference. Backport of V8 7d081be20f98
# (use the public Float64Min/Max wrappers). No-op on trees that already have it,
# skipped on trees without RISC-V Maglev (v22 and older).
if [ -f deps/v8/src/maglev/riscv/maglev-ir-riscv.cc ]; then
  sed -i \
    -e 's/__ FloatMinMaxHelper<double>(out, left, right, MaxMinKind::kMin);/__ Float64Min(out, left, right);/' \
    -e 's/__ FloatMinMaxHelper<double>(out, left, right, MaxMinKind::kMax);/__ Float64Max(out, left, right);/' \
    deps/v8/src/maglev/riscv/maglev-ir-riscv.cc
fi

make -j$(getconf _NPROCESSORS_ONLN) binary V= \
  DESTCPU="riscv64" \
  ARCH="riscv64" \
  VARIATION="" \
  DISTTYPE="$disttype" \
  CUSTOMTAG="$customtag" \
  DATESTRING="$datestring" \
  COMMIT="$commit" \
  RELEASE_URLBASE="$release_urlbase" \
  CONFIG_FLAGS="$config_flags"

# If removal of ICU is desired, add "BUILD_INTL_FLAGS=--with-intl=none" above

mv node-*.tar.?z /out/
