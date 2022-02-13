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
;				DEBUG.INC
;				---------
;	Definitions for kernel debugging procedures for Tripple-DOS.
;
;=============================================================================

	DBG_COMMAND_ROW		EQU	15
	DBG_COMMAND_ATTR	EQU	3

	Dbg_CMD_GO	EQU	1
	Dbg_CMD_TRACE	EQU	2
	Dbg_CMD_DUMP	EQU	3
	Dbg_CMD_QUIT	EQU	4
	Dbg_CMD_BOOT	EQU	5
	Dbg_CMD_BKPT	EQU	6
	Dbg_CMD_PHYS	EQU	7
	Dbg_CMD_LIN	EQU	8
	Dbg_CMD_I3HERE	EQU	9
	Dbg_CMD_LOG	EQU	10
	Dbg_CMD_ATTR	EQU	11

Dbg_COMMAND	STRUCT
	Command	DB	?
	Sel	DW	?
	Offs	DD	?
	Param1	DD	?
	Param2	DD	?
	Param3	DD	?
	Param4	DD	?
Dbg_COMMAND	ENDS
