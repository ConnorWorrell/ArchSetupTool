#!/bin/bash

user="$(whoami)"
scriptdir="$(echo $0 | rev | cut -d/ -f1 --complement | rev )"

echo "Starting arch auto setup"

# Setup Pacman
sudo pacman -S archlinux-keyring
sudo cp /etc/pacman.conf /etc/pacman.conf.bak
sudo sed -i 's/#Color/Color/g' /etc/pacman.conf
coreCount="$(expr 1 + $(awk '/^processor/{print $3}' /proc/cpuinfo | tail -n 1) )"
eval "sudo sed -i 's/#ParallelDownloads = 5/ParallelDownloads = $coreCount/g' /etc/pacman.conf"
sudo pacman -S reflector
sudo sed -i -z 's|#\[multilib\]\n#Include = /etc/pacman.d/mirrorlist|\[multilib\]\nInclude = /etc/pacman.d/mirrorlist|g' /etc/pacman.conf

# Setup Makepkg
echo "Setting up makepkg"
makeCores="$(expr $coreCount - 1)"
sudo cp /etc/makepkg.conf /etc/makepkg.conf.bak
eval "sudo sed -i 's/#MAKEFLAGS=\"-j2\"/MAKEFLAGS=\"-j$makeCores\"/g' /etc/makepkg.conf"

# Updating mirror list
echo "Setting up reflector"
sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
sudo reflector --latest 100 --sort rate --country US --save /etc/pacman.d/mirrorlist

sudo pacman -Syyu

# MicroCode
if [ "$(grep -i amd /proc/cpuinfo | wc -l)" -gt "$(grep -i intel /proc/cpuinfo | wc -l)" ]
then
	echo "AMD Microcode Install"
	sudo pacman -S amd-ucode
else
	echo "Intel Microcode Install"
	sudo pacman -S intel-ucode
fi

if [ "$(lspci | grep -i "nvidia" | wc -l)" -gt 0 ]
then
	echo "Installing nvidia graphics drivers"
	sudo pacman -S nvidia-dkms lib32-nvidia-utils
fi

# Install core packages
echo "Installing core packages"
sudo pacman -S $(cat $scriptdir/standardPackageList)

# Move to user space
echo "switching to userspace"
cd /home/$user
mkdir .customPackages

# My packages

echo Making custom packages
git clone https://github.com/ConnorWorrell/st.git .customPackages/st && make -C .customPackages/st && sudo make -C .customPackages/st clean install
git clone https://github.com/ConnorWorrell/dwm.git .customPackages/dwm && make -C .customPackages/dwm && sudo make -C .customPackages/dwm clean install
git clone https://github.com/ConnorWorrell/dwmblocks.git .customPackages/dwmblocks && make -C .customPackages/dwmblocks && sudo make -C .customPackages/dwmblocks clean install
git clone https://github.com/ConnorWorrell/dmenu.git .customPackages/dmenu && make -C .customPackages/dmenu && sudo make -C .customPackages/dmenu clean install

# Config files
echo Applying config files
mv ~/.bashrc ~/.bashrc.bak
git clone https://github.com/ConnorWorrell/configFiles.git .configFiles || cd ~/.configFiles && stow -t ~ $(ls */ | cut -d/ -f1-1)
git clone https://github.com/ConnorWorrell/desktopScripts.git ~/.scripts

[ -d /etc/pacman.d/hooks ] || sudo mkdir /etc/pacman.d/hooks && sudo cp ~/.scripts/Other/pacman-cacheclean.hook /etc/pacman.d/hooks/cacheclean.hook
sudo pacman -Syyu

sudo systemctl enable --now bluetooth.service
sudo grub-mkconfig -o /boot/grub/grub.cfg

echo "------------------------------------------"
echo "------------------------------------------"
echo "Next steps:
   1. Encrypting home directory:
      Log out and log back in a root
	  Copy autoEcrypt.sh out of user directory
	  Run ./autoEcrypt.sh [user]
   2. AUR (Do after encrypt)
      Run aurSetup.sh"
