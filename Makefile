GPPPARAMS = -m32 -fno-use-cxa-atexit -nostdlib -fno-builtin -fno-rtti -fno-exceptions -fno-leading-underscore
ASPARAMS = --32
LDPARAMS = -melf_i386

objects = loader.o kernel.o

device ?= /dev/sdb
size ?= 1G
margin ?= 100M
image ?= mykernel.iso

override size := $(shell numfmt --from=si $(size))
override margin := $(shell numfmt --from=si $(margin))

%.o: %.cpp
	g++ $(GPPPARAMS) -o $@ -c $<

%.o: %.s
	as $(ASPARAMS) -o $@ $<

mykernel.bin: linker.ld $(objects)
	ld $(LDPARAMS) -T $< -o $@ $(objects)

install: mykernel.bin
	sudo cp $< /boot/mykernel.bin

$(image): mykernel.bin
	mkdir -p iso/boot/grub
	cp $< iso/boot/
	
	echo "\n\
	set timeout=0\n\
	set default=0\n\n\
	menuentry 'My Operating System' {\n\
		multiboot /boot/mykernel.bin\n\
		boot\n\
	}\n\
	" > iso/boot/grub/grub.cfg
	
	grub-mkrescue --output=$@ iso
	rm -rf iso

vbox: $(image)
	VirtualBoxVM --startvm os2 &

qemu: $(image)
	qemu-system-i386 -drive format=raw,file=$(image)

run: qemu

flash: $(image)
	@set -e; \
	if [ ! -b $(device) ]; then \
		echo "ERROR: $(device) not found or not a block device."; \
		exit 1; \
	fi; \
	actual_size=$$(lsblk -bno SIZE $(device)); \
	actual_size_str=$$(numfmt --to=si $$actual_size); \
	size_str=$$(numfmt --to=si $$size); \
	margin_str=$$(numfmt --to=si $$margin); \
	min_size=$$(expr $(size) - $(margin)); \
	max_size=$$(expr $(size) + $(margin)); \
	if [ "$$actual_size" -lt "$$min_size" ] || [ "$$actual_size" -gt "$$max_size" ]; then \
		echo "ERROR: Device $(device) size ($$actual_size_str bytes) is not within range of $$size_str ±$$margin_str."; \
		echo "PLEASE VERIFY CORRECT DEVICE, THEN RUN: make flash device=$(device) size=$$actual_size_str"; \
		exit 1; \
	fi; \
	lsblk | sed "s|^\($(notdir $(device))\)\(.*\)|\x1b[32m\1\2\x1b[0m|"; \
	read -p "About to flash $(image) to $(device). Are you SURE? (y/N): " ans; \
	if [ "$$ans" != "y" ] && [ "$$ans" != "Y" ]; then \
		echo "Aborted."; \
		exit 0; \
	fi; \
	sudo dd if=$(image) of=$(device) bs=512 status=progress && sync; \
	echo "Flash complete."

