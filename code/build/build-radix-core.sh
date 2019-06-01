#!/bin/bash
# Raul Dipeas Repo
echo 'deb https://apt.radix.ws/repo core main' > /etc/apt/sources.list.d/rauldipeas.list
wget -O- https://apt.radix.ws/repo/rauldipeas.key | gpg --dearmor > /etc/apt/trusted.gpg.d/rauldipeas.gpg
# WINE Staging
wget -O- https://dl.winehq.org/wine-builds/winehq.key | gpg --dearmor > /etc/apt/trusted.gpg.d/winehq.gpg
echo 'deb https://dl.winehq.org/wine-builds/ubuntu/ disco main #WINE' > /etc/apt/sources.list.d/winehq.list
# NVIDIA
rm -rf /etc/apt/sources.list.d/graphics-drivers-ubuntu-ppa*
add-apt-repository -y -n ppa:graphics-drivers/ppa
sed -i 's/main/main #NVIDIA/g' /etc/apt/sources.list.d/graphics-drivers-ubuntu-ppa*
# Intel/AMD
rm -rf /etc/apt/sources.list.d/oibaf-ubuntu-graphics-drivers*
add-apt-repository -y -n ppa:oibaf/graphics-drivers
sed -i 's/main/main #Intel\/AMD/g' /etc/apt/sources.list.d/oibaf-ubuntu-graphics-drivers*
# Liquorix
rm -rf /etc/apt/sources.list.d/damentz-ubuntu-liquorix*
add-apt-repository -y -n ppa:damentz/liquorix
sed -i 's/main/main #Liquorix/g' /etc/apt/sources.list.d/damentz-ubuntu-liquorix*
# Hardcode-Tray
rm -rf /etc/apt/sources.list.d/papirus-ubuntu-hardcode-tray*
sudo add-apt-repository -y -n ppa:papirus/hardcode-tray
sed -i 's/main/main #HardcodeTray/g' /etc/apt/sources.list.d/papirus-ubuntu-hardcode-tray*

# Pre-Install
add-apt-repository universe;add-apt-repository multiverse;dpkg --add-architecture i386;apt update
apt install -y build-essential

# Remoção de pacotes desnecessários
apt autoremove --purge -y\
 apport*\
 elementary-*\
 gnome-accessibility-themes\
 gnome-themes-standard\
 greybird-gtk-theme\
 gucharmap*\
 humanity-icon-theme\
 imagemagick\
 libgucharmap*\
 libyelp*\
 light-locker\
 lightdm-gtk-greeter\
 numix-gtk-theme\
 plymouth-theme-*\
 spice-vdagent\
 ubuntu-advantage-tools\
 ubuntu-minimal\
 ubuntu-release-upgrader-core\
 ubuntu-standard\
 xfce4-appfinder\
 xfce4-indicator-plugin\
 xfce4-power-manager-plugins\
 xfce4-pulseaudio-plugin\
 xfce4-screenshooter\
 xfce4-statusnotifier-plugin\
 xfce4-terminal\
 xubuntu*\
 yelp*

# Atualização dos pacotes
apt dist-upgrade -y

# Instalação do repositório e das customizações do RaDiX
echo jackd2 jackd/tweak_rt_limits string true | debconf-set-selections
apt install -y rauldipeas-repo
apt install --reinstall linux-generic linux-image-generic linux-image-5.0.0-13-generic

# Remoção de pacotes desnecessários
apt autoremove --purge -y build-essential fonts-lato imagemagick jackd qjackctl yelp* libyelp*
rm -rfv /usr/share/fonts/truetype/lato
dpkg -l | grep -E linux-image-.*-generic | cut -d ' ' -f3 | grep -v `dpkg -l | grep -E linux-image-.*-generic | cut -d ' ' -f3 | tail -1` | grep -v `uname -r` | xargs apt autoremove --purge -y

# LightDM
echo '[SeatDefaults]
autologin-user=radix
user-session=xfce
greeter-session=lightdm-webkit-greeter' > /etc/lightdm/lightdm.conf

# User Groups (Converter em Deb)
sed -i 's/#EXTRA_GROUPS/EXTRA_GROUPS/g' /etc/adduser.conf
sed -i 's/plugdev users/plugdev users input virtualbox/g' /etc/adduser.conf
sed -i 's/#ADD_EXTRA_GROUPS/ADD_EXTRA_GROUPS/g' /etc/adduser.conf
