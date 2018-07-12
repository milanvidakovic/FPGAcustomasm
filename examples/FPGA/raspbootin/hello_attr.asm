#addr 0x400
; this program will print HELLO WORLD
VIDEO_0 = 2400 ; beginning of the text frame buffer

	mov r1, hello  ; r1 holds the address of the "HELLO WORLD" string
	mov r2, 0      ; r2 is the index
	mov r3, 0      ; r3 has the attribute
again:	
	ld.b r0, [r1]          ; load r0 with the content of the memory location to which r1 points (current character)
	cmp r0, 0              ; if the current character is 0 (string terminator),
	jz end                 ; go out of this loop 
	st.b [r2 + VIDEO_0], r3; store the attribute
	inc r2								 ; move to the character location
	st.b [r2 + VIDEO_0], r0; store the character at the VIDEO_0 + r2 
	inc r1								 ; move to the next character in the string
	inc r2                 ; move to the next location (attribute) in video memory
	inc r3                 ; change the attribute of the current character
	j again                ; continue with the loop
end:	
	halt
hello:
	#str "Hello World!\0"
