METHODSCRIPTS = getbootscript.http getnodeconfig.http getvnfs.http


rootfs:
	rm -rf rootfs
	mkdir rootfs
	mkdir rootfs/sbin
	cp -a $(METHODSCRIPTS) rootfs/sbin/
	chmod +x rootfs/sbin/*

http.cpio: rootfs
	cd rootfs/; find . | cpio -o -H newc -F ../http.cpio

install: http.cpio
	install -d -m 755 $(DESTDIR)/$(WAREWULF_STATEDIR)/warewulf/initramfs/
	install -m 644 http.cpio $(DESTDIR)/$(WAREWULF_STATEDIR)/warewulf/initramfs/http-interface

clean:
	rm -rf _work
	rm -f unionfs


EXTRA_DIST = $(METHODSCRIPTS)
