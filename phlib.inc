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
;				PHLIB.INC
;				---------
;
;	Include file for source for Phantoms standard library.
;
;	Project:	INSP2
;	Copyright (c) White & Black Phantoms 1995, 1996.
;	Written by Black Phantom.
;	Start Project:		(approx.) ??/11/95
;	Last Update:		14/04/96
;
;=============================================================================

;
;  Definitions.
;
		NULL		EQU	0
		WRITE_HANDLE	EQU	40h
		STDOUT		EQU	1
		STDERR		EQU	2

		FALSE		EQU	0
		TRUE		EQU	not FALSE

		NULL		EQU	0
		CR		EQU	13
		NL		EQU	10
		SPACE		EQU	32
		TAB		EQU	9
		BACKSPACE	EQU	8

;
;  Procedures.
;
IFNDEF	WHITEANDBLACKPHANTOMS
	extrn	PrintString:near
	extrn	StrLen:near
	extrn	StrCpy:near
	extrn	HexToA:near
	extrn	Hex16ToA:near
	extrn	Hex32ToA:near
	extrn	LongUIToA:near
	extrn	AToLongUI:near
ENDIF
