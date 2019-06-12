#/bin/bash
######################################################
### Explanation and correction of errors in :
###          https://niemand108.wordpress.com/2019/06/09/cross-compiling-with-old-shit-for-arm32-targets-in-2019-armv7-a-kernel-3-0/
######################################################


# -------------------
TARGET=armv7-unk-linuxeabi #only you must change this variable
PREFIX=/home/$(whoami)/tmp/cross-compiler-output
PREFIX_ARCH=$PREFIX/$TARGET
HEADERS=$PREFIX/$TARGET/include
BUILDS=/home/$(whoami)/tmp/builds
SOURCE=/home/$(whoami)/tmp/source
export PATH=$PREFIX/bin/:$PATH
# -------------------
mkdir -p $PREFIX
mkdir -p $SOURCE
mkdir -p $BUILDS
mkdir -p $BUILDS/build-binutils
mkdir -p $BUILDS/build-gcc
mkdir -p $BUILDS/build-glibc
# -------------------
cd $SOURCE
wget https://mirrors.edge.kernel.org/pub/linux/kernel/v3.0/linux-3.0.36.tar.gz
wget https://ftp.gnu.org/gnu/gcc/gcc-4.8.5/gcc-4.8.5.tar.gz
wget https://ftp.gnu.org/gnu/glibc/glibc-2.19.tar.gz
wget http://ftpmirror.gnu.org/binutils/binutils-2.24.tar.gz
tar xzf linux-3.0.36.tar.gz
tar xzf gcc-4.8.5.tar.gz
tar xzf glibc-2.19.tar.gz
tar xzf binutils-2.24.tar.gz
# ------------
cd $SOURCE/gcc-4.8.5
./contrib/download_prerequisites
# -------------
cd $BUILDS/build-binutils
CFLAGS='-Wno-cast-function-type -Wno-error -Wno-implicit-fallthrough -Wno-format-overflow' CCFLAGS='-Wno-cast-function-type -Wno-error -Wno-implicit-fallthrough -Wno-format-overflow' $SOURCE/binutils-2.24/configure --prefix=$PREFIX --target=$TARGET --disable-multilib
make -j4
make install
# --------------
cd $SOURCE/linux-3.0.36/
make ARCH=arm INSTALL_HDR_PATH=$PREFIX_ARCH headers_install
# -------------------
cd $BUILDS/build-gcc/
$SOURCE/gcc-4.8.5/configure --prefix=$PREFIX --target=$TARGET --enable-languages=c,c++ --disable-multilib
make -j4 all-gcc
# --------------------
cd $BUILDS/build-glibc/
$SOURCE/glibc-2.19/configure –prefix=$PREFIX_ARCH –build=$MACHTYPE –host=$TARGET –target=$TARGET –with-headers=$HEADERS –disable-multilib libc_cv_forced_unwind=yes
make install-bootstrap-headers=yes install-headers
make -j4 csu/subdir_lib
install csu/crt1.o csu/crti.o csu/crtn.o $PREFIX_ARCH/lib
$($TARGET-gcc -nostdlib -nostartfiles -shared -x c /dev/null -o $PREFIX_ARCH/lib/libc.so)
touch $PREFIX_ARCH/include/gnu/stubs.h
# ------------------
cd $BUILDS/build-gcc/
make -j4 all-target-libgcc
make install-target-libgcc
# ----------------- 
cd $BUILDS/build-glibc
make -j4
make install
# -----------------
cd $BUILDS/build-gcc/
make -j4
make install
# ----------------
cd $SOURCE/linux-3.0.3
make ARCH=arm CROSS_COMPILE=$TARGET- vexpress_defconfig
make ARCH=arm CROSS_COMPILE=$TARGET- menuconfig
make ARCH=arm CROSS_COMPILE=$TARGET- -j4 all
