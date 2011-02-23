SUBDIRS = GPL BSD

all: gpxelinux.0

SYSLINUX_VERSION = 4.03
SYSLINUX_SOURCE = $(top_srcdir)/3rd_party/GPL/syslinux-$(SYSLINUX_VERSION).tar.bz2
SYSLINUX_DIR = syslinux-$(SYSLINUX_VERSION)

gpxelinux.0:
	@ if [ ! -d "_work/$(SYSLINUX_DIR)" ]; then \
		echo "Extracting syslinux distribution" ;\
		mkdir -p _work/ ;\
		tar xjf $(SYSLINUX_SOURCE) -C _work/ ;\
	fi
	cp _work/$(SYSLINUX_DIR)/gpxe/gpxelinux.0 .

install: install-recursive gpxelinux.0
	mkdir -p $(DESTDIR)/$(datadir)/warewulf/
	install -m 644 gpxelinux.0 $(DESTDIR)/$(datadir)/warewulf/gpxelinux.0

clean:
	rm -rf _work
	rm -f gpxelinux.0
