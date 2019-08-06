all:
	nasm pmtest2.asm -o pmtest2.bin
	dd if=pmtest2.bin of=a.img count=1 conv=notrunc
	cp a.img ../bochs-2.6.9/a.img
