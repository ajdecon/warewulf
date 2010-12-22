SUBDIRS = lib initramfs modules etc bin cgi-bin share 3rd_party

MAINTAINERCLEANFILES = ChangeLog Makefile.in aclocal.m4 configure compile config.* ltmain.sh
DISTCLEANFILES = 
CLEANFILES = 
EXTRA_DIST = warewulf-provision.spec LICENSE

# Fix for make distcheck
DISTCHECK_CONFIGURE_FLAGS = --with-perllibdir=$$dc_install_base/perllibs

