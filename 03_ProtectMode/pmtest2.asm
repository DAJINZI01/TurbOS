;===============================================
; pmtest1.asm
; 编译方法：nasm pmtest1.asm -o pmtest1.bin
;===============================================

%include "pm.inc"	; 常量，宏，以及一些说明
org 	0x7C00
;org 	0100H
	jmp	LABEL_BEGIN
[SECTION .gdt]
; GDT
;					段基址		段界限			属性
LABEL_GDT:		Descriptor	0,		0,			0		; 空描述符
LABEL_DESC_NORMAL:	Descriptor 	0, 		0FFFFH,			DA_DRW 		; Normal 描述符
LABEL_DESC_CODE32:	Descriptor	0,		SegCode32Len - 1,	DA_C + DA_32	; 非一致代码段,32
LABEL_DESC_CODE16:	Descriptor	0,		0FFFFH,			DA_C	 	; 非一致代码段,16
LABEL_DESC_DATA:	Descriptor	0,		DataLen - 1,		DA_DRW	 	; Data
LABEL_DESC_STACK:	Descriptor	0,		TopOfStack,		DA_DRWA + DA_32 ; Stack, 32 
LABEL_DESC_TEST:	Descriptor	0,		0FFFFH,			DA_DRW		;
LABEL_DESC_VIDEO:	Descriptor	0B8000H,	0FFFFH,			DA_DRW		; 显存首地址

; GDT 结束

GdtLen		equ	$ - LABEL_GDT	; GDT长度
GdtPtr		dw	GdtLen - 1	; GDT界限
		dd	0		; GDT首地址

; GDT 选择子
SelectorNormal	equ	LABEL_DESC_NORMAL - LABEL_GDT
SelectorCode32	equ	LABEL_DESC_CODE32 - LABEL_GDT
SelectorCode16	equ	LABEL_DESC_CODE16 - LABEL_GDT
SelectorData	equ	LABEL_DESC_DATA- LABEL_GDT
SelectorStack	equ	LABEL_DESC_STACK- LABEL_GDT
SelectorTest	equ	LABEL_DESC_TEST- LABEL_GDT
SelectorVideo	equ	LABEL_DESC_VIDEO - LABEL_GDT
; END of [SECTION .gdt]

[SECTION .data1]; 数据段
ALIGN	32
[BITS 32]
LABEL_DATA:
SPValueInRealMode	dw	0
; 字符串
PMessage:		db	"In Protect Mode now.", 0; 在保护模式中显示
OffsetPMessage		equ 	PMessage - $$
StrTest:		db 	"ABCDEFGHIJKLMNOPQRSTUVWXYZ", 0
OffsetStrTest		equ 	StrTest - $$
DataLen 		equ 	$ - LABEL_DATA
; END of [SECTION .data1]

; 全局堆栈段
[SECTION .gs]
ALIGN 32
[BITS 32]
LABEL_STACK:
	times 512 db 0
TopOfStack	equ 	$ - LABEL_STACK - 1
; END of [SECTION .gs]

LABEL_SEG_CODE32:
	mov 	ax, SelectorData
	mov 	ds, ax			; 数据段选择子
	mov 	ax, SelectorTest
	mov 	es, ax			; 测试段选择子
	mov 	ax, SelectorVideo
	mov 	gs, ax			; 视频段选择子

	mov 	ax, SelectorStack
	mov 	es, ax 			; 堆栈段选择子
	mov 	esp, TopOfStack	

	; 下面显示一个字符串
	mov 	ah, 0ch 		; 黑底红色
	xor  	esi, esi
	xor 	edi, edi
	mov 	esi, OffsetPMessage	; 源数据偏移
	mov 	edi, (80 * 10 + 0) * 2	; 目的数据偏移，屏幕第10行，第0列
	cld
.1:
	lodsb
	test 	al, al
	jz	.2
	mov 	[gs:edi], eax
	add 	edi, 00000002H
	jmp 	.1
.2:	; 屏显完毕
	call 	DispReturn
	call 	TestRead
	call 	TestWrite
	call 	TestRead

	; 到此停止
	jmp 	SelectorCode16:0

; -------------------------------------------
TestRead:
	xor 	esi, esi
	mov 	ecx, 8
.loop:
	mov 	al, [es:esi]
	call 	DispAL
	inc 	esi
	loop 	.loop
	call 	DispReturn
	ret
; TestRead 结束------------------------------

; -------------------------------------------
TestWrite:
	push	esi
	push 	edi
	xor 	esi, esi
	xor  	edi, edi
	mov 	esi, OffsetStrTest; 源数据偏移
	cld
.1:
	lodsb
	test 	al, al
	jz 	.2
	mov 	[es:edi], al
	inc 	edi
	jmp 	.1
.2:
	pop 	edi
	pop 	esi
	ret
; TestWrite 结束 ---------------------------------

; ------------------------------------------------
; 显示 AL 中的数字
; 默认地：
;	数字已经在 AL　中
;	edi 始终指向要显示的下一个字符的位置	
; 被改变的寄存器：
;	ax, edi
; ------------------------------------------------
DispAL:
	push 	ecx
	push 	edx
	
	mov 	ah, 0CH; 黑底红色
	mov 	dl, al
	shr 	al, 4
	mov 	ecx, 2
.begin:
	and 	al, 0FH
	cmp 	al, 9
	ja 	.1
	add 	al, '0'
	jmp 	.2
.1:
	sub 	al, 0AH
	add 	al, 'A'
.2:
	mov 	[gs:edi], ax
	add 	edi, 2

	mov 	al, dl
	loop 	.begin
	add 	edi, 2
	
	pop 	edx
	pop 	ecx
	ret
; DispAL 结束 ------------------------------

; ------------------------------------------
DispReturn:
	push 	eax
	push 	ebx
	mov 	eax, edi
	mov 	bl, 160
	div 	bl
	and 	eax, 0FFH
	inc 	eax
	mov 	bl, 160
	mul 	bl
	mov 	edi, eax
	pop 	ebx
	pop 	eax
	ret
; DispReturn 结束 --------------------------

SegCode32Len	equ	$ - LABEL_SEG_CODE32
[SECTION .S16]
[BITS 16]
LABEL_BEGIN:
	mov	ax, cs
	mov 	ds, ax
	mov 	es, ax
	mov	ss, ax
	mov 	sp, 0100H

	; 初始化 32 位代码段描述符
	xor	eax, eax
	mov	ax, cs
	shl	eax, 4
	add	eax, LABEL_SEG_CODE32
	mov	[LABEL_DESC_CODE32 + 2], ax
	shr	eax, 16
	mov	[LABEL_DESC_CODE32 + 4], al
	mov 	[LABEL_DESC_CODE32 + 7], ah

	; 为加载 GDTR 作准备
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_GDT; eax <- gdt 基地址
	mov	[GdtPtr + 2], eax; [GdtPtr + 2] <- gdt 基地址
	
	; 加载 GDTR
	lgdt	[GdtPtr]
	
	; 关中断
	cli

	; 打开地址线A20
	in	al, 92H
	or	al, 02H
	out	92H, al

	; 准备切换到保护模式
	mov	eax, cr0
	or	eax, 1
	mov	cr0, eax
	
	; 真正进入保护模式
	jmp	dword SelectorCode32:00000000H	;执行这句会把SelectorCode32 装入cs,并跳到 Code32Selector:0 处
; END of [SECTION. s16]

; [SECTION .s32]; 32 位代码段， 由实模式跳入
; [BITS 32]
; LABEL_SEG_CODE32:
; 	mov	ax, SelectorVideo
; 	mov	gs, ax			; 视频段选择子（目的）
; 	mov 	edi, (80 * 11 + 79) * 2 ; 屏幕第 11 行，第 79 列
; 	mov	ah, 0CH			; 黑底红字
; 	mov	al, 'p'
; 	mov 	[gs:edi], ax
; 
; 	; 到此停止
; 	jmp	$
; 
; SegCode32Len	equ	$ - LABEL_SEG_CODE32
; ; END of [SECTION .s32]	
