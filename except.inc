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
;				EXCEPT.INC
;				----------
;	Exception handling data structures for Tripple-DOS.
;
;	For MASM v6.1x.
;
;=============================================================================

;
;	Exception stack structures. "Exception" here means error code on
; stack, "interrupt" - no error code.
;

EXC386_STACK	STRUC
	dwErrorCode	DD	?
	dwEip		DD	?
	wCs		DW	?
			DW	?
	dwEflags	DD	?
EXC386_STACK	ENDS


INT386_STACK	STRUC
	dwEip		DD	?
	wCs		DW	?
			DW	?
	dwEflags	DD	?
INT386_STACK	ENDS


INT386_PL_STACK	STRUC
	dwEip		DD	?
	wCs		DW	?
			DW	?
	dwEflags	DD	?
	dwFaultEsp	DD	?
	wFaultSs	DW	?
INT386_PL_STACK	ENDS


EXC386_PL_STACK	STRUC
	dwErrorCode	DD	?
	dwEip		DD	?
	wCs		DW	?
			DW	?
	dwEflags	DD	?
	dwFaultEsp	DD	?
	wFaultSs	DW	?
EXC386_PL_STACK	ENDS


INT386_VM_STACK	STRUC
	dwEip		DD	?
	wCs		DW	?
			DW	?
	dwEflags	DD	?
	dwFaultEsp	DD	?
	wFaultSs	DW	?
			DW	?
	wFaultEs	DW	?
			DW	?
	wFaultDs	DW	?
			DW	?
	wFaultFs	DW	?
			DW	?
	wFaultGs	DW	?
			DW	?
INT386_VM_STACK	ENDS


EXC386_VM_STACK	STRUC
	dwErrorCode	DD	?
	dwEip		DD	?
	wCs		DW	?
			DW	?
	dwEflags	DD	?
	dwFaultEsp	DD	?
	wFaultSs	DW	?
			DW	?
	wFaultEs	DW	?
			DW	?
	wFaultDs	DW	?
			DW	?
	wFaultFs	DW	?
			DW	?
	wFaultGs	DW	?
			DW	?
EXC386_VM_STACK	ENDS

; Exception traps max. number
	MAX_TRAPS		EQU	32
; Number of handled interrupts (including exceptions).
	HANDLED_INTS	EQU	30h
