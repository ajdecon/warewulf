all: rootfs

SUBDIRS =

rootfs:
	rm -rf rootfs
	mkdir rootfs
	mkdir rootfs/bin
	mkdir rootfs/sbin
	mkdir rootfs/etc
	mkdir rootfs/proc
	mkdir rootfs/var
	mkdir rootfs/tmp
	mkdir rootfs/usr
	cp -a ../3rd_party/busybox/* rootfs/
	cp -a ../3rd_party/unionfs rootfs/sbin/
	cp -L --parents /lib*/ld-linux* rootfs/
	find rootfs -type f -perm -o+x  -print | xargs ldd | grep "=>" | awk '{print $$3}' | sort | uniq | while read i; do cp -L --parents $$i rootfs/; done
	rm -f rootfs/linuxrc
	install -m 755 init rootfs/init


clean:
	rm -rf rootfs
