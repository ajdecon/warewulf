#!/bin/sh

VNFSDIR=$1
VNFSPATH=$2

if [ -z "$VNFSPATH" ]; then
    echo "USAGE: $0 /path/to/chroot /path/to/name.vnfs"
    exit 1
fi

if [ -z "$VNFSDIR" ]; then
    echo "USAGE: $0 /path/to/chroot /path/to/name.vnfs"
    exit 1
elif [ -d "$VNFSDIR" ]; then

    DIRNAME=`dirname $VNFSPATH`
    if [ ! -d "$DIRNAME" ]; then
        mkdir -p $DIRNAME
    fi
    ( cd $VNFSDIR; find . | cpio -o -H newc ) | gzip -9 > $VNFSPATH

else
    echo "The initial argument must be a chroot!"
    exit 1
fi
