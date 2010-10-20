all: unionfs

top_srcdir = @top_srcdir@

UNIONFS_VERSION = 0.24
UNIONFS_SOURCE = unionfs-fuse-$(UNIONFS_VERSION).tar.bz2
UNIONFS_DIR = unionfs-fuse-$(UNIONFS_VERSION)


unionfs:
	@ if [ ! -d "_work/unionfs-fuse/$(UNIONFS_DIR)" ]; then \
	    echo "Preparing to build unionfs-fuse" ;\
	    mkdir -p _work/unionfs-fuse;\
	    tar xjf $(UNIONFS_SOURCE) -C _work/unionfs-fuse/ ;\
	fi
	@ if [ ! -f "_work/unionfs-fuse/$(UNIONFS_DIR)/src/unionfs" ]; then \
	    echo "Building unionfs-fuse" ;\
	    make -C _work/unionfs-fuse/$(UNIONFS_DIR) ;\
	fi
	@ if [ ! -f "unionfs" ]; then \
	    echo "Installing unionfs" ;\
	    cp -a _work/unionfs-fuse/$(UNIONFS_DIR)/src/unionfs unionfs ;\
	fi


clean:
	rm -rf _work
	rm -f unionfs


EXTRA_DIST = $(UNIONFS_SOURCE)

