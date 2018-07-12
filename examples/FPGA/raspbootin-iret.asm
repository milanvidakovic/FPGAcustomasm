; this is the boot loader compatible with the raspbootin loader
VIDEO_0 = 2400 ; beginning of the text frame buffer

; ########################################################
; RESET CODE (4 bytes max)
; ########################################################
#addr 0x0000
	j start

; ########################################################
; IRQ 1 CODE (4 bytes max) - KEY1
; ########################################################
#addr 0x0008
	iret

; ########################################################
; IRQ 2 CODE (4 bytes max) - UART
; ########################################################
#addr 0x0010
	j irq_triggered

; ########################################################
; THE REAL START OF THE PROGRAM
; ########################################################
#addr 0x100
start:	
	mov sp, 0x300  ; set stack

	mov r0, 0
	st [state], r0
	st [size], r0
	st [loaded], r0
	st [current_size], r0
	st [sum_all], r0
	mov r0, 0x400							; address to load code
	st [current_addr], r0
		
	call wipe			 ; wipe video memory for messages
	call hello_world
	
	; send raspbootin boot char sequence
	mov r0, 77								; "M" character
	call uart_send
	mov r0, 13								; \n character
	call uart_send
	mov r0, 10								; \r character
	call uart_send
	mov r0, 3
	call uart_send
	mov r0, 3
	call uart_send
	mov r0, 3
	call uart_send

not_loaded:
	ld r0, [loaded]
	cmp r0, 1
	jz 0x400
	nop
	j not_loaded

; ########################################################
; Subroutine for sending a character to the UART
; r0 - holds the character to be sent
; ########################################################
uart_send:
	push r1
uagain:	
	in r1, [65]   ; tx busy in r1
	cmp r1, 0     
	jz not_busy   ; if not busy, send the given character
	nop						; waste a little bit of time
	j uagain		  ; otherwise, go again
not_busy:
	out [66], r0  ; send the received character to the UART
	pop r1
	ret	

; ########################################################
; Subroutine for printing hello world to the screen
; ########################################################
hello_world:	
	mov r1, hello  ; r1 holds the address of the "HELLO WORLD" string
	mov r2, 0      ; r2 is the index
again:	
	ld r0, [r1]            ; load r0 with the content of the memory location to which r1 points (current character)
	cmp r0, 0              ; if the current character is 0 (string terminator),
	jz end                 ; go out of this loop 
	st [r2 + VIDEO_0], r0  ; store the character at the VIDEO_0 + r2 
	inc r1                 ; move to the next character
	inc r2                 ; move to the next location in the video memory
	j again                ; continue with the loop
end:	
	ret
hello:
	#str16 "WAITING...\0"

; ########################################################
; Subroutine for wiping first three rows of the video memory
; ########################################################
wipe:
	mov r0, 0
	mov r2, 240
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

	ld r0, [state]				; current state in r0
	cmp r0, 0
	jz first_byte
	cmp r0, 1
	jz second_byte
	cmp r0, 2
	jz third_byte
	cmp r0, 3
	jz fourth_byte

	; ###########################################################
	; if the state is 4, then the code started to arrive via UART	
	; ###########################################################
	
	in r1, [64]						; get the byte from the uart into r1

	mov r2, r1
	ld r0, [sum_all]
	add r0, r2
	st [sum_all], r0			; primitive checksum - sum of all bytes
	
	; at this moment, r1 holds the received byte
	ld r2, [current_addr]	; r2 holds the current pointer in memory to store the received byte
	st.b [r2], r1						; store the received byte into the memory
	
	inc r2								; move to the next location in memory
	st [current_addr], r2 ; save the incremented value of the current address
	
	ld r2, [current_size] ; increment the byte counter
	inc r2	
	st [current_size], r2
	
	cmp r2, [size]				; did we receive all?
	jz all_arrived
	j skip

all_arrived:
	; send the sum of all bytes
	ld r0, [sum_all]
	and r0, 255
	call uart_send
	ld r0, [sum_all]
	shr r0, 8
	call uart_send

	mov r0, 1							; signal to the main program that the loader has received all bytes
	st [loaded], r0
	
	j skip

first_byte:
	in r1, [64]						; get the char from the uart
	st [size], r1					; store the lowest byte to the size variable
	inc [state]						; next state -> 1 (second byte)	
	
	j skip								; return from interrupt
second_byte:
	in r1, [64]						; get the char from the uart (8 upper bits)
	ld r2, [size]					; get the lower 8 bits (received earlier)
	shl r1, 8							; shift the received byte 8 bits to the left to become upper byte
	or r1, r2							; put together lower and upper 8 bits
	st [size], r1					; store the calcluated size of the code into the size variable
	inc [state]						; next state -> 2 (third byte)	
	
	j skip								; return from interrupt
third_byte:
	; this is 16-bit cpu, so we don't load code bigger than 65535 bytes
	inc [state]						; next state -> 3 (fourth byte)	
	
	j skip
fourth_byte:
	; this is 16-bit cpu, so we don't load code bigger than 65535 bytes
	; send confirmation that the code has been loaded
	ld r0, [size]
	and r0, 255
	call uart_send
	ld r0, [size]
	shr r0, 8
	call uart_send	
	
	inc [state]						; next state -> 4 (code arrives)	

skip:
	pop r2
	pop r1
	pop r0
	iret								  ; return from the IRQ

state:
	#d16 0
size:
	#d16 0
current_size:
	#d16 0
current_addr:
	#d16 0x400
current_byte:
	#d16 0
loaded:
	#d16 0
sum_all:
	#d16 0		
	