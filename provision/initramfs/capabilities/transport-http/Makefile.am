METHODSCRIPTS = wwgetscript wwgetnodeconfig wwgetvnfs register functions wwgetfiles

TRANSPORT_NAME = http


rootfs:
	rm -rf rootfs
	mkdir -p rootfs/warewulf/transports/$(TRANSPORT_NAME)
	@ for i in $(METHODSCRIPTS); do \
		echo "install -m 755 $$i rootfs/warewulf/transports/$(TRANSPORT_NAME)/$$i" ; \
		install -m 755 $$i rootfs/warewulf/transports/$(TRANSPORT_NAME)/$$i; \
	done

http.cpio: rootfs
	cd rootfs/; find . | cpio -o -H newc -F ../capability.cpio

install: http.cpio
	install -d -m 755 $(DESTDIR)/$(WAREWULF_STATEDIR)/warewulf/initramfs/
	install -m 644 capability.cpio $(DESTDIR)/$(WAREWULF_STATEDIR)/warewulf/initramfs/transport-http

clean:
	rm -rf _work
	rm -f unionfs


EXTRA_DIST = $(METHODSCRIPTS)
