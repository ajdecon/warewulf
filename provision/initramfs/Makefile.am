SUBDIRS = capabilities

all: initramfs.cpio

top_srcdir = @top_srcdir@

BUSYBOX_VERSION = 1.19.3
BUSYBOX_SOURCE = $(top_srcdir)/3rd_party/GPL/busybox-$(BUSYBOX_VERSION).tar.bz2
BUSYBOX_DIR = busybox-$(BUSYBOX_VERSION)
BUSYBOX_PATCHES = $(top_srcdir)/3rd_party/GPL/busybox-1.19.3-udhcpc_ipoib.patch

E2FSPROGS_VERSION = 1.42
E2FSPROGS_SOURCE = $(top_srcdir)/3rd_party/GPL/e2fsprogs-$(E2FSPROGS_VERSION).tar.gz
E2FSPROGS_DIR = e2fsprogs-$(E2FSPROGS_VERSION)
E2FSPROGS_CONFIGARGS = --disable-testio-debug --disable-debugfs --disable-imager --disable-resizer  --disable-defrag --disable-fsck --disable-tls --disable-uuidd --disable-nls --disable-checker --disable-profile


e2fsprogs:
	@ if [ ! -d "_work/$(E2FSPROGS_DIR)" ]; then \
		echo "Preparing to build e2fsprogs" ;\
		mkdir -p _work/ ;\
		tar xzf $(E2FSPROGS_SOURCE) -C _work/ ;\
	fi
	@ if [ ! -f "_work/$(E2FSPROGS_DIR)/misc/mke2fs" ]; then \
		echo "Building e2fsprogs" ;\
		(cd _work/$(E2FSPROGS_DIR)/; ./configure $(E2FSPROGS_CONFIGARGS)) ;\
		make -C _work/$(E2FSPROGS_DIR);\
	fi


busybox:
	@ if [ ! -d "_work/$(BUSYBOX_DIR)" ]; then \
		echo "Preparing to build initramfs core" ;\
		mkdir -p _work/ ;\
		tar xjf $(BUSYBOX_SOURCE) -C _work/ ;\
		for i in $(BUSYBOX_PATCHES); do \
			(cd _work/$(BUSYBOX_DIR); patch -p1 < ../../$${i} || exit 1) \
		done ;\
		cp $(srcdir)/busybox.config _work/busybox-$(BUSYBOX_VERSION)/.config ;\
	fi
	@ if [ ! -f "_work/$(BUSYBOX_DIR)/" ]; then \
		echo "Building initramfs core" ;\
		make -C _work/$(BUSYBOX_DIR) busybox ;\
	fi
	@ if [ ! -d "_work/$(BUSYBOX_DIR)/_install" ]; then \
		echo "Installing initramfs core" ;\
		make -C _work/$(BUSYBOX_DIR) install ;\
	fi


rootfs: busybox e2fsprogs
	rm -rf rootfs
	mkdir rootfs
	mkdir rootfs/bin
	mkdir rootfs/sbin
	mkdir rootfs/etc
	mkdir rootfs/proc
	mkdir rootfs/var
	mkdir rootfs/tmp
	mkdir rootfs/usr
	mkdir rootfs/lib
	mkdir rootfs/lib64
	chmod -R u+w rootfs/
	cp -a _work/$(BUSYBOX_DIR)/_install/* rootfs/
	cp _work/$(E2FSPROGS_DIR)/misc/mke2fs rootfs/sbin/mkfs.ext4
	ln -s mkfs.ext4 rootfs/sbin/mkfs.ext3
	cp -L --parents /lib*/ld-linux* rootfs/
	find rootfs -type f -perm -o+x  -print | xargs ldd | grep "=>" | awk '{print $$3}' | grep "^/" | sort | uniq | while read i; do cp -L --parents $$i rootfs/; done
	find rootfs -type f -perm -o+x -print | xargs strip -g
	rm -f rootfs/linuxrc
	install -m 755 $(srcdir)/init rootfs/init
	install -m 755 $(srcdir)/functions rootfs/etc/functions
	install -m 755 $(srcdir)/dhcp-script rootfs/sbin/
	install -m 755 $(srcdir)/detect rootfs/sbin/
	install -m 755 $(srcdir)/transporthandler rootfs/sbin/
	install -m 755 $(srcdir)/provisionhandler rootfs/sbin/
	install -m 755 $(srcdir)/wwlogger rootfs/sbin/
	ln -s transporthandler rootfs/sbin/wwgetvnfs
	ln -s transporthandler rootfs/sbin/wwgetscript
	ln -s transporthandler rootfs/sbin/wwgetnodeconfig
	ln -s transporthandler rootfs/sbin/wwgetfiles

initramfs.cpio: rootfs
	install -m 644 $(srcdir)/devs.cpio initramfs.cpio
	cd rootfs/; find . | cpio -o -H newc -A -F ../initramfs.cpio

install-data-local: initramfs.cpio
	install -d -m 755 $(DESTDIR)/$(WAREWULF_STATEDIR)/warewulf/initramfs/
	install -m 644 initramfs.cpio $(DESTDIR)/$(WAREWULF_STATEDIR)/warewulf/initramfs/base

uninstall-local:
	rm -rf $(DESTDIR)/$(WAREWULF_STATEDIR)/warewulf/initramfs/base

clean-local:
	rm -rf _work rootfs initramfs.cpio



EXTRA_DIST = busybox.config init devs.cpio functions dhcp-script detect transporthandler provisionhandler wwlogger

