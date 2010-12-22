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

install:
	install -d -m 755 $(DESTDIR)$(initramfsdir)/statelite/sbin/
	install -m 755 unionfs $(DESTDIR)$(initramfsdir)/statelite/sbin/

clean:
	rm -rf _work
	rm -f unionfs

