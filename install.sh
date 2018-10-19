#!/bin/sh

set -eux

currentdir=$(curl -Lf https://images.linuxcontainers.org/images/archlinux/current/amd64/default/ | grep -Eoh '<td><a href="[^"]*"' | cut -d\" -f2 | cut -d/ -f2 | tail -n3 | head -n1)

url=https://images.linuxcontainers.org/images/archlinux/current/amd64/default/"$currentdir"/rootfs.tar.xz

#installdir=$(mktemp -d)
installdir=~/.megaman
chmod 700 "$installdir"
mkdir "$installdir"/rootfs | true

#curl -Lf "$url" | tar -xJf - -C "$installdir/rootfs"

cd "$installdir/rootfs"

# because it is a symlink
rm    ./etc/resolv.conf || true
touch ./etc/resolv.conf || true

binscript='#!/bin/sh
set -e
cd "'"$installdir/rootfs"'"
unshare --mount --user -r sh -ec '\''
mount --rbind /tmp  ./tmp
mount --rbind /home ./home
mount --rbind /root ./root
mount --rbind /sys  ./sys
mount --rbind /dev  ./dev
mount --rbind /proc ./proc
mount --bind /etc/resolv.conf ./etc/resolv.conf
PLASH_NO_UNSHARE=1 exec chroot . "$@"
'\'' -- "$@"
'

cd "$installdir"
echo "$binscript" > ./run-rootfs
chmod +x ./run-rootfs

./run-rootfs sh -c '
set -eux
sed -i 's/CheckSpace/#CheckSpace/' /etc/pacman.conf
pacman -Syu python-pip unionfs-fuse --noconfirm
pip3 install plash --upgrade
plash init
'
