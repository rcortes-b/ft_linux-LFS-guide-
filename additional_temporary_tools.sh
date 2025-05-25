set -e

############### --- GETTEXT --- ###############

TARFILE=$(echo gettext*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

./configure --disable-shared

make

cp -v gettext-tools/src/{msgfmt,msgmerge,xgettext} /usr/bin

cd /sources
rm -rf $NAME

############### --- BISON --- ###############

TARFILE=$(echo bison*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

./configure --prefix=/usr \
            --docdir=/usr/share/doc/bison-3.8.2

make

make install

cd /sources
rm -rf $NAME

############### --- PERL --- ###############

TARFILE=$(echo perl*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

sh Configure -des                                         \
             -D prefix=/usr                               \
             -D vendorprefix=/usr                         \
             -D useshrplib                                \
             -D privlib=/usr/lib/perl5/5.40/core_perl     \
             -D archlib=/usr/lib/perl5/5.40/core_perl     \
             -D sitelib=/usr/lib/perl5/5.40/site_perl     \
             -D sitearch=/usr/lib/perl5/5.40/site_perl    \
             -D vendorlib=/usr/lib/perl5/5.40/vendor_perl \
             -D vendorarch=/usr/lib/perl5/5.40/vendor_perl

make

make install

cd /sources
rm -rf $NAME

############### --- PYTHON --- ###############

TARFILE=$(echo Python*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

./configure --prefix=/usr   \
            --enable-shared \
            --without-ensurepip

make

make install

cd /sources
rm -rf $NAME

############### --- TEXINFO --- ###############

TARFILE=$(echo texinfo*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

./configure --prefix=/usr

make

make install

cd /sources
rm -rf $NAME

############### --- UTIL-LINUX --- ###############

TARFILE=$(echo util*.tar.*)
NAME=$(echo ${TARFILE%.tar.*})

tar -xf $TARFILE

cd $NAME

mkdir -pv /var/lib/hwclock

./configure --libdir=/usr/lib     \
            --runstatedir=/run    \
            --disable-chfn-chsh   \
            --disable-login       \
            --disable-nologin     \
            --disable-su          \
            --disable-setpriv     \
            --disable-runuser     \
            --disable-pylibmount  \
            --disable-static      \
            --disable-liblastlog2 \
            --without-python      \
            ADJTIME_PATH=/var/lib/hwclock/adjtime \
            --docdir=/usr/share/doc/util-linux-2.40.4

make

make install

cd /sources
rm -rf $NAME
