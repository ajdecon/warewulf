#!/bin/sh

VNFSDIR=$1
VNFSPATH=$2

if [ -z "$VNFSPATH" ]; then
    echo "USAGE: $0 /path/to/vnfs_directory /path/to/vnfs_file"
    exit 1
fi

if [ -z "$VNFSDIR" ]; then
    echo "USAGE: $0 /path/to/vnfs_directory /path/to/vnfs_file"
    exit 1
elif [ -d "$VNFSDIR" ]; then

    ( cd $VNFSDIR; find . | cpio -o -H newc ) | gzip -9 > $VNFSPATH

else
    echo "VNFS must be a directory"
    exit 1
fi
