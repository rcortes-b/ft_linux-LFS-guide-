# ft_linux-LFS-guide- 🐧
This is a minimal guide for LFS (Linux from Scratch) to start ft_linux 42 project. I'm using the version 12.3 of the LFS Book.

---

## Setting up the VM 📦🖥️
1. First of all, create a VM of Linux 4.x, with 2048 MB (minimum), 2 CPUs and 30 GB (Dynamic Allocation).
2. Once the VM has been created, go to settings -> storage -> in Controller: IDE, press "Adds optical drive" -> Add the base distribution you chose (Ubuntu, Debian, ...) and check the Live CD/DVD option.

***Choose a minimal and Live ISO***

![Captura de pantalla 2025-05-19 094848](https://github.com/user-attachments/assets/751c0463-85bb-4533-b2fc-a8abbd435b41)

---

## Installation 🛠️
1. Install the base system with Ubuntu untill it ask you to "Remove the installation medium" and then in the VM window, go to "Devices -> Optical Drives -> Uncheck the ISO of your choice and press Enter".
2. In the VM, go to settings -> storage -> in Controller: Sata -> "Adds hard disk" -> Create -> VDI -> Check "Pre-allocate Full size" -> 20GB -> Finish.

**This one is the hardisk where the LFS system will be built.**

![Captura de pantalla 2025-05-19 100117](https://github.com/user-attachments/assets/11f00ce4-469b-4489-8e61-76fb90171feb)

---

## Setting up the Host 🖥️

```
sudo apt update && sudo apt upgrade -y
sudo apt install build-essential curl wget git vim parted gawk texinfo man-db \
  bison g++ flex libncurses5-dev libssl-dev grub2 sudo lsb-release -y
```

---

## Create the partitions 🖴

```
sudo fdisk /dev/sdb
```
Create the 3 partitions:
  - root /mnt/lfs -> 12GB
  - boot /mnt/lfs/boot -> 1GB
  - swap -> 2GB

**Modify the /etc/fstab file to mount the partitions every time you boot the VM**

![Captura de pantalla 2025-05-19 101656](https://github.com/user-attachments/assets/a8750829-3335-4015-90ae-779e1093e901)

---

**DISCLAIMER: This is not a step-by-step guide. Steps like "Set up the LFS environment (export LFS=/mnt/lfs), etc ..." are not in this guide.**

---

## Packages 📦

- Download the package list
```
wget https://www.linuxfromscratch.org/lfs/view/stable/wget-list-sysv
```
- Download the required patches
```
wget https://www.linuxfromscratch.org/patches/lfs/12.3/coreutils-9.6-i18n-1.patch
wget https://www.linuxfromscratch.org/patches/lfs/12.3/bzip2-1.0.8-install_docs-1.patch
wget https://www.linuxfromscratch.org/patches/lfs/12.3/expect-5.45.4-gcc14-1.patch
wget https://www.linuxfromscratch.org/patches/lfs/12.3/kbd-2.7.1-backspace-1.patch
wget https://www.linuxfromscratch.org/patches/lfs/12.3/glibc-2.41-fhs-1.patch
wget https://www.linuxfromscratch.org/patches/lfs/12.3/sysvinit-3.14-consolidated-1.patch
```
and place them into the sources directory:
```
mv -v *.patch $LFS/sources/.
```
- Download the md5sums verification and place it into the sources directory
```
wget https://www.linuxfromscratch.org/lfs/view/stable/md5sums
mv -v md5sums /mnt/lfs/sources/.
```
**The expat link in the package list is not correct, so i found this one (the LFS Book uses the 2.6.4 expat version, but i downloaded the 2.7.1 version):**
```
wget https://sourceforge.net/projects/expat/files/expat/2.7.1/expat-2.7.1.tar.xz/download
```

---

## TIP: Share files between your host machine and the VM 🔁

One thing to make the project easier is sharing files from your host to the VM (for example, scripts to automatize some of the processes)

- **In the VM:**

  - **This step is done in the VM menu ->**  settings -> network -> In "Attached to" chose "Bridged Adapter"
  - Install OpenSSH
  ```
  sudo apt install openssh-server
  ```
  - Get your IP
  ```
  ip -a | grep 192
  ```
  It is the first serial number next to "inet". For example, 192.168.1.xxx.
  - Connect to SSH
  ```
  ssh your_username@your_ip
  ```
- **In the host (if you are using windows):**

  - Check if you have ssh installed
  ```
  Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*'
  ```
  - If you haven't it installed:
  ```
  Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
  ```
  - Start the service
  ```
  Start-Service sshd
  Set-Service -Name sshd -StartupType 'Automatic'
  ```

Once you have your host and the VM setted up, you can use it with the next command (in the host):
```
scp path_of_the_file_you_want_to_send vm_username@ip_vm:path_of_the_vm_to_store_the_file
```
```
scp .\user_script.sh rcortes-@192.168.1.136:/home/rcortes-/.
```

---

## Set up the environment 📟

```
cat > ~/.bash_profile << "EOF"
exec env -i HOME=$HOME TERM=$TERM PS1='\u:\w\$ ' /bin/bash
EOF

cat > ~/.bashrc << "EOF"
set +h
umask 022
LFS=/mnt/lfs
LC_ALL=POSIX
LFS_TGT=$(uname -m)-lfs-linux-gnu
PATH=/usr/bin
if [ ! -L /bin ]; then PATH=/bin:$PATH; fi
PATH=$LFS/tools/bin:$PATH
CONFIG_SITE=$LFS/usr/share/config.site
MAKEFLAGS=-j$(nproc)
export LFS LC_ALL LFS_TGT PATH CONFIG_SITE MAKEFLAGS
EOF

source ~/.bash_profile
```

---

## Toolchain build ⚒️

[Link to the script of the toolchain build step](./toolchain_build.sh)


## Cross Compiling Temporary Tools ⚒️

```
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
```

---

## Entering Chroot

```
set -e

sudo su #Log in as root
export LFS=/mnt/lfs
chown --from lfs -R root:root $LFS/{usr,lib,var,etc,bin,sbin,tools,lib64}

mkdir -pv $LFS/{dev,proc,sys,run}
mount -v --bind /dev $LFS/dev
mount -vt devpts devpts -o gid=5,mode=0620 $LFS/dev/pts
mount -vt proc proc $LFS/proc
mount -vt sysfs sysfs $LFS/sys
mount -vt tmpfs tmpfs $LFS/run

if [ -h $LFS/dev/shm ]; then
  install -v -d -m 1777 $LFS$(realpath /dev/shm)
else
  mount -vt tmpfs -o nosuid,nodev tmpfs $LFS/dev/shm
fi

chroot "$LFS" /usr/bin/env -i   \
    HOME=/root                  \
    TERM="$TERM"                \
    PS1='(lfs chroot) \u:\w\$ ' \
    PATH=/usr/bin:/usr/sbin     \
    MAKEFLAGS="-j$(nproc)"      \
    TESTSUITEFLAGS="-j$(nproc)" \
    /bin/bash --login

mkdir -pv /{boot,home,mnt,opt,srv}

mkdir -pv /etc/{opt,sysconfig}
mkdir -pv /lib/firmware
mkdir -pv /media/{floppy,cdrom}
mkdir -pv /usr/{,local/}{include,src}
mkdir -pv /usr/lib/locale
mkdir -pv /usr/local/{bin,lib,sbin}
mkdir -pv /usr/{,local/}share/{color,dict,doc,info,locale,man}
mkdir -pv /usr/{,local/}share/{misc,terminfo,zoneinfo}
mkdir -pv /usr/{,local/}share/man/man{1..8}
mkdir -pv /var/{cache,local,log,mail,opt,spool}
mkdir -pv /var/lib/{color,misc,locate}

ln -sfv /run /var/run
ln -sfv /run/lock /var/lock

install -dv -m 0750 /root
install -dv -m 1777 /tmp /var/tmp

ln -sv /proc/self/mounts /etc/mtab

cat > /etc/hosts << EOF
127.0.0.1  localhost $(hostname)
::1        localhost
EOF

cat > /etc/passwd << "EOF"
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/usr/bin/false
daemon:x:6:6:Daemon User:/dev/null:/usr/bin/false
messagebus:x:18:18:D-Bus Message Daemon User:/run/dbus:/usr/bin/false
uuidd:x:80:80:UUID Generation Daemon User:/dev/null:/usr/bin/false
nobody:x:65534:65534:Unprivileged User:/dev/null:/usr/bin/false
EOF

cat > /etc/group << "EOF"
root:x:0:
bin:x:1:daemon
sys:x:2:
kmem:x:3:
tape:x:4:
tty:x:5:
daemon:x:6:
floppy:x:7:
disk:x:8:
lp:x:9:
dialout:x:10:
audio:x:11:
video:x:12:
utmp:x:13:
cdrom:x:15:
adm:x:16:
messagebus:x:18:
input:x:24:
mail:x:34:
kvm:x:61:
uuidd:x:80:
wheel:x:97:
users:x:999:
nogroup:x:65534:
EOF

echo "tester:x:101:101::/home/tester:/bin/bash" >> /etc/passwd
echo "tester:x:101:" >> /etc/group
install -o tester -d /home/tester

exec /usr/bin/bash --login

touch /var/log/{btmp,lastlog,faillog,wtmp}
chgrp -v utmp /var/log/lastlog
chmod -v 664  /var/log/lastlog
chmod -v 600  /var/log/btmp
```

---

## Additional Temporary Tools

```
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

```
