#!/bin/sh

set -x
libtoolize -f -c
aclocal
autoconf
autoheader
automake -ca -Wno-portability

if [ -z "$NO_CONFIGURE" ]; then
   ./configure $@
fi

