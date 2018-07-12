; this program will demonstrate UART ECHO
#addr 0x400
; ########################################################
; REAL START OF THE PROGRAM
; ########################################################

	mov sp, 1000

	mov r0, 14
	st [cursor], r0
	
	mov r2, 80
	mov r0, 65							; A
	st [r2 + VIDEO_0], r0
	
	; set the IRQ handler for UART to our own IRQ handler
	mov r0, 1
	mov r1, 16
	st [r1], r0
	mov r0, irq_triggered
	mov r1, 18
	st [r1], r0

	mov r2, 81
	mov r0, 66							; B
	st [r2 + VIDEO_0], r0
	
;	ld r0, [9]
;	push r0
;	call print_num
;	sub sp, 1        ; return the stack pointer to the state before calling the print_num	
	
	mov r2, 82
	mov r0, 67							; C
	st [r2 + VIDEO_0], r0
	
	halt

; ########################################################
; Subroutine for wiping first two rows of the video memory
; ########################################################
wipe:
	mov r0, 0
	mov r2, 160
loop1:
	st [r2 + VIDEO_0], r0
	dec r2
	jp loop1
	ret

; ##################################################################
; Subroutine which is called whenever some byte arrives at the UART
; ##################################################################
irq_triggered:	
	push r0
	push r1
	push r2   
	push r5
	push r6

	mov r2, 82
	mov r0, 68							; D
	st [r2 + VIDEO_0], r0

	in r1, [64] 		   	 	   ; r1 holds now received byte from the UART (address 64 decimal)
	ld r6, [cursor]
	st [r6 + VIDEO_0], r1    ; store the UART character at the VIDEO_0 + r2 
	add r6, 2                ; move to the next location in the video memory
	st [cursor], r6

loop2:
	in r5, [65]   ; tx busy in r5
	cmp r5, 0     
	jz not_busy   ; if not busy, send back the received character 
	j loop2
	
not_busy:
	out [66], r1  ; send the received character to the UART
	
skip:
	pop r6
	pop r5
	pop r2
	pop r1                 
	pop r0
	iret									 
#include "stdio.asm"
cursor:
	#d16 14
hello:
	#str16 "HELLO WORLD\0"
