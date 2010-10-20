all: initramfs.cpio

top_srcdir = @top_srcdir@

BUSYBOX_VERSION = 1.17.3
BUSYBOX_SOURCE = busybox-$(BUSYBOX_VERSION).tar.bz2
BUSYBOX_DIR = busybox-$(BUSYBOX_VERSION)
BUSYBOX_PATCHES = 

SUBDIRS =

busybox:
	@ if [ ! -d "_work/$(BUSYBOX_DIR)" ]; then \
		echo "Preparing to build initramfs core" ;\
		mkdir -p _work/ ;\
		tar xjf $(BUSYBOX_SOURCE) -C _work/ ;\
		for i in $(BUSYBOX_PATCHES); do \
			(cd _work/$(BUSYBOX_DIR); patch -p1 < ../../$${i} || exit 1) \
		done ;\
		cp busybox.config _work/$(BUSYBOX_DIR)/.config ;\
	fi
	@ if [ ! -f "_work/$(BUSYBOX_DIR)/" ]; then \
		echo "Building initramfs core" ;\
		make -C _work/$(BUSYBOX_DIR) busybox ;\
	fi
	@ if [ ! -d "_work/$(BUSYBOX_DIR)/_install" ]; then \
		echo "Installing initramfs core" ;\
		make -C _work/$(BUSYBOX_DIR) install ;\
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
	cp -a _work/$(BUSYBOX_DIR)/_install/* rootfs/
	cp -L --parents /lib*/ld-linux* rootfs/
	find rootfs -type f -perm -o+x  -print | xargs ldd | grep "=>" | awk '{print $$3}' | sort | uniq | while read i; do cp -L --parents $$i rootfs/; done
	rm -f rootfs/linuxrc
	install -m 755 init rootfs/init

initramfs.cpio: rootfs
	cp devs.cpio initramfs
	cd rootfs/; find . | cpio -o -H newc -A -F ../initramfs.cpio

install:
	install -d -m 755 $(DESTDIR)/$(localstatedir)/warewulf/
	install -m 644 initramfs $(DESTDIR)/$(localstatedir)/warewulf/initramfs.cpio

clean:
	rm -rf _work
	rm -rf rootfs
	rm -rf initramfs



EXTRA_DIST = $(BUSYBOX_SOURCE) *.config init devs.cpio

