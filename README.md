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

## TIP: Share files between your host machine and the VM

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
