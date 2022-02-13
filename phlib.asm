;=============================================================================
;
;	This source code file is copyright (c) Vadim Drubetsky AKA the 
; Black Phantom. All rights reserved.
;
;	This source code file is a part of the Tripple-DOS project. Your use 
; of this source code must fully comply with the accompanying license file, 
; LICENSE.TXT. You must have this file enclosed with your Tripple-DOS copy in
; order for it to be legal.
;
;	In no event, except for when it is explicitly stated by the applicable 
; law, shall Vadim Drubetsky aka the Black Phantom be liable for any special,
; incidental, indirect, or consequential damages (including but not limited to
; profit loss, business interruption, loss of business information, or any 
; other pecuniary loss) arising out of the use of or inability to use 
; Tripple-DOS, even if he has been advised of the possibility of such damages.
;
;=============================================================================

;=============================================================================
;
;				PHLIB.ASM
;				---------
;
;	This is a source for White & Black Phantoms standard library.
;
;	Several general concepts.
;  * "String" always means ASCIIz string.
;  * On input: memory buffer always will be pointed by DS:SI, number - given
;  in AX (AL) register, long integer - in DX:AX register pair.
;  * On output: memory buffer always will be pointed by ES:DI, number will
;  be returned in AX (AL, DX:AX), CF=0 means no error, CF=1 - any error.
;  * Each procedure preserves all CPU registers except used in return.
;	For MASM v6.1
;
;	Project:	Tripple-DOS
;	Copyright (c) White & Black Phantoms 1995, 1996.
;	Written by Black Phantom.
;	Start Project:		(approx.) ??/09/95
;	Last Update:		14/04/96
;
;=============================================================================

WHITEANDBLACKPHANTOMS	EQU	666

			INCLUDE	PHLIB.INC

DATA	SEGMENT	PARA	PUBLIC	USE16	'DATA'
DATA	ENDS

STK	SEGMENT	PARA STACK	USE16	'STACK'
STK	ENDS

CODE	SEGMENT	PARA	PUBLIC	USE16	'CODE'
ASSUME CS:CODE, DS:DATA, SS:STK

;-----------------------------------------------------------------------------
;
;	I:  DS:SI -> source string.
;	O:  nothing
;
;	Prints ASCIIz string.
;
;-----------------------------------------------------------------------------
PrintString	PROC
	push	ax
	push	bx
	push	cx
	push	dx

	call	StrLen
	xchg	ax, cx

	mov	ah, WRITE_HANDLE
	mov	bx, STDOUT
	mov	dx, si
	int	21h

	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
PrintString	ENDP


;-----------------------------------------------------------------------------
;
;	I:  AL = character
;	O:  nothing
;
;	Prints single char.
;
;-----------------------------------------------------------------------------
PrintChar	PROC	USES ax dx
	mov	ah, 6
	mov	dl, al
	cmp	al, -1
	jz	@F
	int	21h
@@:
	ret
PrintChar	ENDP


;-----------------------------------------------------------------------------
;
;	I:  AL = 1-byte hex, ES:DI -> converted 2 bytes, 0-term.
;	O:  nothing
;
;	Converts number in AL to hex. representation at ES:DI
;
;-----------------------------------------------------------------------------
HexToA		PROC
	push	ax
	push	cx

	mov	ah, al
	and	al, 0F0h
	and	ah, 0Fh
	add	ah, '0'
	cmp	ah, '9'
	jna	@F
	add	ah, 'A' - '0' - 10
@@:
	mov	cl, 4
	shr	al, cl
	add	al, '0'
	cmp	al, '9'
	jna	@F
	add	al, 'A' - '0' - 10
@@:
	mov	es:[di], ax
	mov	byte ptr es:[di+2], 0

	pop	cx
	pop	ax
	ret
HexToA		ENDP


;-----------------------------------------------------------------------------
;
;	I:  AX = 2-byte hex, ES:DI -> converted 4 bytes, 0-term.
;	O:  nothing
;
;	Converts number in AX to hex. representation at ES:DI
;
;-----------------------------------------------------------------------------
Hex16ToA	PROC
	xchg	ah, al
	call	HexToA
	add	di, 2
	xchg	ah, al
	call	HexToA
	sub	di, 2
	ret
Hex16ToA	ENDP


;-----------------------------------------------------------------------------
;
;	I:  DX:AX = 4-byte hex, ES:DI -> converted 8 bytes, 0-term.
;	O:  nothing
;
;	Converts number in DX:AX to hex. representation at ES:DI
;
;-----------------------------------------------------------------------------
Hex32ToA	PROC
	xchg	ax, dx
	call	Hex16ToA
	add	di, 4
	xchg	ax, dx
	call	Hex16ToA
	sub	di, 4
	ret
Hex32ToA	ENDP


;-----------------------------------------------------------------------------
;
;	I:  AX = unsigned integer, ES:DI -> buffer to converted string.
;	O:  ES:DI -> buffer filled.
;
;	Converts unsigned integer to decimal representation string.
;
;-----------------------------------------------------------------------------
UIToA		PROC
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	push	di

	mov	bx, 5

itoa_loop:
	xor	dx, dx
	mov	cx, 10
	div	cx
	add	dl, '0'
	mov	es:[bx+di], dl
	dec	bx
	or	ax, ax
	jnz	itoa_loop

	inc	bx
	mov	si, di
itoa_copy_lp:
	mov	al, es:[bx+di]
	mov	es:[si], al
	inc	si
	inc	bx
	cmp	bx, 5
	jna	itoa_copy_lp

	mov	byte ptr es:[si], 0

	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret

UIToA		ENDP


;-----------------------------------------------------------------------------
;
;	I:  AX = signed integer, ES:DI -> buffer to fill
;	O:  Buffer (ES:DI->) filled.
;
;	Converts signed integer to decimal representation string.
;
;-----------------------------------------------------------------------------
IToA		PROC
	or	ax, ax
	jns	@F
	push	ax
	push	di
	neg	ax
	mov	byte ptr es:[di], '-'
	inc	di
	call	UIToA
	pop	di
	pop	ax
	ret
@@:
	call	UIToA
	ret
IToA		ENDP


;-----------------------------------------------------------------------------
;
;	I:  DX:AX = long unsigned integer, ES:DI -> buffer.
;	O:  Buffer (ES:DI->) filled.
;
;	Converts long unsigned integer to string.
;
;-----------------------------------------------------------------------------
LongUIToA	PROC
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	push	di

	mov	byte ptr es:[di+11], 0
	mov	bx, 10
div10loop:
	call	Div32BitBy10
	add	cl, '0'
	mov	es:[bx+di], cl
	dec	bx
	or	ax, ax
	jnz	div10loop
	or	dx, dx
	jnz	div10loop

	inc	bx
	mov	si, di
copy_res_loop:
	mov	al, es:[bx+di]
	mov	es:[si], al
	inc	bx
	inc	si
	cmp	bx, 11
	jna	copy_res_loop

	mov	byte ptr es:[si], '0'

	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
LongUIToA	ENDP


;-----------------------------------------------------------------------------
;
;	I:  DX:AX = long signed integer, ES:DI -> buffer.
;	O:  Buffer (ES:DI->) filled.
;
;	Converts long signed integer to string.
;
;-----------------------------------------------------------------------------
LongIToA	PROC
	or	dx, dx
	jns	@F

	push	ax
	push	dx
	push	di

	not	ax
	not	dx
	add	ax, 1
	adc	dx, 0
	inc	di
	call	LongUIToA

	pop	di
	pop	dx
	pop	ax
	ret
@@:
	call	LongUIToA
	ret
LongIToA	ENDP


;-----------------------------------------------------------------------------
;
;	I:  DX:AX = long unsigned integer.
;	O:  DX:AX = result ( DX:AX = DX:AX / 10 ), CX = remainder.
;
;	Pefrorms integer division of 32-bit unsigned value by 10.
;
;-----------------------------------------------------------------------------
Div32BitBy10	PROC
	push	bx
	push	si
	push	di

	xchg	ax, cx
	xchg	ax, dx
	xor	dx, dx
	mov	bx, 10
	div	bx
	xchg	ax, si		; SI:DI - number.

	xchg	ax, dx
	ror	ax, 1
	ror	ax, 1
	ror	ax, 1
	ror	ax, 1
	mov	dx, cx
	shr	dx, 1
	shr	dx, 1
	shr	dx, 1
	shr	dx, 1
	and	ax, 0F000h
	or	ax, dx
	xor	dx, dx
	div	bx
	xchg	ax, di
	shl	di, 1
	shl	di, 1
	shl	di, 1
	shl	di, 1

	xchg	ax, dx
	shl	ax, 1
	shl	ax, 1
	shl	ax, 1
	shl	ax, 1
	and	ax, 00F0h
	mov	dx, cx
	and	dx, 000Fh
	or	ax, dx
	xor	dx, dx
	div	bx
	add	di, ax
	mov	cx, dx
	mov	dx, si
	xchg	ax, di

	pop	di
	pop	si
	pop	bx
	ret

Div32BitBy10	ENDP


;-----------------------------------------------------------------------------
;
;	I:  DS:SI -> decimal-represented number.
;	O:  CF = 0 - success, AX = number. CF = 1 - can't convert.
;
;-----------------------------------------------------------------------------
AToUI		PROC
	push	bx
	push	cx
	push	dx
	push	di

	call	StrLen
	xchg	ax, bx
	dec	bx
	mov	di, 1		; DI = mul operand
	sub	cx, cx		; CX = number
to_int_loop:
	mov	al, [bx+si]
	call	IsDigit
	jc	err_exit
	sub	al, '0'
	sub	ah, ah
	mul	di
	adc	cx, ax
	mov	ax, 10
	mul	di
	xchg	ax, di
	dec	bx
	jns	to_int_loop
	xchg	ax, cx
	clc
err_exit:
	pop	di
	pop	dx
	pop	cx
	pop	bx
	ret
AToUI		ENDP


;-----------------------------------------------------------------------------
;
;	I:  DS:SI -> decimal-represented number.
;	O:  CF = 0 - success, AX = number. CF = 1 - can't convert.
;
;-----------------------------------------------------------------------------
AToI		PROC
	cmp	byte ptr [si], '-'
	jnz	@F
	inc	si
	call	AToUI
	dec	si
	neg	ax
	ret
@@:
	call	AToUI
	ret
AToI		ENDP


;-----------------------------------------------------------------------------
;
;	I:  DS:SI -> Buffer (hex. representation of a number).
;	O:  CF = 0 - success, DX:AX = number. CF = 1 - can't convert.
;
;-----------------------------------------------------------------------------
AToHex		PROC
	push	bx
	push	cx
	push	di

	call	StrLen
	xchg	ax, bx
	dec	bx
	sub	dx, dx
	sub	di, di		; DX:DI = number.
	sub	ax, ax
	xor	cl, cl
to_hex_loop:
	mov	al, [bx+si]
	call	ToUpper
	call	IsDigit16
	jc	err_exit
	sub	al, '0'
	cmp	al, 9
	jna	@F
	sub	al, 'A' - 10 - '0'
@@:
	sub	ah, ah
	rol	ax, cl
	cmp	cl, 16
	jnb	to_hiword
	add	di, ax
	jmp	@F
to_hiword:
	add	dx, ax
@@:
	add	cl, 4
	dec	bx
	jns	to_hex_loop

	xchg	ax, di
err_exit:
	pop	di
	pop	cx
	pop	bx
	ret
AToHex		ENDP


;-----------------------------------------------------------------------------
;
;	I:  DS:SI -> Buffer (int representation of a long integer).
;	O:  DX:AX = number.
;
;-----------------------------------------------------------------------------
AToLongUI	PROC
	push	bx
	push	cx
	push	di

	push	bp
	mov	bp, sp
	sub	sp, 4

	call	StrLen
	xchg	ax, bx
	dec	bx

	sub	cx, cx		; CX:DI = number.
	sub	di, di
	mov	word ptr [bp-4], 1
	mov	word ptr [bp-4][2], 0

to_lint_loop:
	mov	al, [bx+si]
	call	IsDigit
	jc	err_exit
	sub	al, '0'
	cbw
	push	ax

	mul	word ptr [bp-4][2]
	add	cx, ax
	pop	ax
	mul	word ptr [bp-4]
	add	di, ax
	adc	cx, dx

	mov	ax, 10
	push	ax
	mul	word ptr [bp-4][2]
	mov	word ptr [bp-4][2], ax
	pop	ax
	mul	word ptr [bp-4]
	mov	word ptr [bp-4], ax
	add	word ptr [bp-4][2], dx

	dec	bx
	jns	to_lint_loop

	xchg	ax, di
	mov	dx, cx

	clc
err_exit:
	mov	sp, bp
	pop	bp

	pop	di
	pop	cx
	pop	bx
	ret
AToLongUI	ENDP


;-----------------------------------------------------------------------------
;
;	I:  AL = char.
;	O:  CF = 0 - digit, CF = 1 - non-digit.
;
;-----------------------------------------------------------------------------
IsDigit		PROC
	cmp	al, '0'
	jb	@F
	cmp	al, '9'
	ja	@F
	clc
	ret
@@:
	stc
	ret
IsDigit		ENDP


;-----------------------------------------------------------------------------
;
;	I:  AL = char.
;	O:  CF = 0 - alpha, CF = 1 - non-alpha.
;
;-----------------------------------------------------------------------------
IsAlpha		PROC
	cmp	al, 'A'
	jb	non_alpha
	cmp	al, 'z'
	ja	non_alpha
	cmp	al, 'Z'
	jna	alpha
	cmp	al, 'a'
	jnb	alpha
	cmp	al, '_'
	jnz	non_alpha
alpha:
	clc
	ret
non_alpha:
	stc
	ret
IsAlpha		ENDP


;-----------------------------------------------------------------------------
;
;	I:  AL = char.
;	O:  CF = 0 - alpha or digit, CF = 1 neither of.
;
;-----------------------------------------------------------------------------
IsAlNum		PROC
	call	IsAlpha
	jc	@F
	call	IsDigit
@@:
	ret
IsAlNum		ENDP


;-----------------------------------------------------------------------------
;
;	I:  AL = char
;	O:  CF = 0 if hex. digit, CF = 1 if not.
;
;-----------------------------------------------------------------------------
IsDigit16	PROC
	call	IsDigit
	jnc	digit16
	cmp	al, 'A'
	jb	non_digit16
	cmp	al, 'F'
	jna	digit16
	cmp	al, 'a'
	jb	non_digit16
	cmp	al, 'f'
	ja	non_digit16
digit16:
	clc
	ret
non_digit16:
	stc
	ret
IsDigit16	ENDP


;-----------------------------------------------------------------------------
;
;	I:  AL = char
;	O:  AL = upcase(AL)
;
;-----------------------------------------------------------------------------
ToUpper		PROC
	cmp	al, 'a'
	jb	@F
	cmp	al, 'z'
	ja	@F
	sub	al, 'a' - 'A'
@@:
	ret
ToUpper		ENDP


;-----------------------------------------------------------------------------
;
;	I:  AL = char
;	O:  AL = lowcase(AL)
;
;-----------------------------------------------------------------------------
ToLower		PROC
	cmp	al, 'A'
	jb	@F
	cmp	al, 'Z'
	ja	@F
	add	al, 'a' - 'A'
@@:
	ret
ToLower		ENDP


;-----------------------------------------------------------------------------
;
;	I:  DS:SI -> source 0-termin. string.
;	O:  AX = string length.
;
;-----------------------------------------------------------------------------
StrLen		PROC
	push	si

	sub	ax, ax
find_0_loop:
	cmp	byte ptr ds:[si], 0
	jz	found_0
	inc	si
	inc	ax
	jmp	find_0_loop
found_0:
	pop	si
	ret
StrLen		ENDP


;-----------------------------------------------------------------------------
;
;	I:  ES:DI -> buffer for arguments (256 bytes).
;	O:  ES:DI buffer filled, AX = number of params.
;
;-----------------------------------------------------------------------------
GetArguments	PROC USES cx si di
	mov	si, 81h
	xor	cx, cx
	xor	ax, ax
	mov	cl, ds:[80h]
	cld
next:
	jcxz	to_end
	cmp	byte ptr [si], SPACE
	jz	@F
	cmp	byte ptr [si], TAB
	jnz	get_param
@@:
	dec	cx
	inc	si
	jmp	next
get_param:
	movsb
	dec	cx
	jcxz	got_param
	cmp	byte ptr [si], SPACE
	jz	got_param
	cmp	byte ptr [si], TAB
	jnz	get_param
got_param:
	inc	ax
	mov	byte ptr es:[di], NULL
	inc	di
	jmp	next
to_end:
	ret
GetArguments	ENDP


;-----------------------------------------------------------------------------
;
;	I:  DS:SI -> source string (0 - terminated).
;	    ES:DI -> dest string.
;	O:  nothing.
;
;	Procedure copies source string to destination. No checking on strings
; overlap is performed. (If second string overlaps first, function may fail.
; Terminating '\0'is included.
;-----------------------------------------------------------------------------
StrCpy		PROC USES ds es si di ax cx
	push	ds
	push	si
	call	StrLen
	pop	si
	pop	ds
	xchg	ax, cx
	inc	cx
	cld
		rep	movsb
	ret
StrCpy		ENDP

CODE	ENDS

END
