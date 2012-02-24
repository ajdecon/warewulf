SUBDIRS = lib bin etc

MAINTAINERCLEANFILES = Makefile.in aclocal.m4 configure compile config.* ltmain.sh
DISTCLEANFILES = 
CLEANFILES = 
EXTRA_DIST = warewulf-vnfs.spec LICENSE

# Fix for make distcheck
DISTCHECK_CONFIGURE_FLAGS = --with-perllibdir=$$dc_install_base/perllibs
