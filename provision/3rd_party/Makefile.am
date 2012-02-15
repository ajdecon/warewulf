SUBDIRS = GPL BSD

all: gpxelinux.0 chain.c32

SYSLINUX_VERSION = 4.04
SYSLINUX_SOURCE = $(top_srcdir)/3rd_party/GPL/syslinux-$(SYSLINUX_VERSION).tar.bz2
SYSLINUX_DIR = syslinux-$(SYSLINUX_VERSION)


chain.c32:
	@ if [ ! -d "_work/$(SYSLINUX_DIR)" ]; then \
		echo "Extracting syslinux distribution" ;\
		mkdir -p _work/ ;\
		tar xjf $(SYSLINUX_SOURCE) -C _work/ ;\
	fi
	cp _work/$(SYSLINUX_DIR)/com32/modules/chain.c32 .

gpxelinux.0:
	@ if [ ! -d "_work/$(SYSLINUX_DIR)" ]; then \
		echo "Extracting syslinux distribution" ;\
		mkdir -p _work/ ;\
		tar xjf $(SYSLINUX_SOURCE) -C _work/ ;\
	fi
	cp _work/$(SYSLINUX_DIR)/gpxe/gpxelinux.0 .

install-data-local: gpxelinux.0 chain.c32
	mkdir -p $(DESTDIR)/$(datadir)/warewulf/
	install -m 644 gpxelinux.0 $(DESTDIR)/$(datadir)/warewulf/
	install -m 644 chain.c32 $(DESTDIR)/$(datadir)/warewulf/

uninstall-local:
	rm -rf $(DESTDIR)/$(datadir)/warewulf/gpxelinux.0 $(DESTDIR)/$(datadir)/warewulf/chain.c32

clean-local:
	rm -rf _work gpxelinux.0 chain.c32
