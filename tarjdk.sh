#!/bin/bash
set -e
. setdevkitpath.sh

unset AR AS CC CXX LD OBJCOPY RANLIB STRIP CPPFLAGS LDFLAGS
git clone --depth 1 -b v2.2.0 https://github.com/termux/termux-elf-cleaner || true
cd termux-elf-cleaner
# This is the last commit that uses autoconf, newer builds are using cmake
autoreconf --install
bash configure
make CFLAGS=-D__ANDROID_API__=${API}
cd ..

findexec() { find $1 -type f -name "*" -not -name "*.o" -exec sh -c '
    case "$(head -n 1 "$1")" in
      ?ELF*) exit 0;;
      MZ*) exit 0;;
      #!*/ocamlrun*)exit0;;
    esac
exit 1
' sh {} \; -print
}

findexec jreout | xargs -- ./termux-elf-cleaner/termux-elf-cleaner
findexec jdkout | xargs -- ./termux-elf-cleaner/termux-elf-cleaner

cp -rv jre_override/lib/* jreout/lib/ || true
cp -rv jre_override/lib/* jdkout/lib/ || true

cd jreout

# Strip
find ./ -name '*.so' -execdir ${TOOLCHAIN}/bin/llvm-strip {} \;

tar cJf ../jre17-${TARGET_SHORT}-`date +%Y%m%d`-${JDK_DEBUG_LEVEL}.tar.xz .

cd ../jdkout
tar cJf ../jdk17-${TARGET_SHORT}-`date +%Y%m%d`-${JDK_DEBUG_LEVEL}.tar.xz .

