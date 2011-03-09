METHODSCRIPTS = wwgetscript wwgetnodeconfig wwgetvnfs register functions

TRANSPORT_NAME = http


rootfs:
	rm -rf rootfs
	mkdir -p rootfs/warewulf/transports/http
	cp -a $(METHODSCRIPTS) rootfs/warewulf/transports/http
	@ for i in $(METHODSCRIPTS); do \
		echo "install -m 755 $$i rootfs/warewulf/transports/$$i.$(TRANSPORT_NAME)" ; \
		install -m 755 $$i rootfs/warewulf/transports/$$i.$(TRANSPORT_NAME); \
	done
	chmod +x rootfs/warewulf/transports/http/*

http.cpio: rootfs
	cd rootfs/; find . | cpio -o -H newc -F ../http.cpio

install: http.cpio
	install -d -m 755 $(DESTDIR)/$(WAREWULF_STATEDIR)/warewulf/initramfs/
	install -m 644 http.cpio $(DESTDIR)/$(WAREWULF_STATEDIR)/warewulf/initramfs/http-interface

clean:
	rm -rf _work
	rm -f unionfs


EXTRA_DIST = $(METHODSCRIPTS)
