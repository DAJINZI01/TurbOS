org 0100h
mov ax, cs
mov ds, ax
mov es, ax
call DispStr
jmp $

DispStr:
	mov ax, BootMessage
	mov bp, ax;			es:bp 串地址
	mov cx, 10h;		串长度
	mov ax, 1301h;		
	mov bx, 000ch;		黑底红字高亮
	mov dl, 0;			页号
	int 10h;			bios提供的10H中断
	ret
	
BootMessage:	db 'hello, os world'
times 510 - ($-$$) db 00h
dw 0aa55h
