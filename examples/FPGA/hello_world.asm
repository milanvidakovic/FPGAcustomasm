; this program will print HELLO WORLD
#addr 0x400
VIDEO_0 = 2400 ; beginning of the text frame buffer

	mov r2, 0      ; r1 is the index
	mov r1, hello  ; r1 holds the address of the "HELLO WORLD" string
	;mov r1, r1
again:	
	ld r0, [r1]            ; load r0 with the content of the memory location to which r1 points (current character)
	cmp r0, 0              ; if the current character is 0 (string terminator),
	jz end                 ; go out of this loop 
	st [r2 + VIDEO_0], r0  ; store the character at the VIDEO_0 + r2 
	inc r1                 ; move to the next character
	inc r2                 ; move to the next location in the video memory
	j again                ; continue with the loop
end:	
	halt
hello:
	#str16 "HELLO WORLD!ASDF ASDF ASDF\0"
