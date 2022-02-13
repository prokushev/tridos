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
;				PHLIB32.ASM
;				-----------
;
;	This is a port of PHLIB library for 32-bit code segment.
;
;=============================================================================

		INCLUDE	CORE.INC

.486p
		EXTRN	Columns: BYTE
		EXTRN	VBufTextSel: WORD

		EXTRN	GetAsciiCode: near32
		EXTRN	GotoXy: near32
		EXTRN	TtyChar: near32

CODE32	SEGMENT	BYTE	PUBLIC	USE32	'CODE'
ASSUME	CS:CODE32, DS:FLAT

;-----------------------------------------------------------------------------
;
;	I:  AL = 1-byte hex, ES:EDI -> converted 2 bytes, 0-term.
;	O:  nothing
;
;	Converts number in AL to hex. representation at ES:EDI
;
;-----------------------------------------------------------------------------
PmHexToA	PROC	near	USES es eax
	push	ds
	pop	es

	mov	ah, al
	and	al, 0F0h
	and	ah, 0Fh
	add	ah, '0'
	cmp	ah, '9'
	jna	@F
	add	ah, 'A' - '0' - 10
@@:
	shr	al, 4
	add	al, '0'
	cmp	al, '9'
	jna	@F
	add	al, 'A' - '0' - 10
@@:
	mov	es:[edi], ax
	mov	byte ptr es:[edi+2], 0

	ret
PmHexToA	ENDP


;-----------------------------------------------------------------------------
;
;	I:  AX = 2-byte hex, ES:EDI -> converted 4 bytes, 0-term.
;	O:  nothing
;
;	Converts number in AX to hex. representation at ES:EDI
;
;-----------------------------------------------------------------------------
PmHex16ToA	PROC	near
	xchg	ah, al
	call	PmHexToA
	add	edi, 2
	xchg	ah, al
	call	PmHexToA
	sub	edi, 2
	ret
PmHex16ToA	ENDP


;-----------------------------------------------------------------------------
;
;	I:  EAX = 4-byte hex, ES:EDI -> converted 8 bytes, 0-term.
;	O:  nothing
;
;	Converts number in EAX to hex. representation at ES:EDI
;
;-----------------------------------------------------------------------------
PmHex32ToA	PROC	near
	ror	eax, 16
	call	PmHex16ToA
	add	edi, 4
	ror	eax, 16
	call	PmHex16ToA
	sub	edi, 4
	ret
PmHex32ToA	ENDP


;-----------------------------------------------------------------------------
;
;	I:  AX = unsigned integer, ES:EDI -> buffer to converted string.
;	O:  ES:EDI -> buffer filled.
;
;	Converts unsigned integer to decimal representation string.
;
;-----------------------------------------------------------------------------
PmUIToA		PROC	near	USES eax ebx ecx edx esi edi
	mov	ebx, 5
	mov	ecx, 10
itoa_loop:
	xor	edx, edx
	div	ecx
	add	dl, '0'
	mov	es:[ebx+edi], dl
	dec	ebx
	test	eax, eax
	jnz	itoa_loop

	inc	ebx
	mov	esi, edi
itoa_copy_lp:
	mov	al, es:[ebx+edi]
	mov	es:[esi], al
	inc	esi
	inc	ebx
	cmp	ebx, 5
	jna	itoa_copy_lp

	mov	byte ptr es:[esi], 0

	ret

PmUIToA		ENDP


;-----------------------------------------------------------------------------
;
;	I:  EAX = signed integer, ES:EDI -> buffer to fill
;	O:  Buffer (ES:EDI->) filled.
;
;	Converts signed integer to decimal representation string.
;
;-----------------------------------------------------------------------------
PmIToA		PROC	near	USES eax edi
	test	eax, eax
	jns	@F

	neg	eax
	mov	byte ptr es:[edi], '-'
	inc	edi
@@:
	call	PmUIToA
	ret
PmIToA		ENDP


;-----------------------------------------------------------------------------
;
;	I:  EAX = long unsigned integer, ES:EDI -> buffer.
;	O:  Buffer (ES:EDI->) filled.
;
;	Converts long unsigned integer to string.
;
;-----------------------------------------------------------------------------
PmLongUIToA	PROC	near	USES eax ebx ecx edx esi edi
	mov	byte ptr es:[edi+11], 0
	mov	ebx, 10
	mov	ecx, 10
div10loop:
	xor	edx, edx
	div	ecx
	add	dl, '0'
	mov	es:[ebx+edi], dl
	dec	ebx
	test	eax, eax
	jnz	div10loop
	test	edx, edx
	jnz	div10loop

	inc	ebx
	mov	esi, edi
copy_res_loop:
	mov	al, es:[ebx+edi]
	mov	es:[esi], al
	inc	ebx
	inc	esi
	cmp	ebx, 11
	jna	copy_res_loop

	mov	byte ptr es:[esi], '0'

	ret
PmLongUIToA	ENDP


;-----------------------------------------------------------------------------
;
;	I:  EAX = long signed integer, ES:DI -> buffer.
;	O:  Buffer (ES:DI->) filled.
;
;	Converts long signed integer to string.
;
;-----------------------------------------------------------------------------
PmLongIToA	PROC	near	USES eax edi
	test	eax, eax
	jns	@F

	neg	eax
	mov	byte ptr es:[edi], '-'
	inc	edi
@@:
	call	PmUIToA
	ret

PmLongIToA	ENDP


;-----------------------------------------------------------------------------
;
;	I:  DS:ESI -> decimal-represented number.
;	O:  CF = 0 - success, EAX = number. CF = 1 - can't convert.
;
;-----------------------------------------------------------------------------
PmAToUI		PROC	near	USES ebx ecx edx edi
	call	PmStrLen
	xchg	eax, ebx
	dec	ebx
	mov	edi, 1		; DI = mul operand
	sub	ecx, ecx	; CX = number
to_int_loop:
	mov	al, [ebx+esi]
	call	PmIsDigit
	jc	err_exit

	sub	al, '0'
	movzx	eax, al
	mul	edi
	adc	ecx, eax
	mov	eax, 10
	mul	edi
	xchg	eax, edi
	dec	ebx
	jns	to_int_loop

	xchg	eax, ecx
	clc
err_exit:
	ret
PmAToUI		ENDP


;-----------------------------------------------------------------------------
;
;	I:  DS:ESI -> decimal-represented number.
;	O:  CF = 0 - success, AX = number. CF = 1 - can't convert.
;
;-----------------------------------------------------------------------------
PmAToI		PROC	near
	cmp	byte ptr [esi], '-'
	jnz	@F

	inc	esi
	call	PmAToUI
	dec	esi
	neg	eax
	ret
@@:
	call	PmAToUI
	ret
PmAToI		ENDP


;-----------------------------------------------------------------------------
;
;	I:  DS:ESI -> Buffer (hex. representation of a number).
;	O:  CF = 0 - success, EAX = number. CF = 1 - can't convert.
;
;-----------------------------------------------------------------------------
PmAToHex	PROC	near	USES ebx ecx edi
	call	PmStrLen
	lea	ebx, [eax-1]
	sub	edx, edx		; EDX = number
	sub	eax, eax
	sub	cl, cl
to_hex_loop:
	mov	al, [esi+ebx]
	call	PmToUpper
	call	PmIsDigit16
	jc	err_exit

	sub	al, '0'
	cmp	al, 9
	jna	@F

	sub	al, 'A' - 10 - '0'
@@:
	and	eax, 0FFh
	shl	eax, cl

	add	edx, eax
	add	cl, 4
	dec	ebx
	jns	to_hex_loop

	xchg	eax, edx
	clc
err_exit:
	ret
PmAToHex	ENDP


;-----------------------------------------------------------------------------
;
;	I:  AL = char.
;	O:  CF = 0 - digit, CF = 1 - non-digit.
;
;-----------------------------------------------------------------------------
PmIsDigit	PROC	near
	cmp	al, '0'
	jb	@F
	cmp	al, '9'
	ja	@F
	clc
	ret
@@:
	stc
	ret
PmIsDigit	ENDP


;-----------------------------------------------------------------------------
;
;	I:  AL = char.
;	O:  CF = 0 - alpha, CF = 1 - non-alpha.
;
;-----------------------------------------------------------------------------
PmIsAlpha	PROC	near
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
PmIsAlpha	ENDP


;-----------------------------------------------------------------------------
;
;	I:  AL = char.
;	O:  CF = 0 - alpha or digit, CF = 1 neither of.
;
;-----------------------------------------------------------------------------
PmIsAlNum	PROC	near
	call	PmIsAlpha
	jc	@F
	call	PmIsDigit
@@:
	ret
PmIsAlNum	ENDP


;-----------------------------------------------------------------------------
;
;	I:  AL = char
;	O:  CF = 0 if hex. digit, CF = 1 if not.
;
;-----------------------------------------------------------------------------
PmIsDigit16	PROC	near
	call	PmIsDigit
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
PmIsDigit16	ENDP


;-----------------------------------------------------------------------------
;
;	I:  AL = char
;	O:  AL = upcase(AL)
;
;-----------------------------------------------------------------------------
PmToUpper	PROC	near
	cmp	al, 'a'
	jb	@F
	cmp	al, 'z'
	ja	@F
	sub	al, 'a' - 'A'
@@:
	ret
PmToUpper	ENDP


;-----------------------------------------------------------------------------
;
;	I:  AL = char
;	O:  AL = lowcase(AL)
;
;-----------------------------------------------------------------------------
PmToLower	PROC	near
	cmp	al, 'A'
	jb	@F
	cmp	al, 'Z'
	ja	@F
	add	al, 'a' - 'A'
@@:
	ret
PmToLower	ENDP


;-----------------------------------------------------------------------------
;
;	I:  DS:ESI -> source 0-termin. string.
;	O:  EAX = string length.
;
;-----------------------------------------------------------------------------
PmStrLen	PROC	near	USES esi
	sub	eax, eax
find_0_loop:
	cmp	byte ptr ds:[esi][eax], 0
	jz	found_0
	inc	eax
	jmp	find_0_loop
found_0:
	ret
PmStrLen	ENDP


;-----------------------------------------------------------------------------
;
;	I:  DS:ESI -> source string (0 - terminated).
;	    ES:EDI -> dest string.
;	O:  nothing.
;
;	PROC	nearedure copies source string to destination. No checking on strings
; overlap is performed. (If second string overlaps first, function may fail.
; Terminating '\0'is included.
;
;-----------------------------------------------------------------------------
PmStrCpy	PROC	near USES ds es esi edi eax ecx
	push	ds
	push	esi
	call	PmStrLen
	pop	esi
	pop	ds
	inc	eax
	mov	ecx, eax
	shr	ecx, 2
	and	eax, 3
	cld
		rep	movsd
	mov	ecx, eax
		rep	movsb
	ret
PmStrCpy	ENDP


;----------------------------------------------------------------------------
;
;	I: DS:ESI -> 1st string (0 - terminated).
;	   ES:EDI -> 2nd string (0 - terminated).
;	   ECX = number of bytes to compare.
;	O: comparison result in flags.
;
;----------------------------------------------------------------------------
PUBLIC	PmStrNCmp
PmStrNCmp	PROC	near USES ecx esi edi
	cld
		repne	cmpsb
	ret
PmStrNCmp	ENDP


;----------------------------------------------------------------------------
;
;	I: DS:ESI -> source string (0-terminated)
;	   ES:EDI -> destination string (0-terminated).
;	O: result of comparison (in flags).
;
;----------------------------------------------------------------------------
PUBLIC	PmStrCmp
PmStrCmp	PROC	near USES eax ecx esi edi
	call	PmStrLen
	mov	ecx, eax
	push	ds
	push	esi
	mov	si, es
	mov	ds, si
	mov	esi, edi
	call	PmStrLen
	pop	esi
	pop	ds
	cmp	ecx, eax
	jne	@F

	cld
		repe	cmpsb
@@:
	ret
PmStrCmp	ENDP


;----------------------------------------------------------------------------
;
;	I:  DS:ESI -> String (0 - terminated).
;	    DL:DH = column: row
;	    BL = color
;
;	R:	PROTMODE.
;
;	Prints a color string.
;
;-----------------------------------------------------------------------------
PUBLIC	PmWriteStr32
PmWriteStr32	PROC	near	USES es eax ecx esi edi
	call	PmStrLen
	mov	ecx, eax
	mov	al, dh
	mul	Columns
	add	al, dl
	adc	ah, 0
	shl	eax, 1
	movzx	edi, ax
	mov	es, VBufTextSel
	mov	ah, bl
	cld
write_loop:
	lodsb
	stosw
	loop	write_loop
	ret
PmWriteStr32	ENDP


;-----------------------------------------------------------------------------
;
;	I: AL = char
;	    DL:DH = column: row
;	    BL = color
;	    ECX = number of repetitions.
;
;	Prints a color char.
;
;-----------------------------------------------------------------------------
PUBLIC	PmWriteChar32
PmWriteChar32	PROC	USES es eax ecx edi
	push	eax
	mov	al, dh
	mul	Columns
	add	al, dl
	adc	ah, 0
	shl	eax, 1
	movzx	edi, ax
	mov	es, VBufTextSel
	pop	eax
	mov	ah, bl
	cld
		rep	stosw

	ret
PmWriteChar32	ENDP


;-----------------------------------------------------------------------------
;
;	I: DS:ESI -> string (0-terminated)
;	    DH = row.
;	    BL = color
;	    AL:AH = start:end column.
;
;	R:	PROTMODE.
;
;	Prints a color centered string.
;
;-----------------------------------------------------------------------------
PUBLIC	PmWriteCenteredStr32
PmWriteCenteredStr32	PROC	USES eax ecx edx edi
; Print spaces.
	mov	ecx, eax
	call	PmStrLen
	xchg	eax, ecx	; ECX = str. len.

	mov	edi, ecx
	neg	cl
	add	cl, ah
	sub	cl, al
	inc	cl
	shr	cl, 1

	mov	dl, al
	call	PmWriteChar32

; Print string.
	add	dl, cl
	call	PmWriteStr32

; Print the rest of spaces.
	add	edx, edi
	add	ecx, edi
	neg	cl
	add	cl, ah
	sub	cl, al
	call	PmWriteChar32

	ret
PmWriteCenteredStr32	ENDP


;-----------------------------------------------------------------------------
;
;	I: DH = row
;	   AH = attribute.
;	O:
;
;-----------------------------------------------------------------------------
PUBLIC	PmClearRow
PmClearRow	PROC	near32	USES eax ecx edx
	xchg	eax, edx
	sub	al, al
	call	GotoXy
	xchg	eax, edx
	mov	al, ' '
	mov	ecx, 80
clear_loop:
	call	TtyChar
	dec	ecx
	jnz	clear_loop
	ret
PmClearRow	ENDP


;-----------------------------------------------------------------------------
;
;	I:  DS:ESI -> memory to receive the string.
;	    EAX - max string length (not including terminating 0).
;	    DL:DH = screen X:Y
;	    BL = attribute.
;
;	O:  Buffer filled
;	    EAX = string length.
;
;-----------------------------------------------------------------------------
PUBLIC	PmGetStr32
PmGetStr32	PROC	near32 USES ecx edx esi
LOCAL	X: byte, Y: byte, Char: byte
	mov	X, dl
	mov	Y, dh
	mov	ecx, eax		; ECX = max. length counter.

; Clear row.
	mov	ah, bl			; Attribute.
	call	PmClearRow

	mov	al, X
	mov	ah, Y
	call	GotoXy

	sub	edx, edx		; EDX = string length counter.
	cld
get_str:
	call	GetAsciiCode
	mov	Char, al

	mov	al, Char
	cmp	al, 13
	je	end_get_str

	test	al, al			; Zero ASCII code?
	jz	get_str

	cmp	al, 8			; Backspace?
	jne	normal_ascii

	test	edx, edx		; If at the beginning, go back.
	jz	get_str
; Delete last char.
	dec	X
	mov	al, X
	mov	ah, Y
	call	GotoXy
	mov	al, ' '
	mov	ah, NORMAL_ATTR
	call	TtyChar
	mov	al, X
	mov	ah, Y
	call	GotoXy
; Decrement all counters.
	dec	esi
	dec	edx
	inc	ecx
	jmp	get_str

normal_ascii:
	mov	[esi], al
	mov	ah, NORMAL_ATTR
	call	TtyChar
	inc	esi
	inc	edx
	inc	X
	dec	ecx
	jnz	get_str

end_get_str:
	mov	byte ptr [esi], 0
	mov	eax, edx
	ret
PmGetStr32	ENDP

CODE32	ENDS
END
