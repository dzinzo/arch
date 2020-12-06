
#!/bin/bash

pacman -Sy
pacman -S reflector --noconfirm
reflector --latest 200 --protocol http --protocol https --sort rate --save /etc/pacman.d/mirrorlist
pacman -S dialog --noconfirm
rootpassword=$(dialog --stdout --passwordbox "Enter root password" 0 0) || exit 1
clear
username=$(dialog --stdout --inputbox "Enter username" 0 0) || exit 1
clear
userpassword=$(dialog --stdout --passwordbox "Enter user password" 0 0) || exit 1
clear
devlist=$(lsblk -dplnx size -o name,size | tac)
dv=$(dialog --stdout --menu "Select disk to install" 0 0 0 ${devlist}) || exit 1
clear
rootsize=$(dialog --stdout --inputbox "Enter root partition size in GB, e.g 12G" 0 0) || exit 1
clear
homesize=$(dialog --stdout --inputbox "Enter home partition size in GB, e.g. 200G" 0 0) || exit 1
clear
cat > de.txt << 'EOT'
KDE Plasma
i3
xfce
EOT
de1=$(cat de.txt | awk 'NR==1' | awk '{print $1,$2'})
de2=$(cat de.txt | awk 'NR==2' | awk '{print $1}')
de3=$(cat de.txt | awk 'NR==3')
demenu=$(dialog --stdout --menu "Select Desktop Environment" 0 0 0 "${de1}" "" "${de2}" "" "${de3}" "") || exit 1
clear
############################################
sgdisk -Z "${dv}"
sgdisk -n 0:0:+1G -t 0:ef00 "${dv}"
sgdisk -n 0:0:+"$rootsize" -t 0:8300 "${dv}"
sgdisk -n 0:0:+"$homesize" -t 0:8300 "${dv}"
############################################
mkfs.vfat /dev/sda1
mkfs.ext4 /dev/sda2
mkfs.ext4 /dev/sda3
mount /dev/sda2 /mnt
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot
mkdir /mnt/home
mount /dev/sda3 /mnt/home
timedatectl set-ntp true
pacstrap /mnt base linux linux-firmware vim nano networkmanager network-manager-applet notification-daemon git
genfstab -U /mnt >> /mnt/etc/fstab
##################################################################
id=$(blkid -s PARTUUID "$dv"2 | awk '{print $2}' | sed 's/"//g')
##################################################################
arch-chroot /mnt /bin/bash <<EOF
ln -sf /usr/share/zoneinfo/Europe/Belgrade /etc/localtime
hwclock --systohc
sed -i '/en_US.UTF-8 UTF-8/s/#//g' /etc/locale.gen
sed -i '/en_US ISO-8859-1/s/#//g' /etc/locale.gen
sed -i '/sr_RS UTF-8/s/#//g' /etc/locale.gen
sed -i '/sr_RS@latin UTF-8/#//g' /etc/locale.gen
locale-gen
touch /etc/locale.conf
echo LANG=en_US.UTF-8 >> /etc/locale.conf
echo arch >> /etc/hostname
echo 127.0.0.1	localhost >> /etc/hosts
echo ::1	localhost >> /etc/hosts
echo 127.0.1.1	arch.localdomain arch >> /etc/hosts
mkinitcpio -P
echo "root:$rootpassword" | chpasswd
bootctl --path=/boot/ install
cat /dev/null > /boot/loader/loader.conf
echo arch >> /boot/loader/loader.conf
echo timeout 4 >> /boot/loader/loader.conf
echo title ArchLinux >> /boot/loader/entries/arch.conf
echo linux /vmlinuz-linux >> /boot/loader/entries/arch.conf
echo initrd /initramfs-linux.img >> /boot/loader/entries/arch.conf
echo options root="$id" rw >> /boot/loader/entries/arch.conf
systemctl enable NetworkManager
useradd -m -g users -G wheel -s /bin/bash "$username"
echo "$username:$userpassword" | chpasswd
rm -rf /home/"$username"/.bash_profile
touch /home/"$username"/.bash_profile
touch /home/"$username"/.xinitrc
pacman -S sudo --noconfirm
sed 's/# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/g' /etc/sudoers > /etc/sudoers.new
export EDITOR="cp /etc/sudoers.new"
visudo
rm /etc/sudoers.new
pacman -S xorg-server --noconfirm
pacman -S xorg-xinit --noconfirm
pacman -S rxvt-unicode --noconfirm
#export DESKTOP_SESSION=plasma
#rm -rf /home/"$username"/.xinitrc
#if [ "{demenu}" == "${de2}
#	then
#		echo exec i3 >> /home/"$username"/.xinitrc
#elif [ "${demenu}" == "${de1} ]
#	then
#		echo exec startplasma-x11 >> /home/"$username/.xinitrc
#echo exec startplasma-x11 >> /home/"$username"/.xinitrc
sed -i 's/#SigLevel = Optional TrustAll/SigLevel = Never/g' /etc/pacman.conf
pacman -S openssh --noconfirm
pacman -S firefox --noconfirm
pacman -S networkmanager-pptp --noconfirm
chown "$username":users /home/"$username"/.bash_profile
if [ "${demenu}" == "${de2}" ]
        then
                sudo echo 1,3,4,5 |pacman -S i3 --noconfirm

elif [ "${demenu}" == "${de1}" ]
        then
                sudo pacman -S plasma --noconfirm
                sudo pacman -S kde-applications --noconfirm
elif [ "${demenu}" == "${de3}" ]
	then
		sudo pacman -S xfce4 --noconfirm
		sudo pacman -S xfce4-goodies --noconfirm
fi
exit
EOF
cat > /mnt/home/"$username"/.bash_profile << 'EOT'
#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc

if systemctl -q is-active graphical.target && [[ ! $DISPLAY && $XDG_VTNR -eq 1 ]]; then
exec startx
fi
EOT
if [ "${demenu}" == "${de2}" ] 
       then
               echo exec i3 >> /mnt/home/"$username"/.xinitrc
elif [ "${demenu}" == "${de1}" ]
       then
               echo exec startplasma-x11 >> /mnt/home/"$username"/.xinitrc
elif [ "${demenu}" == "${de3}" ]
	then
		echo exec startxfce4 >>	/mnt/home/"$username"/.xinitrc
fi

umount -l /mnt

