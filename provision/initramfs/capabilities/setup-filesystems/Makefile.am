METHODSCRIPTS = 20-filesystems 80-mkbootable 95-umount 99-postreboot


rootfs:
	rm -rf rootfs
	mkdir -p rootfs/warewulf/provision/
	@ for i in $(METHODSCRIPTS); do \
		echo "install -m 755 $$i rootfs/warewulf/provision/$$i" ; \
		install -m 755 $(srcdir)/$$i rootfs/warewulf/provision/$$i; \
	done

http.cpio: rootfs
	cd rootfs/; find . | cpio -o -H newc -F ../capability.cpio

install: http.cpio
	install -d -m 755 $(DESTDIR)/$(WAREWULF_STATEDIR)/warewulf/initramfs/
	install -m 644 capability.cpio $(DESTDIR)/$(WAREWULF_STATEDIR)/warewulf/initramfs/setup-filesystems

clean:
	rm -rf _work
	rm -f unionfs


EXTRA_DIST = $(METHODSCRIPTS) $(INITSCRIPT)
