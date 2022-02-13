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
;				DEBUG.ASM
;				---------
;
;	Kernel debugging procedures for Tripple-DOS.
;
;=============================================================================

.486p
	INCLUDE	DEBUG.INC
	INCLUDE	DEVICES.INC
	INCLUDE	DEF.INC
	INCLUDE	CORE.INC
	INCLUDE	X86.INC
	INCLUDE	PHLIB32.MCR

	EXTRN	AddExcTrap: near32
	EXTRN	GetScanCode: near32
	EXTRN	GetAsciiCode: near32
	EXTRN	PmGetStr32: near32
	EXTRN	PmClearRow: near32
	EXTRN	PmStrLen: near32
	EXTRN	PmAToHex: near32
	EXTRN	PmStrCmp: near32
	EXTRN	SaveClientRegs: near32
	EXTRN	RestoreClientRegs: near32
	EXTRN	DumpRegs: near32
	EXTRN	SimulateInt: near32
	EXTRN	PointerToLinear: near32
	EXTRN	LinearToPhysical: near32

	EXTRN	ExcEflags: dword
	EXTRN	ExcSeg: word
	EXTRN	ExcOffs: dword

	EXTRN	GdtBase: dword
	EXTRN	CurrLdtBase: dword

	EXTRN	QuitPm: byte
	EXTRN	Start32Esp: dword
	EXTRN	ExcNumber: dword


DATA	SEGMENT	PARA	PUBLIC	USE16	'DATA'
	PUBVAR		TraceFlag, DB, 0
	BkptFlag	DB	0
	MasterMask	DB	?
	SlaveMask	DB	?

; Flag is set when debugger is entered and removed at the IRET.
; Indicates that IRQ handler (kbd) is not to save registers.
	PUBVAR		DebugFlag, DB, 0

	DebuggeeRegs	REG_PACK	<>
	DebuggeeSregs	SREG_PACK	<>
	DbgEsp		DD		?	; Will keep ESP for callback.
	DbgExcNum	DD		?	; Keeps debug exception num.

	I3Here		DB		1
	DbgCommand	Dbg_COMMAND	<>

	CmdField	DB	100 DUP (?)

	CmdTbl		DB	"g", 0
			DB	"t", 0
			DB	"d", 0
			DB	"q", 0
			DB	"b", 0
			DB	"bp", 0
			DB	"phys", 0
			DB	"lin", 0
			DB	"i3here", 0
			DB	"log", 0
			DB	"attr", 0

	CmdValTbl	DB	Dbg_CMD_GO
			DB	Dbg_CMD_TRACE
			DB	Dbg_CMD_DUMP
			DB	Dbg_CMD_QUIT
			DB	Dbg_CMD_BOOT
			DB	Dbg_CMD_BKPT
			DB	Dbg_CMD_PHYS
			DB	Dbg_CMD_LIN
			DB	Dbg_CMD_I3HERE
			DB	Dbg_CMD_LOG
			DB	Dbg_CMD_ATTR
	DBG_COMMANDS	=	$ - offset CmdValTbl
DATA	ENDS

CODE32	SEGMENT	PARA	PUBLIC	USE32	'CODE'
ASSUME	CS:CODE32, DS:FLAT

;-----------------------------------------------------------------------------
;
;	Initializes debugging system (interrupt traps).
;
;-----------------------------------------------------------------------------
PUBLIC	InitDbg
InitDbg		PROC	near32
	
; Set Int3Callback callback.
	mov	eax, 03h		; Trap INT 3.
	mov	ecx, offset DebugCallback
	call	AddExcTrap

	mov	eax, 01h		; Trap INT 1.
	mov	ecx, offset DebugCallback
	call	AddExcTrap

	ret
InitDbg		ENDP


;-----------------------------------------------------------------------------
;
;	I:  DS:ESI -> command.
;
;	Parses debug command and fills command structure.
;
;	(!) DS = ES.
;	(!) Destroys all registers.
;
;-----------------------------------------------------------------------------
GetDbgCmd	PROC	USES eax ebx ecx edx esi edi
	mov	DbgCommand.Command, 0
	mov	DbgCommand.Sel, 0
	mov	DbgCommand.Offs, 0
	mov	DbgCommand.Param1, 0
	mov	DbgCommand.Param2, 0
	mov	DbgCommand.Param3, 0
	mov	DbgCommand.Param4, 0

; Get command string.
	mov	esi, offset CmdField
	mov	eax, 100
	mov	dh, COMMAND_ROW
	sub	dl, dl
	mov	bl, NORMAL_ATTR
	call	PmGetStr32

; Get command.
	call	skip_spaces

	mov	edi, esi
	call	skip_non_spaces
	mov	byte ptr [esi], 0	; Substitute ' ' with 0.

	mov	esi, offset CmdTbl
	mov	ecx, -DBG_COMMANDS
find_cmd:
	call	PmStrCmp
	je	cmd_found

	call	PmStrLen
	lea	esi, [esi+eax+1]
	inc	ecx
	jnz	find_cmd

no_cmd_err:
	mov	esi, edi
	call	skip_non_spaces
	mov	byte ptr [esi], ' '
	mov	DbgCommand.Command, -1
	jmp	end_get_cmd		; Error: no command found!

cmd_found:
	mov	esi, edi
	call	skip_non_spaces
	mov	byte ptr [esi], ' '
	mov	al, CmdValTbl[ ecx + DBG_COMMANDS ]
	mov	DbgCommand.Command, al
	call	skip_non_spaces

; Get address.
	call	skip_spaces

	mov	al, [esi]
	test	al, al
	jz	end_get_cmd

; Check if address is specified.
; If there is ':' separator, then address is specified.
	call	PmStrLen
	mov	edi, esi
	mov	ecx, eax
	mov	al, ':'
		repne	scasb
	jne	get_params		; No address - get parameters.

get_address:
; Get address. First get selector.
	mov	byte ptr [edi-1], 0	; Substitute ':' with 0.
	call	PmAToHex
	jc	wrong_prm_err

	mov	DbgCommand.Sel, ax
	mov	byte ptr [edi-1], ':'	; Return back ':'.
	mov	esi, edi
; Get offset.
	mov	edx, esi
	call	skip_non_spaces
	mov	byte ptr [esi], 0	; Substitute ' ' with 0.
	mov	edi, esi
	mov	esi, edx
	call	PmAToHex
	mov	esi, edi
	mov	byte ptr [esi], ' '	; Return back ' '.
	jc	wrong_prm_err

	mov	DbgCommand.Offs, eax
	call	skip_spaces

get_params:
; Get parameters.
	mov	ecx, offset DbgCommand.Param1
get_next_param:
	cmp	byte ptr [esi], 0
	je	end_get_cmd

	mov	edi, esi
	call	skip_non_spaces
	xchg	esi, edi
	mov	byte ptr [edi], 0
	call	PmAToHex
	mov	byte ptr [edi], ' '
	jnc	next_param_ok

wrong_prm_err:
	mov	DbgCommand.Command, -2		; Error: wrong params!
	jmp	end_get_cmd
next_param_ok:
	mov	esi, edi
	mov	[ecx], eax
	add	ecx, 4
	call	skip_spaces
	jmp	get_next_param

end_get_cmd:
	ret

;;
;; Local subroutines.
;;
skip_spaces:
	cmp	byte ptr [esi], 0
	je	end_skip
	cmp	byte ptr [esi], ' '
	ja	end_skip
	inc	esi
	jmp	skip_spaces

skip_non_spaces:
	cmp	byte ptr [esi], 0
	je	end_skip
	cmp	byte ptr [esi], ' '
	jna	end_skip
	inc	esi
	jmp	skip_non_spaces

end_skip:
	retn
GetDbgCmd	ENDP


;-----------------------------------------------------------------------------
;
;	Callback for INT 1 & 3.
;
;-----------------------------------------------------------------------------
PUBLIC	DebugCallback
DebugCallback	PROC
	mov	DbgEsp, esp
	mov	esp, DBG_STK

	mov	eax, ExcNumber
	mov	DbgExcNum, eax		; Save debug exception number.

; If exception 1 and TraceFlag = 0 then go to simulate instantly.
	cmp	DbgExcNum, 1
	je	@F

	cmp	I3Here, 0
	jne	handle_exc
	jmp	simulate
@@:
	cmp	BkptFlag, 0
	jne	handle_exc

	cmp	TraceFlag, 0
	je	simulate

handle_exc:
; Set in-debug flag
	mov	DebugFlag, 1

; Mask all interrupts for debug wait.
	in	al, PIC_MASTER_MASK
	mov	MasterMask, al
	in	al, PIC_SLAVE_MASK
	mov	SlaveMask, al

	mov	al, 0FFh
	out	PIC_MASTER_MASK, al
	out	PIC_SLAVE_MASK, al

; Save debuggee's registers.
	mov	ebx, offset DebuggeeRegs
	mov	ecx, offset DebuggeeSregs
	call	SaveClientRegs

regs_saved:
; Clear trace flag.
	mov	TraceFlag, 0

; Dump registers.
	call	DumpRegs

key_loop:
	call	GetDbgCmd
	mov	dh, DBG_COMMAND_ROW
	mov	ah, DBG_COMMAND_ATTR
	call	PmClearRow
	mov	al, DbgCommand.Command

	cmp	al, Dbg_CMD_GO
	jne	trace?
; 'g' key.
	jmp	go_on

trace?:
	cmp	al, Dbg_CMD_TRACE
	jne	dump?
; 't' key.
	mov	TraceFlag, 1
	jmp	go_on

dump?:
	cmp	al, Dbg_CMD_DUMP
	jne	bkpt?

; 'd' key.
	mov	si, DbgCommand.Sel
	mov	edi, DbgCommand.Offs
	mov	ebx, DebuggeeRegs.dwEflags
	call	PointerToLinear

	mov	esi, eax
	mov	ecx, DbgCommand.Param1
; If number of bytes not specified, dump 16 bytes.
	test	ecx, ecx
	jnz	@F

	mov	ecx, 16
@@:

; For dump purposes disable breakpoints.
	mov	eax, dr7
	push	eax
	sub	eax, eax
	mov	dr7, eax

	sub	edx, edx
	mov	dh, DBG_COMMAND_ROW
	mov	bl, DBG_COMMAND_ATTR
dump_loop:
	push	ecx
	push	esi
	PM_PRINT_HEX	fs:[esi]
	pop	esi
	pop	ecx

	inc	esi
	add	dl, 3
	cmp	dl, 80
	jb	@F
	sub	dl, dl
	inc	dh
@@:
	dec	ecx
	jnz	dump_loop

; Restore DR7.
	pop	eax
	mov	dr7, eax

	jmp	key_loop

bkpt?:
	cmp	al, Dbg_CMD_BKPT
	jne	phys?
; 'bp' command.
	mov	si, DbgCommand.Sel
	mov	edi, DbgCommand.Offs
	mov	ebx, DebuggeeRegs.dwEflags
	call	PointerToLinear

	mov	dr0, eax	; Set breakpoint address.

	mov	eax, 202h	; Global enable BKPT #0 & global exact bkpt.
	mov	ecx, DbgCommand.Param1
	and	ecx, 3		; Param1 = bkpt type: 0 = exec, 1 = write
				; 2 = I/O, 3 = read/write.
	shl	ecx, 16
	or	eax, ecx

	mov	ecx, DbgCommand.Param2
	and	ecx, 3		; Param2 = bkpt length: 0 = byte, 1 = word
				; 2 = undef, 3 = dword
	shl	ecx, 18
	or	eax, ecx
	mov	dr7, eax	; Breakpoint condition.

	mov	BkptFlag, 1
	jmp	key_loop

phys?:
	cmp	al, Dbg_CMD_PHYS
	jne	lin?
; 'phys' command.
	PM_PRINT_HEX32	DbgCommand.Param1, 0, DBG_COMMAND_ROW, DBG_COMMAND_ATTR
	mov	eax, DbgCommand.Param1
	call	LinearToPhysical
	PM_PRINT_HEX32	, 10, DBG_COMMAND_ROW, DBG_COMMAND_ATTR
	jmp	key_loop

lin?:
	cmp	al, Dbg_CMD_LIN
	jne	i3here?
; 'lin' command.
	mov	si, DbgCommand.Sel
	mov	edi, DbgCommand.Offs
	mov	ebx, DebuggeeRegs.dwEflags
	call	PointerToLinear
	PM_PRINT_HEX32	, 0, DBG_COMMAND_ROW, DBG_COMMAND_ATTR
	jmp	key_loop

i3here?:
	cmp	al, Dbg_CMD_I3HERE
	jne	quit?
	mov	eax, DbgCommand.Param1
	mov	I3Here, al
	jmp	key_loop

quit?:
	cmp	al, Dbg_CMD_QUIT
	jne	boot?
; 'q' key.
EXTRN	core_entry: near32
	mov	QuitPm, 1
	mov	esp, Start32Esp
	jmp	core_entry

boot?:
	cmp	al, Dbg_CMD_BOOT
	jne	log?
; 'b' key.
	mov	al, 0FEh
	out	64h, al
	cli
	hlt

log?:
	cmp	al, Dbg_CMD_LOG
	jne	attr?
	jmp	keys_done

attr?:
	cmp	al, Dbg_CMD_ATTR
	jne	keys_done
; 'attr' command - print segment access rights / attributes.
	mov	eax, DbgCommand.Param1
	mov	ebx, GdtBase
	test	eax, 4				; Which DT?
	jz	@F
	mov	ebx, CurrLdtBase
@@:
	and	eax, NOT 7

	pushad
	PM_PRINT_HEX	(Descriptor386 PTR fs:[ebx][eax]).Access, 0, DBG_COMMAND_ROW, DBG_COMMAND_ATTR
	popad

	mov	al, (Descriptor386 PTR fs:[ebx][eax]).LimitHigh20
	and	al, 0F0h

	pushad
	PM_PRINT_HEX	, 4, DBG_COMMAND_ROW, DBG_COMMAND_ATTR
	popad

keys_done:
	jmp	key_loop

go_on:
; Restore debuggee's registers.

	mov	ebx, offset DebuggeeRegs
	mov	ecx, offset DebuggeeSregs
	call	RestoreClientRegs

; Restore interrupt masks.
	mov	al, MasterMask
	out	PIC_MASTER_MASK, al
	mov	al, SlaveMask
	out	PIC_SLAVE_MASK, al

; Reset in-debug flag.
	mov	DebugFlag, 0

	cmp	DbgExcNum, 1
	je	end_dbg_exc

simulate:
	test	ExcEflags, FL_VM
	jnz	@F
	test	ExcSeg, 3
	jz	end_dbg_exc
@@:
	mov	eax, DbgExcNum
	call	SimulateInt
end_dbg_exc:

; Return.
	mov	esp, DbgEsp
	clc
	ret
DebugCallback	ENDP

CODE32	ENDS
END
