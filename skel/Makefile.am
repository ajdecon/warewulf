SUBDIRS = lib

MAINTAINERCLEANFILES = Makefile.in aclocal.m4 configure compile config.* ltmain.sh install-sh missing
DISTCLEANFILES = 
CLEANFILES = 
EXTRA_DIST = warewulf-skel.spec

# Fix for make distcheck
DISTCHECK_CONFIGURE_FLAGS = --with-perllibdir=$$dc_install_base/perllibs
