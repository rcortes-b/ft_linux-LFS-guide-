set -e
############### --- M4 --- ###############

TARFILE=$(echo m4*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)

make

make DESTDIR=$LFS install

cd $LFS/sources
rm -rf $NAME

############### --- NCURSES --- ###############

TARFILE=$(echo ncurses*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

mkdir build
pushd build
../configure AWK=gawk
make -C include
make -C progs tic
popd

./configure --prefix=/usr                \
            --host=$LFS_TGT              \
            --build=$(./config.guess)    \
            --mandir=/usr/share/man      \
            --with-manpage-format=normal \
            --with-shared                \
            --without-normal             \
            --with-cxx-shared            \
            --without-debug              \
            --without-ada                \
            --disable-stripping          \
            AWK=gawk

make

make DESTDIR=$LFS TIC_PATH=$(pwd)/build/progs/tic install
ln -sv libncursesw.so $LFS/usr/lib/libncurses.so
sed -e 's/^#if.*XOPEN.*$/#if 1/' \
    -i $LFS/usr/include/curses.h

cd $LFS/sources
rm -rf $NAME

############### --- BASH --- ###############

TARFILE=$(echo bash*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

./configure --prefix=/usr                      \
            --build=$(sh support/config.guess) \
            --host=$LFS_TGT                    \
            --without-bash-malloc

make

make DESTDIR=$LFS install

ln -sv bash $LFS/bin/sh

cd $LFS/sources
rm -rf $NAME

############### --- COREUTILS --- ###############

TARFILE=$(echo coreutils*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

./configure --prefix=/usr                     \
            --host=$LFS_TGT                   \
            --build=$(build-aux/config.guess) \
            --enable-install-program=hostname \
            --enable-no-install-program=kill,uptime

make

make DESTDIR=$LFS install

mv -v $LFS/usr/bin/chroot $LFS/usr/sbin
mkdir -pv $LFS/usr/share/man/man8
mv -v $LFS/usr/share/man/man1/chroot.1 $LFS/usr/share/man/man8/chroot.8
sed -i 's/"1"/"8"/' $LFS/usr/share/man/man8/chroot.8

cd $LFS/sources
rm -rf $NAME

############### --- DIFFUTILS --- ###############

TARFILE=$(echo diffutils*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(./build-aux/config.guess)

make

make DESTDIR=$LFS install

cd $LFS/sources
rm -rf $NAME

############### --- FILE --- ###############

TARFILE=$(echo file*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

mkdir build
pushd build
../configure --disable-bzlib      \
             --disable-libseccomp \
             --disable-xzlib      \
             --disable-zlib
make
popd

./configure --prefix=/usr --host=$LFS_TGT --build=$(./config.guess)

make FILE_COMPILE=$(pwd)/build/src/file

make DESTDIR=$LFS install

rm -v $LFS/usr/lib/libmagic.la

cd $LFS/sources
rm -rf $NAME

############### --- FINDUTILS --- ###############

TARFILE=$(echo findutils*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

./configure --prefix=/usr                   \
            --localstatedir=/var/lib/locate \
            --host=$LFS_TGT                 \
            --build=$(build-aux/config.guess)

make

make DESTDIR=$LFS install

cd $LFS/sources
rm -rf $NAME

############### --- GAWK --- ###############

TARFILE=$(echo gawk*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

sed -i 's/extras//' Makefile.in

./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)

make

make DESTDIR=$LFS install

cd $LFS/sources
rm -rf $NAME

############### --- GREP --- ###############

TARFILE=$(echo grep*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(./build-aux/config.guess)

make

make DESTDIR=$LFS install

cd $LFS/sources
rm -rf $NAME

############### --- GZIP --- ###############

TARFILE=$(echo gzip*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

./configure --prefix=/usr   \
            --host=$LFS_TGT

make

make DESTDIR=$LFS install

cd $LFS/sources
rm -rf $NAME

############### --- MAKE --- ###############

TARFILE=$(echo make*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

./configure --prefix=/usr   \
            --without-guile \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)

make

make DESTDIR=$LFS install

cd $LFS/sources
rm -rf $NAME

############### --- PATCH --- ###############

TARFILE=$(echo patch*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)

make

make DESTDIR=$LFS install

cd $LFS/sources
rm -rf $NAME

############### --- SED --- ###############

TARFILE=$(echo sed*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(./build-aux/config.guess)

make

make DESTDIR=$LFS install

cd $LFS/sources
rm -rf $NAME

############### --- TAR --- ###############

TARFILE=$(echo tar*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)

make

make DESTDIR=$LFS install

cd $LFS/sources
rm -rf $NAME

############### --- XZ --- ###############

TARFILE=$(echo xz*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

./configure --prefix=/usr                     \
            --host=$LFS_TGT                   \
            --build=$(build-aux/config.guess) \
            --disable-static                  \
            --docdir=/usr/share/doc/xz-5.6.4

make

make DESTDIR=$LFS install

rm -v $LFS/usr/lib/liblzma.la

cd $LFS/sources
rm -rf $NAME

############### --- BINUTILS - PASS 2 --- ###############

TARFILE=$(echo binutils*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

sed '6031s/$add_dir//' -i ltmain.sh

mkdir -v build
cd       build

../configure                   \
    --prefix=/usr              \
    --build=$(../config.guess) \
    --host=$LFS_TGT            \
    --disable-nls              \
    --enable-shared            \
    --enable-gprofng=no        \
    --disable-werror           \
    --enable-64-bit-bfd        \
    --enable-new-dtags         \
    --enable-default-hash-style=gnu

make

make DESTDIR=$LFS install

rm -v $LFS/usr/lib/lib{bfd,ctf,ctf-nobfd,opcodes,sframe}.{a,la}

cd $LFS/sources
rm -rf $NAME

############### --- GCC - PASS 2 --- ###############

TARFILE=$(echo gcc*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

tar -xf ../mpfr-4.2.1.tar.xz
mv -v mpfr-4.2.1 mpfr
tar -xf ../gmp-6.3.0.tar.xz
mv -v gmp-6.3.0 gmp
tar -xf ../mpc-1.3.1.tar.gz
mv -v mpc-1.3.1 mpc

sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64

sed '/thread_header =/s/@.*@/gthr-posix.h/' -i libgcc/Makefile.in libstdc++-v3/include/Makefile.in

mkdir -v build
cd       build

../configure                                       \
    --build=$(../config.guess)                     \
    --host=$LFS_TGT                                \
    --target=$LFS_TGT                              \
    LDFLAGS_FOR_TARGET=-L$PWD/$LFS_TGT/libgcc      \
    --prefix=/usr                                  \
    --with-build-sysroot=$LFS                      \
    --enable-default-pie                           \
    --enable-default-ssp                           \
    --disable-nls                                  \
    --disable-multilib                             \
    --disable-libatomic                            \
    --disable-libgomp                              \
    --disable-libquadmath                          \
    --disable-libsanitizer                         \
    --disable-libssp                               \
    --disable-libvtv                               \
    --enable-languages=c,c++

make

make DESTDIR=$LFS install

ln -sv gcc $LFS/usr/bin/cc

cd $LFS/sources
rm -rf $NAME
