; this is a snakes game 
UP    = 0
DOWN  = 2
LEFT  = 3
RIGHT = 1
STARTY = 15
HEIGHT = 40

#addr 0x400
; ########################################################
; REAL START OF THE PROGRAM
; ########################################################

	mov sp, 26000
	call keyboard_setup
		
	mov r0, 1							; JUMP instruction opcode
	mov r1, KEY_PRESSED_HANDLER_ADDR
	st [r1], r0
	mov r0, pressed				; key pressed routine address
	mov r1, KEY_PRESSED_HANDLER_ADDR + 2
	st [r1], r0

	mov r0, 1							; JUMP instruction opcode
	mov r1, KEY_RELEASED_HANDLER_ADDR
	st [r1], r0
	mov r0, released			; key released routine address
	mov r1, KEY_RELEASED_HANDLER_ADDR + 2
	st [r1], r0

	in r0, [PORT_MILLIS]		; get current number of milliseconds
	st [seed], r0

snakes_again:
	mov r0, 0
	st [VIRTUAL_KEY_ADDR], r0	; reset the virtual key code
	st [n], r0
	st [end], r0
	st [points], r0

	call draw_frame
	call print_status
	call init_snake
	call draw_snake		
	call calculate_star
	
	ld r0, [sx]
	st [x], r0
	ld r0, [sy]
	st [y], r0				; GotoXY(sx, sy); 
	mov r0, 42				; '*'
	call putc					; write('*');

; $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
main_snake_loop:	
	ld r0, [end]
	cmp r0, 1
	jz game_over
	
	ld r0, [is_key_pressed]
	cmp r0, 1
	jz key_is_pressed
	
main1:
	call move_snake
	mov r0, 100
	call delay	
	j main_snake_loop
; $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

game_over:	
	ld r0, [is_key_pressed]
	cmp r0, 1
	jz go_key
	j game_over
go_key:
	mov r0, 0
	st [is_key_pressed], r0
	ld r0, [VIRTUAL_KEY_ADDR]
	cmp r0, VK_ENTER
	jz snakes_again
	j game_over
	halt

key_is_pressed:
	mov r0, 0
	st [is_key_pressed], r0
	
	ld r0, [VIRTUAL_KEY_ADDR]
	cmp r0, VK_UP_ARROW
	jz go_up
	cmp r0, VK_DOWN_ARROW
	jz go_down
	cmp r0, VK_LEFT_ARROW
	jz go_left
	cmp r0, VK_RIGHT_ARROW
	jz go_right
	
go_up:
	ld r0, [direction]
	cmp r0, DOWN
	jz main1
	mov r0, UP
	st [direction], r0		; if (c = up) and (smer <> 2) then smer := 0
	j main1
go_down:
	ld r0, [direction]
	cmp r0, UP
	jz main1
	mov r0, DOWN
	st [direction], r0		; else if (c = down) and (smer <> 0) then smer := 2
	j main1
go_left:
	ld r0, [direction]
	cmp r0, RIGHT
	jz main1
	mov r0, LEFT
	st [direction], r0		; else if (c = left) and (smer <> 1) then smer := 3
	j main1
go_right:
	ld r0, [direction]
	cmp r0, LEFT
	jz main1
	mov r0, RIGHT
	st [direction], r0		; else if (c = right) and (smer <> 3) then smer := 1
	j main1
			
is_key_pressed:
	#d16 0
	
; ##################################################################
; function pressed()
; called when a key is pressed
; ##################################################################
pressed:	
;	ld r0, [VIRTUAL_KEY_ADDR]			; get the VK of the key pressed
	push r0
	
	mov r0, 1
	st [is_key_pressed], r0

	pop r0	
	iret
	
; ##################################################################
; function released()
; called when a key is released
; ##################################################################
released:	
;	ld r0, [VIRTUAL_KEY_ADDR]

	iret

seed:
	#d16 19987
a:
	#d16 11035
c:
	#d16 12345
m:
	#d16 32768	

; ##################################################################
; function r0 = random(r1, r2)
; returns pseudo-random number in range from r1 to r2
; ##################################################################

random:
	push r1
	push r2
	in r0, [PORT_MILLIS]		; get current number of milliseconds
	st [a], r0
	ld r0, [seed]
	mul r0, [a]
	add r0, [c]
	div r0, [m]
  mov r0, h
  st [seed], r0

	sub r2, r1
  div r0, r2
	mov r0, h
	cmp r0, 0
	js neg_random

random1:	
	add r0, r1
	pop r2
	pop r1	
	ret
neg_random:
	neg r0
	j random1

; ##################################################################
; function calculate_star
; calculates a new position of the star
; ##################################################################
calculate_star:
	push r0
	push r1
	push r2

cs4:							; repeat	
	mov r1, 2
	mov r2, 78
	call random
	st [sx], r0			; sx := SlucajanBroj(2, 78);
	ld r1, [n]
	inc r1
	shl r1, 1
	st [r1 + zx], r0	; zx[N + 1] := sx;
	
	mov r1, STARTY + 2
	mov r2, STARTY + HEIGHT-2
	call random
	st [sy], r0			; sy := SlucajanBroj(3, HEIGHT-2);
	ld r1, [n]
	inc r1
	shl r1, 1
	st [r1 + zy], r0	; zy[N + 1] := sy;
	
	mov r1, 0					; i := 0;
cs3:
	mov r2, r1
	shl r2, 1
	ld r0, [r2 + zx]	; while (zx[i] <> sx) or (zy[i] <> sy) do
	cmp r0, [sx]			; (zx[i] <> sx)
	jnz cs1
	ld r0, [r2 + zy]
	cmp r0, [sy]			; (zy[i] <> sy)
	jz cs2
cs1:	
	inc r1					; i := i + 1
	j cs3	

cs2:	
	ld r0, [n]
	inc r0
	cmp r1, r0
	jnz cs4				; until i = N + 1
	
  pop r2
  pop r1
  pop r0
	ret

; ##################################################################
; function draw_frame
; draws a frame around the screen
; ##################################################################
draw_frame:
	push r0
	push r1
	push r2
	
	call clrscr

	mov r0, 30
	st [x], r0
	mov r0, STARTY
	st [y], r0		; GotoXY(30, 0)
	mov r0, points_str
	call write		; write("POINTS: ");
	
	mov r0, 0
	st [x], r0
	mov r0, STARTY + 1
	st [y], r0		; GotoXY(0, 1)
	mov r0, 43		; '+'
	call putc			; write('+');
	mov r0, 45		; '-'
	mov r1, 0
df1:	
	call putc			;for i := 0 to 78 do write('-');
	inc r1
	cmp r1, 78
	js df1
	mov r0, 43		; '+'
	call putc			; write('+');
	
	mov r1, STARTY + 2
df3:						; for i := 2 to HEIGHT-2 do begin
	mov r0, 0
	st [x], r0
	st [y], r1		; GotoXY(0, i);
	mov r0, 124		; '|'
	call putc			; write('|');
	mov r0, 79
	st [x], r0
	st [y], r1		; GotoXY(79, i);
	mov r0, 124		; '|'
	call putc			; write('|')
	inc r1
	cmp r1, STARTY + HEIGHT-2
	jse df3				; end
	
	mov r0, 0
	st [x], r0
	mov r0, STARTY + HEIGHT-1
	st [y], r0		; GotoXY(0, HEIGHT-1);
	mov r0, 43		; '+'
	call putc			; write('+');

	mov r0, 45		; '-'
	mov r1, 0
df4:	
	call putc			;for i := 0 to 78 do write('-');
	inc r1
	cmp r1, 78
	js df4

	mov r0, 43		; '+'
	call putc			; write('+');
	
	pop r2
	pop r1
	pop r0
	ret

; ##################################################################
; function putc(r0)
; prints a single character
; reads x and y variables and updates them
; ##################################################################
putc:
	push r1
	push r2
	
	ld r1, [x]
	shl r1, 1
	ld r2, [y]
	mul r2, 160
	add r1, r2
	add r1, VIDEO_0
	st [r1], r0
	ld r1, [x]
	ld r2, [y]
	inc r1
	cmp r1, 80
	jz putc1

putc2:	
	st [x], r1
	st [y], r2
	
	pop r2
	pop r1
	ret
	
putc1:
	mov r1, 0
	inc r2
	cmp r2, HEIGHT
	jz putc3
	j putc2
putc3:
	mov r2, 0
	j putc2		

; ##################################################################
; function write(r0)
; prints the string
; ##################################################################
write:
	push r1
	mov r1, r0
wr2:	
	ld.b r0, [r1]
	cmp r0, 0
	jz wr1
	call putc
	inc r1
	j wr2
	
wr1:	
	pop r1
	ret
		
; ##################################################################
; function clrscr
; clears the screen
; ##################################################################
clrscr:
	push r0
	push r1
	mov r0, 0
	mov r1, 0
clrscr1:	
	st [r1 + VIDEO_0], r0
	inc r1
	cmp r1, (60)*160
	jnz clrscr1
	
	pop r1
	pop r0	
	ret


; ##################################################################
; function print_status()
; prints the status
; ##################################################################
print_status:
	push r0
	push r1

	mov r1, 37
	st [x], r1
	mov r1, STARTY
	st [y], r1			; GotoXY(7, 0);
	ld r0, [points]
	mov r1, buffer
	call int2str
	mov r0, buffer
	call write	
	
	pop r1
	pop r0
	ret

; ##################################################################
; function int2str(r0, r1)
; converts integer to string
; r0 holds the number to be converted
; r1 holds the address of the buffer to receive string
; ##################################################################
int2str:
	push r2
	push r3
	
	mov r3, 0						; counter of digits
	mov r2, buffer_d
i2s1:	
	div r0, 10       		; divide by 10; the result is in r0, while the remainder (digit) is in the h register
	
	st [r2], h   				; write the digit into the character array
	inc r3            	; increment the digit counter
	add r2, 2						; move to the next position in buffer
	cmp r0, 0
	jnz i2s1	        	; if the result is 0, we finish

  sub r2, 2
i2s2:  
  ld r0, [r2]      		; load the current digit
  add r0, 48          ; make it an ascii character
  st.b [r1], r0       
  
  sub r2, 2
  inc r1
  dec r3
  jp i2s2
	
	mov r0, 0
	st.b [r1 - 1], r0
		
	pop r3
	pop r2
	ret

; ##################################################################
; function init_snake()
; initializes the snake
; ##################################################################
init_snake:
	push r0
	push r1
	push r2
	
	mov r0, 2
	st [n], r0				; N := 2;
	
	mov r1, 10
	mov r2, 72
	call random
	st [zx], r0				; zx[0] := SlucajanBroj(10, 72);

	mov r1, STARTY + 10
	mov r2, STARTY + 17
	call random
	st [zy], r0				; zy[0] := SlucajanBroj(10, 17);

	mov r1, 0
	mov r2, 3
	call random				
	st [direction], r0	; smer  := SlucajanBroj(0, 3);
	
	cmp r0, UP
	jz init_snakeUP
	cmp r0, RIGHT
	jz init_snakeRIGHT
	cmp r0, DOWN
	jz init_snakeDOWN
	cmp r0, LEFT
	jz init_snakeLEFT

init_snake_end:
	pop r2
	pop r1
	pop r0
	ret
init_snakeUP:
	mov r1, zx
	mov r2, zy

	ld r0, [r1]				
	st [r1 + 2], r0		; zx[1] := zx[0];
	ld r0, [r2]
	inc r0
	st [r2 + 2], r0		; zy[1] := zy[0] + 1;

	ld r0, [r1]				
	st [r1 + 4], r0		; zx[2] := zx[0];
	ld r0, [r2]
	add r0, 2
	st [r2 + 4], r0		; zy[2] := zy[0] + 2	

	j init_snake_end

init_snakeRIGHT:
	mov r1, zx
	mov r2, zy

	ld r0, [r2]				
	st [r2 + 2], r0		; zy[1] := zy[0];
	ld r0, [r1]
	dec r0
	st [r1 + 2], r0		; zx[1] := zx[0] - 1;

	ld r0, [r2]				
	st [r2 + 4], r0		; zy[2] := zy[0]; 
	ld r0, [r1]
	sub r0, 2
	st [r1 + 4], r0		; zx[2] := zx[0] - 2

	j init_snake_end

init_snakeDOWN:
	mov r1, zx
	mov r2, zy

	ld r0, [r1]				
	st [r1 + 2], r0		; zx[1] := zx[0];
	ld r0, [r2]
	dec r0
	st [r2 + 2], r0		; zy[1] := zy[0] - 1;

	ld r0, [r1]				
	st [r1 + 4], r0		; zx[2] := zx[0];
	ld r0, [r2]
	sub r0, 2
	st [r2 + 4], r0		; zy[2] := zy[0] - 2

	j init_snake_end

init_snakeLEFT:
	mov r1, zx
	mov r2, zy

	ld r0, [r2]				
	st [r2 + 2], r0		; zy[1] := zy[0];
	ld r0, [r1]
	inc r0
	st [r1 + 2], r0		; zx[1] := zx[0] + 1;

	ld r0, [r2]				
	st [r2 + 4], r0		; zy[2] := zy[0];
	ld r0, [r1]
	add r0, 2
	st [r1 + 4], r0		; zx[2] := zx[0] + 2

	j init_snake_end

; ##################################################################
; function draw_snake()
; draws a snake
; ##################################################################
draw_snake:
	push r0
	push r1
	push r2
	
	ld r0, [zx]
	st [x], r0
	
	ld r0, [zy]
	st [y], r0				; GotoXY(zx[0], zy[0]);
	
	mov r0, 64				; '@'
	call putc					; write('@');
	
	mov r1, 1					;   for i := 1 to N do begin
ds1:	
	mov r2, r1
	shl r2, 1
	ld r0, [r2 + zx]				
	st [x], r0

	ld r0, [r2 + zy]
	st [y], r0				; GotoXY(zx[i], zy[i]);

	mov r0, 79				; 'O'
	call putc					; write('O');
	inc r1
	cmp r1, [n]
	jse ds1
	
	pop r2
	pop r1
	pop r0
	ret

; ##################################################################
; function calculate_position()
; calculate snake head position
; places new x and y coordinates, depending on the direction
; ##################################################################
calculate_position:
	push r0
	
	;   { 0 - up, 1 - right, 2 - down, 3 - left }
	ld r0, [direction]	; case smer of
	cmp r0, UP
	jz cpUP
	cmp r0, RIGHT
	jz cpRIGHT
	cmp r0, DOWN
	jz cpDOWN
	cmp r0, LEFT
	jz cpLEFT
	
cp_end:	
	pop r0
	ret
cpUP:
	ld r0, [zx]
	st [xx], r0				; x := zx[0];
	ld r0, [zy]
	dec r0
	st [yy], r0				; y := zy[0] - 1;
	j cp_end
cpRIGHT:
	ld r0, [zx]
	inc r0
	st [xx], r0				; x := zx[0] + 1;
	ld r0, [zy]
	st [yy], r0				; y := zy[0]
	j cp_end
cpDOWN:
	ld r0, [zx]
	st [xx], r0				; x := zx[0];
	ld r0, [zy]
	inc r0
	st [yy], r0				; y := zy[0] + 1
	j cp_end
cpLEFT:
	ld r0, [zx]
	dec r0
	st [xx], r0				; x := zx[0] - 1;
	ld r0, [zy]
	st [yy], r0				; y := zy[0]
	j cp_end
	
; ##################################################################
; function r0 = hit_wall()
; returns 1 if the snake has hit the wall
; ##################################################################
hit_wall:
	ld r0, [xx]
	cmp r0, 0				; x == 0
	jz hit1
	cmp r0, 79			; x == 79
	jz hit1
	ld r0, [yy]
	cmp r0, STARTY + 1				; y == 1
	jz hit1
	cmp r0, STARTY + HEIGHT-1			; y == HEIGHT-1
	jz hit1
	mov r0, 0
	j hit_end
hit1:
	mov r0, 1
hit_end:	
	ret		

; ##################################################################
; function r0 = hit_tail()
; returns 1 if the snake has hit its own tail
; ##################################################################
hit_tail:
	push r1
	push r2
	push r3
	push r4
	push r5
	
	ld r0, [n]
	inc r0							; N + 1
	shl r0, 1
	ld r1, [xx]
	st [r0 + zx], r1		; zx[N + 1] := x;
	ld r2, [yy]
	st [r0 + zy], r2		; zy[N + 1] := y;
	
	mov r3, zx
	mov r4, zy
	mov r5, 0					
ht1:	
	add r3, 2
	add r4, 2
	inc r5						; i := 1;
	ld r0, [r3]
	cmp r0, r1				; x <> zx[i]
	jnz ht1
	ld r0, [r4]
	cmp r0, r2				; y <> zy[i]
	jnz ht1						; while (x <> zx[i]) or (y <> zy[i]) do i := i + 1;

ht2:
	ld r0, [n]				; r0 <- N
	cmp r5, r0				; r5 <- i
	jse ht_true
	mov r0, 0
ht_end:	
	pop r5
	pop r4
	pop r3
	pop r2
	pop r1
	ret
ht_true:
	mov r0, 1
	j ht_end
	
; ##################################################################
; function move_snake()
; moves snake
; ##################################################################
move_snake:
	push r1
	push r2
	push r3
	
	call calculate_position
	call hit_wall						
	cmp r0, 1
	jz game_end
	call hit_tail
	cmp r0, 1
	jz game_end				; if hit_wall or hit_tail then goto end

	ld r0, [xx]
	cmp r0, [sx]			; x == sx
	jnz move_on
	ld r0, [yy]
	cmp r0, [sy]			; y == sy
	jnz move_on
	; we have reached the star
	ld r0, [zx]
	st [x], r0
	ld r0, [zy]
	st [y], r0			; GotoXY(zx[0], zy[0]);
	mov r0, 79			; 'O'
	call putc				; write('O');	

	ld r0, [xx]
	st [x], r0
	ld r0, [yy]
	st [y], r0			; GotoXY(x, y);
	mov r0, 64			; '@'
	call putc				; write('@');	
	inc [n]					; N := N + 1;
	
	ld r0, [n]
ms1:							; for i := N downto 1 do begin	
	mov r3, r0
	shl r3, 1
	mov r1, zx
	add r1, r3
	ld r2, [r1 - 2]
	st [r1], r2			; zx[i] := zx[i-1];

	mov r3, r0
	shl r3, 1
	mov r1, zy
	add r1, r3
	ld r2, [r1 - 2]
	st [r1], r2			; zy[i] := zy[i-1];
	
	dec r0
	cmp r0, 0
	jnz ms1					; end
	
	ld r0, [xx]
	st [zx], r0			; zx[0] := x;
	ld r0, [yy]
	st [zy], r0			; zy[0] := y;
	
	ld r0, [points]
	add r0, 10
	st [points], r0	; Poeni := Poeni + 10;
	call print_status
	call calculate_star
	ld r0, [sx]
	st [x], r0
	ld r0, [sy]
	st [y], r0		; GotoXY(sx, sy);
	mov r0, 42		; '*'
	call putc			; write('*');
	j ms_end
	
move_on:					; else begin
	mov r1, zx
	ld r0, [n]
	shl r0, 1
	add r1, r0
	ld r0, [r1]
	st [x], r0		; GotoXY(zx[N], zy[N]);
	
	mov r1, zy
	ld r0, [n]
	shl r0, 1
	add r1, r0
	ld r0, [r1]
	st [y], r0		; GotoXY(zx[N], zy[N]);
	mov r0, 32		; ' '
	call putc			; write(' ');

	ld r0, [zx]
	st [x], r0		; GotoXY(zx[0], zy[0]);
	
	ld r0, [zy]
	st [y], r0		; GotoXY(zx[0], zy[0]);
	mov r0, 79		; 'O'
	call putc			; write('O');

	ld r0, [xx]
	st [x], r0		; GotoXY(x, y);
	
	ld r0, [yy]
	st [y], r0		; GotoXY(x, y);
	mov r0, 64		; '@'
	call putc			; write('@');
	
	ld r0, [n]
ms2:							; for i := N downto 1 do begin	
	mov r3, r0
	shl r3, 1
	mov r1, zx
	add r1, r3
	ld r2, [r1 - 2]
	st [r1], r2			; zx[i] := zx[i-1];

	mov r3, r0
	shl r3, 1
	mov r1, zy
	add r1, r3
	ld r2, [r1 - 2]
	st [r1], r2			; zy[i] := zy[i-1];
	
	dec r0
	cmp r0, 0
	jnz ms2					; end
	
	ld r0, [xx]
	st [zx], r0			; zx[0] := x;
	ld r0, [yy]
	st [zy], r0			; zy[0] := y;

ms_end:	
	pop r3
	pop r2
	pop r1
	ret
game_end:
	mov r0, 1
	st [end], r0		; kraj := true;
	ld r0, [xx]
	st [x], r0
	ld r0, [yy]
	st [y], r0
	mov r0, 88			; 'X'
	call putc				; GotoXY(x, y); write('X')
	j ms_end		

; #######################################################################################
; function wipe_screen(ro)
; deletes a screen with a given number of characters to be deleted, starting from the first character (0, 0)
; #######################################################################################
wipe_screen:
	push r2
	mov r2, r0				; r2 holds the number_of_characters_to_be_deleted
	mov r0, 0
ws_loop1:
	st [r2 + VIDEO_0], r0
	dec r2
	jp ws_loop1
	pop r2		
ret

; ##################################################################
; function delay(r0)
; waits for the r0 milliseconds
; ##################################################################
delay:
	push r1
	push r2
delay_loop2:
	in r1, [PORT_MILLIS]
delay_loop1:
	in r2, [PORT_MILLIS]
	sub r2, r1
	jz delay_loop1			; one millisecond elapsed here
	dec r0
	jnz delay_loop2
	
	pop r1
	pop r2
	ret

zx:
	#res 2000
zy:
	#res 2000
n:
	#d16 0
direction:
	#d16 0
points:
	#d16 0
end:
	#d16 0
key:
	#d16 0
sx:
	#d16 0
sy:
	#d16 0
x:
	#d16 0
y:
	#d16 0
xx:
	#d16 0
yy:
	#d16 0
points_str:
	#str "POINTS: \0"
buffer:
	#d8 0, 0, 0, 0, 0, 0
buffer_d:
	#d16 0, 0, 0, 0, 0, 0
		
#include "keyboard.asm"

send_serial:	
	push r5
ss1:
	in r5, [PORT_UART_TX_BUSY]   ; tx busy in r5
	cmp r5, 0     
	jz ss2   ; if not busy, send back the received character 
	j ss1
	
ss2:
	out [PORT_UART_TX_SEND_BYTE], r0  ; send the character to the UART
	
	pop r5
	ret
