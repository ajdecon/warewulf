SUBDIRS = capabilities

all: initramfs.cpio

top_srcdir = @top_srcdir@

BUSYBOX_VERSION = 1.18.1
BUSYBOX_SOURCE = $(top_srcdir)/3rd_party/GPL/busybox-$(BUSYBOX_VERSION).tar.bz2
BUSYBOX_DIR = busybox-$(BUSYBOX_VERSION)
BUSYBOX_PATCHES = 

busybox:
	@ if [ ! -d "_work/$(BUSYBOX_DIR)" ]; then \
		echo "Preparing to build initramfs core" ;\
		mkdir -p _work/ ;\
		tar xjf $(BUSYBOX_SOURCE) -C _work/ ;\
		for i in $(BUSYBOX_PATCHES); do \
			(cd _work/busybox-$(BUSYBOX_VERSION); patch -p1 < ../../$${i} || exit 1) \
		done ;\
		cp busybox.config _work/busybox-$(BUSYBOX_VERSION)/.config ;\
	fi
	@ if [ ! -f "_work/busybox-$(BUSYBOX_VERSION)/" ]; then \
		echo "Building initramfs core" ;\
		make -C _work/busybox-$(BUSYBOX_VERSION) busybox ;\
	fi
	@ if [ ! -d "_work/busybox-$(BUSYBOX_VERSION)/_install" ]; then \
		echo "Installing initramfs core" ;\
		make -C _work/busybox-$(BUSYBOX_VERSION) install ;\
	fi


rootfs: busybox
	rm -rf rootfs
	mkdir rootfs
	mkdir rootfs/bin
	mkdir rootfs/sbin
	mkdir rootfs/etc
	mkdir rootfs/proc
	mkdir rootfs/var
	mkdir rootfs/tmp
	mkdir rootfs/usr
	cp -a _work/busybox-$(BUSYBOX_VERSION)/_install/* rootfs/
	cp -L --parents /lib*/ld-linux* rootfs/
	find rootfs -type f -perm -o+x  -print | xargs ldd | grep "=>" | awk '{print $$3}' | sort | uniq | while read i; do cp -L --parents $$i rootfs/; done
	find rootfs -type f -perm -o+x -print | xargs strip -g
	rm -f rootfs/linuxrc
	install -m 755 init rootfs/init
	install -m 755 functions rootfs/etc/functions
	install -m 755 dhcp-script rootfs/sbin/
	install -m 755 detect rootfs/sbin/
	install -m 755 hwaddr rootfs/sbin/
	install -m 755 methodhandler rootfs/sbin/
	ln -s methodhandler rootfs/sbin/getvnfs
	ln -s methodhandler rootfs/sbin/getbootscript
	ln -s methodhandler rootfs/sbin/getnodeconfig

initramfs.cpio: rootfs
	cp devs.cpio initramfs.cpio
	cd rootfs/; find . | cpio -o -H newc -A -F ../initramfs.cpio

install: install-recursive initramfs.cpio
	install -d -m 755 $(DESTDIR)/$(WAREWULF_STATEDIR)/warewulf/initramfs/
	install -m 644 initramfs.cpio $(DESTDIR)/$(WAREWULF_STATEDIR)/warewulf/initramfs/base

clean:
	rm -rf _work
	rm -rf rootfs
	rm -rf initramfs



EXTRA_DIST = *.config init devs.cpio functions dhcp-script detect hwaddr methodhandler

