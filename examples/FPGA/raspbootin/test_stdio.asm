; this program will print HELLO WORLD
#addr 0x400
	mov sp, 40000
	push 20						; cursor offset: first row, 11'th character
	push hello_str
	call print_str
	sub sp, 4       	; return the stack pointer to the state before calling the print_str

	mov r0, 16
	mov r1, 16
	mul r0, r1
	push 160					; cursor offset: second row, the first character
	push r0						; number to print
	call print_num
	sub sp, 4      	  ; return the stack pointer to the state before calling the print_str
	
	halt

#include "stdio.asm"
hello_str:
	#str16 "Hello World!\0"
