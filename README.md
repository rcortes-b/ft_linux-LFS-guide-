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

This script is to install all the croos-toolchain in this step: [Link to the LFS book](https://www.linuxfromscratch.org/lfs/view/stable/chapter05/introduction.html)

[Link to the script of the toolchain build step](./toolchain_build.sh)

---

## Cross Compiling Temporary Tools ⚒️

This script is to install all the croos compiling temporary tools in this step: [Link to the LFS book](https://www.linuxfromscratch.org/lfs/view/stable/chapter06/introduction.html)

[Link to the script of the croos compiling temporary tools step](./cross_compiling_tools.sh)

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

## Additional Temporary Tools ⚒️

This script is to install the additional temporary tools from this step: [Link to the LFS book](https://www.linuxfromscratch.org/lfs/view/stable/chapter07/gettext.html) until the last tool of the chapter, in my case is util-linux.

[Link to the script of the additional temporary tools step](./additional_temporary_tools.sh)

---

## Building the LFS System - Installing Basic System Software ⚒️

This script is to install all the basic tools that our LFS system will have. It's based in this chapter: [Link to the LFS book](https://www.linuxfromscratch.org/lfs/view/stable/chapter08/introduction.html).

 **¡Caution!** You have to be careful because the 'set -e' command can stop the script when doing the 'make check' step, especially in the glibc step.

[Link to the script of the basic system software step](./basic-system-software.sh)

---

## Creating Configuration Files 📁

### /etc/sysconfig/ifconfig.<NAME>
```
bash /usr/lib/udev/init-net-rules.sh
cat /etc/udev/rules.d/70-persistent-net.rules #Check the value of "NAME"
ip route show #To obtain the GATEWAY value --> default via <GATEWAY>
ip address show enp0s3 #To obtain the IP, PREFIX and BROADCAST --> inet <IP>/<PREFIX> metric 100 brd <BROADCAST>
#I'll use as name enp0s3
cd /etc/sysconfig/
cat > ifconfig.enp0s3 << EOF
ONBOOT=yes
IFACE=<NAME>
SERVICE=ipv4-static
IP=192.168.1.<VM_ip>
GATEWAY=<GATEWAY>
PREFIX=<PREFIX>
BROADCAST=<BROADCAST>
EOF
```

### /etc/resolv.conf
```
cat > /etc/resolv.conf << "EOF"
# Begin /etc/resolv.conf

domain ft_linux
nameserver <GATEWAY> #Replace it with the GATEWAY obtained for the ifconfig.<NAME> file
nameserver 8.8.8.8 #Google Public IPv4 DNS address
nameserver 8.8.4.4 #Google Public IPv4 DNS address

# End /etc/resolv.conf
EOF
```

### /etc/hosts
```
cat > /etc/hosts << "EOF"
# Begin /etc/hosts

127.0.0.1 localhost.localdomain localhost
127.0.1.1 <42_login> <42_login>
<VM_IP> <42_login>
::1       localhost ip6-localhost ip6-loopback
ff02::1   ip6-allnodes
ff02::2   ip6-allrouters

# End /etc/hosts
EOF
```

### /etc/inittab
```
cat > /etc/inittab << "EOF"
# Begin /etc/inittab

id:3:initdefault:

si::sysinit:/etc/rc.d/init.d/rc S

l0:0:wait:/etc/rc.d/init.d/rc 0
l1:S1:wait:/etc/rc.d/init.d/rc 1
l2:2:wait:/etc/rc.d/init.d/rc 2
l3:3:wait:/etc/rc.d/init.d/rc 3
l4:4:wait:/etc/rc.d/init.d/rc 4
l5:5:wait:/etc/rc.d/init.d/rc 5
l6:6:wait:/etc/rc.d/init.d/rc 6

ca:12345:ctrlaltdel:/sbin/shutdown -t1 -a -r now

su:S06:once:/sbin/sulogin
s1:1:respawn:/sbin/sulogin

1:2345:respawn:/sbin/agetty --noclear tty1 9600
2:2345:respawn:/sbin/agetty tty2 9600
3:2345:respawn:/sbin/agetty tty3 9600
4:2345:respawn:/sbin/agetty tty4 9600
5:2345:respawn:/sbin/agetty tty5 9600
6:2345:respawn:/sbin/agetty tty6 9600

# End /etc/inittab
EOF
```


### /etc/sysconfig/clock
```
cat > /etc/sysconfig/clock << "EOF"
# Begin /etc/sysconfig/clock

UTC=1
ZONE="Europe/Madrid"
CLOCKPARAMS=

# End /etc/sysconfig/clock
EOF
```

### /etc/sysconfig/console
```
cat > /etc/sysconfig/console << "EOF"
# Begin /etc/sysconfig/console

UNICODE="1"
KEYMAP="es"
FONT="lat9w-16"

# End /etc/sysconfig/console
EOF
```

### /etc/profile
```
cat > /etc/profile << "EOF"
# Begin /etc/profile

for i in $(locale); do
  unset ${i%=*}
done

export LANG=es_ES.UTF-8
export LC_ALL=

# End /etc/profile
EOF
```

### /etc/inputrc
```
cat > /etc/inputrc << "EOF"
# Begin /etc/inputrc

# Allow the command prompt to wrap to the next line
set horizontal-scroll-mode Off

# Enable 8-bit input
set meta-flag On
set input-meta On

# Turns off 8th bit stripping
set convert-meta Off

# Keep the 8th bit for display
set output-meta On

# none, visible or audible
set bell-style none

# All of the following map the escape sequence of the value
# contained in the 1st argument to the readline specific functions
"\eOd": backward-word
"\eOc": forward-word

# for linux console
"\e[1~": beginning-of-line
"\e[4~": end-of-line
"\e[5~": beginning-of-history
"\e[6~": end-of-history
"\e[3~": delete-char
"\e[2~": quoted-insert

# for xterm
"\eOH": beginning-of-line
"\eOF": end-of-line

# for Konsole
"\e[H": beginning-of-line
"\e[F": end-of-line

# End /etc/inputrc
EOF
```

### /etc/shells
```
cat > /etc/shells << "EOF"
# Begin /etc/shells

/bin/sh
/bin/bash

# End /etc/shells
EOF
```
