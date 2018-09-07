#include "keyboard.asm"

; ###########################################################
; print_num function which prints a number on a screen
; to call it, you must:
; 	push <cursor_offset>
; 	push <number_to_be_printed_or_register_to_be_printed>
;		call print_num   	; call print_num 
;		sub sp, 4        	; return the stack pointer to the state before calling the print_num
; ###########################################################
print_num:
	; arguments:
	; [r7 - 8] - cursor offset (row*80 + col)
	; [r7 - 6] - number to be printed
	; local variables:
	; [r7 + 2] <-> [r7 + 12] - one local variable, holding an array of characters (5 words == 10 bytes) to be printed

	; prepare the stack frame
	push r7          		; save the current frame pointer
	mov r7, sp       		; load the stack frame pointer from the sp
	add sp, 12       		; move sp to go out of the current stack frame, so we could call another function from this one
                   		; this is how much we should add: add sp, <size_of_local_variables_space> + 2
                   		; here we have six words for the array of characters, so it is 10 + 2

	mov r0, 0          	; fill the array of characters with zeroes
	mov r1, 5
	mov r6, r7
again1:
	st [r6 + 1], r0
	inc r6
	dec r1
	jnz again1
	
	ld r0, [r7 - 6]  		; load r0 with the number to be printed (the first and the only argument of this function)
	cmp r0, 0
	js print_num_negative
print_num_1:
	mov r1, 0						; counter of digits
	mov r6, r7
again2:	
	inc r1            	; increment the digit counter
	add r6, 2						; move to the next position in memory
	div r0, 10       		; divide by 10; the result is in r0, while the remainder (digit) is in the h register
	st [r6], h   				; write the digit into the character array
	jnz again2        	; if the result is 0, we finish
	
  ; at this moment, the r7 + 1 points to the last digit in the character array (digits are stored in the reverse order)
  ; at this moment, the r1 holds the number of digits
  mov r2, VIDEO_0     ; write digits into the VIDEO memory
  add r2, [r7 - 8]		; add cursor offset to the beginning of the video memory
  dec r1
again3:  
  ld r0, [r6]      		; load the current digit
  add r0, 48          ; make it an ascii character
  st [r2], r0       
  add r2, 2						; move to the next character in video memory
  sub r6, 2						; move to the next digit in memory
  dec r1
  jp again3
  
	; clean up before returning
	mov sp, r7	       	; restore the old stack pointer
	pop r7						 	; restore the old frame pointer
	ret
print_num_negative:
	neg r0
	add r0, 1
	j print_num_1

; #######################################################################################
; print_str function which prints a number on a screen
; to call it, you must:
; 	push <cursor_offset>
; 	push <address_of_the_string>
;		call print_str  	; call print_str
;		sub sp, 4        	; return the stack pointer to the state before calling the print_num
; #######################################################################################
print_str:

	; prepare the stack frame
	push r7          			; save the current frame pointer
	mov r7, sp       			; load the stack frame pointer from the sp
	add sp, 2        			; move sp to go out of the current stack frame, so we could call another function from this one
                   			; this is how much we should add: add sp, <size_of_local_variables_space> + 1

	ld r0, [r7 - 6]				; [r7 - 6] holds the pointer to the string to be printed
  mov r1, VIDEO_0      	; write digits into the VIDEO memory
  add r1, [r7 - 8]		 	; [r7 - 8] holds the offset from the beginning of the video memory (position on the screen)
print_str_again:  
	ld r2, [r0]  					; fetch the current character
  cmp r2, 0							; terminating zero
  jz print_str_end
  st [r1], r2						; store current character in the current video address
  add r0,2
  add r1,2
	j print_str_again	             

print_str_end:
	; clean up before returning
	mov sp, r7	       		; restore the old stack pointer
	pop r7						 		; restore the old frame pointer
	ret

