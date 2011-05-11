METHODSCRIPTS = 10-sanitycheck 15-partition 16-format 20-mount 30-getvnfs 50-config 70-devtree 80-dracut 80-grubify 90-files
INITSCRIPT = init

PROVISION_NAME = localdisk


rootfs:
	rm -rf rootfs
	mkdir -p rootfs/warewulf/provision/
	@ for i in $(METHODSCRIPTS); do \
		echo "install -m 755 $$i rootfs/warewulf/provision/$$i.$(PROVISION_NAME)" ; \
		install -m 755 $(srcdir)/$$i rootfs/warewulf/provision/$$i.$(PROVISION_NAME); \
	done
	install -m 755 $(INITSCRIPT) rootfs/warewulf/init.$(PROVISION_NAME)

http.cpio: rootfs
	cd rootfs/; find . | cpio -o -H newc -F ../capability.cpio

install: http.cpio
	install -d -m 755 $(DESTDIR)/$(WAREWULF_STATEDIR)/warewulf/initramfs/
	install -m 644 capability.cpio $(DESTDIR)/$(WAREWULF_STATEDIR)/warewulf/initramfs/provision-localdisk

clean:
	rm -rf _work
	rm -f unionfs


EXTRA_DIST = $(METHODSCRIPTS) $(INITSCRIPT)
