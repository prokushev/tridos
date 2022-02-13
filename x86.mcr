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
;	Macros file for Tripple-DOS project.
;
;=============================================================================

;
; Add GDT segment.
;
ADD_GDT_SEGMENT	MACRO	Base, Limit, Access, Attr
IFNB	<Base>
	mov	eax, Base
ENDIF
	mov	ecx, Limit
	mov	dl, Access
IFNB	<Attr>
	mov	dh, Attr
ELSE
	sub	dh, dh
ENDIF
	call	AddGdtSegment
ENDM

;
; CPUID for assembler that doesn't support mnemonic.
;
IF	@Version	LT	611

CPUID		MACRO
	DB	0Fh, 0A2h	; CPUID instruction
ENDM

ENDIF
