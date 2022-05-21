#!/bin/bash

user="$(whoami)"
scriptdir="$($0 | rev | cut -d/ -f1 --complement | rev )"

su
echo "Starting arch auto setup"

# Setup Pacman
sed -i 's/#Color/Color/g' /etc/pacman.conf
coreCount="$(expr 1 + $(awk '/^processor/{print $3}' /proc/cpuinfo | tail -n 1) )"
eval "sed -i \'s/#ParallelDownloads = 5/ParallelDownloads = $coreCount/g\' /etc/pacman.conf"
sed -i 's/#[multilib]/[multilib]/g' /etc/pacman.conf
sed -i 's/#Include = \/etc\/pacman.d\/mirrorlist/Include = \/etc\/pacman.c\/mirrorlist/g' /etc/pacman.conf

# Setup Makepkg
echo "Setting up makepkg"
pacman -S makepkg
makeCores="$(expr $coreCount - 1)"
sed -i 's/#MAKEFLAGS="-j2"/MAKEFLAGS="-j7"/g' /etc/makepkg.conf

# Updating mirror list
pacman -Syyu
echo "Setting up reflector"
pacman -S reflector
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
reflector --latest 100 --sort rate --country US --save /etc/pacman.d/mirrorlist

# MicroCode
if [ "$(grep -i amd /proc/cpuinfo | lc)" -gt "$(grep -i intel /proc/cpuinfo | lc)" ]
then
	echo "AMD Microcode Install"
	pacman -S amd-ucode
else
	echo "Intel Microcode Install"
	pacman -S intel-ucode
fi

# Install core packages
echo "Installing core packages"
pacman -S $(cat $scriptdir/standardPackageList)

# Move to user space
echo "switching to userspace"
su $user
cd /home/$user
mkdir .customPackages

# My packages

echo Making custom packages
git clone https://github.com/ConnorWorrell/st.git .customPackages/st && make -C .customPackages/st && sudo make -C .customPackages/st clean install &
git clone https://github.com/ConnorWorrell/dwm.git .customPackages/dwm && make -C .customPackages/dwm && sudo make -C .customPackages/dwm clean install &
git clone https://github.com/ConnorWorrell/dwmblocks.git .customPackages/dwmblocks && make -C .customPackages/dwmblocks && sudo make -C .customPackages/dwmblocks clean install &
git clone https://github.com/ConnorWorrell/dmenu.git .customPackages/dmenu && make -C .customPackages/dwmblocks && sudo make -C .customPackages/dwmblocks clean install &

# Config files
echo Applying config files
pacman -S stow && git clone https://github.com/ConnorWorrell/configFiles.git .configFiles && cd .configFiles && stow -t ~ *

# Yay
echo Making Yay
git clone https://aur.archlinux.org/yay-git.git .customPackages/yay
cd .customPackages/yay
makepkg -si
cd ~

for package in $(cat $scriptdir/aurPackageList)
do
	echo "Installing $package"
	yay -S $package || (echo "...Failed..." && echo "$package" ~/InstallInfo/Failed)
done




