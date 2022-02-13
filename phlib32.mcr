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
; law, shall Vadim Drubetsky aka the Black Phantoms be liable for any special,
; incidental, indirect, or consequential damages (including but not limited to
; profit loss, business interruption, loss of business information, or any 
; other pecuniary loss) arising out of the use of or inability to use 
; Tripple-DOS, even if he has been advised of the possibility of such damages.
;
;=============================================================================

;=============================================================================
;
;	Macros file for Tripple-DOS project. Calling PHLIB32 functions.
;
;=============================================================================

.486p
	EXTRN	Field: byte

	EXTRN	PmWriteStr32: near32
	EXTRN	PmWriteCenteredStr32: near32
	EXTRN	PmHexToA: near32
	EXTRN	PmHex16ToA: near32
	EXTRN	PmHex32ToA: near32
	EXTRN	PmClearRow: near32

PM_PRINT_STR	MACRO	OffMsg, X, Y, Color
IFNB	<OffMsg>
	mov	esi, OffMsg
ENDIF
IFNB	<X>
	mov	dl, X
ENDIF
IFNB	<Y>
	mov	dh, Y
ENDIF
IFNB	<Color>
	mov	bl, Color
ENDIF
	call	PmWriteStr32
ENDM


PM_PRINT_CENTERED_STR	MACRO	OffMsg, StartX, EndX, Y, Color
IFNB	<OffMsg>
	mov	esi, OffMsg
ENDIF
IFNB	<StartX>
	mov	al, StartX
ENDIF
IFNB	<EndX>
	mov	ah, EndX
ENDIF
IFNB	<Y>
	mov	dh, Y
ENDIF
IFNB	<Color>
	mov	bl, Color
ENDIF
	call	PmWriteCenteredStr32
ENDM

PM_PRINT_HEX	MACRO	Number, X, Y, Color
	mov	edi, offset Field
IFNB	<Number>
	mov	al, Number
ENDIF
	call	PmHexToA
	mov	esi, edi
	PM_PRINT_STR	edi, X, Y, Color
ENDM


PM_PRINT_HEX16	MACRO	Number, X, Y, Color
	mov	edi, offset Field
IFNB	<Number>
	mov	ax, Number
ENDIF
	call	PmHex16ToA
	PM_PRINT_STR	edi, X, Y, Color
ENDM


PM_PRINT_HEX32	MACRO	Number, X, Y, Color
	mov	edi, offset Field
IFNB	<Number>
	mov	eax, Number
ENDIF
	call	PmHex32ToA
	PM_PRINT_STR	edi, X, Y, Color
ENDM


PM_PRINT_MSG	MACRO	OffMsg
	mov	dh, REPORT_ROW
	mov	ah, REPORT_ATTR
	call	PmClearRow
	PM_PRINT_STR	OffMsg, 0, REPORT_ROW, REPORT_ATTR
ENDM
