# SPDX-License-Identifier: EUPL-1.2
# SPDX-FileCopyrightText: 2021 Alyssa Ross <hi@alyssa.is>

# qemu-kvm is non-standard, but is present in at least Fedora and
# Nixpkgs.  If you don't have qemu-kvm, you'll need to set e.g.
# QEMU_KVM = qemu-system-x86_64 -enable-kvm.
QEMU_KVM = qemu-kvm
CLOUD_HYPERVISOR = cloud-hypervisor

VMM = qemu

# These don't have the host/ prefix because they're not referring to
# paths in the source tree.
HOST_S6_RC_DIRECTORIES = s6-rc/appvm-catgirl-vmm/env

HOST_S6_RC_FILES = \
	host/s6-rc/appvm-catgirl-vmm/data/pid2mac \
	host/s6-rc/appvm-catgirl-vmm/dependencies \
	host/s6-rc/appvm-catgirl-vmm/notification-fd \
	host/s6-rc/appvm-catgirl-vmm/run \
	host/s6-rc/appvm-catgirl-vmm/type \
	host/s6-rc/appvm-catgirl/dependencies \
	host/s6-rc/appvm-catgirl/run \
	host/s6-rc/appvm-catgirl/type

HOST_S6_RC_BUILD_FILES = \
	build/host/data/appvm-catgirl/rootfs.ext4 \
	build/host/data/appvm-catgirl/vmlinux

# We produce an s6-rc source directory, but that doesn't play nice
# with Make, because it won't know to update if some file in the
# directory is changed, or a file is created or removed in a
# subdirectory.  Using the whole source directory could also end up
# including files that aren't intended to be part of the input, like
# temporary editor files or .license files.  So for all these reasons,
# only explicitly listed files are included in the build result.
build/svc: $(HOST_S6_RC_FILES) $(HOST_S6_RC_BUILD_FILES)
	rm -rf $@
	mkdir -p $@

	tar -c $(HOST_S6_RC_FILES) | tar -C $@ -x --strip-components 1
	tar -c $(HOST_S6_RC_BUILD_FILES) | tar -C $@ -x --strip-components 2
	cd $@ && mkdir -p $(HOST_S6_RC_DIRECTORIES)

build/host/data/appvm-catgirl/vmlinux: $(VMLINUX)
	mkdir -p $$(dirname $@)
	cp $(VMLINUX) $@

# tar2ext4 will leave half a filesystem behind if it's interrupted
# half way through.
build/host/data/appvm-catgirl/rootfs.ext4: build/rootfs.tar
	mkdir -p $$(dirname $@)
	tar2ext4 -i build/rootfs.tar -o $@.tmp
	mv $@.tmp $@

VM_FILES = \
	etc/fstab \
	etc/init \
	etc/mdev.conf \
	etc/mdev/iface \
	etc/passwd \
	etc/resolv.conf

# These are separate because they need to be included, but putting
# them as make dependencies would confuse make.
VM_LINKS = bin etc/ssl/certs/ca-certificates.crt

VM_BUILD_FILES = build/etc/s6-rc
VM_MOUNTPOINTS = dev run proc sys

build/rootfs.tar: $(PACKAGES_TAR) $(VM_FILES) $(VM_BUILD_FILES)
	cp --no-preserve=mode -f $(PACKAGES_TAR) $@
	tar $(TARFLAGS) --append -f $@ $(VM_FILES) $(VM_LINKS)
	echo $(VM_BUILD_FILES) | cut -d/ -f2 | \
	    tar $(TARFLAGS) --append -f $@ -C build -T -
	for m in $(VM_MOUNTPOINTS); do \
	    tar $(TARFLAGS) --append -hf $@ --xform="s,.*,$$m," /var/empty ; \
	done
	tar $(TARFLAGS) --append -hf $@ --xform='s,.*,etc/service,' /var/empty

VM_S6_RC_FILES = \
	etc/s6-rc/catgirl/run \
	etc/s6-rc/catgirl/type \
	etc/s6-rc/mdevd-coldplug/dependencies \
	etc/s6-rc/mdevd-coldplug/type \
	etc/s6-rc/mdevd-coldplug/up \
	etc/s6-rc/mdevd/notification-fd \
	etc/s6-rc/mdevd/run \
	etc/s6-rc/mdevd/type \
	etc/s6-rc/ok-all/contents \
	etc/s6-rc/ok-all/type

build/etc/s6-rc: $(VM_S6_RC_FILES)
	mkdir -p $$(dirname $@)
	rm -rf $@

	dir=$$(mktemp -d) && \
	    tar -c $(VM_S6_RC_FILES) | tar -C $$dir -x --strip-components 2 && \
	    s6-rc-compile $@ $$dir; \
	    exit=$$?; rm -r $$dir; exit $$exit

run-qemu: build/host/data/appvm-catgirl/rootfs.ext4
	$(QEMU_KVM) -m 128 -cpu host -machine q35,kernel=$(KERNEL) -vga none \
	  -drive file=build/host/data/appvm-catgirl/rootfs.ext4,if=virtio,format=raw,readonly=on \
	  -append "console=ttyS0 root=/dev/vda" \
	  -netdev user,id=net0 \
	  -device virtio-net,netdev=net0,mac=0A:B3:EC:00:00:00 \
	  -chardev pty,id=virtiocon0 \
	  -device virtio-serial-pci \
	  -device virtconsole,chardev=virtiocon0
.PHONY: run-qemu

run-cloud-hypervisor: build/host/data/appvm-catgirl/rootfs.ext4
	$(CLOUD_HYPERVISOR) \
	    --api-socket path=vmm.sock \
	    --memory size=128M
	    --disk path=build/host/data/appvm-catgirl/rootfs.ext4,readonly=on \
	    --net tap=tap0,mac=0A:B3:EC:00:00:00 \
	    --kernel $(KERNEL) \
	    --cmdline "console=ttyS0 root=/dev/vda" \
	    --console pty \
	    --serial tty
.PHONY: run-cloud-hypervisor

run: run-$(VMM)
.PHONY: run

clean:
	rm -rf build
.PHONY: clean