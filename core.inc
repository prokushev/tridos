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
;				CORE.INC
;				--------
;	Include file for Tripple-DOS core.
;
;=============================================================================

IFNDEF	__CORE_INC__
	__CORE_INC__	EQU	1

;
; Structures definitions.
;
REG_PACK	STRUC
	dwEflags	DD	?
	dwEip		DD	?
	dwEax		DD	?
	dwEcx		DD	?
	dwEdx		DD	?
	dwEbx		DD	?
	dwEsp		DD	?
	dwEbp		DD	?
	dwEsi		DD	?
	dwEdi		DD	?
REG_PACK	ENDS


GEN_REG_PACK	STRUC
	dwEax		DD	?
	dwEcx		DD	?
	dwEdx		DD	?
	dwEbx		DD	?
	dwEbp		DD	?
	dwEsi		DD	?
	dwEdi		DD	?
	dwEflags	DD	?
GEN_REG_PACK	ENDS


SREG_PACK	STRUC
	wCs		DW	?
	wSs		DW	?
	wEs		DW	?
	wDs		DW	?
	wFs		DW	?
	wGs		DW	?
SREG_PACK	ENDS


CALL_V86_INT	STRUC
	bInt		DB	?
	stRegs		REG_PACK	<>
	stSregs		SREG_PACK	<>
CALL_V86_INT	ENDS


;
;	Constants.
;
	REPORT_ROW	EQU	24
	REPORT_ATTR	EQU	7Ch
	VIDEO_MODE	EQU	3	; BIOS mode.
	TITLE_ROW	EQU	0
	PROMPT_ROW	EQU	1
	COMMAND_ROW	EQU	24	; Command propmt row.
	TITLE_ATTR	EQU	1Fh
	NORMAL_ATTR	EQU	07h
	ROWS_PER_SCR	EQU	25
	COLS_PER_ROW	EQU	80

	SLICE_TICKS	EQU	10	; ticks per slice.
	LOG_SIZE	EQU	100000h	; Memory to allocate for log.
	LOG_COM		EQU	2	; COM port used for logging.

ENDIF	; __CORE_INC__
