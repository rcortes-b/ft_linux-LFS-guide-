#####################################################
#													#
#	with 'set -e' is possible that the scipt stops	#
#	in the 'make check' step						#
#####################################################

set -e

############### --- MAN-PAGES --- ###############

TARFILE=$(echo man-pages*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

rm -v man3/crypt*

make -R GIT=false prefix=/usr install

cd /sources
rm -rf $NAME

############### --- IANA-ETC --- ###############

TARFILE=$(echo iana*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

cp services protocols /etc

cd /sources
rm -rf $NAME

############### --- GLIBC --- ###############

TARFILE=$(echo glibc*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

patch -Np1 -i ../glibc-2.41-fhs-1.patch

mkdir -v build
cd       build

echo "rootsbindir=/usr/sbin" > configparms

../configure --prefix=/usr                            \
             --disable-werror                         \
             --enable-kernel=5.4                      \
             --enable-stack-protector=strong          \
             --disable-nscd                           \
             libc_cv_slibdir=/usr/lib

make

make check 2>&1 | tee /sources/glibc-test.log

### CAUTION!!!! 
###You should stop right now and check for possible failures and if necessary, solve them

grep '^FAIL:' glibc-test.log

touch /etc/ld.so.conf

sed '/test-installation/s@$(PERL)@echo not running@' -i ../Makefile

make install

sed '/RTLDLIST=/s@/usr@@g' -i /usr/bin/ldd

localedef -i C -f UTF-8 C.UTF-8
localedef -i cs_CZ -f UTF-8 cs_CZ.UTF-8
localedef -i de_DE -f ISO-8859-1 de_DE
localedef -i de_DE@euro -f ISO-8859-15 de_DE@euro
localedef -i de_DE -f UTF-8 de_DE.UTF-8
localedef -i el_GR -f ISO-8859-7 el_GR
localedef -i en_GB -f ISO-8859-1 en_GB
localedef -i en_GB -f UTF-8 en_GB.UTF-8
localedef -i en_HK -f ISO-8859-1 en_HK
localedef -i en_PH -f ISO-8859-1 en_PH
localedef -i en_US -f ISO-8859-1 en_US
localedef -i en_US -f UTF-8 en_US.UTF-8
localedef -i es_ES -f ISO-8859-15 es_ES@euro
localedef -i es_MX -f ISO-8859-1 es_MX
localedef -i fa_IR -f UTF-8 fa_IR
localedef -i fr_FR -f ISO-8859-1 fr_FR
localedef -i fr_FR@euro -f ISO-8859-15 fr_FR@euro
localedef -i fr_FR -f UTF-8 fr_FR.UTF-8
localedef -i is_IS -f ISO-8859-1 is_IS
localedef -i is_IS -f UTF-8 is_IS.UTF-8
localedef -i it_IT -f ISO-8859-1 it_IT
localedef -i it_IT -f ISO-8859-15 it_IT@euro
localedef -i it_IT -f UTF-8 it_IT.UTF-8
localedef -i ja_JP -f EUC-JP ja_JP
localedef -i ja_JP -f SHIFT_JIS ja_JP.SJIS 2> /dev/null || true
localedef -i ja_JP -f UTF-8 ja_JP.UTF-8
localedef -i nl_NL@euro -f ISO-8859-15 nl_NL@euro
localedef -i ru_RU -f KOI8-R ru_RU.KOI8-R
localedef -i ru_RU -f UTF-8 ru_RU.UTF-8
localedef -i se_NO -f UTF-8 se_NO.UTF-8
localedef -i ta_IN -f UTF-8 ta_IN.UTF-8
localedef -i tr_TR -f UTF-8 tr_TR.UTF-8
localedef -i zh_CN -f GB18030 zh_CN.GB18030
localedef -i zh_HK -f BIG5-HKSCS zh_HK.BIG5-HKSCS
localedef -i zh_TW -f UTF-8 zh_TW.UTF-8

make localedata/install-locales

localedef -i C -f UTF-8 C.UTF-8
localedef -i ja_JP -f SHIFT_JIS ja_JP.SJIS 2> /dev/null || true

cat > /etc/nsswitch.conf << "EOF"
# Begin /etc/nsswitch.conf

passwd: files
group: files
shadow: files

hosts: files dns
networks: files

protocols: files
services: files
ethers: files
rpc: files

# End /etc/nsswitch.conf
EOF

tar -xf ../../tzdata2025a.tar.gz

ZONEINFO=/usr/share/zoneinfo
mkdir -pv $ZONEINFO/{posix,right}

for tz in etcetera southamerica northamerica europe africa antarctica  \
          asia australasia backward; do
    zic -L /dev/null   -d $ZONEINFO       ${tz}
    zic -L /dev/null   -d $ZONEINFO/posix ${tz}
    zic -L leapseconds -d $ZONEINFO/right ${tz}
done

cp -v zone.tab zone1970.tab iso3166.tab $ZONEINFO
zic -d $ZONEINFO -p America/New_York
unset ZONEINFO tz

### Here you have to do some manual steps (in my case my localtime is Europe/Madrid)

tzselect

ln -sfv /usr/share/zoneinfo/Europe/Madrid /etc/localtime

cat > /etc/ld.so.conf << "EOF"
# Begin /etc/ld.so.conf
/usr/local/lib
/opt/lib

EOF

cat >> /etc/ld.so.conf << "EOF"
# Add an include directory
include /etc/ld.so.conf.d/*.conf

EOF
mkdir -pv /etc/ld.so.conf.d

cd /sources
rm -rf $NAME

############### --- ZLIB --- ###############

TARFILE=$(echo zlib*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

./configure --prefix=/usr

make

make install

rm -fv /usr/lib/libz.a

cd /sources
rm -rf $NAME

############### --- BZIP --- ###############

TARFILE=$(echo bzip*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

patch -Np1 -i ../bzip2-1.0.8-install_docs-1.patch

sed -i 's@\(ln -s -f \)$(PREFIX)/bin/@\1@' Makefile
sed -i "s@(PREFIX)/man@(PREFIX)/share/man@g" Makefile

make -f Makefile-libbz2_so
make clean

make PREFIX=/usr install

cp -av libbz2.so.* /usr/lib
ln -sv libbz2.so.1.0.8 /usr/lib/libbz2.so

cp -v bzip2-shared /usr/bin/bzip2
for i in /usr/bin/{bzcat,bunzip2}; do
  ln -sfv bzip2 $i
done

rm -fv /usr/lib/libbz2.a

cd /sources
rm -rf $NAME

############### --- XZ --- ###############

TARFILE=$(echo xz*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/xz-5.6.4

make

make check 2>&1 | tee /sources/xz-test.log

make install

cd /sources
rm -rf $NAME

############### --- LZ4 --- ###############

TARFILE=$(echo lz4*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

make BUILD_STATIC=no PREFIX=/usr

make -j1 check 2>&1 | tee /sources/lz4-test.log

make BUILD_STATIC=no PREFIX=/usr install

cd /sources
rm -rf $NAME

############### --- ZSTD --- ###############

TARFILE=$(echo zstd*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

make prefix=/usr

make check 2>&1 | tee /sources/zstd-test.log

make prefix=/usr install

rm -v /usr/lib/libzstd.a

cd /sources
rm -rf $NAME

############### --- FILE --- ###############

TARFILE=$(echo file*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

./configure --prefix=/usr

make

make check 2>&1 | tee /sources/file-test.log

make install

cd /sources
rm -rf $NAME

############### --- READLINE --- ###############

TARFILE=$(echo readline*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

sed -i '/MV.*old/d' Makefile.in
sed -i '/{OLDSUFF}/c:' support/shlib-install
sed -i 's/-Wl,-rpath,[^ ]*//' support/shobj-conf

./configure --prefix=/usr    \
            --disable-static \
            --with-curses    \
            --docdir=/usr/share/doc/readline-8.2.13

make SHLIB_LIBS="-lncursesw"

make install
install -v -m644 doc/*.{ps,pdf,html,dvi} /usr/share/doc/readline-8.2.13

cd /sources
rm -rf $NAME

############### --- M4 --- ###############

TARFILE=$(echo m4*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

./configure --prefix=/usr

make

make check 2>&1 | tee /sources/m4-test.log

make install

cd /sources
rm -rf $NAME

############### --- BC --- ###############

TARFILE=$(echo bc*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

CC=gcc ./configure --prefix=/usr -G -O3 -r

make

make test

make install

cd /sources
rm -rf $NAME
