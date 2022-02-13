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
;				EXCEPT.ASM
;				----------
;	Exception and interrupts handling routines and data for Tripple-DOS.
;
;	For MASM v6.1x.
;
;=============================================================================

CODE	SEGMENT	PARA	PUBLIC	USE16	'CODE'
ASSUME	CS:CODE, DS:DATA
.486p
;-----------------------------------------------------------------------------
;
;	Setup IDT (load IDTR).
;
;-----------------------------------------------------------------------------
PUBLIC	SetupIdt
SetupIdt	PROC	near
	sub	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, IDT_START
	mov	Idt.Base, eax
	lidt	fword ptr Idt
	ret
SetupIdt	ENDP


;-----------------------------------------------------------------------------
;
;	Setup traps list. Traps are a queue of exception "trappers" -
; callbacks for the same CPU exceptions that will be called one-by-on (FIFO:
; first registrated - first called.
;	At the beginning all tail pointers are 0s (all FIFOs empty)
;
;-----------------------------------------------------------------------------
PUBLIC	SetupExcTraps
SetupExcTraps	PROC	near	USES es
	mov	eax, EXC_TRAPS
	mov	ExcTrapsListSeg, ax
	mov	es, ax
	shl	eax, 4
	mov	ExcTrapsList, eax

; Clear exception trap list.
	sub	di, di
	sub	eax, eax
	mov	ecx, HANDLED_INTS * MAX_TRAPS / 4
	cld
		rep	stosd

	ret
SetupExcTraps	ENDP


CODE	ENDS

	INCLUDE	EXCEPT.INC
	INCLUDE	X86.INC
	INCLUDE	DEVICES.INC
	INCLUDE	DEF.INC
	INCLUDE	CORE.INC
	INCLUDE	TASKMAN.INC
	INCLUDE	PHLIB32.MCR
	INCLUDE	DPMI.INC

	EXTRN	PointerToLinear: near32
	EXTRN	LinearToPhysical: near32
	EXTRN	SimulateInt: near32
	EXTRN	GetScanCode: near32
	EXTRN	core_start: near32
	EXTRN	NextTask: near32
	EXTRN	FocusToNextTask: near32
	EXTRN	StopTask: near32
	EXTRN	SwitchTask: near32

	EXTRN	DebugCallback: near32
	EXTRN	WriteLog: near32

	EXTRN	TickCount: dword
	EXTRN	TicksReport: dword

	EXTRN	KeyReady: byte
	EXTRN	KeyPressed: byte
	EXTRN	KeyExtCode: byte
	EXTRN	ShiftKeys: byte
	EXTRN	ShiftScanTbl: dword
	EXTRN	ShiftBitCode: byte
	EXTRN	KeyboardQ: byte
	EXTRN	KbdQHead: dword
	EXTRN	KbdQTail: dword
	EXTRN	TempScanCode: byte

	EXTRN	OsStartPage: dword

IFDEF	DEBUG_BUILD
	EXTRN	TraceFlag: byte
	EXTRN	DebugFlag: byte
ENDIF	; DEBUG_BUILD

	EXTRN	CurrentTask: dword
	EXTRN	CurrTaskPtr: dword
	EXTRN	ForegroundTask: dword
	EXTRN	FirstTask: dword
	EXTRN	NumOfTasks: dword
	EXTRN	VirtualIf: dword
	EXTRN	HddSema4Own: dword
	EXTRN	HddSema4: byte
	EXTRN	FddSema4Own: dword
	EXTRN	FddSema4: byte
	EXTRN	Com1: GenDevice
	EXTRN	Com2: GenDevice
	EXTRN	SystemTask: dword

	EXTRN	Start32Esp: dword

	EXTRN	SysPdb: dword
	EXTRN	Pdb: dword
	EXTRN	SysPdbLin: dword
	EXTRN	PdbLin: dword
	EXTRN	SysPagesCtl: dword
	EXTRN	PagesCtl: dword

	EXTRN	PmCallbackCs: word
	EXTRN	PmCallbackSs: word

	EXTRN	DpmiSrvAddr: dword

DATA	SEGMENT	PARA	PUBLIC	USE16	'DATA'
	RetAddr		DD	?
	HaltFlag	DB	0	; non-0 when exception is going to
					; halt.

	PUBVAR	VirtualIp, DD, ?	; VM Interrupts pending.
	PUBVAR	VirtualIsr, DD, ?	; Virtual PIC's ISR register.
	PUBVAR	VirtualImr, DD, ?	; Virtual PIC's IMR register.
	PUBVAR	IrqReported, DD, 0	; Bit mask of what IRQ are reported.
					; 1 means reported.
	PUBVAR	ExcTrapsListSeg, DW, ?	; Segment address for exceptions
					; traps list (array of FIFOs)
	PUBVAR	ExcTrapsList, DD, ?	; Linear address -"-
	PUBVAR	ExcTrapsTail, DD, 0
		DD	HANDLED_INTS - 1 DUP (0)	
				; 32 pointers to FIFOs tails (count of 
				; exception traps)

	TimeStr		DB	"xx:xx:xx", 0
	TimeClr		DB	0
	ExcStr		DB	"Exception:", 0
	AddrStr		DB	"Fault at:", 0
	HaltStr		DB	"The machine will halt", 0
	OpcodeStr	DB	"Opcode caused exception:", 0
	CrStr		DB	"CR0=xxxxxxxx CR2=xxxxxxxx CR3=xxxxxxxx", 0
	LdtStr		DB	"LDTR=xxxx", 0
	GdtStr		DB	"GDTR base=xxxxxxxx limit=xxxx", 0
	GpRegsStr	DB	"EAX=xxxxxxxx EBX=xxxxxxxx ECX=xxxxxxxx "
			DB	"EDX=xxxxxxxx ESI=xxxxxxxx EDI=xxxxxxxx", 0
	SRegsStr	DB	"DS=xxxx ES=xxxx FS=xxxx GS=xxxx", 0
	StkStr		DB	"SS:ESP=xxxx:xxxxxxxx EBP=xxxxxxxx", 0
	TaskFaultStr	DB	"Task # xxxxxxxx caused an exception. "
			DB	"Press any key to terminate it", 0

	InvPageStr	DB	"Linear address is invalid", 0
	DoubleHaltMsg	DB	"Double halt", 0
	DoubleFaultMsg	DB	"Double fault", 0

	ReportExcStr	DB	"Reporting an exception: "
	ReportIrqStr	DB	"Reporting an IRQ: "

	PUBVAR	Cpl0EspAdjust, DD, CPL0_STK_SIZE	; Adjustment for overlapped ints/exc.
	PUBVAR	ExcNumber, DD, ?	; Exception number
	ErrCodePresent	DD	?	; Error code present.

	PUBVAR	ExcCode		,DD,	?
	PUBVAR	ExcOffs		,DD,	?
	PUBVAR	ExcSeg		,DW,	?
				DW	0
	PUBVAR	ExcEflags	,DD,	?
	PUBVAR	ExcEax		,DD,	?
	PUBVAR	ExcEcx		,DD,	?
	PUBVAR	ExcEdx		,DD,	?
	PUBVAR	ExcEbx		,DD,	?
	PUBVAR	ExcEsp		,DD,	?
	PUBVAR	ExcEbp		,DD,	?
	PUBVAR	ExcEsi		,DD,	?
	PUBVAR	ExcEdi		,DD,	?
	PUBVAR	ExcDs		,DD,	?
	PUBVAR	ExcEs		,DD,	?
	PUBVAR	ExcFs		,DD,	?
	PUBVAR	ExcGs		,DD,	?
	PUBVAR	ExcSs		,DD,	?

IFDEF	DEBUG_BUILD
	DbgClientRegs	REG_PACK	<>
	DbgClientSregs	SREG_PACK	<>
ENDIF	; DEBUG_BUILD

	Idt		DTR	< IDT_SIZE, ? >

IDT_START	EQU	$
; Exceptions
	Gate386	< LOWWORD (offset DivisionBy0), CODE_32, 0, INT_386_ACCESS , 0 >
	Gate386	< LOWWORD (offset DebugExc), CODE_32, 0, INT_386_ACCESS or 60h, 0 >
	Gate386	< LOWWORD (offset Nmi), CODE_32, 0, INT_386_ACCESS , 0 >
	Gate386	< LOWWORD (offset Int3Exc), CODE_32, 0, INT_386_ACCESS or 60h, 0 >
	Gate386	< LOWWORD (offset Overflow), CODE_32, 0, INT_386_ACCESS , 0 >
	Gate386	< LOWWORD (offset BoundExc), CODE_32, 0, INT_386_ACCESS , 0 >
	Gate386	< LOWWORD (offset InvOpcode), CODE_32, 0, INT_386_ACCESS , 0 >
	Gate386	< LOWWORD (offset X87NotAvl), CODE_32, 0, INT_386_ACCESS , 0 >

PUBLIC	DoubleFaultEntry
DoubleFaultEntry	LABEL	Gate386
	Gate386	< 0, 0, 0, TASK_GATE_ACCESS , 0 >
;	Gate386	< LOWWORD (offset DoubleFault), CODE_32, 0, TASK_GATE_ACCESS , 0 >

	Gate386	< LOWWORD (offset Exception09), CODE_32, 0, INT_386_ACCESS , 0 >
	Gate386	< LOWWORD (offset InvTSS), CODE_32, 0, INT_386_ACCESS , 0 >
	Gate386	< LOWWORD (offset SegNotPresent), CODE_32, 0, INT_386_ACCESS , 0 >
	Gate386	< LOWWORD (offset StackFault), CODE_32, 0, INT_386_ACCESS , 0 >
	Gate386	< LOWWORD (offset GPExc), CODE_32, 0, INT_386_ACCESS , 0 >
	Gate386	< LOWWORD (offset PageFault), CODE_32, 0, INT_386_ACCESS , 0 >
	Gate386	< LOWWORD (offset Exception0F), CODE_32, 0, INT_386_ACCESS , 0 >
	Gate386	< LOWWORD (offset FPError), CODE_32, 0, INT_386_ACCESS , 0 >
	Gate386	< LOWWORD (offset AlignCheckExc), CODE_32, 0, INT_386_ACCESS , 0 >
	Gate386	< LOWWORD (offset Exception12), CODE_32, 0, INT_386_ACCESS , 0 >
	Gate386	< LOWWORD (offset Exception13), CODE_32, 0, INT_386_ACCESS , 0 >
	Gate386	< LOWWORD (offset Exception14), CODE_32, 0, INT_386_ACCESS , 0 >
	Gate386	< LOWWORD (offset Exception15), CODE_32, 0, INT_386_ACCESS , 0 >
	Gate386	< LOWWORD (offset Exception16), CODE_32, 0, INT_386_ACCESS , 0 >
	Gate386	< LOWWORD (offset Exception17), CODE_32, 0, INT_386_ACCESS , 0 >
	Gate386	< LOWWORD (offset Exception18), CODE_32, 0, INT_386_ACCESS , 0 >
	Gate386	< LOWWORD (offset Exception19), CODE_32, 0, INT_386_ACCESS , 0 >
	Gate386	< LOWWORD (offset Exception1A), CODE_32, 0, INT_386_ACCESS , 0 >
	Gate386	< LOWWORD (offset Exception1B), CODE_32, 0, INT_386_ACCESS , 0 >
	Gate386	< LOWWORD (offset Exception1C), CODE_32, 0, INT_386_ACCESS , 0 >
	Gate386	< LOWWORD (offset Exception1D), CODE_32, 0, INT_386_ACCESS , 0 >
	Gate386	< LOWWORD (offset Exception1E), CODE_32, 0, INT_386_ACCESS , 0 >
	Gate386	< LOWWORD (offset Exception1F), CODE_32, 0, INT_386_ACCESS , 0 >
; Hardware interrupts -- 20h - 27h ( IRQ 0 - 7 )
	Gate386	< LOWWORD (offset TimerInt), CODE_32, 0, INT_386_ACCESS , 0 >
	Gate386	< LOWWORD (offset KbdInt), CODE_32, 0, INT_386_ACCESS , 0 >
	Gate386	< LOWWORD (offset Irq2Int), CODE_32, 0, INT_386_ACCESS , 0 >
	Gate386	< LOWWORD (offset Irq3Int), CODE_32, 0, INT_386_ACCESS , 0 >
	Gate386	< LOWWORD (offset Irq4Int), CODE_32, 0, INT_386_ACCESS , 0 >
	Gate386	< LOWWORD (offset Irq5Int), CODE_32, 0, INT_386_ACCESS , 0 >
	Gate386	< LOWWORD (offset Irq6Int), CODE_32, 0, INT_386_ACCESS , 0 >
	Gate386	< LOWWORD (offset Irq7Int), CODE_32, 0, INT_386_ACCESS , 0 >
; Hardware interrupts -- 28h - 2Fh ( IRQ 8 - F )
	Gate386	< LOWWORD (offset Irq8Int), CODE_32, 0, INT_386_ACCESS , 0 >
	Gate386	< LOWWORD (offset Irq9Int), CODE_32, 0, INT_386_ACCESS , 0 >
	Gate386	< LOWWORD (offset IrqAInt), CODE_32, 0, INT_386_ACCESS , 0 >
	Gate386	< LOWWORD (offset IrqBInt), CODE_32, 0, INT_386_ACCESS , 0 >
	Gate386	< LOWWORD (offset IrqCInt), CODE_32, 0, INT_386_ACCESS , 0 >
	Gate386	< LOWWORD (offset IrqDInt), CODE_32, 0, INT_386_ACCESS , 0 >
	Gate386	< LOWWORD (offset IrqEInt), CODE_32, 0, INT_386_ACCESS , 0 >
	Gate386	< LOWWORD (offset IrqFInt), CODE_32, 0, INT_386_ACCESS , 0 >
IDT_SIZE	EQU	$ - IDT_START

DATA	ENDS


EXC_TRAPS	SEGMENT	PARA	PUBLIC	USE16	'BSS'
	DB	HANDLED_INTS * MAX_TRAPS * 4 DUP (?)
EXC_TRAPS	ENDS


CODE32	SEGMENT	PARA	PUBLIC	USE32	'CODE'
ASSUME	CS:CODE32, DS:FLAT


;-----------------------------------------------------------------------------
;
;	Adds an exception trap to a list.
;
;	I: EAX = exception number.
;	   ECX = offset (segment is CODE32)
;	O: CF = 0 ok
;	      = 1 FIFO is full (can't add)
;
;-----------------------------------------------------------------------------
PUBLIC	AddExcTrap
AddExcTrap	PROC	USES edx
	cmp	eax, HANDLED_INTS
	jb	chk_traps
	stc
	ret

chk_traps:
	cmp	ExcTrapsTail[eax * 4], MAX_TRAPS
	jb	add_trap
	stc
	ret

add_trap:
	mov	edx, eax
	shl	edx, 5
	add	edx, ExcTrapsTail[eax * 4]
	shl	edx, 2
	add	edx, ExcTrapsList
	mov	fs:[edx], ecx

	inc	ExcTrapsTail[eax * 4]

	clc
	ret
AddExcTrap	ENDP


;-----------------------------------------------------------------------------
;
;	Dumps all exception registers contents.
;
;-----------------------------------------------------------------------------
PUBLIC	DumpRegs
DumpRegs	PROC
	pop	RetAddr		; Get return address.

; Output exception string.
	PM_PRINT_STR	(offset ExcStr), 2, 5, 13h

; Print exception number.
	PM_PRINT_HEX32	ExcNumber, (3 + SIZEOF ExcStr)

; Print exception error code.
	cmp	ErrCodePresent, 0
	jz	code_printed

	PM_PRINT_HEX32	ExcCode, (16 + SIZEOF ExcStr)

code_printed:
; Print address message.
	PM_PRINT_STR	(offset AddrStr), 2, 6

; Print address of the fault instruction.
	mov	edi, offset Field
	mov	ax, ExcSeg
	call	PmHex16ToA
	add	edi, 4

	mov	byte ptr [edi], ':'
	inc	edi
	mov	eax, ExcOffs
	call	PmHex32ToA

	PM_PRINT_STR	(offset Field), (2 + SIZEOF AddrStr)

; Print Eflags.
	PM_PRINT_HEX32	ExcEflags, (17 + SIZEOF ExcStr)

; Print virtual IF.
	PM_PRINT_HEX32	VirtualIf, (32 + SIZEOF ExcStr)

IFDEF	DUMP_STACK
; Dump 10 words from stack.
	mov	ecx, 8
	mov	dh, 8
	mov	dl, 2

stack_dump_loop:
	pop	eax
	mov	edi, offset Field
	call	PmHex32ToA
	mov	esi, offset Field
	call	PmWriteStr32
	add	dl, 9
	dec	ecx
	jnz	stack_dump_loop
ENDIF	; DUMP_STACK

; Dump control registers.
	PM_PRINT_STR	(offset CrStr), 2, 9

; Print CR0.
	PM_PRINT_HEX32	cr0, 6
; Print CR2.
	PM_PRINT_HEX32	cr2, 19
; Print CR3.
	PM_PRINT_HEX32	cr3, 32

; Dump LDT.
	PM_PRINT_STR	(offset LdtStr), 2, 10
	sldt	ax
	PM_PRINT_HEX16	, 7
; Dump GDT.
	PM_PRINT_STR	(offset GdtStr), 20
	sub	esp, 8
	sgdt	[esp]
	mov	eax, [esp][2]
	PM_PRINT_HEX32	, 30
	mov	ax, [esp]
	PM_PRINT_HEX16	, 45
	add	esp, 8

; Dump general purpose registers.
	PM_PRINT_STR	(offset GpRegsStr), 2, 11

; Print EAX.
	PM_PRINT_HEX32	ExcEax, 6
; Print EBX.
	PM_PRINT_HEX32	ExcEbx, 19
; Print ECX.
	PM_PRINT_HEX32	ExcEcx, 32
; Print EDX.
	PM_PRINT_HEX32	ExcEdx, 45
; Print ESI.
	PM_PRINT_HEX32	ExcEsi, 58
; Print EDI.
	PM_PRINT_HEX32	ExcEdi, 71

; Dump segment registers.
	PM_PRINT_STR	(offset SRegsStr), 2, 12
; Print DS.
	PM_PRINT_HEX16	(word ptr ExcDs), 5
; Print ES.
	PM_PRINT_HEX16	(word ptr ExcEs), 13
; Print FS.
	PM_PRINT_HEX16	(word ptr ExcFs), 21
; Print GS.
	PM_PRINT_HEX16	(word ptr ExcGs), 29

; Dump stack (SS:ESP, EBP)
	PM_PRINT_STR	(offset StkStr), 2, 13
; Print GS.
	PM_PRINT_HEX16	(word ptr ExcSs), 9
; Print ESP.
	PM_PRINT_HEX32	ExcEsp, 14
; Print EBP.
	PM_PRINT_HEX32	ExcEbp, 27
	
; Dump faulting opcode (16 bytes)
	inc	dh
	mov	dl, 2
	mov	esi, offset OpcodeStr
	call	PmWriteStr32
	inc	dh
	mov	cx, FLAT_DS
	mov	fs, cx
	mov	si, ExcSeg
	mov	edi, ExcOffs
	mov	ebx, ExcEflags
	call	PointerToLinear
	mov	bl, 13h
	mov	ebp, eax		; fs: EBP+ECX point to fault. opcode
	sub	ecx, ecx

; Check if linear address of opcode is valid.
	mov	eax, ebp
	call	LinearToPhysical
	jnc	dump_opcode
	PM_PRINT_STR	(offset InvPageStr)
	jmp	end_dump_regs

dump_opcode:
	push	ecx
	mov	edi, offset Field
	mov	eax, fs:[ebp+ecx]
	call	PmHexToA
	mov	esi, offset Field
	call	PmWriteStr32
	add	dl, 3
	pop	ecx

	inc	ecx
	cmp	ecx, 16			; Dump 16 bytes.
	jb	dump_opcode

end_dump_regs:
	jmp	RetAddr
DumpRegs	ENDP


;-----------------------------------------------------------------------------
;
;	Calls exception or interrupt callbacks.
;
;	I:  EAX = exception number
;	O:  CF set/clear (clear = processed).
;
;-----------------------------------------------------------------------------
CallCallbacks	PROC	USES eax ecx edx
	cmp	ExcTrapsTail[eax*4], 0	; If no callbacks, STC and RET
	je	not_handled

call_callbacks:
	sub	ecx, ecx
	mov	edx, eax
	shl	edx, 5 + 2
	add	edx, ExcTrapsList

next_callback:
	cmp	ecx, ExcTrapsTail[eax*4]
	jnb	not_handled

	push	es
	pushad
	call	dword ptr fs:[edx][ecx*4]	; Callback prepares all registers
					; for returning to caller or returns
					; CF = 1
	popad
	pop	es
	jnc	handled

	inc	ecx
	jmp	next_callback

not_handled:
	stc
handled:
	ret
CallCallbacks	ENDP


;-----------------------------------------------------------------------------
;
;	Contains all exceptions handlers entry points.
;
;	Convention: entry point sets AX = exception number and ECX to number
;	of bytes of error code on stack.
;
;-----------------------------------------------------------------------------
ExcHandler	PROC
DivisionBy0::
	push	0
	call	GetClientRegs
	mov	ExcNumber, 0
	jmp	HandleExc

DebugExc::

IFDEF	DEBUG_BUILD
	test	(INT386_STACK PTR [esp]). dwEflags, FL_VM
	jnz	@F
	test	(INT386_STACK PTR [esp]). wCs, 3
	jnz	@F

	call	SaveDbgClientRegs
@@:
ENDIF	; DEBUG_BUILD

	push	0
	call	GetClientRegs
	mov	ExcNumber, 1
	jmp	HandleExc

Nmi::
	push	0
	call	GetClientRegs
	mov	ExcNumber, 2
	jmp	HandleExc

Int3Exc::

IFDEF	DEBUG_BUILD
	test	(INT386_STACK PTR [esp]). dwEflags, FL_VM
	jnz	@F
	test	(INT386_STACK PTR [esp]). wCs, 3
	jnz	@F

	call	SaveDbgClientRegs
@@:
ENDIF	; DEBUG_BUILD

	push	0
	call	GetClientRegs
	mov	ExcNumber, 3
	jmp	HandleExc

Overflow::
	push	0
	call	GetClientRegs
	mov	ExcNumber, 4
	jmp	HandleExc

BoundExc::
	push	0
	call	GetClientRegs
	mov	ExcNumber, 5
	jmp	HandleExc

InvOpcode::
	push	0
	call	GetClientRegs
	mov	ExcNumber, 6
	jmp	HandleExc

X87NotAvl::
	push	0
	call	GetClientRegs
	mov	ExcNumber, 7
	jmp	HandleExc

PUBLIC	DoubleFault
DoubleFault::
nop
nop
nop
nop
nop

	PM_PRINT_MSG (offset DoubleFaultMsg)
	cli
	hlt

	push	4
	call	GetClientRegs
	mov	ExcNumber, 8
	jmp	HandleExc

Exception09::
	push	0
	call	GetClientRegs
	mov	ExcNumber, 9
	jmp	HandleExc

InvTSS::
	push	4
	call	GetClientRegs
	mov	ExcNumber, 0Ah
	jmp	HandleExc

SegNotPresent::
	push	4
	call	GetClientRegs
	mov	ExcNumber, 0Bh
	jmp	HandleExc

StackFault::
	push	4
	call	GetClientRegs
	mov	ExcNumber, 0Ch
	jmp	HandleExc

;-----------------------------------------------------------------------------
;
;	GP exception. Used for emulation.
;
;-----------------------------------------------------------------------------
GPExc::
	push	4
	call	GetClientRegs
	mov	ExcNumber, 0Dh
	jmp	HandleExc

PageFault::
	push	4
	call	GetClientRegs
	mov	ExcNumber, 0Eh
	jmp	HandleExc

Exception0F::
	push	0
	call	GetClientRegs
	mov	ExcNumber, 0Fh
	jmp	HandleExc

FPError::
	push	0
	call	GetClientRegs
	mov	ExcNumber, 10h
	jmp	HandleExc

AlignCheckExc::
	push	0
	call	GetClientRegs
	mov	ExcNumber, 11h
	jmp	HandleExc

Exception12::
	push	0
	call	GetClientRegs
	mov	ExcNumber, 12h
	jmp	HandleExc

Exception13::
	push	0
	call	GetClientRegs
	mov	ExcNumber, 13h
	jmp	HandleExc

Exception14::
	push	0
	call	GetClientRegs
	mov	ExcNumber, 14h
	jmp	HandleExc

Exception15::
	push	0
	call	GetClientRegs
	mov	ExcNumber, 15h
	jmp	HandleExc

Exception16::
	push	0
	call	GetClientRegs
	mov	ExcNumber, 16h
	jmp	HandleExc

Exception17::
	push	0
	call	GetClientRegs
	mov	ExcNumber, 17h
	jmp	HandleExc

Exception18::
	push	0
	call	GetClientRegs
	mov	ExcNumber, 18h
	jmp	HandleExc

Exception19::
	push	0
	call	GetClientRegs
	mov	ExcNumber, 19h
	jmp	HandleExc

Exception1A::
	push	0
	call	GetClientRegs
	mov	ExcNumber, 1Ah
	jmp	HandleExc

Exception1B::
	push	0
	call	GetClientRegs
	mov	ExcNumber, 1Bh
	jmp	HandleExc

Exception1C::
	push	0
	call	GetClientRegs
	mov	ExcNumber, 1Ch
	jmp	HandleExc

Exception1D::
	push	0
	call	GetClientRegs
	mov	ExcNumber, 1Dh
	jmp	HandleExc

Exception1E::
	push	0
	call	GetClientRegs
	mov	ExcNumber, 1Eh
	jmp	HandleExc

Exception1F::
	push	0
	call	GetClientRegs
	mov	ExcNumber, 1Fh
	jmp	HandleExc

;
; HandleExc CPU upon the exception
;
HandleExc:

;IFDEF	LOG_DPMI
IF 0
	pushad

	cmp	NumOfTasks, 0
	je	@F

	cmp	SystemTask, 1
	je	@F

	mov	eax, CurrTaskPtr
	cmp	(DosTask PTR fs:[eax]).TaskLdt, 0
	je	@F

; Log exception event.
	mov	esi, offset ExcStr
	mov	ecx, SIZEOF ExcStr
	call	WriteLog

	mov	eax, ExcNumber
	mov	edi, offset Field
	call	PmHex32ToA
	mov	Field[8], ' '
	mov	eax, offset Field
	mov	ecx, 9
	mov	esi, offset Field
	call	WriteLog

	mov	eax, ExcCode
	mov	edi, offset Field
	call	PmHex32ToA
	mov	Field[8], ' '
	mov	eax, offset Field
	mov	ecx, 9
	mov	esi, offset Field
	call	WriteLog

	mov	esi, offset AddrStr
	mov	ecx, SIZEOF AddrStr
	call	WriteLog

	mov	ax, ExcSeg
	mov	edi, offset Field
	call	PmHex16ToA
	mov	Field[4], ':'
	mov	eax, offset Field
	mov	ecx, 5
	mov	esi, offset Field
	call	WriteLog

	mov	eax, ExcOffs
	mov	edi, offset Field
	call	PmHex32ToA
	mov	Field[8], ' '
	mov	eax, offset Field
	mov	ecx, 9
	mov	esi, offset Field
	call	WriteLog

	mov	eax, ExcEflags
	mov	edi, offset Field
	call	PmHex32ToA
	mov	Field[8], 13
	mov	Field[9], 10
	mov	eax, offset Field
	mov	ecx, 10
	mov	esi, offset Field
	call	WriteLog
@@:
	popad
ENDIF	; LOG_DPMI

	mov	eax, ExcNumber
	call	CallCallbacks
	jnc	SetClientRegs		; Exception handled

; Exception is not handled by system. Call DPMI handlers. Call only for
; PM CPL 3 exceptions.
	test	ExcEflags, FL_VM
	jz	pm_exc

; An exception occurred in VM. For exceptions 0, 1, 3, 4 call an interrupt.
	mov	eax, ExcNumber
	test	eax, eax
	je	call_vm_int
	cmp	eax, 1
	je	call_vm_int
	cmp	eax, 3
	je	call_vm_int
	cmp	eax, 4
	jne	unhandled_dump

call_vm_int:
IFNDEF	DEBUG_BUILD
	call	SimulateInt
	jmp	SetClientRegs
ENDIF

pm_exc:
	test	ExcSeg, 3
	jz	dump_and_halt
; If DPMI not initialized, go to unhandled dump.
	mov	eax, CurrTaskPtr
	cmp	(DosTask PTR fs:[eax]).TaskLdt, 0
	je	unhandled_dump

; If exception handler was installed, jump to it.
	mov	ebx, (DosTask PTR fs:[eax]).DpmiPmExcs
	mov	ecx, ExcNumber
	cmp	dword ptr fs:[ebx+ecx*8][4], 0
	jne	redir_exc

; Exceptions 0..5 and 7 are redirected as interrupts.
	mov	ecx, ExcNumber
redir_as_int:
	mov	ebx, (DosTask PTR fs:[eax]).DpmiPmInts
	cmp	ecx, 7
	ja	unhandled_dump
	cmp	ecx, 6
	je	unhandled_dump
	cmp	dword ptr fs:[ebx+ecx*8][4], 0
	je	unhandled_dump		; Interrupt handler not installed.

	mov	eax, ecx
EXTRN	SimulatePmInt: near32
	call	SimulatePmInt
	jmp	SetClientRegs

redir_exc:

IFDEF	LOG_DPMI
	pushad
	mov	eax, ecx
	PRINT_LOG	ReportExcStr

	mov	edi, offset Field
	call	PmHex32ToA
	mov	Field[8], ' '
	mov	eax, offset Field
	mov	ecx, 9
	mov	esi, offset Field
	call	WriteLog

	mov	eax, ExcCode
	mov	edi, offset Field
	call	PmHex32ToA
	mov	Field[8], 13
	mov	Field[9], 10
	mov	eax, offset Field
	mov	ecx, 10
	mov	esi, offset Field
	call	WriteLog

	popad
	LOG_STATE
ENDIF

; Push exception stack frame on locked DPMI stack.
	test	(DosTask PTR fs:[eax]).TaskFlags, TASK_32BIT
	jz	task_16bit

; 32-bit task.
; Push far return address.
	mov	edx, (DosTask PTR fs:[eax]).DpmiPmStack
	sub	edx, 20h
	mov	dword ptr fs:[edx],  PM_RET_TRAP_OFFS
	mov	si, PmCallbackCs
	mov	fs:[edx][4],  si

; Push error code.
	mov	esi, ExcCode
	mov	fs:[edx][8], esi

; Push excetion location, flags and SS:ESP.
	mov	esi, ExcOffs
	mov	fs:[edx][0Ch], esi
	mov	si, ExcSeg
	mov	fs:[edx][10h], si

	mov	esi, ExcEflags
	and	esi, NOT FL_IF
	or	esi, VirtualIf
	mov	fs:[edx][14h], esi

	mov	esi, ExcEsp
	mov	fs:[edx][18h], esi
	mov	esi, ExcSs
	mov	fs:[edx][1Ch], si

	mov	edx, (DosTask PTR fs:[eax]).DpmiPmEsp
	sub	edx, 20

	jmp	set_callback_addr

; 16-bit task. Adjust PM locked stack.
task_16bit:
; Push far return address.
	mov	edx, (DosTask PTR fs:[eax]).DpmiPmStack
	sub	edx, 10h
	mov	word ptr fs:[edx],  PM_RET_TRAP_OFFS
	mov	si, PmCallbackCs
	mov	fs:[edx][2],  si

; Push error code.
	mov	esi, ExcCode
	mov	fs:[edx][4], si
; Push exception location, flags and SS:ESP.
	mov	esi, ExcOffs
	mov	fs:[edx][6], si
	mov	si, ExcSeg
	mov	fs:[edx][8], si

	mov	esi, ExcEflags
	and	esi, NOT FL_IF
	or	esi, VirtualIf
	mov	fs:[edx][0Ah], si

	mov	esi, ExcEsp
	mov	fs:[edx][0Ch], si
	mov	esi, ExcSs
	mov	fs:[edx][0Eh], si

	mov	edx, (DosTask PTR fs:[eax]).DpmiPmEsp
	sub	edx, 10

set_callback_addr:
; Set callback address.
	mov	esi, fs:[ebx+ecx*8]
	mov	ExcOffs, esi
	mov	esi, fs:[ebx+ecx*8][4]
	mov	ExcSeg, si
	and	VirtualIf, NOT FL_IF		; Interrupts disabled.

; Set new SS:ESP.
	mov	si, PmCallbackSs
	mov	word ptr ExcSs, si
	mov	ExcEsp, edx

LOG_STATE	1

	jmp	SetClientRegs

PUBLIC	handled_exc
handled_exc::
; Restore return address and stack.
	mov	eax, CurrTaskPtr
	test	(DosTask PTR fs:[eax]).TaskFlags, TASK_32BIT
	jz	@F

; Restore 32-bit task.
	RESTORE_32BIT_EXC_STACK
	jmp	SetClientRegs

; Restore 16-bit task.
@@:
	RESTORE_16BIT_EXC_STACK
	jmp	SetClientRegs

PUBLIC	unhandled_exc
unhandled_exc::

; Get exception number from DPMI trap.
	mov	si, ExcSeg
	mov	edi, ExcOffs
	mov	ebx, ExcEflags
	call	PointerToLinear
	movzx	esi, byte ptr fs:[eax][6]
int 3
	mov	ExcNumber, esi

;
;	Restore original exception parameters from locked stack.
; Assumed that a program jumped to default exception handler (i.e. program
; termination) without changing locked stack. Otherwise diagnostic won't
; be good.
;
	mov	eax, CurrTaskPtr
	test	(DosTask PTR fs:[eax]).TaskFlags, TASK_32BIT
	jnz	@F

; 16 bit locked stack.
	RESTORE_16BIT_EXC_STACK
	mov	ecx, ExcNumber
	jmp	redir_as_int
@@:
	RESTORE_32BIT_EXC_STACK
	mov	ecx, ExcNumber
	jmp	redir_as_int

unhandled_dump:
IFDEF	DEBUG_BUILD
	call	DebugCallback		; DEBUG.
ENDIF	; DEBUG_BUILD

;	call	DumpRegs

	cmp	NumOfTasks, 0
	je	dump_and_halt

; Task caused an exception. Press any key and terminate it.
	PM_PRINT_MSG	(offset TaskFaultStr)
	PM_PRINT_HEX32	CurrentTask, 7, REPORT_ROW, REPORT_ATTR

IFDEF	DEBUG_BUILD
	mov	DebugFlag, 1
ENDIF	; DEBUG_BUILD

	call	GetScanCode		; Wait for key pressed.

IFDEF	DEBUG_BUILD
	mov	DebugFlag, 0
ENDIF	; DEBUG_BUILD

	sub	al, al			; Enable all interrupts but kbd.
	out	PIC_MASTER_MASK, al
	out	PIC_SLAVE_MASK, al

	mov	eax, CurrentTask
	call	StopTask
	cmp	NumOfTasks, 0
	je	@F
	jmp	SetClientRegs

@@:
; Jump to system task.
	mov	esp, Start32Esp
	jmp	core_start

dump_and_halt:
IFDEF	DEBUG_BUILD
	call	DebugCallback		; DEBUG.
ENDIF	; DEBUG_BUILD

	cmp	HaltFlag, 0
	je	dump_on
	PM_PRINT_MSG	(offset DoubleHaltMsg)
	cli
	hlt

dump_on:
	mov	HaltFlag, 1
	call	DumpRegs

; Print halt message.
	PM_PRINT_STR	(offset HaltStr), 2, 7

; Halt CPU.
	cli
	hlt

ExcHandler	ENDP


;-----------------------------------------------------------------------------
;
;	Saves debuggee's client registers.
;
;	Called from inconsistent context.
;
;-----------------------------------------------------------------------------
SaveDbgClientRegs	PROC	USES ds es eax ebx ecx
IFDEF	DEBUG_BUILD
; Set DS -> data segment.
	push	INIT_DS
	pop	ds

; Set ES -> data segment
	push	INIT_DS
	pop	es

; Save debuggee's client regs.
	mov	ebx, offset DbgClientRegs
	mov	ecx, offset DbgClientSregs
	call	SaveClientRegs

	ret
ENDIF	;DEBUG_BUILD
SaveDbgClientRegs	ENDP


;-----------------------------------------------------------------------------
;
;	Saves debuggee's client registers.
;
;	Called from inconsistent context.
;
;-----------------------------------------------------------------------------
RestoreDbgClientRegs	PROC	USES ds es eax ebx ecx

IFDEF	DEBUG_BUILD
; Set DS -> data segment.
	push	INIT_DS
	pop	ds

; Set ES -> data segment
	push	INIT_DS
	pop	es

; Save debuggee's client regs.
	mov	ebx, offset DbgClientRegs
	mov	ecx, offset DbgClientSregs
	call	RestoreClientRegs

	ret
ENDIF	;DEBUG_BUILD

RestoreDbgClientRegs	ENDP


;-----------------------------------------------------------------------------
;
;	Saves client registers in REG_PACK and SREG_PACK structure.
;
;	I:	ES:EBX -> REG_PACK
;		ES:ECX -> SREG_PACK
;
;-----------------------------------------------------------------------------
PUBLIC	SaveClientRegs
SaveClientRegs	PROC
PUSHCONTEXT	ASSUMES
ASSUME	ebx: PTR REG_PACK
ASSUME	ecx: PTR SREG_PACK

; Save general purpose registers, EIP and Eflags.
	mov	eax, ExcOffs
	mov	es:[ebx].dwEip, eax
	mov	eax, ExcEflags
	mov	es:[ebx].dwEflags, eax
	mov	eax, ExcEax
	mov	es:[ebx].dwEax, eax
	mov	eax, ExcEbx
	mov	es:[ebx].dwEbx, eax
	mov	eax, ExcEcx
	mov	es:[ebx].dwEcx, eax
	mov	eax, ExcEdx
	mov	es:[ebx].dwEdx, eax
	mov	eax, ExcEsi
	mov	es:[ebx].dwEsi, eax
	mov	eax, ExcEdi
	mov	es:[ebx].dwEdi, eax
	mov	eax, ExcEsp
	mov	es:[ebx].dwEsp, eax
	mov	eax, ExcEbp
	mov	es:[ebx].dwEbp, eax

; Save segment regsters.
	movzx	eax, ExcSeg
	mov	es:[ecx].wCs, ax
	mov	eax, ExcDs
	mov	es:[ecx].wDs, ax
	mov	eax, ExcEs
	mov	es:[ecx].wEs, ax
	mov	eax, ExcFs
	mov	es:[ecx].wFs, ax
	mov	eax, ExcGs
	mov	es:[ecx].wGs, ax
	mov	eax, ExcSs
	mov	es:[ecx].wSs, ax

	ret
POPCONTEXT	ASSUMES
SaveClientRegs	ENDP


;-----------------------------------------------------------------------------
;
;	Restore client registers from REG_PACK and SREG_PACK structure.
;
;	I:	ES:EBX -> REG_PACK
;		ES:ECX -> SREG_PACK
;
;-----------------------------------------------------------------------------
PUBLIC	RestoreClientRegs
RestoreClientRegs	PROC
PUSHCONTEXT	ASSUMES
ASSUME	ebx: PTR REG_PACK
ASSUME	ecx: PTR SREG_PACK

; Restore general purpose registers, EIP and Eflags.
	mov	eax, es:[ebx].dwEip
	mov	ExcOffs, eax
	mov	eax, es:[ebx].dwEflags
	mov	ExcEflags, eax
	mov	eax, es:[ebx].dwEax
	mov	ExcEax, eax
	mov	eax, es:[ebx].dwEbx
	mov	ExcEbx, eax
	mov	eax, es:[ebx].dwEcx
	mov	ExcEcx, eax
	mov	eax, es:[ebx].dwEdx
	mov	ExcEdx, eax
	mov	eax, es:[ebx].dwEsi
	mov	ExcEsi, eax
	mov	eax, es:[ebx].dwEdi
	mov	ExcEdi, eax
	mov	eax, es:[ebx].dwEsp
	mov	ExcEsp, eax
	mov	eax, es:[ebx].dwEbp
	mov	ExcEbp, eax

; Restore segment regsters.
	movzx	eax, es:[ecx].wCs
	mov	ExcSeg, ax
	movzx	eax, es:[ecx].wDs
	mov	ExcDs, eax
	movzx	eax, es:[ecx].wEs
	mov	ExcEs, eax
	movzx	eax, es:[ecx].wFs
	mov	ExcFs, eax
	movzx	eax, es:[ecx].wGs
	mov	ExcGs, eax
	movzx	eax, es:[ecx].wSs
	mov	ExcSs, eax

	ret
POPCONTEXT	ASSUMES
RestoreClientRegs	ENDP


;-----------------------------------------------------------------------------
;
;	Gets client's registers.
;
;	I:	ESP+4 - error code flag.
;	O:
;
;-----------------------------------------------------------------------------
PUBLIC	GetClientRegs
GetClientRegs	PROC

; Recover possible DS corruption.
	push	ds
	push	INIT_DS
	pop	ds
	pop	ExcDs			; Will be further altered if fault CS
					; PL > 0.

	pop	RetAddr			; Get return address from stack.

	cmp	dword ptr [esp], 0	; Error code present?
	pop	ErrCodePresent		; Get error code indicator from stack.
	je	save_regs
	pop	ExcCode			; Get error code.

save_regs:
; Save CPU regs as were at the exception time.
	mov	ExcEax, eax
	mov	ExcEbx, ebx
	mov	ExcEcx, ecx
	mov	ExcEdx, edx
	mov	ExcEbp, ebp
	mov	ExcEsi, esi
	mov	ExcEdi, edi

get_exc_offs:
; Pop Eflags and return address.
	pop	ExcOffs
	pop	esi
	mov	ExcSeg, si
	pop	ExcEflags

; Recover segment registers.
	test	ExcEflags, FL_VM
	jz	get_pmode_sregs

	pop	ExcEsp
	pop	ExcSs
	pop	ExcEs
	pop	ExcDs
	pop	ExcFs
	pop	ExcGs
	jmp	done

get_pmode_sregs:
	mov	ExcEs, es
	mov	ExcFs, fs
	mov	ExcGs, gs
	test	ExcSeg, 3	; Check if faulting CS was at PL > 0
	jnz	pop_stk_regs

	mov	ExcEsp, esp	; No stack switch.
	mov	ExcSs, ss

;	mov	esp, EXC_STK
	jmp	done

pop_stk_regs:
	pop	ExcEsp
	pop	ExcSs

done:
; Adjust ESP.
;	sub	esp, Cpl0EspAdjust
;	add	Cpl0EspAdjust, CPL0_STK_SIZE

; Set segment registers context.
	mov	ecx, INIT_DS
	mov	es, cx
	mov	ecx, FLAT_DS
	mov	fs, cx
	mov	gs, cx

	jmp	RetAddr		; Return to gotten return address.
GetClientRegs	ENDP


;-----------------------------------------------------------------------------
;
;	Report highest privilege pending IRQ to client.
;
;	I:
;	O:
;
;-----------------------------------------------------------------------------
ReportIrq	PROC
; If no interrupts are pending, return
	cmp	VirtualIp, 0
	jne	@F
	ret

@@:
; If interrupted address is at DPMI service page, return
	mov	si, ExcSeg
	mov	edi, ExcOffs
	mov	ebx, ExcEflags
	call	PointerToLinear
	mov	ecx, eax
	and	ecx, NOT 0FFFh
;	cmp	ecx, DPMI_SERVICE_PAGE
	cmp	ecx, DpmiSrvAddr
	jne	@F

;int 3
;	mov	byte ptr fs:[eax][6], 3
;extrn	DpmiCallbackRet: near32
;	call	DpmiCallbackRet
;	test	ExcEflags, FL_VM
;	jz	ret000
;ret000:
	ret

@@:
; Isolate IRQ that's going to be serviced in EAX.
	mov	eax, VirtualIp
	lea	edx, [eax-1]
	and	edx, eax
	xor	eax, edx

; If the requested interrupt is masked, don't report.
	test	eax, VirtualImr
	jz	@F
   	ret
@@:

; Check if IRQ of the same or more privilege is being serviced.
	mov	ecx, VirtualIsr
	lea	edx, [ecx-1]
	and	edx, ecx
	xor	ecx, edx

	test	ecx, ecx
	jz	@F

IF 0
; If the set bit in in-service register is of a lower lever, exit
	cmp	ecx, eax
	jnb	@F
	mov	ebx, VirtualIp
	mov	edx, VirtualIsr
	mov	si, ExcSeg
	mov	edi, ExcOffs
	mov	ebp, VirtualImr
int 3
	ret
ENDIF

@@:
; If it's not IRQ 2, service it. Else, service cascaded IRQ.
	cmp	eax, 4
	jne	sim_master_irq

; Service cascaded instead. Isolate the requested bit.
	mov	eax, VirtualIp
	shr	eax, 8
	lea	edx, [eax-1]
	and	edx, eax
	xor	eax, edx

; If the requested interrupt is masked, don't report.
	mov	edx, VirtualImr
	shr	edx, 8
	test	eax, edx
	jz	@F
   	ret
@@:
; If the ISR bit > 2, don't check anything - go to repoting.
	test	ecx, 4
	jz	@F

	mov	ecx, VirtualIsr
	shr	ecx, 8
	lea	edx, [ecx-1]
	and	edx, ecx
	xor	ecx, edx

; If no bit was set, go to reporting.
	test	ecx, ecx
	jz	@F

; Service only if a lesser bit than in in-service register.
	cmp	ecx, eax
	ja	@F
	ret

@@:
; If it was last cascaded IRQ, clear IRQ 2 pending.
	test	edx, edx
	jnz	sim_cascaded_irq
	and	VirtualIp, NOT 4
; Set is-service bit for IRQ #2.
	or	VirtualIsr, 4

sim_cascaded_irq:
; Clear pending IRQ and set is-service bit.
	mov	edx, eax
	shl	eax, 8
	or	VirtualIsr, eax
	not	eax
	and	VirtualIp, eax

; Simulate interrupt.
	mov	eax, 70h
@@:
	shr	edx, 1
	jc	@F
	inc	eax
	jmp	@B

@@:
	call	SimulateInt
	ret
	
sim_master_irq:
; If no bit was set, go to reporting.
	test	ecx, ecx
	jz	@F

; Service only if a lesser bit than in in-service register.
	cmp	ecx, eax
	ja	@F
	ret
@@:
	mov	edx, eax
; Clear pending IRQ and set in-service bit.
	or	VirtualIsr, eax
	not	eax
	and	VirtualIp, eax

; Simulate interrupt.
	mov	eax, 8
@@:
	shr	edx, 1
	jc	@F
	inc	eax
	jmp	@B
@@:
	call	SimulateInt
	ret
ReportIrq	ENDP


;-----------------------------------------------------------------------------
;
;	Sets client regs and returns to the client (caller)
;
;	I:
;	O:
;
;-----------------------------------------------------------------------------
PUBLIC	SetClientRegs
SetClientRegs	PROC

IFDEF	DEBUG_BUILD
; If TraceFlag, set TF = 1.
	movzx	eax, TraceFlag
	shl	eax, 8
	and	ExcEflags, NOT FL_TF
	or	ExcEflags, eax
ENDIF	; DEBUG_BUILD

;IFDEF	LOG_DPMI
IF	0
	pushad

	cmp	NumOfTasks, 0
	je	@F

	cmp	SystemTask, 1
	je	@F

	mov	eax, CurrTaskPtr
	cmp	(DosTask PTR fs:[eax]).TaskLdt, 0
	je	@F

	mov	ax, ExcSeg
	mov	edi, offset Field
	call	PmHex16ToA
	mov	Field[4], ' '
	mov	eax, offset Field
	mov	ecx, 5
	mov	esi, offset Field
	call	WriteLog

	mov	eax, ExcOffs
	mov	edi, offset Field
	call	PmHex32ToA
	mov	Field[8], ' '
	mov	eax, offset Field
	mov	ecx, 9
	mov	esi, offset Field
	call	WriteLog

	mov	eax, ExcEflags
	mov	edi, offset Field
	call	PmHex32ToA
	mov	Field[8], 13
	mov	Field[9], 10
	mov	eax, offset Field
	mov	ecx, 10
	mov	esi, offset Field
	call	WriteLog
@@:
	popad
ENDIF	; LOG_DPMI

; Report IRQs only for ring 3 or VM code.
	test	ExcEflags, FL_VM
	jnz	@F
	test	ExcSeg, 3
	jz	restore_pm_regs
@@:
; Service VM pending interrupts if possible.
	cmp	VirtualIf, 0
	jz	@F

	call	ReportIrq
@@:
; Clear NT flag.
	and	ExcEflags, NOT FL_NT

; Set return frame according to target mode.
	test	ExcEflags, FL_VM
	jz	restore_pm_regs

restore_vm_regs:

IFDEF	MONITOR_LOCKED_STACK
EXTRN	LogX: byte, LogY: byte, LogClr: byte
pushad
	cmp	SystemTask, 0
	jne	@F
	mov	edx, CurrTaskPtr
	cmp	(DosTask PTR fs:[edx]).TaskLdt, 0
	je	@F
	mov	eax, (DosTask PTR fs:[edx]).DpmiRmStack
	PM_PRINT_HEX32	, LogX, LogY, LogClr
	add	LogX, 9
	cmp	LogX, 80
	jb	@F
	mov	LogX, 0
	inc	LogY
	cmp	LogY, 25
	jb	@F
	mov	LogY, 0
	inc	LogClr
	cmp	LogClr, 16
	jb	@F
	mov	LogClr, 1
@@:
popad
ENDIF

IFDEF	TASK_MON
	cmp	SystemTask, 0
	jne	@F

	pushad
	mov	eax, 0
	TASK_PTR	, ecx
	PM_PRINT_HEX	(DosTask PTR fs:[ecx]).TaskState, 30, 23, 13
	PM_PRINT_HEX	(DosTask PTR fs:[ecx]).TaskBlock, 40, 23, 14
	mov	eax, 1
	TASK_PTR	, ecx
	PM_PRINT_HEX	(DosTask PTR fs:[ecx]).TaskState, 50, 23, 11
	PM_PRINT_HEX	(DosTask PTR fs:[ecx]).TaskBlock, 60, 23, 12
	PM_PRINT_HEX32	CurrentTask, 70, 23, 10
	popad

@@:
ENDIF

; Restore general purpose registers.
	mov	eax, ExcEax
	mov	ebx, ExcEbx
	mov	ecx, ExcEcx
	mov	edx, ExcEdx
	mov	esi, ExcEsi
	mov	edi, ExcEdi
	mov	ebp, ExcEbp

	push	ExcGs
	push	ExcFs
	push	ExcDs
	push	ExcEs
	push	ExcSs
	push	ExcEsp
	push	ExcEflags
	push	dword ptr ExcSeg
	push	ExcOffs

; Adjust CPL0 ESP back.
;	sub	Cpl0EspAdjust, CPL0_STK_SIZE
	iretd

; Restore general purpose registers.
restore_pm_regs:

IFDEF	MONITOR_LOCKED_STACK
EXTRN	LogX: byte, LogY: byte, LogClr: byte
pushad
	test	ExcSeg, 3
	jz	@F
	mov	edx, CurrTaskPtr
	mov	bl, LogClr
	or	bl, 70h
	mov	eax, (DosTask PTR fs:[edx]).DpmiPmStack
	PM_PRINT_HEX32	, LogX, LogY
	add	LogX, 9
	cmp	LogX, 80
	jb	@F
	mov	LogX, 0
	inc	LogY
	cmp	LogY, 25
	jb	@F
	mov	LogY, 0
	inc	LogClr
	cmp	LogClr, 16
	jb	@F
	mov	LogClr, 1
@@:
popad
ENDIF

	mov	eax, ExcEax
	mov	ebx, ExcEbx
	mov	ecx, ExcEcx
	mov	edx, ExcEdx
	mov	esi, ExcEsi
	mov	edi, ExcEdi
	mov	ebp, ExcEbp

	test	ExcSeg, 3
	jz	ring0_caller

	mov	es, ExcEs
	mov	fs, ExcFs
	mov	gs, ExcGs

; Adjust CPL0 ESP back.
;	sub	Cpl0EspAdjust, CPL0_STK_SIZE

	push	ExcSs
	push	ExcEsp
	push	ExcEflags
	push	dword ptr ExcSeg
	push	ExcOffs
	mov	ds, ExcDs
	iretd

ring0_caller:

; Adjust CPL0 ESP back.
;	sub	Cpl0EspAdjust, CPL0_STK_SIZE

if 1
cmp	ExcSeg, CODE_32
je	@F

mov	ax, ExcSeg
mov	ebx, ExcOffs
mov	ecx, ExcEflags
mov	edx, ExcSs
mov	esi, ExcEsp
mov	edi, ExcNumber
mov	NumOfTasks, 0
int 13h
@@:
endif
	mov	ss, ExcSs
	mov	esp, ExcEsp
	push	ExcEflags
	push	dword ptr ExcSeg
	push	ExcOffs

IFDEF	DEBUG_BUILD
	push	ExcDs

	cmp	ExcNumber, 1
	je	@F
	cmp	ExcNumber, 3
	jne	pop_ds
@@:
	call	RestoreDbgClientRegs
pop_ds:
	pop	ds
ELSE
	mov	ds, ExcDs
ENDIF	; DEBUG_BUILD

	mov	es, ExcEs
	mov	fs, ExcFs
	mov	gs, ExcGs

	iretd

SetClientRegs	ENDP


;-----------------------------------------------------------------------------
;
;	Timer interrupt handler (IRQ 0).
;
;-----------------------------------------------------------------------------
TimerInt	PROC
	push	0			; no error code
	call	GetClientRegs

IFDEF	PRINT_TIME
;
; Print current time.
;
	push	ds
	pop	es
; Get CMOS hours.
	mov	al, Cmos_RTC_HOURS
	out	CMOS_ADDR, al
	in	al, CMOS_DATA
	mov	edi, offset TimeStr
	call	PmHexToA
	mov	byte ptr es:[di+2], ':'
; Get CMOS hours minutes.
	mov	al, Cmos_RTC_MIN
	out	CMOS_ADDR, al
	in	al, CMOS_DATA
	add	edi, 3
	call	PmHexToA
	mov	byte ptr es:[di+2], ':'
; Get CMOS seconds.
	mov	al, Cmos_RTC_SEC
	out	CMOS_ADDR, al
	in	al, CMOS_DATA
	add	edi, 3
	call	PmHexToA

; Print current time in the middle of the screen.
	mov	esi, offset TimeStr
	mov	dh, 12
	mov	dl, 36
	mov	bl, TimeClr
	call	PmWriteStr32
ENDIF

	mov	al, CMD_EOI
	out	PIC_MASTER, al		; EOI

	mov	eax, 20h		; Timer IRQ #.
	call	CallCallbacks		; Call callbacks, CF doesn't matter.

; If no active tasks, sense global ticks count.
	cmp	NumOfTasks, 0
	jne	report_local_timer

	inc	TickCount
	mov	eax, TickCount
	cmp	eax, TicksReport
	jb	end_timer_int

	mov	TickCount, 0
	jmp	report_timer

; Increment number of ticks.
report_local_timer:
	mov	ecx, CurrTaskPtr
	inc	(DosTask PTR fs:[ecx]).TaskTickCount

	mov	ecx, CurrTaskPtr
	mov	eax, (DosTask PTR fs:[ecx]).TaskTickCount
	cmp	eax, (DosTask PTR fs:[ecx]).TaskTicksReport
	jb	end_timer_int		; If not reached counter value, end interrupt.

; Reset ticks counter.
	mov	(DosTask PTR fs:[ecx]).TaskTickCount, 0

IFDEF	PRINT_TIME
	inc	TimeClr
ENDIF

report_timer:
	test	ExcEflags, FL_VM
	jnz	@F
	test	ExcSeg, 3
	jz	end_timer_int

; Timer interrupt is reported to an active task. If tasks are switched,
; report to a new task.
@@:
	or	VirtualIp, 1		; Virtual IRQ0 pending.

end_timer_int:
;
; If a keyboard buffer is not empty, set IRQ 1 pending for foreground task.
;
	mov	eax, KbdQHead
	cmp	eax, KbdQTail
	je	@F
	TASK_PTR	ForegroundTask
	or	(DosTask PTR fs:[eax]).TaskVirtualIp, 2

@@:
	jmp	SetClientRegs		; Return to client's call.
TimerInt	ENDP


;-----------------------------------------------------------------------------
;
;	Keyboard interrupt handler.
;
;-----------------------------------------------------------------------------
KbdInt		PROC	near
	push	0				; no error code
	call	GetClientRegs

	in	al, KBD_STATUS
	test	al, STS_Data_Ready
	jz	kbd_eoi

	cmp	KeyExtCode, 0
	je	read_key

; Extended scan code.
	cmp	KeyExtCode, 0E1h
	je	pause_key?

	in	al, KBD_DATA
	mov	TempScanCode, al		; Save keyboard data.

	cmp	al, 2Ah
	je	kbd_eoi
	cmp	al, 0AAh
	je	kbd_eoi

	mov	KeyPressed, al
	jmp	kbd_eoi

pause_key?:
	in	al, KBD_DATA
	cmp	al, 1Dh
	jne	kbd_eoi
	mov	TempScanCode, al		; Save keyboard data.
	in	al, KBD_DATA
;	cmp	al, 0C5h
;	je	pause_key
	cmp	al, 45h
	jne	kbd_eoi

pause_key:
	mov	KeyReady, 1
	mov	KeyPressed, al
	jmp	kbd_eoi

read_key:
	in	al, KBD_DATA
	mov	TempScanCode, al		; Save keyboard data.
	cmp	al, 0FEh
	je	kbd_eoi

	cmp	al, 0E0h
	jb	test_break_code
	cmp	al, 0E1h
	jne	test_break_code

	mov	KeyExtCode, al
	jmp	kbd_eoi

test_break_code:
	test	al, 80h			; Break (release) code.
	jz	key_pressed

; Test if shift keys are released.
	sub	esi, esi
	and	eax, 7Fh		; Clear released bit.
	mov	ah, KeyExtCode
@@::
	cmp	eax, ShiftScanTbl[ esi * 4 ]
	je	@F
	inc	esi
	cmp	esi, 8
	jb	@B
	jmp	kbd_eoi

@@:
	mov	al, ShiftBitCode[ esi ]
	not	al
	and	ShiftKeys, al
	jmp	kbd_eoi

key_pressed:
	mov	KeyReady, 1
	mov	KeyPressed, al

; Test shift codes.
	sub	esi, esi
	sub	eax, eax
	mov	al, KeyPressed
	mov	ah, KeyExtCode
@@:
	cmp	eax, ShiftScanTbl[ esi * 4 ]
	je	@F
	inc	esi
	cmp	esi, 8
	jb	@B
	jmp	kbd_eoi

@@:
	mov	al, ShiftBitCode[ esi ]
	or	ShiftKeys, al

kbd_eoi:
	mov	al, CMD_EOI
	out	PIC_MASTER, al

IFDEF	DEBUG_BUILD
	cmp	DebugFlag, 0
	jnz	end_kbd_int
ENDIF	; DEBUG_BUILD

	or	IrqReported, 2		; By default, report IRQ 1.
	mov	eax, 21h		; Keyboard interrupt #
	call	CallCallbacks		; Call callbacks, CF doesn't matter.

; If happened not in CPL 3, exit.
	test	ExcEflags, FL_VM
	jnz	@F
	test	ExcSeg, 3
	jz	end_kbd_int
; If happened while debugging in CPL 3, exit.
@@:

IFDEF	DEBUG_BUILD
	cmp	TraceFlag, 0
	jnz	end_kbd_int
ENDIF	; DEBUG_BUILD

; If key was designated for system, don't report.
	test	IrqReported, 2
	jz	end_kbd_int

; If happened in system task, no report.
	cmp	SystemTask, 0
	jne	end_kbd_int

; Insert key to a virtual keyboard cyclic queue.
	mov	eax, KbdQTail		; Set EAX -> next code to insert.
	inc	eax
	cmp	eax, KEYBOARD_Q_SIZE
	jb	@F
	sub	eax, eax
@@:
	cmp	eax, KbdQHead		; If queue is full, don't insert.
	je	@F

	mov	cl, TempScanCode
	mov	edx, KbdQTail
	mov	KeyboardQ[ edx ], cl	; Save keyboard code.
	mov	KbdQTail, eax		; Update keyboard queue tail.
@@:

; Keyboard interrupt is reported only to a foreground task.
	mov	eax, ForegroundTask
	cmp	eax, CurrentTask
	je	report_int

; Boost foreground task.

; Clear block on keyboard event state.
	TASK_PTR
	and	(DosTask PTR fs:[eax]).TaskBlock, NOT KBD_INPUT
	jnz	end_kbd_int
	and	(DosTask PTR fs:[eax]).TaskState, NOT TASK_BLOCKED
@@:
	mov	eax, ForegroundTask
	call	SwitchTask

report_int:
	or	VirtualIp, 2		; Virtual IRQ1 pending.
end_kbd_int:
	jmp	SetClientRegs
KbdInt		ENDP


;-----------------------------------------------------------------------------
;
;	IRQ 2 - 7 handler
;
;-----------------------------------------------------------------------------
IrqHandler0	PROC
Irq2Int::
	push	0
	call	GetClientRegs
	mov	edx, 00000100b
	jmp	gluke0_int
Irq3Int::
	push	0
	call	GetClientRegs
	mov	edx, 00001000b

; If some task is owning a Com1 semaphore, report IRQ4 only to it.
	cmp	Com1.DevSema4.State, 0
	jne	gluke0_int			; Else, report to all.

	mov	eax, Com2.DevSema4.Owner
	cmp	eax, CurrentTask
;	jne	@F
	je	@F
	call	SwitchTask
	jc	report_irq3_pending
@@:
; Report to the current task
	or	VirtualIp, 00001000b
	jmp	end_gluke0_int
report_irq3_pending:
	TASK_PTR
	or	(DosTask PTR fs:[eax]).TaskVirtualIp, 00001000b
	jmp	end_gluke0_int
Irq4Int::
	push	0
	call	GetClientRegs
	mov	edx, 00010000b

; If some task is owning a Com1 semaphore, report IRQ4 only to it.
	cmp	Com1.DevSema4.State, 0
	jne	gluke0_int			; Else, report to all.

	mov	eax, Com1.DevSema4.Owner
	cmp	eax, CurrentTask
	jne	@F
; Report to the current task
	or	VirtualIp, 00010000b
	jmp	end_gluke0_int
@@:
	TASK_PTR
	or	(DosTask PTR fs:[eax]).TaskVirtualIp, 00010000b
	jmp	end_gluke0_int
Irq5Int::
	push	0
	call	GetClientRegs
	mov	edx, 00100000b
	jmp	gluke0_int
Irq6Int::
	push	0
	call	GetClientRegs

; IRQ 6 - FDD completion interrupt.
	cmp	FddSema4, 0
	je	normal_irq6

	mov	eax, FddSema4Own
	cmp	eax, CurrentTask
	je	retire_dma

; Boost FDD semaphore owner.
	call	SwitchTask

EXTRN	RetireDma: near32
retire_dma:
	push	eax
	mov	al, 2
	call	RetireDma
	pop	eax

normal_irq6:
	mov	edx, 01000000b
	jmp	gluke0_int

Irq7Int::
	push	0
	call	GetClientRegs
	mov	edx, 10000000b

;
; Generic handling of IRQ 2 - 7.
;
gluke0_int:
; EOI.
	mov	al, CMD_EOI
	out	PIC_MASTER, al

	test	ExcEflags, FL_VM
	jnz	@F
	test	ExcSeg, 3
	jz	end_gluke0_int
@@:
; Set virtual interrupt pending for all tasks - both active and suspended.
	or	VirtualIp, edx
	mov	ecx, FirstTask
	mov	ebx, NumOfTasks
set_int_pending:
	or	(DosTask PTR fs:[ecx]).TaskVirtualIp, edx
	add	ecx, SIZEOF DosTask
	dec	ebx
	jnz	set_int_pending

end_gluke0_int:
	jmp	SetClientRegs		; return

IrqHandler0	ENDP


;-----------------------------------------------------------------------------
;
;	IRQ 8 - F handler
;
;-----------------------------------------------------------------------------
IrqHandler1	PROC
Irq8Int::
	push	0
	call	GetClientRegs
	mov	edx, 0000000100000100b
	jmp	gluke1_int
Irq9Int::
	push	0
	call	GetClientRegs
	mov	edx, 0000001000000100b
	jmp	gluke1_int
IrqAInt::
	push	0
	call	GetClientRegs
	mov	edx, 0000010000000100b
	jmp	gluke1_int
IrqBInt::
	push	0
	call	GetClientRegs
	mov	edx, 0000100000000100b
sub	edx, edx
	jmp	gluke1_int
IrqCInt::
	push	0
	call	GetClientRegs
	mov	edx, 0001000000000100b
	jmp	gluke1_int
IrqDInt::
	push	0
	call	GetClientRegs
	mov	edx, 0010000000000100b
	jmp	gluke1_int
IrqEInt::
	push	0
	call	GetClientRegs

; IRQ E - IDE completion interrupt.
	cmp	HddSema4, 0
	je	normal_irqE

	mov	eax, HddSema4Own
	cmp	eax, CurrentTask
	je	normal_irqE

; Boost HDD semaphore owner.
	call	SwitchTask

; Test for the rare case that task is blocked on both events.
;	jnc	normal_irqE
;
;	mov	esi, eax
;	TASK_PTR
;	mov	bl, (DosTask PTR fs:[eax]).TaskState
;	mov	cl, (DosTask PTR fs:[eax]).TaskBlock
;int 3

normal_irqE:
	or	VirtualIp, 0100000000000100b

; EOI.
	mov	al, CMD_EOI
	out	PIC_SLAVE, al
	out	PIC_MASTER, al

	jmp	end_gluke1_int

IrqFInt::
	push	0
	call	GetClientRegs
	mov	edx, 1000000000000100b
	jmp	gluke1_int

gluke1_int:
; EOI.
	mov	al, CMD_EOI
	out	PIC_SLAVE, al
	out	PIC_MASTER, al

	test	ExcEflags, FL_VM
	jnz	@F
	test	ExcSeg, 3
	jz	end_gluke1_int

; Set virtual interrupt pending for all tasks - running and suspended.
@@:
	or	VirtualIp, edx
	mov	ecx, FirstTask
	mov	ebx, NumOfTasks
set_int_pending:
	or	(DosTask PTR fs:[ecx]).TaskVirtualIp, edx
	add	ecx, SIZEOF DosTask
	dec	ebx
	jnz	set_int_pending

end_gluke1_int:
	jmp	SetClientRegs		; return

IrqHandler1	ENDP


CODE32	ENDS
END
