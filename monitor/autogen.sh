#!/bin/sh

set -x
libtoolize -f -c
aclocal
autoheader
autoconf
automake -ca -Wno-portability

if [ -z "$NO_CONFIGURE" ]; then
#   ./configure CFLAGS="-g -std=gnu99 -ljson -lsqlite3" $@ 
   ./configure $@ 
fi

