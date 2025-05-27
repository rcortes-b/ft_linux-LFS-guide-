#####################################################
#													#
#	with 'set -e' is possible that the scipt stops	#
#	in the 'make check' step						#
#####################################################

set -e
mkdir -pv /sources/logs

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

make check 2>&1 | tee /sources/logs/glibc-test.log

### CAUTION!!!! 
###You should stop right now and check for possible failures and if necessary, solve them

grep '^FAIL:' /sources/logs/glibc-test.log

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

make check 2>&1 | tee /sources/logs/xz-test.log

make install

cd /sources
rm -rf $NAME

############### --- LZ4 --- ###############

TARFILE=$(echo lz4*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

make BUILD_STATIC=no PREFIX=/usr

make -j1 check 2>&1 | tee /sources/logs/lz4-test.log

make BUILD_STATIC=no PREFIX=/usr install

cd /sources
rm -rf $NAME

############### --- ZSTD --- ###############

TARFILE=$(echo zstd*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

make prefix=/usr

make check 2>&1 | tee /sources/logs/zstd-test.log

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

make check 2>&1 | tee /sources/logs/file-test.log

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

make check 2>&1 | tee /sources/logs/m4-test.log

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

############### --- FLEX --- ###############

TARFILE=$(echo flex*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

./configure --prefix=/usr \
            --docdir=/usr/share/doc/flex-2.6.4 \
            --disable-static

make

make check 2>&1 | tee /sources/logs/flex-test.log

make install

ln -sv flex   /usr/bin/lex
ln -sv flex.1 /usr/share/man/man1/lex.1

cd /sources
rm -rf $NAME

############### --- TCL --- ###############

TARFILE=$(echo tcl*-src.tar.*)
NAME=$(echo ${TARFILE%-src.tar.*})

tar -xf $TARFILE

cd $NAME

SRCDIR=$(pwd)
cd unix
./configure --prefix=/usr           \
            --mandir=/usr/share/man \
            --disable-rpath

make

sed -e "s|$SRCDIR/unix|/usr/lib|" \
    -e "s|$SRCDIR|/usr/include|"  \
    -i tclConfig.sh

sed -e "s|$SRCDIR/unix/pkgs/tdbc1.1.10|/usr/lib/tdbc1.1.10|" \
    -e "s|$SRCDIR/pkgs/tdbc1.1.10/generic|/usr/include|"    \
    -e "s|$SRCDIR/pkgs/tdbc1.1.10/library|/usr/lib/tcl8.6|" \
    -e "s|$SRCDIR/pkgs/tdbc1.1.10|/usr/include|"            \
    -i pkgs/tdbc1.1.10/tdbcConfig.sh

sed -e "s|$SRCDIR/unix/pkgs/itcl4.3.2|/usr/lib/itcl4.3.2|" \
    -e "s|$SRCDIR/pkgs/itcl4.3.2/generic|/usr/include|"    \
    -e "s|$SRCDIR/pkgs/itcl4.3.2|/usr/include|"            \
    -i pkgs/itcl4.3.2/itclConfig.sh

unset SRCDIR

make test

make install

chmod -v u+w /usr/lib/libtcl8.6.so

make install-private-headers

ln -sfv tclsh8.6 /usr/bin/tclsh
mv /usr/share/man/man3/{Thread,Tcl_Thread}.3

cd ..
tar -xf ../tcl8.6.16-html.tar.gz --strip-components=1
mkdir -v -p /usr/share/doc/tcl-8.6.16
cp -v -r  ./html/* /usr/share/doc/tcl-8.6.16

cd /sources
rm -rf $NAME

############### --- EXPECT --- ###############

TARFILE=$(echo expect*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

python3 -c 'from pty import spawn; spawn(["echo", "ok"])'

./configure --prefix=/usr           \
            --with-tcl=/usr/lib     \
            --enable-shared         \
            --disable-rpath         \
            --mandir=/usr/share/man \
            --with-tclinclude=/usr/include

make

make test

make install
ln -svf expect5.45.4/libexpect5.45.4.so /usr/lib

cd /sources
rm -rf $NAME

############### --- DEJAGNU --- ###############

TARFILE=$(echo dejagnu*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

mkdir -v build
cd       build

../configure --prefix=/usr
makeinfo --html --no-split -o doc/dejagnu.html ../doc/dejagnu.texi
makeinfo --plaintext       -o doc/dejagnu.txt  ../doc/dejagnu.texi

make check 2>&1 | tee /sources/logs/dejagnu-test.log

make install
install -v -dm755  /usr/share/doc/dejagnu-1.6.3
install -v -m644   doc/dejagnu.{html,txt} /usr/share/doc/dejagnu-1.6.3

cd /sources
rm -rf $NAME

############### --- PKGCONF --- ###############

TARFILE=$(echo pkgconf*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

./configure --prefix=/usr              \
            --disable-static           \
            --docdir=/usr/share/doc/pkgconf-2.3.0

make

make install

ln -sv pkgconf   /usr/bin/pkg-config
ln -sv pkgconf.1 /usr/share/man/man1/pkg-config.1

cd /sources
rm -rf $NAME

############### --- BINUTILS --- ###############

TARFILE=$(echo binutils*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

mkdir -v build
cd       build

../configure --prefix=/usr       \
             --sysconfdir=/etc   \
             --enable-ld=default \
             --enable-plugins    \
             --enable-shared     \
             --disable-werror    \
             --enable-64-bit-bfd \
             --enable-new-dtags  \
             --with-system-zlib  \
             --enable-default-hash-style=gnu

make tooldir=/usr

make -k check 2>&1 | tee /sources/logs/binutils-test.log

make tooldir=/usr install

rm -rfv /usr/lib/lib{bfd,ctf,ctf-nobfd,gprofng,opcodes,sframe}.a \
        /usr/share/doc/gprofng/

cd /sources
rm -rf $NAME

############### --- GMP --- ###############

TARFILE=$(echo gmp*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

./configure --prefix=/usr    \
            --enable-cxx     \
            --disable-static \
            --docdir=/usr/share/doc/gmp-6.3.0

make
make html

make check 2>&1 | tee /sources/logs/gmp-test.log

awk '/# PASS:/{total+=$3} ; END{print total}' /sources/logs/gmp-test.log

make install
make install-html

cd /sources
rm -rf $NAME

############### --- MPFR --- ###############

TARFILE=$(echo mpfr*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

./configure --prefix=/usr        \
            --disable-static     \
            --enable-thread-safe \
            --docdir=/usr/share/doc/mpfr-4.2.1

make
make html

make check 2>&1 | tee /sources/logs/mpfr-test.log

make install
make install-html

cd /sources
rm -rf $NAME

############### --- MPC --- ###############

TARFILE=$(echo mpc*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/mpc-1.3.1

make
make html

make check 2>&1 | tee /sources/logs/mpc-test.log

make install
make install-html

cd /sources
rm -rf $NAME

############### --- ATTR --- ###############

TARFILE=$(echo attr*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

./configure --prefix=/usr     \
            --disable-static  \
            --sysconfdir=/etc \
            --docdir=/usr/share/doc/attr-2.5.2

make

make check 2>&1 | tee /sources/logs/attr-test.log

make install

cd /sources
rm -rf $NAME

############### --- ACL --- ###############

TARFILE=$(echo acl*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

./configure --prefix=/usr         \
            --disable-static      \
            --docdir=/usr/share/doc/acl-2.3.2

make

make check 2>&1 | tee /sources/logs/acl-test.log

make install

cd /sources
rm -rf $NAME

############### --- LIBCAP --- ###############

TARFILE=$(echo libcap*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

sed -i '/install -m.*STA/d' libcap/Makefile

make test

make prefix=/usr lib=lib install

cd /sources
rm -rf $NAME

############### --- LIBXCRYPT --- ###############

TARFILE=$(echo libxcrypt*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

./configure --prefix=/usr                \
            --enable-hashes=strong,glibc \
            --enable-obsolete-api=no     \
            --disable-static             \
            --disable-failure-tokens

make

make check 2>&1 | tee /sources/logs/libxcrypt-test.log

make install

cd /sources
rm -rf $NAME

############### --- SHADOW --- ###############

TARFILE=$(echo shadow*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

sed -i 's/groups$(EXEEXT) //' src/Makefile.in
find man -name Makefile.in -exec sed -i 's/groups\.1 / /'   {} \;
find man -name Makefile.in -exec sed -i 's/getspnam\.3 / /' {} \;
find man -name Makefile.in -exec sed -i 's/passwd\.5 / /'   {} \;

sed -e 's:#ENCRYPT_METHOD DES:ENCRYPT_METHOD YESCRYPT:' \
    -e 's:/var/spool/mail:/var/mail:'                   \
    -e '/PATH=/{s@/sbin:@@;s@/bin:@@}'                  \
    -i etc/login.defs

touch /usr/bin/passwd
./configure --sysconfdir=/etc   \
            --disable-static    \
            --with-{b,yes}crypt \
            --without-libbsd    \
            --with-group-name-max-length=32

make
make exec_prefix=/usr install
make -C man install-man

pwconv
grpconv

mkdir -p /etc/default
useradd -D --gid 999

#Here you will set the root password manually
passwd root

cd /sources
rm -rf $NAME

############### --- GCC --- ###############

TARFILE=$(echo gcc*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
  ;;
esac

mkdir -v build
cd build

../configure --prefix=/usr            \
             LD=ld                    \
             --enable-languages=c,c++ \
             --enable-default-pie     \
             --enable-default-ssp     \
             --enable-host-pie        \
             --disable-multilib       \
             --disable-bootstrap      \
             --disable-fixincludes    \
             --with-system-zlib

make

ulimit -s -H unlimited
sed -e '/cpython/d'               -i ../gcc/testsuite/gcc.dg/plugin/plugin.exp
sed -e 's/no-pic /&-no-pie /'     -i ../gcc/testsuite/gcc.target/i386/pr113689-1.c
sed -e 's/300000/(1|300000)/'     -i ../libgomp/testsuite/libgomp.c-c++-common/pr109062.c
sed -e 's/{ target nonpic } //' \
    -e '/GOTPCREL/d'              -i ../gcc/testsuite/gcc.target/i386/fentryname3.c

chown -R tester .
su tester -c "PATH=$PATH make -k check" | tee /sources/logs/gcc-test.log
../contrib/test_summary > /sources/logs/gcc-test.log

make install

chown -v -R root:root \
    /usr/lib/gcc/$(gcc -dumpmachine)/14.2.0/include{,-fixed}

ln -svr /usr/bin/cpp /usr/lib
ln -sv gcc.1 /usr/share/man/man1/cc.1
ln -sfv ../../libexec/gcc/$(gcc -dumpmachine)/14.2.0/liblto_plugin.so \
        /usr/lib/bfd-plugins/

### At this moment you've to check if everything is going well following the steps in the LFS Book
### If everything is working, you can continue:

mkdir -pv /usr/share/gdb/auto-load/usr/lib
mv -v /usr/lib/*gdb.py /usr/share/gdb/auto-load/usr/lib

cd /sources
rm -rf $NAME

############### --- NCURSES --- ###############

TARFILE=$(echo ncurses*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

./configure --prefix=/usr           \
            --mandir=/usr/share/man \
            --with-shared           \
            --without-debug         \
            --without-normal        \
            --with-cxx-shared       \
            --enable-pc-files       \
            --with-pkg-config-libdir=/usr/lib/pkgconfig

make
make DESTDIR=$PWD/dest install
install -vm755 dest/usr/lib/libncursesw.so.6.5 /usr/lib
rm -v  dest/usr/lib/libncursesw.so.6.5
sed -e 's/^#if.*XOPEN.*$/#if 1/' \
    -i dest/usr/include/curses.h
cp -av dest/* /

for lib in ncurses form panel menu ; do
    ln -sfv lib${lib}w.so /usr/lib/lib${lib}.so
    ln -sfv ${lib}w.pc    /usr/lib/pkgconfig/${lib}.pc
done

ln -sfv libncursesw.so /usr/lib/libcurses.so
cp -v -R doc -T /usr/share/doc/ncurses-6.5

cd /sources
rm -rf $NAME

############### --- SED --- ###############

TARFILE=$(echo sed*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

./configure --prefix=/usr

make
make html

chown -R tester .
su tester -c "PATH=$PATH make check" | tee /sources/logs/sed-test.log

make install
install -d -m755           /usr/share/doc/sed-4.9
install -m644 doc/sed.html /usr/share/doc/sed-4.9

cd /sources
rm -rf $NAME

############### --- PSMISC --- ###############

TARFILE=$(echo psmisc*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

./configure --prefix=/usr

make
make check 2>&1 | tee /sources/logs/psmisc-test.log

make install

cd /sources
rm -rf $NAME

############### --- GETTEXT --- ###############

TARFILE=$(echo gettext*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/gettext-0.24

make
make check 2>&1 | tee /sources/logs/gettext-test.log

make install
chmod -v 0755 /usr/lib/preloadable_libintl.so

cd /sources
rm -rf $NAME

############### --- BISON --- ###############

TARFILE=$(echo bison*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

./configure --prefix=/usr --docdir=/usr/share/doc/bison-3.8.2

make
make check 2>&1 | tee /sources/logs/bison-test.log

make install

cd /sources
rm -rf $NAME

############### --- GREP --- ###############

TARFILE=$(echo grep*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

sed -i "s/echo/#echo/" src/egrep.sh

./configure --prefix=/usr

make
make check 2>&1 | tee /sources/logs/grep-test.log

make install

cd /sources
rm -rf $NAME

############### --- BASH --- ###############

TARFILE=$(echo bash*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

./configure --prefix=/usr             \
            --without-bash-malloc     \
            --with-installed-readline \
            --docdir=/usr/share/doc/bash-5.2.37

make

chown -R tester .
su -s /usr/bin/expect tester << "EOF"
set timeout -1
spawn make tests
expect eof
lassign [wait] _ _ _ value
exit $value
EOF

make install

exec /usr/bin/bash --login

cd /sources
rm -rf $NAME

############### --- LIBTOOL --- ###############

TARFILE=$(echo libtool*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

./configure --prefix=/usr

make
make check 2>&1 | tee /sources/logs/libtool-test.log

make install

rm -fv /usr/lib/libltdl.a

cd /sources
rm -rf $NAME

############### --- GDBM --- ###############

TARFILE=$(echo gdbm*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

./configure --prefix=/usr    \
            --disable-static \
            --enable-libgdbm-compat

make
make check 2>&1 | tee /sources/logs/gdbm-test.log

make install

cd /sources
rm -rf $NAME

############### --- GPERF --- ###############

TARFILE=$(echo gperf*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

./configure --prefix=/usr --docdir=/usr/share/doc/gperf-3.1

make
make -j1 check 2>&1 | tee /sources/logs/gperf-test.log

make install

cd /sources
rm -rf $NAME

############### --- EXPAT --- ###############

TARFILE=$(echo expat*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/expat-2.7.1

make
make check 2>&1 | tee /sources/logs/expat-test.log

make install
install -v -m644 doc/*.{html,css} /usr/share/doc/expat-2.7.1

cd /sources
rm -rf $NAME

############### --- INETUTILS --- ###############

TARFILE=$(echo inetutils*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

sed -i 's/def HAVE_TERMCAP_TGETENT/ 1/' telnet/telnet.c

./configure --prefix=/usr        \
            --bindir=/usr/bin    \
            --localstatedir=/var \
            --disable-logger     \
            --disable-whois      \
            --disable-rcp        \
            --disable-rexec      \
            --disable-rlogin     \
            --disable-rsh        \
            --disable-servers

make
make check 2>&1 | tee /sources/logs/inetutils-test.log

make install
mv -v /usr/{,s}bin/ifconfig

cd /sources
rm -rf $NAME

############### --- LESS --- ###############

TARFILE=$(echo less*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

./configure --prefix=/usr --sysconfdir=/etc

make
make check 2>&1 | tee /sources/logs/less-test.log

make install

cd /sources
rm -rf $NAME

############### --- PERL --- ###############

TARFILE=$(echo perl*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

export BUILD_ZLIB=False
export BUILD_BZIP2=0

sh Configure -des                                          \
             -D prefix=/usr                                \
             -D vendorprefix=/usr                          \
             -D privlib=/usr/lib/perl5/5.40/core_perl      \
             -D archlib=/usr/lib/perl5/5.40/core_perl      \
             -D sitelib=/usr/lib/perl5/5.40/site_perl      \
             -D sitearch=/usr/lib/perl5/5.40/site_perl     \
             -D vendorlib=/usr/lib/perl5/5.40/vendor_perl  \
             -D vendorarch=/usr/lib/perl5/5.40/vendor_perl \
             -D man1dir=/usr/share/man/man1                \
             -D man3dir=/usr/share/man/man3                \
             -D pager="/usr/bin/less -isR"                 \
             -D useshrplib                                 \
             -D usethreads

make
TEST_JOBS=$(nproc) make test_harness | tee /sources/logs/perl-test.log

make install
unset BUILD_ZLIB BUILD_BZIP2

cd /sources
rm -rf $NAME

############### --- XML::PARSER --- ###############

TARFILE=$(echo XML*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

perl Makefile.PL

make
make test | tee /sources/logs/XML-test.log

make install

cd /sources
rm -rf $NAME

############### --- INTLTOOL --- ###############

TARFILE=$(echo intl*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

sed -i 's:\\\${:\\\$\\{:' intltool-update.in

./configure --prefix=/usr

make
make check 2>&1 | tee /sources/logs/intltool-test.log

make install
install -v -Dm644 doc/I18N-HOWTO /usr/share/doc/intltool-0.51.0/I18N-HOWTO

cd /sources
rm -rf $NAME

############### --- AUTOCONF --- ###############

TARFILE=$(echo autoconf*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

./configure --prefix=/usr

make
make check 2>&1 | tee /sources/logs/autoconf-test.log

make install

cd /sources
rm -rf $NAME

############### --- AUTOMAKE --- ###############

TARFILE=$(echo automake*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

./configure --prefix=/usr --docdir=/usr/share/doc/automake-1.17

make
make -j$(($(nproc)>4?$(nproc):4)) check 2>&1 | tee /sources/logs/automake-test.log

make install

cd /sources
rm -rf $NAME

############### --- OPENSSL --- ###############

TARFILE=$(echo openssl*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

./config --prefix=/usr         \
         --openssldir=/etc/ssl \
         --libdir=lib          \
         shared                \
         zlib-dynamic
make
HARNESS_JOBS=$(nproc) make test | tee /sources/logs/openssl-test.log

sed -i '/INSTALL_LIBS/s/libcrypto.a libssl.a//' Makefile
make MANSUFFIX=ssl install

mv -v /usr/share/doc/openssl /usr/share/doc/openssl-3.4.1
cp -vfr doc/* /usr/share/doc/openssl-3.4.1

cd /sources
rm -rf $NAME

############### --- LIBELF FROM ELFUTILS --- ###############

TARFILE=$(echo elfutils*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

./configure --prefix=/usr                \
            --disable-debuginfod         \
            --enable-libdebuginfod=dummy

make
make check 2>&1 | tee /sources/logs/libelf-test.log

make -C libelf install
install -vm644 config/libelf.pc /usr/lib/pkgconfig
rm /usr/lib/libelf.a

cd /sources
rm -rf $NAME

############### --- LIBFFI --- ###############

TARFILE=$(echo libffi*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

./configure --prefix=/usr          \
            --disable-static       \
            --with-gcc-arch=native

make
make check 2>&1 | tee /sources/logs/libffi-test.log

make install

cd /sources
rm -rf $NAME

############### --- PYTHON --- ###############

TARFILE=$(echo Python*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

./configure --prefix=/usr        \
            --enable-shared      \
            --with-system-expat  \
            --enable-optimizations

make
make test TESTOPTS="--timeout 120" | tee /sources/logs/Python-test.log

make install

cat > /etc/pip.conf << EOF
[global]
root-user-action = ignore
disable-pip-version-check = true
EOF

install -v -dm755 /usr/share/doc/python-3.13.2/html

tar --strip-components=1  \
    --no-same-owner       \
    --no-same-permissions \
    -C /usr/share/doc/python-3.13.2/html \
    -xvf ../python-3.13.2-docs-html.tar.bz2

cd /sources
rm -rf $NAME

############### --- FLIT-CORE --- ###############

TARFILE=$(echo flit*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
pip3 install --no-index --find-links dist flit_core

cd /sources
rm -rf $NAME

############### --- WHEEL --- ###############

TARFILE=$(echo wheel*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
pip3 install --no-index --find-links dist wheel

cd /sources
rm -rf $NAME

############### --- SETUPTOOLS --- ###############

TARFILE=$(echo setuptools*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
pip3 install --no-index --find-links dist setuptools

cd /sources
rm -rf $NAME

############### --- NINJA --- ###############

TARFILE=$(echo ninja*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

export NINJAJOBS=4
sed -i '/int Guess/a \
  int   j = 0;\
  char* jobs = getenv( "NINJAJOBS" );\
  if ( jobs != NULL ) j = atoi( jobs );\
  if ( j > 0 ) return j;\
' src/ninja.cc

python3 configure.py --bootstrap --verbose
install -vm755 ninja /usr/bin/
install -vDm644 misc/bash-completion /usr/share/bash-completion/completions/ninja
install -vDm644 misc/zsh-completion  /usr/share/zsh/site-functions/_ninja

cd /sources
rm -rf $NAME

############### --- MESON --- ###############

TARFILE=$(echo meson*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD

pip3 install --no-index --find-links dist meson
install -vDm644 data/shell-completions/bash/meson /usr/share/bash-completion/completions/meson
install -vDm644 data/shell-completions/zsh/_meson /usr/share/zsh/site-functions/_meson

cd /sources
rm -rf $NAME

############### --- KMOD --- ###############

TARFILE=$(echo kmod*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

mkdir -p build
cd       build

meson setup --prefix=/usr ..    \
            --sbindir=/usr/sbin \
            --buildtype=release \
            -D manpages=false

ninja
ninja install

cd /sources
rm -rf $NAME

############### --- COREUTILS --- ###############

TARFILE=$(echo coreutils*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

patch -Np1 -i ../coreutils-9.6-i18n-1.patch

autoreconf -fv
automake -af
FORCE_UNSAFE_CONFIGURE=1 ./configure \
            --prefix=/usr            \
            --enable-no-install-program=kill,uptime

make
make NON_ROOT_USERNAME=tester check-root

groupadd -g 102 dummy -U tester
chown -R tester .
su tester -c "PATH=$PATH make -k RUN_EXPENSIVE_TESTS=yes check" \
   < /dev/null
groupdel dummy

make install

mv -v /usr/bin/chroot /usr/sbin
mv -v /usr/share/man/man1/chroot.1 /usr/share/man/man8/chroot.8
sed -i 's/"1"/"8"/' /usr/share/man/man8/chroot.8

cd /sources
rm -rf $NAME

############### --- CHECK --- ###############

TARFILE=$(echo check*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

./configure --prefix=/usr --disable-static

make
make check 2>&1 | tee /sources/logs/check-test.log
make docdir=/usr/share/doc/check-0.15.2 install

cd /sources
rm -rf $NAME

############### --- DIFFUTILS --- ###############

TARFILE=$(echo diffutils*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

./configure --prefix=/usr

make
make check 2>&1 | tee /sources/logs/diffutils-test.log
make install

cd /sources
rm -rf $NAME

############### --- GAWK --- ###############

TARFILE=$(echo gawk*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

sed -i 's/extras//' Makefile.in
./configure --prefix=/usr

make

chown -R tester .
su tester -c "PATH=$PATH make check" | tee /sources/logs/gawk-test.log

rm -f /usr/bin/gawk-5.3.1
make install

ln -sv gawk.1 /usr/share/man/man1/awk.1
install -vDm644 doc/{awkforai.txt,*.{eps,pdf,jpg}} -t /usr/share/doc/gawk-5.3.1

cd /sources
rm -rf $NAME

############### --- FINDUTILS --- ###############

TARFILE=$(echo findutils*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

./configure --prefix=/usr --localstatedir=/var/lib/locate

make

chown -R tester .
su tester -c "PATH=$PATH make check" | tee /sources/logs/findutils-test.log

make install

cd /sources
rm -rf $NAME

############### --- GROFF --- ###############

TARFILE=$(echo groff*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

PAGE=A4 ./configure --prefix=/usr

make

make check 2>&1 | tee /sources/logs/groff-test.log

make install

cd /sources
rm -rf $NAME

############### --- GRUB --- ###############

TARFILE=$(echo grub*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

unset {C,CPP,CXX,LD}FLAGS
echo depends bli part_gpt > grub-core/extra_deps.lst

./configure --prefix=/usr          \
            --sysconfdir=/etc      \
            --disable-efiemu       \
            --disable-werror

make

make install
mv -v /etc/bash_completion.d/grub /usr/share/bash-completion/completions

cd /sources
rm -rf $NAME

############### --- GZIP --- ###############

TARFILE=$(echo gzip*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

./configure --prefix=/usr

make

make check 2>&1 | tee /sources/logs/gzip-test.log

make install

cd /sources
rm -rf $NAME

############### --- IPROUTE --- ###############

TARFILE=$(echo iproute*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

sed -i /ARPD/d Makefile
rm -fv man/man8/arpd.8

make NETNS_RUN_DIR=/run/netns
make SBINDIR=/usr/sbin install
install -vDm644 COPYING README* -t /usr/share/doc/iproute2-6.13.0

cd /sources
rm -rf $NAME

############### --- KBD --- ###############

TARFILE=$(echo kbd*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

patch -Np1 -i ../kbd-2.7.1-backspace-1.patch
sed -i '/RESIZECONS_PROGS=/s/yes/no/' configure
sed -i 's/resizecons.8 //' docs/man/man8/Makefile.in

./configure --prefix=/usr --disable-vlock

make

make check 2>&1 | tee /sources/logs/kbd-test.log

make install
cp -R -v docs/doc -T /usr/share/doc/kbd-2.7.1

cd /sources
rm -rf $NAME

############### --- LIBPIPELINE --- ###############

TARFILE=$(echo libpipeline*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

./configure --prefix=/usr --disable-vlock

make

make check 2>&1 | tee /sources/logs/libpipeline-test.log

make install

cd /sources
rm -rf $NAME

############### --- MAKE --- ###############

TARFILE=$(echo make*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

./configure --prefix=/usr

make

chown -R tester .
su tester -c "PATH=$PATH make check" | tee /sources/logs/make-test.log

make install

cd /sources
rm -rf $NAME

############### --- PATCH --- ###############

TARFILE=$(echo patch*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

./configure --prefix=/usr

make

make check 2>&1 | tee /sources/logs/patch-test.log

make install

cd /sources
rm -rf $NAME

############### --- TAR --- ###############

TARFILE=$(echo tar*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

FORCE_UNSAFE_CONFIGURE=1  \
./configure --prefix=/usr

make

make check 2>&1 | tee /sources/logs/tar-test.log

make install
make -C doc install-html docdir=/usr/share/doc/tar-1.35

cd /sources
rm -rf $NAME

############### --- TEXINFO --- ###############

TARFILE=$(echo texinfo*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

./configure --prefix=/usr

make

make check 2>&1 | tee /sources/logs/texinfo-test.log

make install
make TEXMF=/usr/share/texmf install-tex

pushd /usr/share/info
  rm -v dir
  for f in *
    do install-info $f dir 2>/dev/null
  done
popd

cd /sources
rm -rf $NAME

############### --- VIM --- ###############

TARFILE=$(echo vim*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

echo '#define SYS_VIMRC_FILE "/etc/vimrc"' >> src/feature.h

./configure --prefix=/usr

make
chown -R tester .
sed '/test_plugin_glvs/d' -i src/testdir/Make_all.mak
su tester -c "TERM=xterm-256color LANG=en_US.UTF-8 make -j1 test" \
   &> vim-test.log

make install

ln -sv vim /usr/bin/vi
for L in  /usr/share/man/{,*/}man1/vim.1; do
    ln -sv vim.1 $(dirname $L)/vi.1
done
ln -sv ../vim/vim91/doc /usr/share/doc/vim-9.1.1166

cat > /etc/vimrc << "EOF"
" Begin /etc/vimrc

" Ensure defaults are set before customizing settings, not after
source $VIMRUNTIME/defaults.vim
let skip_defaults_vim=1

set nocompatible
set backspace=2
set mouse=
syntax on
if (&term == "xterm") || (&term == "putty")
  set background=dark
endif

" End /etc/vimrc
EOF

vim -c ':options'

cd /sources
rm -rf $NAME

############### --- MARKUPSAFE --- ###############

TARFILE=$(echo markupsafe*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
pip3 install --no-index --find-links dist Markupsafe

cd /sources
rm -rf $NAME

############### --- JINJA --- ###############

TARFILE=$(echo jinja*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
pip3 install --no-index --find-links dist Jinja2

cd /sources
rm -rf $NAME

############### --- UDEV --- ###############

TARFILE=$(echo systemd-257.3*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

sed -e 's/GROUP="render"/GROUP="video"/' \
    -e 's/GROUP="sgx", //'               \
    -i rules.d/50-udev-default.rules.in
sed -i '/systemd-sysctl/s/^/#/' rules.d/99-systemd.rules.in

mkdir -p build
cd       build

meson setup ..                  \
      --prefix=/usr             \
      --buildtype=release       \
      -D mode=release           \
      -D dev-kvm-mode=0660      \
      -D link-udev-shared=false \
      -D logind=false           \
      -D vconsole=false

export udev_helpers=$(grep "'name' :" ../src/udev/meson.build | \
                      awk '{print $3}' | tr -d ",'" | grep -v 'udevadm')

ninja udevadm systemd-hwdb                                           \
      $(ninja -n | grep -Eo '(src/(lib)?udev|rules.d|hwdb.d)/[^ ]*') \
      $(realpath libudev.so --relative-to .)                         \
      $udev_helpers

install -vm755 -d {/usr/lib,/etc}/udev/{hwdb.d,rules.d,network}
install -vm755 -d /usr/{lib,share}/pkgconfig
install -vm755 udevadm                             /usr/bin/
install -vm755 systemd-hwdb                        /usr/bin/udev-hwdb
ln      -svfn  ../bin/udevadm                      /usr/sbin/udevd
cp      -av    libudev.so{,*[0-9]}                 /usr/lib/
install -vm644 ../src/libudev/libudev.h            /usr/include/
install -vm644 src/libudev/*.pc                    /usr/lib/pkgconfig/
install -vm644 src/udev/*.pc                       /usr/share/pkgconfig/
install -vm644 ../src/udev/udev.conf               /etc/udev/
install -vm644 rules.d/* ../rules.d/README         /usr/lib/udev/rules.d/
install -vm644 $(find ../rules.d/*.rules \
                      -not -name '*power-switch*') /usr/lib/udev/rules.d/
install -vm644 hwdb.d/*  ../hwdb.d/{*.hwdb,README} /usr/lib/udev/hwdb.d/
install -vm755 $udev_helpers                       /usr/lib/udev
install -vm644 ../network/99-default.link          /usr/lib/udev/network

tar -xvf ../../udev-lfs-20230818.tar.xz
make -f udev-lfs-20230818/Makefile.lfs install

tar -xf ../../systemd-man-pages-257.3.tar.xz                            \
    --no-same-owner --strip-components=1                              \
    -C /usr/share/man --wildcards '*/udev*' '*/libudev*'              \
                                  '*/systemd.link.5'                  \
                                  '*/systemd-'{hwdb,udevd.service}.8

sed 's|systemd/network|udev/network|'                                 \
    /usr/share/man/man5/systemd.link.5                                \
  > /usr/share/man/man5/udev.link.5

sed 's/systemd\(\\\?-\)/udev\1/' /usr/share/man/man8/systemd-hwdb.8   \
                               > /usr/share/man/man8/udev-hwdb.8

sed 's|lib.*udevd|sbin/udevd|'                                        \
    /usr/share/man/man8/systemd-udevd.service.8                       \
  > /usr/share/man/man8/udevd.8

rm /usr/share/man/man*/systemd*

unset udev_helpers
udev-hwdb update

cd /sources
rm -rf $NAME

############### --- MAN-DB --- ###############

TARFILE=$(echo man-db*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

./configure --prefix=/usr                         \
            --docdir=/usr/share/doc/man-db-2.13.0 \
            --sysconfdir=/etc                     \
            --disable-setuid                      \
            --enable-cache-owner=bin              \
            --with-browser=/usr/bin/lynx          \
            --with-vgrind=/usr/bin/vgrind         \
            --with-grap=/usr/bin/grap             \
            --with-systemdtmpfilesdir=            \
            --with-systemdsystemunitdir=

make

make check 2>&1 | tee /sources/logs/mandb-test.log

make install

cd /sources
rm -rf $NAME

############### --- PROCPS-NG --- ###############

TARFILE=$(echo procps-ng*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

./configure --prefix=/usr                           \
            --docdir=/usr/share/doc/procps-ng-4.0.5 \
            --disable-static                        \
            --disable-kill                          \
            --enable-watch8bit

make

chown -R tester .
su tester -c "PATH=$PATH make check" | tee /sources/logs/procpsng-test.log

make install

cd /sources
rm -rf $NAME

############### --- UTIL-LINUX --- ###############

TARFILE=$(echo util-linux*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

./configure --bindir=/usr/bin     \
            --libdir=/usr/lib     \
            --runstatedir=/run    \
            --sbindir=/usr/sbin   \
            --disable-chfn-chsh   \
            --disable-login       \
            --disable-nologin     \
            --disable-su          \
            --disable-setpriv     \
            --disable-runuser     \
            --disable-pylibmount  \
            --disable-liblastlog2 \
            --disable-static      \
            --without-python      \
            --without-systemd     \
            --without-systemdsystemunitdir        \
            ADJTIME_PATH=/var/lib/hwclock/adjtime \
            --docdir=/usr/share/doc/util-linux-2.40.4

make

touch /etc/fstab
chown -R tester .
su tester -c "make -k check" | tee /sources/logs/utillinux-test.log

make install

cd /sources
rm -rf $NAME

############### --- E2FSPROGS --- ###############

TARFILE=$(echo e2fsprogs*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

mkdir -v build
cd       build

../configure --prefix=/usr           \
             --sysconfdir=/etc       \
             --enable-elf-shlibs     \
             --disable-libblkid      \
             --disable-libuuid       \
             --disable-uuidd         \
             --disable-fsck

make

make check 2>&1 | tee /sources/logs/e2fsprogs-test.log

make install

rm -fv /usr/lib/{libcom_err,libe2p,libext2fs,libss}.a
gunzip -v /usr/share/info/libext2fs.info.gz
install-info --dir-file=/usr/share/info/dir /usr/share/info/libext2fs.info
makeinfo -o      doc/com_err.info ../lib/et/com_err.texinfo
install -v -m644 doc/com_err.info /usr/share/info
install-info --dir-file=/usr/share/info/dir /usr/share/info/com_err.info

sed 's/metadata_csum_seed,//' -i /etc/mke2fs.conf

cd /sources
rm -rf $NAME

############### --- SYSKLOGD --- ###############

TARFILE=$(echo sysklogd*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

./configure --prefix=/usr      \
            --sysconfdir=/etc  \
            --runstatedir=/run \
            --without-logger   \
            --disable-static   \
            --docdir=/usr/share/doc/sysklogd-2.7.0

make

make install

cat > /etc/syslog.conf << "EOF"
# Begin /etc/syslog.conf

auth,authpriv.* -/var/log/auth.log
*.*;auth,authpriv.none -/var/log/sys.log
daemon.* -/var/log/daemon.log
kern.* -/var/log/kern.log
mail.* -/var/log/mail.log
user.* -/var/log/user.log
*.emerg *

# Do not open any internet ports.
secure_mode 2

# End /etc/syslog.conf
EOF

cd /sources
rm -rf $NAME

############### --- SYSVINIT --- ###############

TARFILE=$(echo sysvinit*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

patch -Np1 -i ../sysvinit-3.14-consolidated-1.patch

make

make install

cd /sources
rm -rf $NAME
