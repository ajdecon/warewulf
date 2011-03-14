METHODSCRIPTS = 05-pre 95-post

PROVISION_NAME = all


rootfs:
	rm -rf rootfs
	mkdir -p rootfs/warewulf/provision/
	@ for i in $(METHODSCRIPTS); do \
		echo "install -m 755 $$i rootfs/warewulf/provision/$$i.$(PROVISION_NAME)" ; \
		install -m 755 $(srcdir)/$$i rootfs/warewulf/provision/$$i.$(PROVISION_NAME); \
	done

http.cpio: rootfs
	cd rootfs/; find . | cpio -o -H newc -F ../capability.cpio

install: http.cpio
	install -d -m 755 $(DESTDIR)/$(WAREWULF_STATEDIR)/warewulf/initramfs/
	install -m 644 capability.cpio $(DESTDIR)/$(WAREWULF_STATEDIR)/warewulf/initramfs/provision-adhoc

clean:
	rm -rf _work
	rm -f unionfs


EXTRA_DIST = $(METHODSCRIPTS)
