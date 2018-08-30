; this program will draw two thick lines in graphics mode
; video memory starts at 26880
; each line is 160 bytes long
; each byte contains two pixels, four bits each: xrgbxrgb
#include "consts.asm"
#addr 0x400
; ########################################################
; REAL START OF THE PROGRAM
; ########################################################

	mov sp, 26000

	mov r0, 1
	out [PORT_VIDEO_MODE], r0  ; set the video mode to graphics
	
	; set 1 to LEDs
	out [PORT_LED], r0  ; totally unrelated to this demo - just to set LEDs

	; now we continue with the demo
	; first line (one pixel thick) at the top of the screen
	mov r0, 0x7777 ; four white pixels
	mov r1, VIDEO_0
	mov r2, 0
loop1:
	st [r1], r0
	add r1, 2
	inc r2
	cmp r2, 80
	jz next1
	j loop1
	
next1:	
	; second line (two pixels thick) at the fourth row from the top of the screen
	mov r0, 0x1111 ; four blue pixels
	mov r1, VIDEO_0 + 3*160
	mov r2, 0
loop2:
	st [r1], r0
	add r1, 2
	inc r2
	cmp r2, 160
	jz next2
	j loop2
	
next2:	
	; third line (two pixels thick) at the bottom the screen
	mov r0, 0x4444 ; four red pixels
	mov r1, VIDEO_0 + 238*160
	mov r2, 0
loop3:
	st [r1], r0
	add r1, 2
	inc r2
	cmp r2, 160
	jz end
	j loop3
		
end:	
	halt

