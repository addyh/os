# Build:

```sh
nasm -g -f elf -o Kernel.o Kernel.asm
ld -T linker.ld -o Kernel.bin Kernel.o
```

# Binary Emulate:

```sh
qemu-system-i386 -curses -kernel Kernel.bin
```

# Create ISO Image:

```sh
mkisofs -R -b boot/grub/stage2_eltorito -no-emul-boot -boot-load-size 4 -boot-info-table -o os.iso os

# --or-- (same)

genisoimage -R -b boot/grub/stage2_eltorito -no-emul-boot -boot-load-size 4 -boot-info-table -o os.iso os
```

# ISO Emulate:

```sh
qemu-system-i386 -curses -cdrom os.iso
```
