all: unionfs

top_srcdir = @top_srcdir@

UNIONFS_VERSION = 0.24
UNIONFS_SOURCE = $(top_srcdir)/3rd_party/BSD/unionfs-fuse-$(UNIONFS_VERSION).tar.bz2

unionfs:
	@ if [ ! -d "_work/unionfs-fuse/unionfs-fuse-$(UNIONFS_VERSION)" ]; then \
	    echo "Preparing to build unionfs-fuse" ;\
	    mkdir -p _work/unionfs-fuse;\
	    tar xjf $(UNIONFS_SOURCE) -C _work/unionfs-fuse/ ;\
	fi
	@ if [ ! -f "_work/unionfs-fuse/unionfs-fuse-$(UNIONFS_VERSION)/src/unionfs" ]; then \
	    echo "Building unionfs-fuse" ;\
	    make -C _work/unionfs-fuse/unionfs-fuse-$(UNIONFS_VERSION) ;\
	fi
	@ if [ ! -f "unionfs" ]; then \
	    cp -a _work/unionfs-fuse/unionfs-fuse-$(UNIONFS_VERSION)/src/unionfs unionfs ;\
	fi


rootfs: unionfs
	rm -rf rootfs
	mkdir rootfs
	mkdir rootfs/sbin
	cp -a unionfs rootfs/sbin/
	find rootfs -type f -perm -o+x -print | xargs ldd | grep "=>" | awk '{print $$3}' | sort | uniq | while read i; do cp -L --parents $$i rootfs/; done
	find rootfs -type f -perm -o+x -print | xargs strip -g

statelite.cpio: rootfs
	cd rootfs/; find . | cpio -o -H newc -F ../statelite.cpio

install: statelite.cpio
	install -d -m 755 $(DESTDIR)/$(WAREWULF_STATEDIR)/warewulf/initramfs/
	install -m 644 statelite.cpio $(DESTDIR)/$(WAREWULF_STATEDIR)/warewulf/initramfs/statelite.cpio

clean:
	rm -rf _work
	rm -f unionfs

