SUBDIRS = lib share etc bin

MAINTAINERCLEANFILES = Makefile.in aclocal.m4 configure compile config.*
DISTCLEANFILES = 
CLEANFILES = 
EXTRA_DIST = warewulf-common.spec LICENSE

# Fix for make distcheck
DISTCHECK_CONFIGURE_FLAGS = --with-perllibdir=$$dc_install_base/perllibs
