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
;				DEF.INC
;				-------
;
;	Global definitions.
;
;=============================================================================

; Public variable.
PUBVAR	MACRO	Name:REQ, Type:REQ, Init:REQ, Times
PUBLIC	Name
	Name	Type	Init
ENDM


; Repeat a datum in a structure initialization.
@REPEAT_DATUM	MACRO	Times, Value
LOCAL	OutStr
OutStr	TEXTEQU	<>
REPEAT	Times
	OutStr	CATSTR	OutStr, <Value>, <!,>
ENDM
EXITM	OutStr
ENDM
