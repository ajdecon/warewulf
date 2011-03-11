#!/bin/sh


VNFSDIR=$1

if [ -z "$VNFSDIR" ]; then
    echo "USAGE: $0 /path/to/chroot"
    exit 1
fi


yum --installroot $VNFSDIR -y install \
    SysVinit basesystem bash redhat-release chkconfig coreutils e2fsprogs \
    ethtool filesystem findutils gawk grep initscripts iproute iputils \
    mingetty mktemp net-tools nfs-utils pam portmap procps psmisc rdate \
    sed setup shadow-utils sysklogd tcp_wrappers termcap tzdata util-linux \
    words zlib tar less gzip which util-linux module-init-tools udev \
    openssh-clients openssh-server passwd dhclient pciutils vim-minimal \
    shadow-utils strace

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to create chroot"
fi

echo
echo "Creating default fstab"
echo "root / tmpfs defaults 1 1" > $VNFSDIR/etc/fstab
echo "tmpfs /dev/shm tmpfs defaults 0 0" >> $VNFSDIR/etc/fstab
echo "devpts /dev/pts devpts gid=5,mode=620 0 0" >> $VNFSDIR/etc/fstab
echo "sysfs /sys sysfs defaults 0 0" >> $VNFSDIR/etc/fstab
echo "proc /proc proc defaults 0 0" >> $VNFSDIR/etc/fstab

echo "Creating SSH host keys"
/usr/bin/ssh-keygen -q -t rsa1 -f $VNFSDIR/etc/ssh/ssh_host_key -C '' -N ''
/usr/bin/ssh-keygen -q -t rsa -f $VNFSDIR/etc/ssh/ssh_host_rsa_key -C '' -N ''
/usr/bin/ssh-keygen -q -t dsa -f $VNFSDIR/etc/ssh/ssh_host_dsa_key -C '' -N ''

if [ -x "$VNFSDIR/usr/bin/passwd" ]; then
    echo "Setting root password..."
    chroot $VNFSDIR /usr/bin/passwd root
else
    echo "Setting root password to NULL (be sure to fix this yourself)"
    sed -i -e 's/^root:\*:/root::/' $VNFSDIR/etc/shadow
fi

echo "Done."
