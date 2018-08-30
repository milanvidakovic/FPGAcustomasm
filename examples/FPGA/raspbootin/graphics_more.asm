; this program will draw lines and circles
; video memory starts at 2400
; each line is 160 bytes long
; each byte contains two pixels, four bits each: xrgbxrgb
#addr 0x400
; ########################################################
; REAL START OF THE PROGRAM
; ########################################################

	mov sp, 26000

	mov r0, 1
	out [PORT_VIDEO_MODE], r0  ; set the video mode to graphics

	mov r0, 320*1/4  ; wipe first line of the screen
	call wipe

 	mov r0, 0		; x = 0
 	mov r1, 100	; y = 100
 	mov r2, 7		; white color (0111)
 	call pixel
 	inc r0			; x = 1
 	mov r2, 4		; red color (0100)
 	call pixel	

  mov r2, 4			; red color (0100)
  mov r0, 50		; A.x = 50
  mov r1, 50		; A.y = 50
  mov r3, 150		; B.x = 150
  mov r4, 150		; B.y = 150
  call line
 
  mov r2, 2			; green color (0010)
  mov r0, 50		; A.x = 50
  mov r1, 50		; A.y = 50
  mov r3, 150		; B.x = 150
  mov r4, 50		; B.y = 50
	call line
	
 	mov r2, 1			; blue color (0001)
 	mov r0, 150		; A.x = 150
 	mov r1, 50		; A.y = 50
 	mov r3, 150		; B.x = 150
 	mov r4, 150		; B.y = 150
 	call line

 	mov r2, 7			; white color (0111)
 	mov r0, 150		; x = 150
 	mov r1, 150		; y = 150
 	mov r3, 50		; r = 50
 	call circle

		
end:	
	halt

; ####################################################################################################
; function wipe(words)
; r0 - words (bytes * 2) to be erased in the framebuffer
; ####################################################################################################
wipe:
	push r0
	push r1
	push r2
	mov r1, VIDEO_0
	mov r2, 0
wipe_0:
	st [r1], r2
	inc r1
	dec r0
	cmp r0, 0
	jnz wipe_0
	pop r2
	pop r1
	pop r0
	ret


; ####################################################################################################
; function pixel(x, y, c)
; r0 - x
; r1 - y
; r2 - color of the pixel (0 - 7)
; ####################################################################################################
pixel:
	push r0
	push r1
	push r2
	push r3
	push r4
	
	mul r1, 160	; gives the offset from the beginning of the framebuffer
	div r0, 2		; divide x coordinate by 4; it gives the offset from the beginning of the line
							; h holds the position of the pixel within the word (0 - 3)
							; r0 is the offset in bytes
	add r1, VIDEO_0
	add r0, r1	; r0 holds the address of the pixel (the whole group of four pixels)
	
	mov r3, 0x1		; set the mask for wiping 
	sub r3, h			; (h == 0) -> (r3 == 1); (h == 1) -> (r3 == 0)
	shl r3, 2			; r3 = r3 * 4
	mov r1, 0xf		; set the mask for one pixel (four bits)
	shl r1, r3		; we shift the mask r3 times to the left
	neg r1				; invert the mask
	ld.b r4, [r0]	; r4 holds the surrounding pixels
	and r4, r1		; we erase the pixel to be changed
	
	shl r2, r3	; we shift the color of the pixel r3 times to the left
	or r4, r2		; we insert the pixel into surrounding pixels
	
	st.b [r0], r4	; save all four pixels into the framebuffer

	pop r4
	pop r3
	pop r2
	pop r1
	pop r0	
	ret
	
; ####################################################################################################
; function line(x0, y0, x1, y1, c)
; r0 - x0	(A.x)
; r1 - y0	(A.y)
; r2 - color of the pixel (0 - 7)
; r3 - x1	(B.x)
; r4 - y1	(B.y)
; ####################################################################################################
line:
	push r0
	push r1
	push r2
	push r3
	push r4
	push r5
	push r6
	push r7
	
	mov r5, r4		; r5 = B.y
	sub r5, r1  	; r5 = B.y - A.y
	call line_abs	; r5 = abs(r5)
	mov r6, r5		; r6 = abs(B.y - A.y)

	mov r5, r3		; r5 = B.x
	sub r5, r0 		; r5 = B.x - A.x
	call line_abs	; r5 = abs(B.x - A.x)
	
	cmp r6, r5 		; if(abs(B.y - A.y) < abs(B.x - A.x)) 	
	js draw_one
	j draw_two
line_end:
	pop r7
	pop r6
	pop r5
	pop r4
	pop r3
	pop r2
	pop r1
	pop r0
	ret

; ######################################################################
draw_one:
	cmp r0, r3 		; if(A.x > B.x) 
	jg swap_and_draw_south
	
	j draw_south

swap_and_draw_south:
	swap r0, r3
	swap r1, r4

; draw_south
draw_south:	
	mov r6, r3		; r6 = B.x
	sub r6, r0		; r6 -> dx = B.x - A.x
	
	mov r5, r4		; r5 = B.y
	sub r5, r1  	; r5 -> dy = B.y - A.y
	
	mov r7, 1			; r7 -> yi
	cmp r5, 0			; if (dy < 0)
	js ds1

ds2:
	mov r4, r5 		; r4 = dy
	shl r4, 1
	sub r4, r6 		; r4 -> D = 2 * dy - dx

	shl r5, 1			; r5 -> 2*dy
	shl r6, 1			; r6 -> 2*dx

ds4:	
  cmp r0, r3		; if A.x > B.x then return
	jg line_end
	
	call pixel		; plot(x,y)	
	cmp r4, 0			; if (D > 0)
	jg ds3
ds5:	
  add r4, r5		; D = D + 2*dy
  
  inc r0				; A.x = A.x + 1
  j ds4
	
ds3:
 	add r1, r7		; y = y + yi
  sub r4, r6		; D = D - 2*dx
  j ds5
ds1:
	mov r7, -1		; yi = -1
  neg r5
  add r5, 1			; dy = -dy
  j ds2
; ######################################################################

; ######################################################################
draw_two:
	cmp r1, r4 		; if(A.y > B.y) 
	jg swap_and_draw_north
	
	j draw_north

swap_and_draw_north:
	swap r0, r3
	swap r1, r4

; draw_north
draw_north:	
	mov r6, r3		; r6 = B.x
	sub r6, r0		; r6 -> dx = B.x - A.x
	
	mov r5, r4		; r5 = B.y
	sub r5, r1  	; r5 -> dy = B.y - A.y
	
	mov r7, 1			; r7 -> xi
	cmp r6, 0			; if (dx < 0)
	js dn1

dn2:
	mov r3, r6 		; r3 = dx
	shl r3, 1
	sub r3, r5 		; r3 -> D = 2 * dx - dy

	shl r5, 1			; r5 -> 2*dy
	shl r6, 1			; r6 -> 2*dx

dn4:	
	cmp r1, r4
	jg line_end
	
	call pixel		; plot(x,y)	
	cmp r3, 0			; if (D > 0)
	jg dn3
dn5:	
  add r3, r6		; D = D + 2*dx
  
  inc r1				; A.y = A.y + 1
  j dn4
	
dn3:
 	add r0, r7		; x = x + xi
  sub r3, r5		; D = D - 2*dy
  j dn5
dn1:
	mov r7, -1		; xi = -1
  neg r6
  add r6, 1			; dx = -dx
  j dn2
; ######################################################################

line_abs:
	cmp r5, 0
	jg la1
	neg r5
	add r5, 1
la1:
	ret

; ####################################################################################################
; function circle(x0, y0, c, r)
; r0 - x0	
; r1 - y0	
; r2 - color of the pixel (0 - 7)
; r3 - radius
; ####################################################################################################
circle:
	push r0
	push r1
	push r2
	push r3
	push r4
	push r5
	push r6
	push r7
	
	mov r7, 0
	st[err], r7
	
	mov r4, r3		; r4 -> radius
	sub r4, 1			; r4 -> x = radius - 1;
	
	mov r5, 0			; r5 -> y = 0
	
	mov r6, 1			; r6 -> dx = 1
	mov r7, 1			; r7 -> dy = 1
	
	call add_err_dxminus	; err += dx - (radius << 1);

circle_loop:	
	cmp r4, r5		; while (x >= y)
	jge circle_body	

circle_end:
	pop r7
	pop r6
	pop r5
	pop r4
	pop r3
	pop r2
	pop r1
	pop r0
	ret
; ########################################################################################################

circle_body:

	push r0				; r4 -> x
	push r1				; r5 -> y
	add r0, r4
	add r1, r5
	call pixel		;pixel (x0 + x, y0 + y)
	pop r1
	pop r0
	
	push r0
	push r1
	add r0, r5
	add r1, r4
	call pixel		;pixel (x0 + y, y0 + x)
	pop r1
	pop r0

	push r0
	push r1
	sub r0, r5
	add r1, r4
	call pixel		;pixel (x0 - y, y0 + x)
	pop r1
	pop r0

	push r0
	push r1
	sub r0, r4
	add r1, r5
	call pixel		;pixel (x0 - x, y0 + y)
	pop r1
	pop r0

	push r0
	push r1
	sub r0, r4
	sub r1, r5
	call pixel		;pixel (x0 - x, y0 - y)
	pop r1
	pop r0

	push r0
	push r1
	sub r0, r5
	sub r1, r4
	call pixel		;pixel (x0 - y, y0 - x)
	pop r1
	pop r0

	push r0
	push r1
	add r0, r5
	sub r1, r4
	call pixel		;pixel (x0 + y, y0 - x)
	pop r1
	pop r0

	push r0
	push r1
	add r0, r4
	sub r1, r5
	call pixel		;pixel (x0 + x, y0 - y)
	pop r1
	pop r0

	push r7
	ld r7, [err]
	cmp r7, 0				; if (err <= 0) {
	pop r7
	jse c1
c3:
	push r7
	ld r7, [err]
	cmp r7, 0				; if (err > 0) {
	pop r7
	jg c2
	j circle_loop

c1:
	inc r5					; y++;
	push r7					; r7 -> dy
	add r7, [err]		; err += dy;
	st [err], r7
	pop r7
	add r7, 2				; dy += 2;
	j c3
c2:
	dec r4					; x--;
	add r6, 2				; dx += 2;
	call add_err_dxminus	;	err += dx - (radius << 1);
	j circle_loop
	
add_err_dxminus:
	; err += dx - (radius << 1);
	push r7				; r7 -> dy
	mov r7, r3		; r7 = radius
	shl r7, 1			; r7 = (radius << 1)
	push r6				; r6 -> dx
	sub r6, r7		; r6 = dx - (radius << 1)
	add r6, [err]	; err += dx - (radius << 1);
	st [err], r6
	pop r6
	pop r7
	ret
err:
	#d16 0
			
#include "stdio.asm"
