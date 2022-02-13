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
;				CORE.ASM
;				--------
;
;	Tripple-DOS system core.
;
;=============================================================================

.486p
	INCLUDE	CORE.INC
	INCLUDE	X86.INC
	INCLUDE	DEVICES.INC
	INCLUDE	PHLIB32.MCR
	INCLUDE	DEF.INC
	INCLUDE	TASKMAN.INC
	INCLUDE	DEBUG.INC
	INCLUDE	DPMI.INC

	EXTRN	InitStkSel: word
	EXTRN	QuitPm: byte
	EXTRN	KeyReady: byte
	EXTRN	KeyPressed: byte
	EXTRN	KeyExtCode: byte
	EXTRN	ShiftKeys: byte
	EXTRN	Start32Esp: dword
	EXTRN	FirstTask: dword
	EXTRN	CurrentTask: dword
	EXTRN	CurrTaskPtr: dword
	EXTRN	ForegroundTask: dword
	EXTRN	NumOfTasks: dword
	EXTRN	IrqReported: dword
	EXTRN	TicksReport: dword
	EXTRN	TickToSec: dword

	EXTRN	ExcSeg: word
	EXTRN	ExcOffs: dword
	EXTRN	ExcEflags: dword
	EXTRN	ExcDs: word
	EXTRN	ExcEs: word
	EXTRN	ExcSs: word
	EXTRN	ExcFs: word
	EXTRN	ExcGs: word
	EXTRN	ExcEax: dword
	EXTRN	ExcEbx: dword
	EXTRN	ExcEcx: dword
	EXTRN	ExcEdx: dword
	EXTRN	ExcEsp: dword
	EXTRN	ExcEbp: dword
	EXTRN	ExcEsi: dword
	EXTRN	ExcEdi: dword

	EXTRN	SysPdb: dword
	EXTRN	Pdb: dword
	EXTRN	SysPdbLin: dword
	EXTRN	PdbLin: dword
	EXTRN	SysPagesCtl: dword
	EXTRN	PagesCtl: dword
	EXTRN	TssBase: dword
	EXTRN	OsHeapEnd: dword

	EXTRN	Field: byte

	EXTRN	AddExcTrap: near32
	EXTRN	StartTask: near32
	EXTRN	StopTask: near32
	EXTRN	HeapAllocMem: near32
	EXTRN	HeapAllocPage: near32
	EXTRN	LinearToPhysical: near32
	EXTRN	PointerToLinear: near32
	EXTRN	LeftFreePages: near32
	EXTRN	FocusToNextTask: near32
	EXTRN	SwitchFocusTo: near32
	EXTRN	NextTask: near32
	EXTRN	EmulateIret: near32
	EXTRN	Int13RetTrap: near32
	EXTRN	Int21RetTrap: near32
	EXTRN	DpmiSwitch: near32
	EXTRN	DpmiCallbackRet: near32
	EXTRN	TrapVideoPorts: near32
	EXTRN	RelGenDevPorts: near32
	EXTRN	TrapIo: near32
	EXTRN	DmaTimer: near32

	EXTRN	handled_exc: near32
	EXTRN	unhandled_exc: near32
	EXTRN	SimulateV86Int: near32
	EXTRN	RestoreVmState: near32
	EXTRN	XlatRet: near32
	EXTRN	CallRmCallback: near32
	EXTRN	RmCallbackRet: near32
	EXTRN	AltSaveState: near32
	EXTRN	AltRestoreState: near32

	EXTRN	GetScanCode: near32

IFDEF	FAKE_WINDOWS
	EXTRN	WinVendorEntry: near32
ENDIF

	EXTRN	XmsEntry: near32

DATA	SEGMENT	PARA	PUBLIC	USE16	'DATA'
; Call V86 data.
	SaveRegs	REG_PACK	<>
	CallPack	CALL_V86_INT	<>
	pV86Int		DD		?
	TempSi		DW		?
	RetAddr		DD		?

; Messages and other data.
	FreeMemMsg	DB	"Left free memory: ", 0

; Task switching data.
	PUBVAR		SliceTicks, DD, SLICE_TICKS
	SliceCount	DD	?
	PUBVAR		SystemTask, DD, 1

; Title data.
      	M32Title	DB	"Tripple-DOS - Black Phantom's DOS multitasker v0.50", 0
	M32Prompt	DB	"~Enter New Shell ~End Stop Task ~Tab Switch Foreground Task ~ESC - Quit", 0

; Task structure alloc error message.
	TaskStrucErrStr	DB	"Error allocating task structure!", 0
	StartTaskErrStr	DB	"Task could not be started!", 0

; Log file.
PUBLIC	M32LogName
	M32LogName	DB	"MULTIX32.LOG", 0
	PUBVAR	M32LogHandle, DD, ?
	PUBVAR	M32LogAddr, DD, ?
	PUBVAR	M32LogHead, DD, 0		; Log is a cyclic buffer.
	PUBVAR	M32LogTail, DD, 0

; If non 0, return to real mode will flush log.
	SystemTraps	DD	offset V86IntRet, offset SystemTaskRet
			DD	offset DpmiSwitches, offset DpmiV86CallbackRet
			DD	offset DpmiExcHandlerRet, offset DpmiDefExcHandler
			DD	offset DpmiDefIntHandler, offset DpmiPmCallbackRet
			DD	offset DpmiXlatRet, offset DpmiCallRmCallback
			DD	offset DpmiRmCallbackRet, offset DpmiWinVendorAPI
			DD	offset CallXmsEntry
			DD	offset DpmiRmSaveRestState, offset DpmiPmSaveRestState
SYSTEM_TRAPS	=	($ - offset SystemTraps) / 4

; Log messages.
	RmStateStr	DB	"Real mode "
	PmStateStr	DB	"Protected mode "
	SaveStateStr	DB	"save state: "
	RestoreStateStr	DB	"restore state: "

DATA	ENDS


STK	SEGMENT	PARA STACK	USE16	'STACK'
STK	ENDS


CODE	SEGMENT	PARA PUBLIC	USE16	'CODE'
ASSUME	CS:CODE, DS:DATA
;
; VM entry point for calling interrupt.
;
V86Entry::
; Get far pointer to interrupt. (FS=0)
	movzx	eax, al
	shl	eax, 2
	mov	eax, fs:[eax]
	mov	pV86Int, eax
; Save SI.
	push	si
; Set registers from DS:SI
	mov	eax, (CALL_V86_INT PTR [si]).stRegs.dwEax
	mov	ebx, (CALL_V86_INT PTR [si]).stRegs.dwEbx
	mov	ecx, (CALL_V86_INT PTR [si]).stRegs.dwEcx
	mov	edx, (CALL_V86_INT PTR [si]).stRegs.dwEdx
	mov	esi, (CALL_V86_INT PTR [si]).stRegs.dwEsi
	mov	edi, (CALL_V86_INT PTR [si]).stRegs.dwEdi
	mov	ebp, (CALL_V86_INT PTR [si]).stRegs.dwEbp
; Call V86 interrupt
	pushf
	call	pV86Int
; Restore SI.
	mov	TempSi, si
	pop	si
; Record registers - exception result.
	pushf
	pop	word ptr (CALL_V86_INT PTR [si]).stRegs.dwEflags
	mov	(CALL_V86_INT PTR [si]).stRegs.dwEax, eax
	mov	(CALL_V86_INT PTR [si]).stRegs.dwEbx, ebx
	mov	(CALL_V86_INT PTR [si]).stRegs.dwEcx, ecx
	mov	(CALL_V86_INT PTR [si]).stRegs.dwEdx, edx
	mov	(CALL_V86_INT PTR [si]).stRegs.dwEdi, edi
	mov	(CALL_V86_INT PTR [si]).stRegs.dwEbp, ebp
	mov	eax, esi
	mov	ax, TempSi
	mov	(CALL_V86_INT PTR [si]).stRegs.dwEsi, eax

; Invalid opcode exception to return to protmode.
	DB	0FEh, 0FFh, 0, 0, 0, 0, 0, 1
CODE	ENDS


CODE32	SEGMENT	PARA	PUBLIC	USE32	'CODE'
ASSUME	CS:CODE32, DS:FLAT


;-----------------------------------------------------------------------------
;
;	I: INIT_DS:ESI -> interrupt calling structure
;	O: structure filled.
;
;	Remarks:
; * Swtiches to VM in the same environment as it started in RM. Mapping = 
; 1-to-1
; * Interrupt calling structure must be filled with appropriate to VM values.
; * Called V86 interrupt executes with I/O privileges (via TSS) and INT pri-
; vileges (to call another INT nn). Therefore, only trusted services should
; be called this way.
; * It will be called in the context of the current 16-bit segmented model.
; * Return to protmode will be via invalid opcode FE FF 00 00 00 00
;
;-----------------------------------------------------------------------------
InvokeV86Int	PROC
; Save registers.
	mov	SaveRegs.dwEax, eax
	mov	SaveRegs.dwEbx, ebx
	mov	SaveRegs.dwEcx, ecx
	mov	SaveRegs.dwEdx, edx
	mov	SaveRegs.dwEsi, esi
	mov	SaveRegs.dwEdi, edi
	mov	SaveRegs.dwEsp, esp
	mov	SaveRegs.dwEbp, ebp
; Switch to virtual mode.
	sub	eax, eax
	push	eax		; GS
	push	eax		; FS
	mov	ax, DATA
	push	eax		; DS
	push	eax		; ES
	mov	ax, STK
	push	eax		; SS
	push	VM_STK		; ESP
; Eflags reg., IOPL=0
	push	FL_VM		; IOPL = 0
	mov	ax, CODE
	push	eax		; CS
	mov	eax, offset V86Entry
	push	eax		; IP
	mov	al, (CALL_V86_INT PTR [esi]).bInt	; Int number
; Set registers from DS:ESI structure.
	iretd			; Switch to VM


; Entry point from invalid opcode handler.
PUBLIC	FromV86Entry
FromV86Entry::
; Restore segment registers.
	mov	ax, INIT_DS
	mov	ds, ax
	mov	es, ax
	mov	ax, FLAT_DS
	mov	fs, ax
	mov	gs, ax

; Restore other registers.
	mov	eax, SaveRegs.dwEax
	mov	ebx, SaveRegs.dwEbx
	mov	ecx, SaveRegs.dwEcx
	mov	edx, SaveRegs.dwEdx
	mov	esi, SaveRegs.dwEsi
	mov	edi, SaveRegs.dwEdi
	mov	esp, SaveRegs.dwEsp
	mov	ebp, SaveRegs.dwEbp

	ret	
InvokeV86Int	ENDP


;-----------------------------------------------------------------------------
;
;	I: AL = mode.
;
;	Sets video mode specified in AL using BIOS (InvokeV86Int).
;
;	(!) System context.
;
;-----------------------------------------------------------------------------
PUBLIC	PmSetVideoMode
PmSetVideoMode	PROC	USES	eax esi
	push	es
	push	edi
	push	ecx

	push	FLAT_DS
	pop	es

	mov	edi, 0B8000h
	mov	ecx, 2048
	mov	ax, 0720h
	cld
		rep	stos word ptr es:[edi]

	pop	ecx
	pop	edi
	pop	es
	ret

	mov	CallPack.bInt, 10h
	movzx	eax, al
	mov	CallPack.stRegs.dwEax, eax	; Bios function 0.
	mov	esi, offset CallPack
	call	InvokeV86Int
	ret
PmSetVideoMode	ENDP


;-----------------------------------------------------------------------------
;
;	I: DS:EAX -> file name.
;	   ECX = attributes.
;	O: CF = 0 - OK, EAX = file handle
;	      = 1 - error.
;
;	Creates a new file.
;
;	(!) System context.
;
;-----------------------------------------------------------------------------
PUBLIC	PmCreateFile
PmCreateFile	PROC	USES	ecx esi
	mov	CallPack.bInt, 21h
	mov	ch, 3Ch
	mov	CallPack.stRegs.dwEax, ecx	; Function #.
	mov	CallPack.stRegs.dwEdx, eax	; File name.
	mov	esi, offset CallPack
	call	InvokeV86Int
	test	CallPack.stRegs.dwEflags, FL_CF
	jz	@F

	stc
	ret
@@:
	mov	eax, CallPack.stRegs.dwEax
	clc
	ret
PmCreateFile	ENDP


;-----------------------------------------------------------------------------
;
;	I: DS:EAX -> file name.
;	   ECX = attributes.
;	O: CF = 0 - OK, EAX = file handle
;	      = 1 - error.
;
;	Opens an existent file.
;
;	(!) System context.
;
;-----------------------------------------------------------------------------
PUBLIC	PmOpenFile
PmOpenFile	PROC	USES	ecx esi
	mov	CallPack.bInt, 21h
	mov	ch, 3Dh
	mov	CallPack.stRegs.dwEax, ecx	; Function #.
	mov	CallPack.stRegs.dwEdx, eax	; File name.
	mov	esi, offset CallPack
	call	InvokeV86Int
	test	CallPack.stRegs.dwEflags, FL_CF
	jz	@F

	stc
	ret
@@:
	mov	eax, CallPack.stRegs.dwEax
	clc
	ret
PmOpenFile	ENDP


;-----------------------------------------------------------------------------
;
;	I: EAX = handle
;	   ECX = position
;	   EDX = where (start/end/current).
;	O: CF = 0 - OK, EAX = new position.
;	      = 1 - error.
;
;	Seeks file for position.
;
;	(!) System context.
;
;-----------------------------------------------------------------------------
PUBLIC	PmSeekFile
PmSeekFile	PROC	USES	ecx edx esi
	mov	CallPack.bInt, 21h
	mov	dh, 42h
	mov	CallPack.stRegs.dwEax, edx	; Function #.
	mov	CallPack.stRegs.dwEbx, eax	; File handle.
	mov	CallPack.stRegs.dwEdx, ecx	; position low word.
	shr	ecx, 16
	mov	CallPack.stRegs.dwEcx, ecx	; position high word.
	mov	esi, offset CallPack
	call	InvokeV86Int
	test	CallPack.stRegs.dwEflags, FL_CF
	jz	@F

	stc
	ret
@@:
	mov	eax, CallPack.stRegs.dwEcx
	shl	eax, 16
	mov	ax, word ptr CallPack.stRegs.dwEdx
	clc
	ret
PmSeekFile	ENDP


;-----------------------------------------------------------------------------
;
;	I: EAX = handle
;	   DS:EDX -> data
;	   ECX = byte count
;	O: CF = 0 - OK,
;	      = 1 - error.
;
;	Writes file.
;
;	(!) System context.
;
;-----------------------------------------------------------------------------
PUBLIC	PmWriteFile
PmWriteFile	PROC	USES	eax esi
	mov	CallPack.bInt, 21h
	mov	CallPack.stRegs.dwEax, 4000h	; Function #.
	mov	CallPack.stRegs.dwEbx, eax	; File handle.
	mov	CallPack.stRegs.dwEdx, edx	; Pointer to data.
	mov	CallPack.stRegs.dwEcx, ecx	; Bytes count.

	mov	esi, offset CallPack
	call	InvokeV86Int

	test	CallPack.stRegs.dwEflags, FL_CF
	jz	@F

	stc
	ret
@@:
	clc
	ret
PmWriteFile	ENDP


;-----------------------------------------------------------------------------
;
;	I: EAX = handle
;	   DS:EDX -> data
;	   ECX = byte count
;	O: CF = 0 - OK,
;	      = 1 - error.
;
;	Writes file.
;
;	(!) System context.
;
;-----------------------------------------------------------------------------
PUBLIC	PmReadFile
PmReadFile	PROC	USES	eax esi
	mov	CallPack.bInt, 21h
	mov	CallPack.stRegs.dwEax, 3F00h	; Function #.
	mov	CallPack.stRegs.dwEbx, eax	; File handle.
	mov	CallPack.stRegs.dwEdx, edx	; Pointer to data.
	mov	CallPack.stRegs.dwEcx, ecx	; Bytes count.

	mov	esi, offset CallPack
	call	InvokeV86Int

	test	CallPack.stRegs.dwEflags, FL_CF
	jz	@F

	stc
	ret
@@:
	clc
	ret
PmReadFile	ENDP


;-----------------------------------------------------------------------------
;
;	I: EAX = file handle.
;	O:
;
;	Closes file.
;
;-----------------------------------------------------------------------------
PUBLIC	PmCloseFile
PmCloseFile	PROC	USES	eax esi
	mov	CallPack.bInt, 21h
	mov	CallPack.stRegs.dwEax, 3E00h	; Function #.
	mov	CallPack.stRegs.dwEbx, eax	; File handle.

	mov	esi, offset CallPack
	call	InvokeV86Int

	ret
PmCloseFile	ENDP


;-----------------------------------------------------------------------------
;
;	Initializes core task (UI).
;
;-----------------------------------------------------------------------------
PUBLIC	InitCore
InitCore	PROC
; Set callback of INT 21h (keyboard interrupt).
	mov	eax, 21h
	mov	ecx, offset KbdCallback
	call	AddExcTrap

; Set callback of INT 20h (timer interrupt).
	mov	eax, 20h
	mov	ecx, offset TimerCallback
	call	AddExcTrap

; Set invalid opcode callback.
	mov	eax, 6
	mov	ecx, offset InvOpCallback
	call	AddExcTrap

; Set timer handler for DMA services.
;	mov	eax, 20h
;	mov	ecx, offset DmaTimer
;	call	AddExcTrap

; Trap keyboard ports in TSS.
	mov	eax, TssBase
	movzx	ecx, (Tss386 PTR fs:[eax]).IoTableBase
	or	byte ptr fs:[eax+ecx+60h/8], 00010001b

; Trap DMA ports in TSS.
	or	word ptr fs:[eax+ecx], 0FFFFh
;	or	dword ptr fs:[eax+ecx+0C0h/8], 0FFFFFFFFh
	or	word ptr fs:[eax+ecx+80h/8], 0FFFFh

; Trap PIC ports in TSS.
	or	byte ptr fs:[eax+ecx+20h/8], 00000011b
	or	byte ptr fs:[eax+ecx+0A0h/8], 00000011b

; Trap PIT ports in TSS.
	or	byte ptr fs:[eax+ecx+40h/8], 00001111b

; Trap FDC ports in TSS.
	or	word ptr fs:[eax+ecx+3F0h/8], 11111111b

; Install generic I/O emulator as GPF handler.
	mov	eax, 0Dh
	mov	ecx, offset TrapIo
	call	AddExcTrap

; Init basic ticks count.
	push	eax
	push	edx
	sub	edx, edx
	mov	eax, PIT_FREQUENCY
	div	TickToSec
	mov	ecx, eax
	pop	edx
	pop	eax

	sub	edx, edx
	mov	eax, 10000h
	div	ecx

	mov	TicksReport, eax ; Set number of ticks to report interrupt.

; Init slice counter.
	mov	SliceCount, 0

; Allocate task structure.
	mov	eax, PAGE_PRESENT OR PAGE_WRITABLE
	mov	ecx, MAX_TASKS * SIZEOF DosTask
	call	HeapAllocMem
	jnc	@F

; If can't allocate task structure, diagnose and quit.
	PM_PRINT_MSG	(offset TaskStrucErrStr)
	call	GetScanCode
	mov	QuitPm, 1
	jmp	core_entry

@@:
	mov	FirstTask, eax

	ret
InitCore	ENDP


;-----------------------------------------------------------------------------
;
;	Keyboard callback.
;
;-----------------------------------------------------------------------------
KbdCallback	PROC
	cmp	KeyReady, 0
	je	end_callback

	test	ShiftKeys, Kbd_LAlt OR Kbd_RAlt
	jz	end_callback

	mov	KeyReady, 0			; Key is read.
	mov	KeyExtCode, 0

	mov	al, KeyPressed
	cmp	al, 1
	jne	Enter?

; ESC pressed - quit.

exit:
	mov	QuitPm, 1
	mov	esp, Start32Esp
	jmp	core_entry

Enter?:
	cmp	al, 1Ch		; Enter?
	jne	F2?

; F1 pressed - start a new DOS task.
	call	StartTask
	jnc	no_report

; If returns, an error occured.
	PM_PRINT_MSG	(offset StartTaskErrStr)

	mov	SystemTask, 0
	jmp	no_report

F2?:
IFDEF	DEBUG_BUILD
	cmp	al, 3Ch		; F2?
	jne	F3?

; F2 pressed - test heap allocation.
	mov	eax, PAGE_PRESENT OR PAGE_WRITABLE
	call	HeapAllocPage
	push	eax
; Print allocated page lin. address
	PM_PRINT_HEX32	, 40, 16, 13h

	call	LinearToPhysical

; Print allocated page lin. address
	PM_PRINT_HEX32	, 50, 16, 13h
	pop	eax

	mov	esi, 12345678h
	mov	fs:[eax], esi			; test write
	mov	esi, fs:[eax]			; Test read

	jmp	no_report

F3?:
	cmp	al, 3Dh
	jne	End?

; F3 pressed - report free memory.
	PM_PRINT_MSG	(offset FreeMemMsg)

	call	LeftFreePages

	shl	eax, 12
	PM_PRINT_HEX32	, (SIZEOF FreeMemMsg - 1)

	PM_PRINT_HEX32	ForegroundTask, (SIZEOF FreeMemMsg - 1) + 10
	PM_PRINT_HEX32	CurrentTask, (SIZEOF FreeMemMsg - 1) + 20
	PM_PRINT_HEX32	NumOfTasks, (SIZEOF FreeMemMsg - 1) + 30

; Check if any physical page is double mapped.
	pushad

	mov	ecx, OS_HEAP

set_page:
	mov	eax, ecx
	call	LinearToPhysical
	mov	esi, eax
	lea	edx, [ecx+1000h]
compare_page:
	mov	eax, edx
	call	LinearToPhysical
	mov	edi, eax

	add	edx, 1000h
	cmp	edx, OsHeapEnd
	jb	compare_page

	add	ecx, 1000h
	lea	ebx, [ecx+1000h]
	cmp	ebx, OsHeapEnd
	jb	set_page

	popad

	jmp	no_report

ENDIF	;DEBUG_BUILD
End?:
;	cmp	al, 3Eh		; F4?
	cmp	al, 4Fh		; End?
	jne	Tab?

; F4 pressed: stop current foreground task.
	mov	eax, ForegroundTask
	call	StopTask

	cmp	NumOfTasks, 0
	jne	no_report

; Jump to system task.
	mov	esp, Start32Esp
	jmp	core_start

Tab?:
;	cmp	al, 3Fh		; F5?
	cmp	al, 0Fh		; Tab?
	jne	end_callback
	
; F5 is pressed: switch focus and context to next task.
	cmp	NumOfTasks, 0
	je	no_report

	call	FocusToNextTask
	mov	SystemTask, 0

no_report:
	and	IrqReported, NOT 2		; Clear IRQ 1 reported bit.

end_callback:
	ret

KbdCallback	ENDP


;-----------------------------------------------------------------------------
;
;	Timer callback.
;
;-----------------------------------------------------------------------------
TimerCallback	PROC
	inc	SliceCount
	push	eax
	mov	eax, SliceTicks
	cmp	SliceCount, eax
	pop	eax
	jb	@F

; If system task is running, no switch on timer.
	cmp	SystemTask, 0
	jne	@F

	mov	SliceCount, 0
	call	NextTask
@@:
	stc
	ret
TimerCallback	ENDP


;-----------------------------------------------------------------------------
;
;	Invalid opcode callback.
;
;-----------------------------------------------------------------------------
PUBLIC	InvOpCallback
InvOpCallback	PROC
	test	ExcEflags, FL_VM
	jnz	@F
	test	ExcSeg, 3
	jz	err_ret
@@:
	mov	si, ExcSeg
	mov	edi, ExcOffs
	mov	ebx, ExcEflags
	call	PointerToLinear

	cmp	dword ptr fs:[eax], 0000FFFEh
	jne	err_ret

	cmp	word ptr fs:[eax][4], 0
	jne	err_ret

	movzx	ebx, byte ptr fs:[eax][7]
	cmp	ebx, SYSTEM_TRAPS
	jnb	err_ret
	jmp	SystemTraps[ebx*4]

V86IntRet::
	cmp	byte ptr fs:[eax][6], 13h
	jne	@F
	call	Int13RetTrap
	clc
	ret
@@:
	cmp	byte ptr fs:[eax][6], 21h
	jne	@F
	call	Int21RetTrap
	clc
	ret
@@:
	jmp	err_ret

; Return from system service.
SystemTaskRet::
	jmp	FromV86Entry

; Dpmi switches.
DpmiSwitches::
	call	DpmiSwitch
	clc
	ret

; Trap return from interrupt redirected to V86 mode.
DpmiV86CallbackRet::
	call	DpmiCallbackRet
	clc
	ret

; Trap return from "exception handler".
DpmiExcHandlerRet::
	jmp	handled_exc

; Trap "default exception handler".
DpmiDefExcHandler::
	jmp	unhandled_exc

; Trap "default interrupt handler".
DpmiDefIntHandler::

; Get interrupt number.
	mov	si, ExcSeg
	mov	edi, ExcOffs
	mov	ebx, ExcEflags
	call	PointerToLinear
	movzx	ecx, byte ptr fs:[eax][6]

; Emulate IRET(d).
	mov	eax, CurrTaskPtr
	mov	eax, (DosTask PTR fs:[eax]).TaskFlags
	call	EmulateIret
    
; Simulate V86 interrupt.
	call	SimulateV86Int
	clc
	ret

; Trap return from PM int handler to VM.
DpmiPmCallbackRet::
	call	RestoreVmState
	clc
	ret

; Trap return from translation services call.
DpmiXlatRet::
	call	XlatRet
	clc
	ret

; Trap real mode callback breakpoint.
DpmiCallRmCallback::
	call	CallRmCallback
	clc
	ret

; Trap return from real mode callback handler.
DpmiRmCallbackRet::
	call	RmCallbackRet
	clc
	ret

; Simulate Windows 3.x vendor API entry point.
DpmiWinVendorAPI::
IFDEF	FAKE_WINDOWS
;	call	WinVendorEntry
	clc
	ret
ELSE
	jmp	err_ret
ENDIF

; Trap XMS server entry point.
CallXmsEntry::
	call	XmsEntry
	clc
	ret

; Trap real mode save / restore entry point.
DpmiRmSaveRestState::
; If called from protected mode, return error.
	test	ExcEflags, FL_VM
	jz	err_ret

IFDEF	LOG_DPMI
	pushad
	PRINT_LOG	RmStateStr
	popad
	LOG_STATE
ENDIF

; Set EBP point to protected mode save buffer.
	mov	ebp, CurrTaskPtr
	mov	ebp, (DosTask PTR fs:[ebp]).DpmiRmStack
	sub	ebp, SIZEOF DpmiState + 4
	jmp	common_save_rest

; Trap protected mode save / restore entry point.
DpmiPmSaveRestState::
; If called from V86 mode, return error.
	test	ExcEflags, FL_VM
	jnz	err_ret

IFDEF	LOG_DPMI
	pushad
	PRINT_LOG	PmStateStr
	popad
	LOG_STATE
ENDIF

; Set EBP point to real mode save buffer.
	mov	ebp, CurrTaskPtr
	mov	ebp, (DosTask PTR fs:[ebp]).DpmiPmStack
	sub	ebp, SIZEOF DpmiState + 4

common_save_rest:
	cmp	byte ptr ExcEax, 0	; AL = 0 means save state.
	jne	restore_state?

IFDEF	LOG_DPMI
	pushad
	PRINT_LOG	SaveStateStr
	popad
ENDIF
	call	AltSaveState
	clc
	ret

restore_state?:
	cmp	byte ptr ExcEax, 1	; AL = 1 means restore state.
	jne	err_ret			; AL not equal 0 or 1 is an error.

IFDEF	LOG_DPMI
	pushad
	PRINT_LOG	RestoreStateStr
	popad
ENDIF
	call	AltRestoreState
	clc
	ret

err_ret:
	stc
	ret
InvOpCallback	ENDP


;-----------------------------------------------------------------------------
;
;	Writes to log.
;
;	I:	DS:ESI -> log buffer
;		ECX = length.
;
;-----------------------------------------------------------------------------
PUBLIC	WriteLog
WriteLog	PROC	USES es eax ecx esi edi
IFDEF	DEBUG_BUILD
	call	TransmitLog
ENDIF
	ret

IF 0
	cld
	push	FLAT_DS
	pop	es
	mov	edi, M32LogTail

; Check if need to wrap log.
	add	edi, ecx
	cmp	edi, LOG_SIZE
	jnb	wrap_log

; Just copy log buffer.
	mov	M32LogTail, edi
	sub	edi, ecx
	add	edi, M32LogAddr
		rep	movsb
	ret

wrap_log:
; Copy wrapped log.
	mov	eax, ecx		; Keep number of bytes to copy.
	mov	edi, M32LogTail
	mov	ecx, LOG_SIZE
	sub	ecx, edi
	sub	eax, ecx		; Remained number of bytes.
	add	edi, M32LogAddr
		rep	movsb

; Copy second part of log.
	sub	edi, edi
	mov	ecx, eax
	add	edi, M32LogAddr
		rep	movsb

	sub	edi, M32LogAddr
	mov	M32LogTail, edi
	inc	edi
	mov	M32LogHead, edi

	ret
ENDIF

WriteLog	ENDP


IF 0
;-----------------------------------------------------------------------------
;
;	Writes log from memory to a log file.
;
;	(!) Must be executed in system context.
;
;-----------------------------------------------------------------------------
PUBLIC	FlushLog
FlushLog	PROC	USES eax ebx ecx edx esi edi
	mov	eax, offset M32LogName
	sub	ecx, ecx
	call	PmCreateFile
	mov	M32LogHandle, eax

	cld
; Check if log wrapped.
	mov	eax, M32LogTail
	cmp	eax, M32LogHead
	jb	log_wrapped

;
; Just write log.
;

; Copy <= 64 bytes to low memory.
write_more:
	mov	ecx, M32LogTail
	sub	ecx, M32LogHead
	cmp	ecx, 64
	jna	@F
	mov	ecx, 64
@@:
	mov	esi, M32LogHead
	add	M32LogHead, ecx

	mov	ebx, ecx			; Keep number of bytes.

	mov	edi, offset Field
	add	esi, M32LogAddr
		rep	movs byte ptr es:[edi], fs:[esi]

	mov	eax, M32LogHandle
	mov	edx, offset Field
	mov	ecx, ebx
	call	PmWriteFile

	cmp	ebx, 64
	jnb	write_more

	mov	M32LogHead, 0
	mov	M32LogTail, 0

	mov	eax, M32LogHandle
	call	PmCloseFile

	ret

;
; Write log in two stages.
;
log_wrapped:
write_more_wrapped:
	mov	ecx, LOG_SIZE
	sub	ecx, M32LogHead
	cmp	ecx, 64
	jna	@F
	mov	ecx, 64
@@:
	mov	esi, M32LogHead
	add	M32LogHead, ecx

	mov	ebx, ecx			; Keep number of bytes.

	mov	edi, offset Field
	add	esi, M32LogAddr
		rep	movs byte ptr es:[edi], fs:[esi]

	mov	eax, M32LogHandle
	mov	edx, offset Field
	mov	ecx, ebx
	call	PmWriteFile

	cmp	ebx, 64
	jnb	write_more_wrapped

	mov	M32LogHead, 0
	jmp	write_more			; Write not wrapped part.

FlushLog	ENDP
ENDIF	; 0


;-----------------------------------------------------------------------------
;
;	Initializes COM 1 port.
;
;-----------------------------------------------------------------------------
PUBLIC	InitCom1
InitCom1	PROC

; Initialize LCR.
	mov	edx, fs:[400h + (LOG_COM - 1) * 2 ]		; Get base port for COM1 set by BIOS.
	add	edx, 3
	mov	al, 10000011b		; no parity, 1 stop bit, 8 bits/char, 
					; select divisor LSB/MSB.
	out	dx, al
	sub	edx, 3

; Initialize divisor for 9600 bits/sec.
	mov	eax, 12			; Divisor = 12.
	out	dx, ax

; Set LCR to transmit/receive.
	add	edx, 3
	mov	al, 00000011b		; Set mode to transmit and disable ints.
	out	dx, al
	sub	edx, 3

	ret
InitCom1	ENDP


;-----------------------------------------------------------------------------
;
;	Transmits log to remote terminal.
;
;	I: DS:ESI -> buffer
;	   ECX = length.
;
;	(!) All regs but EDX saved by caller.
;
;-----------------------------------------------------------------------------
TransmitLog	PROC	USES edx

; Wait for line ready.
@@:
	mov	edx, fs:[400h + (LOG_COM - 1) * 2]
	add	edx, 5
	in	al, dx
	test	al, 00100000b			; Transmit holder empty?
	jz	@B				; No, wait.

	lodsb
	mov	edx, fs:[400h + (LOG_COM - 1) * 2]
	out	dx, al				; Send

	dec	ecx
	jnz	@B				; Next

	ret
TransmitLog	ENDP


;-----------------------------------------------------------------------------
;
;	System loop (when there are no running tasks).
;
;-----------------------------------------------------------------------------
PUBLIC	core_start
core_start	PROC
	mov	SystemTask, 1
	sub	eax, eax
	call	TrapVideoPorts	; Enable access to video ports.
	call	RelGenDevPorts	; Enable access to general devices ports.

; Set video mode.
	mov	al, VIDEO_MODE
	call	PmSetVideoMode

	PM_PRINT_CENTERED_STR	(offset M32Title), 0, COLS_PER_ROW - 1, TITLE_ROW, TITLE_ATTR
	PM_PRINT_CENTERED_STR	(offset M32Prompt), 0, COLS_PER_ROW - 1, PROMPT_ROW, TITLE_ATTR

PUBLIC	core_entry
core_entry::
	mov	eax, SysPdbLin
	mov	PdbLin, eax
	mov	eax, SysPagesCtl
	mov	PagesCtl, eax
	mov	eax, SysPdb
	mov	Pdb, eax
	mov	cr3, eax
core_loop:
	sti
; If Mode0 is non-0 (1), set mode 0 via InvokeV86Int
	cmp	QuitPm, 0
	je	core_loop
EXTRN	end_pmode: near32
	jmp	end_pmode
core_start	ENDP


CODE32	ENDS
END
