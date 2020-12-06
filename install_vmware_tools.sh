#!/bin/bash
#By: Dovla
#VMware toolbar > VM > Install VMware Tools
#In KDE, when prompted mount the virtual cd or mount manually
#to /run/media/$USER
#Execute ./install_vmware_tools.sh
#When prompted, answer yes to everything or hit enter
#When given the prompt "What is the directory that contains the init directories (rc0.d/ to rc6.d/) ?"
#type: /etc/init.rd
#Enter and/or yes/y to all prompts


/usr/bin/sudo pacman -Sy
/usr/bin/sudo pacman -S base-devel net-tools linux-headers asp --noconfirm
sudo su <<EOF
mkdir /etc/init.rd
mkdir /etc/init.rd/rc{0..6}.d
EOF
sudo cp /run/media/$USER/VMware\ Tools/VMwareTools-10.3.2-9925305.tar.gz ~
tar -xzvf VMwareTools-10.3.2-9925305.tar.gz 
sudo /usr/bin/perl vmware-tools-distrib/vmware-install.pl
asp checkout open-vm-tools
cd open-vm-tools/repos/community-x86_64/
makepkg -s --asdeps
sudo cp vm* /usr/lib/systemd/system
sudo systemctl enable vmware-vmblock-fuse
sudo systemctl enable vmtoolsd
touch vmwaretools.service
cat << EOF > vmwaretools.service 
[Unit]
Description=VMWare Tools daemon

[Service]
ExecStart=/etc/init.d/vmware-tools start
ExecStop=/etc/init.d/vmware-tools stop
PIDFile=/var/lock/subsys/vmware
TimeoutSec=0
RemainAfterExit=yes
 
[Install]
WantedBy=multi-user.target
EOF
sudo cp vmwaretools.service /etc/systemd/system/vmwaretools.service
sudo systemctl enable vmwaretools.service
sudo pacman -S xf86-input-vmmouse xf86-video-vmware mesa --noconfirm
echo "reboot for changes to take effect"
