; this program will demonstrate UART ECHO
#addr 0x400
; ########################################################
; REAL START OF THE PROGRAM
; ########################################################

	mov sp, 26000

	; set the IRQ handler for keyboard to our own IRQ handler
	mov r0, 1						; JUMP instruction opcode
	mov r1, IRQ2_ADDR		; IRQ#2 vector address (raw keyboard interrupt)
	st [r1], r0
	mov r0, irq_triggered
	mov r1, IRQ2_ADDR + 2	  
	st [r1], r0	; the keyboard IRQ handler has been set
	
	call wipe

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

	in r1, [PORT_KEYBOARD] 	; r1 holds the keyboard scancode
	
loop2:
	in r5, [PORT_UART_TX_BUSY]   ; tx busy in r5
	cmp r5, 0     
	jz not_busy   ; if not busy, send back the received character 
	j loop2
	
not_busy:
	out [PORT_UART_TX_SEND_BYTE], r1  ; send the received character to the UART
	
skip:
	pop r6
	pop r5
	pop r2
	pop r1                 
	pop r0
	iret									 

#include "stdio.asm"
	
