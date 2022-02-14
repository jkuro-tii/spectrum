# SPDX-License-Identifier: EUPL-1.2
# SPDX-FileCopyrightText: 2021-2022 Alyssa Ross <hi@alyssa.is>

# qemu-kvm is non-standard, but is present in at least Fedora and
# Nixpkgs.  If you don't have qemu-kvm, you'll need to set e.g.
# QEMU_KVM = qemu-system-x86_64 -enable-kvm.
QEMU_KVM = qemu-kvm

MCOPY = mcopy
MKFS_FAT = mkfs.fat
MMD = mmd
OBJCOPY = objcopy
SCRIPTS = ../scripts
TRUNCATE = truncate
VERITYSETUP = veritysetup

build/live.img: $(SCRIPTS)/format-uuid.sh $(SCRIPTS)/make-gpt.sh build/boot.fat build/rootfs.verity.superblock build/rootfs.verity.roothash $(ROOT_FS) $(EXT_FS)
	$(SCRIPTS)/make-gpt.sh $@.tmp \
	    build/boot.fat:c12a7328-f81f-11d2-ba4b-00a0c93ec93b \
	    build/rootfs.verity.superblock:2c7357ed-ebd2-46d9-aec1-23d437ec2bf5:$$($(SCRIPTS)/format-uuid.sh "$$(dd if=build/rootfs.verity.roothash bs=32 skip=1 count=1 status=none)") \
	    $(ROOT_FS):4f68bce3-e8cd-4db1-96e7-fbcaf984b709:$$($(SCRIPTS)/format-uuid.sh "$$(head -c 32 build/rootfs.verity.roothash)") \
	    $(EXT_FS):9293e1ff-cee4-4658-88be-898ec863944f
	mv $@.tmp $@

build/cmdline: build/rootfs.verity.roothash
	printf "ro console=ttyS0 roothash=" > $@
	cat build/rootfs.verity.roothash >> $@

build/bootx64.efi: etc/os-release build/cmdline $(INITRAMFS)
	$(OBJCOPY) --add-section .osrel=etc/os-release --change-section-vma .osrel=0x20000 \
	    --add-section .cmdline=build/cmdline --change-section-vma .cmdline=0x30000 \
	    --add-section .linux=$(KERNEL) --change-section-vma .linux=0x40000 \
	    --add-section .initrd=$(INITRAMFS) --change-section-vma .initrd=0x3000000 \
	    $(EFI_STUB) $@

build/boot.fat: build/bootx64.efi
	$(TRUNCATE) -s 157286400 $@
	$(MKFS_FAT) $@
	$(MMD) -i $@ ::/EFI ::/EFI/BOOT
	$(MCOPY) -i $@ build/bootx64.efi ::/EFI/BOOT

# veritysetup format produces two files, but Make only (portably)
# supports one output per rule, so we combine the two outputs then
# define two more rules to separate them again.
build/rootfs.verity: $(ROOT_FS)
	mkdir -p build
	$(VERITYSETUP) format $(ROOT_FS) build/rootfs.verity.superblock.tmp \
	    | awk -F ':[[:blank:]]*' '$$1 == "Root hash" {print $$2; exit}' \
	    > build/rootfs.verity.roothash.tmp
	cat build/rootfs.verity.roothash.tmp build/rootfs.verity.superblock.tmp \
	    > $@
	rm build/rootfs.verity.roothash.tmp build/rootfs.verity.superblock.tmp
build/rootfs.verity.roothash: build/rootfs.verity
	head -n 1 build/rootfs.verity > $@
build/rootfs.verity.superblock: build/rootfs.verity
	tail -n +2 build/rootfs.verity > $@

clean:
	rm -rf build
.PHONY: clean

run: build/live.img
	$(QEMU_KVM) -m 4G \
	    -bios $(OVMF_FD) \
	    -cpu host \
	    -display gtk,gl=on \
	    -device virtio-vga-gl \
	    -device qemu-xhci \
	    -device usb-storage,drive=drive1,removable=true \
	    -drive file=build/live.img,id=drive1,format=raw,if=none,readonly=true
.PHONY: run