# Preparação de arquivos e pastas

sudo service snapd stop
sudo apt install -y curl git gnupg rsync squashfs-tools unzip wget
cd code/livecdtmp
cp -v /var/lib/buildkite-agent/xubuntu-19.04-core-amd64.iso .
wget -c https://unit193.net/xubuntu/core/xubuntu-19.04-core-amd64.iso
sudo mount -o loop xubuntu*.iso mnt 2>/dev/null
sudo rsync --exclude=/casper/filesystem.squashfs -a mnt/ extract-cd
sudo unsquashfs mnt/casper/filesystem.squashfs
sudo mv squashfs-root edit

# Montagem do ambiente chroot

sudo cp -rv /run edit/run
#sudo mount --bind edit/run/ edit/run
sudo cp -rv /dev edit/dev
#sudo mount --bind /dev/ edit/dev
sudo chroot edit mount -t proc none /proc
sudo chroot edit mount -t sysfs none /sys
sudo chroot edit mount -t devpts none /dev/pts
sudo chroot edit sh -c "export HOME=/root"
sudo chroot edit sh -c "export LC_ALL=C"
sudo chroot edit sh -c "dbus-uuidgen > /var/lib/dbus/machine-id"
sudo chroot edit dpkg-divert --local --rename --add /sbin/initctl
sudo chroot edit ln -s /bin/true /sbin/initctl

# Execução do script de criação do sistema

sudo chroot edit mkdir -pv RaDiX
sudo cp -rv ../build edit/RaDiX/;sudo cp -rv ../boot-files edit/RaDiX/
sudo chroot edit bash RaDiX/build/build-radix-core.sh
sudo chroot edit chsh -s /usr/bin/fish root
sudo chroot edit wget -O oh-my-fish.sh https://get.oh-my.fish
sudo chroot edit su -c "fish oh-my-fish.sh --noninteractive"
sudo chroot edit su -c "fish -c 'omf install bobthefish'"
sudo chroot edit rm -rf oh-my-fish.sh
sudo chroot edit sed -i -e 's@user-uid [0-9]*@user-uid 990@' /usr/share/initramfs-tools/scripts/casper-bottom/25adduser

# Desmontagem do ambiente chroot

sudo chroot edit apt clean
sudo chroot edit rm -rf RaDiX /tmp/* ~/.bash_history ~/.fish* ~/.config ~/.local
sudo chroot edit rm /var/lib/dbus/machine-id
sudo chroot edit rm /sbin/initctl
sudo chroot edit dpkg-divert --rename --remove /sbin/initctl
sudo chroot edit umount /proc || umount -lf /proc
sudo chroot edit umount /sys
sudo chroot edit umount /dev/pts
sudo umount edit/dev
sudo umount edit/run
sleep 30
sudo umount edit/run

# Geração do arquivo de manifesto

sudo chmod +w extract-cd/casper/filesystem.manifest
sudo sh -c "chroot edit dpkg-query -W --showformat='${Package} ${Version}\n' > extract-cd/casper/filesystem.manifest"
sudo cp extract-cd/casper/filesystem.manifest extract-cd/casper/filesystem.manifest-desktop
sudo sed -i '/ubiquity/d' extract-cd/casper/filesystem.manifest-desktop
sudo sed -i '/casper/d' extract-cd/casper/filesystem.manifest-desktop

# Compactação do sistema de arquivos da imagem de instalação

sudo rm -rf extract-cd/casper/filesystem.squashfs
sudo mksquashfs edit extract-cd/casper/filesystem.squashfs
sudo sh -c 'printf $(du -sx --block-size=1 edit | cut -f1) > extract-cd/casper/filesystem.size'

# Informações da imagem de instalação (carece de correções)

sudo touch extract-cd/ubuntu
sudo mkdir -pv extract-cd/.disk
cd extract-cd/.disk
sudo touch base_installable
echo "full_cd/single" | sudo tee cd_type
echo "RaDiX - Core - 22.05.2019" | sudo tee info
echo "RaDiX - Core" | sudo tee release_notes_url
cd ../..

# Geração do arquivo md5sum

cd extract-cd
sudo rm md5sum.txt
sudo find -type f -print0 | sudo xargs -0 md5sum | grep -v isolinux/boot.cat | sudo tee md5sum.txt

# Geração da imagem de instalação

sudo cp -v ../../boot-files/*.cfg boot/grub
sudo cp -rv ../../boot-files/themes boot/grub/
sudo rm -rfv dists/{stable,unstable} isolinux pics preseed ubuntu
sudo cp -rfv ../../boot-files/isolinux .
sudo cp ../edit/boot/initrd.img-*-generic casper/initrd
sudo cp ../edit/boot/vmlinuz-*-generic casper/vmlinuz
sudo apt install -y isolinux sshpass xorriso
sudo xorriso \
  -as mkisofs -r -V "$IMAGE_NAME" -l \
  -iso-level 3 \
  -b isolinux/isolinux.bin \
  -c isolinux/boot.cat \
  -no-emul-boot \
  -boot-load-size 4 \
  -boot-info-table \
  -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
  -eltorito-alt-boot \
  -e boot/grub/efi.img \
  -no-emul-boot \
  -isohybrid-gpt-basdat \
  -o "../iso/radix-core-amd64.iso" .
md5sum ../iso/radix-core-amd64.iso | sudo tee ../iso/radix-core-amd64.md5
cd ..;sudo umount mnt edit/run ; sudo rm -rf edit extract-cd iso/.empty

# Upload da imagem de instalação para o GitHub

bash /var/lib/buildkite-agent/github-release.sh
