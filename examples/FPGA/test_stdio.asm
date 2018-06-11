; this program will print HELLO WORLD
#addr 0x400
	mov r7, 1000
	; prepare the stack frame

	mov r5, 0

	mov r0, 0         ; fill the array of characters with zeroes
	mov r1, 5
	mov r2, r7
	add r2, 1					; r2 points to the array of characters
again1:	
	st [r2], r0
	inc r2
	dec r1
	jnz again1

	mov r6, 65				; 'A'
	st [r5 + 2480], r6

	mov r0, 123  ; load r0 with the number to be printed (the first and the only argument of this function)
	
	mov r1, 0					; digits counter
	mov r2, r7
	inc r2						; r2 points to the array of characters
again2:	

	div r0, 10       ; divide by 10; the result is in r0, while the remainder (digit) is in the h register
	jz end           ; if the result is 0, we finish
	st [r2], h   		 ; write the digit into the character array
	inc r1           ; increment the digits counter
	inc r2					 ; move to the next character
	
	inc r5
	mov r6, h			 
	add r6, 48
	st [r5 + 2480], r6
	
	j again2         ; if the result is 0, we finish

end:	

	inc r5
	mov r6, h			 
	add r6, 48
	st [r5 + 2480], r6

	st [r2], h            ; write the first digit into the character array (the last written, since the array is reversed)
  ; at this moment, the r2 points to the last digit in the character array (digits are stored in the reverse order)
  ; at this moment, the r1 holds the number of digits
  mov r3, 2400      ; write digits into the VIDEO memory
again3:  
  ld r0, [r2] 	    ; load the current digit
  add r0, 48        ; make it an ascii character
  st [r3], r0       
  inc r3
  dec r2
  dec r1
  jp again3

	inc r5
	mov r6, 68				; 'D'
	st [r5 + 2480], r6

  
halt