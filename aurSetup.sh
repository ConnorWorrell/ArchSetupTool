#/bin/bash

scriptdir="$(echo $0 | rev | cut -d/ -f1 --complement | rev )"

# Yay
echo Making Yay
#git clone https://aur.archlinux.org/yay-git.git ~/.customPackages/yay
#cd ~/.customPackages/yay
#makepkg -si --noconfirm
#cd ~

rm Failed && rm Failedold

for package in $(cat $scriptdir/aurPackageList)
do
	echo "Installing $package"
	yay -S --noremovemake --nocleanmenu --nodiffmenu --noeditmenu --noupgrademenu --noprovides --noconfirm --needed $package || (echo "...Failed..." && echo "$package" >> $scriptdir/Failed)
done

mv $scriptdir/Failed $scriptdir/Failedold
cp /etc/resolv.conf $scriptdir/resolv.conf
sudo sed -i "2 cnameserver 1.1.1.1" /etc/resolv.conf
for package in $(cat $scriptdir/Failedold)
do
	echo "Installing $package"
	yay -S --noremovemake --nocleanmenu --nodiffmenu --noeditmenu --noupgrademenu --noprovides --noconfirm --needed $package || (echo "...Failed..." && echo "$package" >> $scriptdir/Failed)
done
sudo mv $scriptdir/resolv.conf /etc/resolv.conf

sudo grub-mkconfig -o /boot/grub/grub.cfg

echo "Failed to install packages:"
cat $scriptdir/Failed
