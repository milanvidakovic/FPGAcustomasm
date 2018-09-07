#include "consts.asm"

; this program will demonstrate make/break parsing of the PS2 keyboard
; it works like full screen editor
#addr 0x400
; ########################################################
; REAL START OF THE PROGRAM
; ########################################################

	mov sp, 26000

	; set the IRQ handler for keyboard to our own IRQ handler
	mov r0, 1							; JUMP instruction opcode
	mov r1, IRQ2_ADDR			; IRQ#2 vector address
	st [r1], r0
	mov r0, irq_triggered
	mov r1, IRQ2_ADDR + 2	  
	st [r1], r0						; the keyboard IRQ handler has been set
	
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


	mov r0, 0
	st [VIRTUAL_KEY_ADDR], r0	; reset the virtual key code
		
	call wipe

	mov r0, 0			; set the initial state of all variables
	st [state], r0
	st [substate], r0
	st [x_cursor], r0
	st [y_cursor], r0

	call toggle_cursor	

	halt

; ##################################################################
; function pressed()
; called when a key is pressed
; ##################################################################
pressed:	
	ld r0, [VIRTUAL_KEY_ADDR]			; get the VK of the key pressed
	
	call check_ascii		; will return the ascii code in r1; otherwise will return 0
	cmp r1, 0
	jnz print		; if it is printable - let's print it (the input is in r1)

	mov r1, r0
	j move			; if it is non-printable key, then maybe it is cursor-moving code - let's move the cursor (the virtual code is in the r1)
	
; ##################################################################
; r1 = function check_ascii(r0)
; returns the ascii code in r1; otherwise returns 0
; ##################################################################
check_ascii:
	mov r1, r0
	cmp r1, 255
	jg no_ascii
	ret
no_ascii:
	mov r1, 0
	ret

; #################################################################
; r1 = function vk_to_char(r1)
; tranaslates virtual key to character
; if shift is pressed, does the uppercase
; #################################################################
vk_to_char:
	push r0
	push r2

	cmp r1, 65
	jge letter1
v2:
	
	mov r0, vk_char_table
v4:	
	ld r2, [r0]	
	cmp r2, 0xFFFF
	jz v1
	cmp r2, r1
	jz v3
	add r0, 6
	j v4
v3:
	add r0, 2
	ld r2, [shift]
	shl r2, 1
	add r0, r2
	ld r1, [r0]
v1:	
	pop r2
	pop r0
	ret

letter1:
	cmp r1, 90
	jse letter
	j v2
letter:
	ld r0, [shift]
	cmp r0, 1
	jz v1
	add r1, 32
	j v1

; ##################################################################	
; function print(r1)
; prints the character in the r1 
; ##################################################################	
print:
	call toggle_cursor
	
	ld r0, [x_cursor]
	ld r2, [y_cursor]
	cmp r1, VK_TAB	; TAB
	jz tab
	cmp r1, VK_ENTER	; ENTER
	jz enter
	
	call vk_to_char			; get the character out of the virtual key
	
	; print the character
	call put_char

move_right:	
	ld r0, [x_cursor]
	ld r2, [y_cursor]
	inc r0	; move right
	cmp r0, 80
	jz next_line	; if we reached the end of line, move to the next line
set_cursor:
	st [x_cursor], r0
	st [y_cursor], r2
	call toggle_cursor
	
	iret
	
next_line:
	cmp r2, 59
	jz stay_r
	mov r0, 0		; x = 0
	inc r2			; y = y + 1
	j set_cursor
stay_r:	
	ld r0, [x_cursor]
	j set_cursor	

move_left:
	ld r0, [x_cursor]
	ld r2, [y_cursor]
	dec r0	; move left
	jnp prev_line	; if we passed the beginning of line, move to the previous line
	j set_cursor
prev_line:
	cmp r2, 0
	jz stay
	dec r2
	mov r0, 79
	j set_cursor		
stay:
	mov r0, 0
	j set_cursor

move_up:
	ld r0, [x_cursor]
	ld r2, [y_cursor]
	cmp r2, 0
	jz set_cursor
	dec r2	; move up
	j set_cursor

move_down:
	ld r0, [x_cursor]
	ld r2, [y_cursor]
	cmp r2, 59
	jz set_cursor
	inc r2	; move down
	j set_cursor

enter:
	cmp r2, 59
	jz set_cursor
	inc r2
	mov r0, 0
	j set_cursor

tab:
	call toggle_cursor
	iret
	;j skip
	
backspace:
	ld r0, [x_cursor]
	ld r2, [y_cursor]
	dec r0	; move left
	jnp back_prev_line	; if we passed the beginning of line, move to the previous line

	mov r1, 32	
	call put_char
	
	j set_cursor
back_prev_line:
	cmp r2, 0
	jz back_stay
	dec r2
	mov r0, 79
	
	mov r1, 32	
	call put_char
	
	j set_cursor		
back_stay:
	mov r0, 0
	j set_cursor

;###############################################################################
; function put_char(r1, r0, r2)
; prints a character in r1 at (r0, r2)
;###############################################################################
put_char:
	push r0
	push r1
	push r2
	shl r0, 1
	mul r2, 160
	add r2, r0
	add r2, VIDEO_0	; calc the position where the char will be printed
	
	st [r2], r1	; store the character on the current cursor position
	pop r2
	pop r1
	pop r0
	ret

shift_pressed:
	mov r1, 1
	st [shift], r1
	j mn1

; ##################################################################	
; function move(r1)
; tries to move cursor, if the key code in r1 is cursor-moving
; ##################################################################	
move:
	call toggle_cursor

	cmp r1, VK_RIGHT_ARROW		; RIGHT ARROW
	jz move_right
	cmp r1, VK_LEFT_ARROW			; LEFT ARROW
	jz move_left
	cmp r1, VK_UP_ARROW				; UP ARROW
	jz move_up
	cmp r1, VK_DOWN_ARROW			; DOWN ARROW
	jz move_down
	cmp r1, VK_BACKSPACE
	jz backspace
	
	cmp r1, VK_LEFT_SHIFT
	jz shift_pressed
	cmp r1, VK_RIGHT_SHIFT
	jz shift_pressed
mn1:	
	call toggle_cursor
	
	iret
	;j skip

x_cursor:
	#d16 0
y_cursor:
	#d16 0
shift:
	#d16 0


; ##################################################################
; function toggle_cursor()
; toggles a character at the current cursors position
; ##################################################################	
toggle_cursor:
	push r0
	push r1
	push r2
	ld r1, [x_cursor]
	ld r2, [y_cursor]
	shl r1, 1
	mul r2, 160
	add r2, r1
	add r2, VIDEO_0
	ld r0, [r2]
	xor r0, 0x7700	; toggle attributes
	st [r2], r0	
	pop r2
	pop r1
	pop r0
	ret

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

shift_released:
	mov r1, 0
	st [shift], r1
	j rl1
	
; #############################################################################
; function released()
; called when a key is released
; #############################################################################
released:	
	ld r1, [VIRTUAL_KEY_ADDR]
	cmp r1, VK_LEFT_SHIFT
	jz shift_released
	cmp r1, VK_RIGHT_SHIFT
	jz shift_released
rl1:	
	iret

; #############################################################################
; #############################################################################
; Subroutine which is called whenever some byte arrives from the PS/2 keyboard
; #############################################################################
; #############################################################################
irq_triggered:	
	push r0
	push r1
	push r2

	in r0, [PORT_KEYBOARD] 	; r0 holds the keyboard scancode

	mov r1, 0
	cmp r1, [state]	
	jz make_code	; state 0 - try to parse received scancode into the virtual key make code (key pressed)

	inc r1
	cmp r1, [state]
	jz break_code	; state 1 - try to parse received scancode into the virtual key break code (key released)
	
skip:
	pop r2
	pop r1                 
	pop r0
	iret									 

; ##################################################################
; function make_code(r0)
; parses the virtual key code of the pressed key
; ##################################################################
make_code:
	in r0, [PORT_KEYBOARD]
	
	ld r1, [substate]
	cmp r1, 0
	jz make0				; state 0 - the first byte of the make code; if not extended, this will be the only byte of the make code
	cmp r1, 1
	jz make1				; state 1 - the second and other bytes of the make code - the extended make codes have multiple bytes

	j skip

make0:
	cmp r0, 0xF0
	jz	break_code	; two keys pressed fast, so instead of make code, here cames the other break code
	cmp r0, 0xE0
	jz extended0		; check if the received make code is the extended0 (E0)
	cmp r0, 0xE1
	jz extended1		; check if the received make code is the extended 1 (E1)

	; not	extended code - it is a normal key, with just one make code byte
	shl r0, 1
	ld r1, [r0 + vk_table1]			; fetch the virtual key code based on the make code
	st [VIRTUAL_KEY_ADDR], r1		; save the parsed virtual key code

	mov r0, 1
	st [state], r0 	; set the next state (1) - ready to receive break code
	mov r0, 0
	st [substate], r0
	
	pop r2
	pop r1
	pop r0
	j KEY_PRESSED_HANDLER_ADDR
	
	;j exec						; try to either print the character, or move the cursor

extended0:
	; Extended0 keys heve two make/break bytes; the first is E0, and the second determines the key
	mov r0, 1
	st [substate], r0	; prepare for the second byte
	j skip

extended1:
	j skip

make1:
	; the second byte has just arrived
	; it is in the r0 register
	in r0, [PORT_KEYBOARD]
	
	; first check for the Print Screen key
	cmp r0, 12
	jz mk_print_screen
	
	mov r2, vk_table2
make2_1:	
	ld r1, [r2]
	cmp r1, 0xFFFF
	jz make2_end	; end of the table; should not happen
	cmp r0, r1
	jz found_e0
	add r2, 4
	j make2_1
found_e0:

	; found the received second byte in the table
	add r2, 2
	ld r1, [r2] 	; get the VK
	st [VIRTUAL_KEY_ADDR], r1	; save it for the exec
	
	mov r0, 1
	st [state], r0
	mov r0, 0
	st [substate], r0 ; prepare for the break code waiting

	pop r2
	pop r1
	pop r0
	j KEY_PRESSED_HANDLER_ADDR
	
	;j exec	

make2_end:
	; second make code not found in the vk_table2; then it should be break code
	mov r1, 0
	st [state], r1
	st [substate], r1 ; prepare for the make code waiting

	j skip

mk_print_screen:
	mov r0, 0
	st [substate], r0
	j skip	
	

; ##################################################################	
; function break_code(r0)
;
; ##################################################################	
break_code:
	mov r1, 1
	st [state], r1
	
	ld r1, [substate]
	cmp r1, 0
	jz break0		; we have received the first break byte
	cmp r1, 1
	jz break1		; we have received the second break byte (extended key or special case of long press or fast click)
	cmp r1, 2
	jz break2		; we have received the second break byte (normal key handler)
	cmp r1, 3
	jz break3		; we have received the third break byte (extended key handler)
	
	j skip

break0:
	cmp r0, 0xF0
	jz break_f0
	cmp r0, 0xE0
	jz break_e0
	cmp r0, 0xE1
	jz break_e1		; print screen pressed very fast, and this is actually the make code
	
	j make_code		; two keys pressed fast, so two make codes came one after another

break_f0:
	mov r0, 2
	st [substate], r0		; set the substate to wait for the second break byte
	j skip

break_e0:
	mov r0, 1
	st [substate], r0		; set the substate to wait for the second break byte, which is maybe a make code (long press)
	j skip

break_e1:
	; this is a special case when after E0 key comes the Print Screen very fast
	mov r0, 1
	st [substate], r0		; set the substate to wait for the second make byte
	mov r0, 0
	st [state], r0			; set the state to be wait for the make code
	
	j skip

break1:
	; we have just received the second break byte
	cmp r0, 0xF0
	jz more_breaks
	
	; we will try to parse this second byte as a make code
	; it happens when you long press non-printable character
	; then, multiple make codes arrive, instead of a break code
	j make1

more_breaks:
	; this part of code handles break code of extended E0 keys
	mov r0, 3
	st [substate], r0
	
	j skip

break2:
	cmp r0, 0x7C
	jz br_print_screen
	
	; not	extended code - it is a normal key
	shl r0, 1
	ld r1, [r0 + vk_table1]	; fetch the virtual key code based on the make code
	st [VIRTUAL_KEY_ADDR], r1		; save the parsed virtual key code
	
	mov r0, 0
	st [substate], r0
	st [state], r0

	pop r2
	pop r1
	pop r0
	j KEY_RELEASED_HANDLER_ADDR

;	j skip

break3:
	; extended key break code
	mov r2, vk_table2
break3_1:	
	ld r1, [r2]
	cmp r1, 0xFFFF
	jz break3_end	; end of the table; should not happen
	cmp r0, r1
	jz found_break_e0
	add r2, 4
	j break3_1

found_break_e0:

	; found the received third byte in the table
	add r2, 2
	ld r1, [r2] 	; get the VK
	st [VIRTUAL_KEY_ADDR], r1	; save it for the exec

	mov r0, 0
	st [substate], r0
	st [state], r0
	
	pop r2
	pop r1
	pop r0
	j KEY_RELEASED_HANDLER_ADDR	

break3_end:
	; third break code not found in the vk_table2; 
	mov r1, 0
	st [state], r1
	st [substate], r1 ; prepare for the make code waiting

	j skip

br_print_screen:
	mov r0, 0
	st [substate], r0
	j skip		
	
state:
	#d16 0
substate:
	#d16 0

vk_table1:
	; Basic key table
	#d16 256												;00 -
	#d16 VK_F9											;01 - F9		
	#d16 256												;02 - 		
	#d16 VK_F5											;03 - F5		
	#d16 VK_F3											;04 - F3		
	#d16 VK_F1											;05 - F1		
	#d16 VK_F2											;06 - F2		
	#d16 VK_F12											;07 - F12		
	#d16 256												;08 - 	
	#d16 VK_F10											;09 - F10		
	#d16 VK_F8											;10 - F8		
	#d16 VK_F6											;11 - F6		
	#d16 VK_F4											;12 - F4		
	#d16 VK_TAB											;13 - TAB	
	#d16 VK_BACK_QUOTE							;14 - `	(TO THE LEFT OF THE 1 KEY)
	#d16 256												;15 - 		
	#d16 256												;16 - 		
	#d16 VK_LEFT_ALT								;17 - Left Alt		
	#d16 VK_LEFT_SHIFT							;18 - Left Shift		
	#d16 256												;19 - 		
	#d16 VK_LEFT_CONTROL						;20 - Left Ctrl		
	#d16 VK_Q												;21 - Q		
	#d16 VK_1												;22 - 1		
	#d16 256												;23 - 		
	#d16 256												;24 - 		
	#d16 256												;25 - 		
	#d16 VK_Z												;26 - Z		
	#d16 VK_S												;27 - S
	#d16 VK_A												;28 - A
	#d16 VK_W												;29 - W
	#d16 VK_2												;30 - 2
	#d16 256												;31 - 
	#d16 256												;32 - 		
	#d16 VK_C												;33 - C		
	#d16 VK_X												;34 - X
	#d16 VK_D												;35 - D
	#d16 VK_E												;36 - E	
	#d16 VK_4												;37 - 4
	#d16 VK_3												;38 - 3
	#d16 256												;39 - 
	#d16 256												;40 - 		
	#d16 VK_SPACE										;41 - SPACE		
	#d16 VK_V												;42 - V
	#d16 VK_F												;43 - F
	#d16 VK_T												;44 - T
	#d16 VK_R												;45 - R
	#d16 VK_5												;46 - 5
	#d16 256												;47 - 
	#d16 256												;48 - 		
	#d16 VK_N												;49 - N		
	#d16 VK_B												;50 - B
	#d16 VK_H												;51 - H
	#d16 VK_G												;52 - G
	#d16 VK_Y												;53 - Y
	#d16 VK_6												;54 - 6
	#d16 256												;55 - 
	#d16 256												;56 - 		
	#d16 256												;57 - 		
	#d16 VK_M												;58 - M		
	#d16 VK_J												;59 - J
	#d16 VK_U												;60 - U
	#d16 VK_7												;61 - 7
	#d16 VK_8												;62 - 8
	#d16 256												;63 - 
	#d16 256												;64 - 		
	#d16 VK_COMMA										;65 - ,		
	#d16 VK_K												;66 - K
	#d16 VK_I												;67 - I
	#d16 VK_O												;68 - O
	#d16 VK_0												;69 - 0 (ZERO)
	#d16 VK_9												;70 - 9
	#d16 256												;71 - 
	#d16 256												;72 - 		
	#d16 VK_FULL_STOP								;73 - .
	#d16 VK_SLASH										;74 - / (LEFT TO THE RIGHT SHIFT KEY)	
	#d16 VK_L												;75 - L
	#d16 VK_SEMICOLON								;76 - ; (TO THE RIGHT OF THE L KEY)		
	#d16 VK_P												;77 - P
	#d16 VK_MINUS										;78 - - (TO THE RIGHT OF THE ZERO KEY)
	#d16 256												;79 - 
	#d16 256												;80 - 		
	#d16 256												;81 - 		
	#d16 VK_QUOTE										;82 - ' (SECOND TO THE RIGHT OF THE L KEY)		
	#d16 256												;83 - 
	#d16 VK_BRACE_LEFT							;84 - [ (TO THE RIGHT OF THE P KEY)		
	#d16 VK_EQUALS									;85 - = (TO THE LEFT OF THE BACKSPACE KEY)
	#d16 256												;86 - 
	#d16 256												;87 - 		
	#d16 VK_CAPS_LOCK								;88 - CAPS LOCK		
	#d16 VK_RIGHT_SHIFT							;89 - RIGHT SHIFT
	#d16 VK_ENTER										;90 - ENTER
	#d16 VK_BRACE_RIGHT							;91 - ] (SECOND RIGHT TO THE P KEY)
	#d16 256												;92 - 
	#d16 VK_BACK_SLASH							;93 - \ (BELOW BACKSPACE)
	#d16 256												;94 - 
	#d16 256												;95 - 
	#d16 256 												;96 - 
	#d16 VK_LESS_THAN								;97 - < (TO THE LEFT OF THE Z KEY)
	#d16 256 												;98 - 
	#d16 256 												;99 - 
	#d16 256												;100- 
	#d16 256												;101 - 
	#d16 VK_BACKSPACE								;102 - BACKSPACE
	#d16 256												;103 - 
	#d16 256												;104 - 
	#d16 VK_NUMPAD1									;105 - NUMPAD 1
	#d16 256												;106 - 
	#d16 VK_NUMPAD4									;107 - NUMPAD 4
	#d16 VK_NUMPAD7									;108 - NUMPAD 7
	#d16 256												;109 - 
	#d16 256												;110 - 
	#d16 256												;111 - 
	#d16 VK_NUMPAD0									;112 - NUMPAD 0
	#d16 VK_NUMPAD_DECIMAL					;113 - NUMPAD .
	#d16 VK_NUMPAD2									;114 - NUMPAD 2
	#d16 VK_NUMPAD5									;115 - NUMPAD 5
	#d16 VK_NUMPAD6									;116 - NUMPAD 6
	#d16 VK_NUMPAD8									;117 - NUMPAD 8
	#d16 VK_ESC											;118 - ESC
	#d16 VK_NUM_LOCK								;119 - NUM LOCK
	#d16 VK_F11											;120 - F11
	#d16 VK_NUMPAD_PLUS							;121 - NUMPAD + 
	#d16 VK_NUMPAD3									;122 - NUMPAD 3
	#d16 VK_NUMPAD_SUBTRACT					;123 - NUMPAD -
	#d16 VK_NUMPAD_MULTIPLY					;124 - NUMPAD *
	#d16 VK_NUMPAD9									;125 - NUMPAD 9
	#d16 VK_SCROLL_LOCK							;126 - SCROLL LOCK
	#d16 256												;127 - 
	#d16 256												;128 - 
	#d16 256												;129 - 
	#d16 VK_F7											;130 - F7

vk_table2:
	; Extended key table
	#d16 0x1F, VK_LEFT_WINDOWS			; Left Windows
	#d16 0x11, VK_RIGHT_ALT					; Right Alt
	#d16 0x27, VK_RIGHT_WINDOWS			; Right Windows
	#d16 0x2F, VK_MENU							; Menu key
	#d16 0x14, VK_RIGHT_CONTROL			; Right Control
	#d16 0x70, VK_INSERT						; Insert
	#d16 0x6C, VK_HOME							; Home
	#d16 0x7D, VK_PAGE_UP						; Page Up
	#d16 0x71, VK_DELETE						; Delete
	#d16 0x69, VK_END								; End
	#d16 0x7A, VK_PAGE_DOWN					; Page Down
	#d16 0x75, VK_UP_ARROW					; Up Arrow
	#d16 0x6B, VK_LEFT_ARROW				; Left Arrow
	#d16 0x72, VK_DOWN_ARROW				; Down Arrow
	#d16 0x74, VK_RIGHT_ARROW				; Right Arrow
	#d16 0x4A, VK_NUMPAD_DIVIDE			; NUMPAD /
	#d16 0x5A, VK_NUMPAD_ENTER			; NUMPAD ENTER
	#d16 0x7C, VK_PRINT_SCREEN			; PRINT SCREEN
	#d16 0xFFFF, 0xFFFF	; end marker

vk_char_table:
	#d16 VK_0, 48, 41	; 0, )!
	#d16 VK_1, 49, 33	; 1, !
	#d16 VK_2, 50, 64	; 2, @
	#d16 VK_3, 51, 35	; 3, #
	#d16 VK_4, 52, 36	; 4, $
	#d16 VK_5, 53, 37	; 5, %
	#d16 VK_6, 54, 94	; 6, ^
	#d16 VK_7, 55, 38	; 7, &
	#d16 VK_8, 56, 42	; 8, *
	#d16 VK_9, 57, 40	; 9, (
	
	#d16 VK_BACK_QUOTE, 96, 126	; `, ~
	#d16 VK_MINUS, 45, 95	; -, _
	#d16 VK_EQUALS, 61, 43	; =, +

	#d16 VK_BRACE_LEFT, 91, 123	; [, {
	#d16 VK_BRACE_RIGHT, 93, 125	; ], }
	#d16 VK_SEMICOLON, 59, 58	; ;, :
	#d16 VK_QUOTE, 39, 34	; ', "
	#d16 VK_BACK_SLASH, 92, 124	; \, |
	#d16 VK_COMMA, 44, 60	; ,, <
	#d16 VK_FULL_STOP, 46, 62	; ., >
	#d16 VK_LESS_THAN, 60, 62	; <, >
	#d16 VK_SLASH, 47, 63	; /, ?
	#d16 0xFFFF	
	
	
	
send_uart:
su2:
	in r5, [PORT_UART_TX_BUSY]   ; tx busy in r5
	cmp r5, 0     
	jz su3   ; if not busy, send back the received character 
	j su2
	
su3:
	out [PORT_UART_TX_SEND_BYTE], r1  ; send the received character to the UART
	ret
