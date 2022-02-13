head	0.53;
access;
symbols;
locks
	BlackPhantom:0.50
	BlackPhantom:0.53; strict;
comment	@;; @;


0.53
date	2002.05.13.03.00.48;	author BlackPhantom;	state Exp;
branches;
next	0.52;

0.52
date	2001.02.13.04.09.54;	author BlackPhantom;	state Exp;
branches;
next	0.51;

0.51
date	2001.02.12.02.23.02;	author BlackPhantom;	state Exp;
branches;
next	0.50;

0.50
date	2001.02.02.23.44.36;	author BlackPhantom;	state Exp;
branches;
next	0.49;

0.49
date	2001.01.19.19.25.00;	author BlackPhantom;	state Exp;
branches;
next	0.48;

0.48
date	2000.12.27.05.36.43;	author BlackPhantom;	state Exp;
branches;
next	0.47;

0.47
date	2000.11.19.00.48.14;	author BlackPhantom;	state Exp;
branches;
next	0.46;

0.46
date	2000.08.31.02.13.37;	author BlackPhantom;	state Exp;
branches;
next	0.45;

0.45
date	2000.08.15.23.51.37;	author BlackPhantom;	state Exp;
branches;
next	0.44;

0.44
date	2000.03.23.14.09.09;	author BlackPhantom;	state Exp;
branches;
next	0.43;

0.43
date	99.08.10.02.48.18;	author BlackPhantom;	state Exp;
branches;
next	0.42;

0.42
date	99.08.06.17.48.52;	author BlackPhantom;	state Exp;
branches;
next	0.41;

0.41
date	99.07.16.03.18.20;	author BlackPhantom;	state Exp;
branches;
next	0.40;

0.40
date	99.06.05.20.07.01;	author BlackPhantom;	state Exp;
branches;
next	0.39;

0.39
date	99.05.28.22.41.24;	author BlackPhantom;	state Exp;
branches;
next	0.38;

0.38
date	99.05.28.18.27.56;	author BlackPhantom;	state Exp;
branches;
next	0.37;

0.37
date	99.05.28.04.20.40;	author BlackPhantom;	state Exp;
branches;
next	0.36;

0.36
date	99.05.27.22.22.07;	author BlackPhantom;	state Exp;
branches;
next	0.35;

0.35
date	99.05.23.19.52.27;	author BlackPhantom;	state Exp;
branches;
next	0.34;

0.34
date	99.05.23.15.13.32;	author BlackPhantom;	state Exp;
branches;
next	0.33;

0.33
date	99.05.21.02.27.28;	author BlackPhantom;	state Exp;
branches;
next	0.32;

0.32
date	99.05.19.01.13.28;	author BlackPhantom;	state Exp;
branches;
next	0.31;

0.31
date	99.05.17.18.49.52;	author BlackPhantom;	state Exp;
branches;
next	0.30;

0.30
date	99.05.11.17.10.49;	author BlackPhantom;	state Exp;
branches;
next	0.29;

0.29
date	99.05.06.22.37.51;	author BlackPhantom;	state Exp;
branches;
next	0.28;

0.28
date	99.05.05.16.38.55;	author BlackPhantom;	state Exp;
branches;
next	;


desc
@DPMI 0.9 server
@


0.53
log
@Last developed version
@
text
@;=============================================================================
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
;				DPMI.ASM
;				--------
;
;	DPMI 0.9 server.
;
;=============================================================================

	INCLUDE	DPMI.INC
	INCLUDE	X86.INC
	INCLUDE	TASKMAN.INC
	INCLUDE	DEF.INC
	INCLUDE	PHLIB32.MCR

	EXTRN	AddGdtSegment: near16

.486p
	EXTRN	PointerToLinear: near32
	EXTRN	LinearToPhysical: near32
	EXTRN	HeapAllocMem: near32
	EXTRN	HeapAllocPage: near32
	EXTRN	HeapAllocZPage: near32
	EXTRN	HeapFreePage: near32
	EXTRN	HeapFreeMem: near32
	EXTRN	SimulateInt: near32
	EXTRN	LeftFreePages: near32
	EXTRN	SaveClientRegs: near32
	EXTRN	RestoreClientRegs: near32
	EXTRN	WriteLog: near32
	EXTRN	PmHex32ToA: near32
	EXTRN	PmHex16ToA: near32

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

	EXTRN	CurrentTask: dword
	EXTRN	CurrTaskPtr: dword
	EXTRN	GdtBase: dword
	EXTRN	GdtPtr: word
	EXTRN	ListOfListsLin: dword

	EXTRN	Cpu: dword

	EXTRN	VirtualIf: dword

	EXTRN	Field: byte

DATA	SEGMENT	PARA	PUBLIC	USE16	'DATA'

	PUBVAR	PmCallbackCs, DW, ?	; CS for calling PM int/exc handlers.
	PUBVAR	PmCallbackSs, DW, ?	; SS for calling PM int/exc handlers.

	DpmiFunctions	DD	0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0Ah, 0Bh, 0Ch, 0Dh
			DD	100h, 101h, 102h
			DD	200h, 201h, 202h, 203h, 204h, 205h
			DD	300h, 301h, 302h, 303h, 304h, 305h, 306h
			DD	400h
			DD	500h, 501h, 502h, 503h
			DD	600h, 601h, 602h, 603h, 604h
			DD	700h, 701h, 702h, 703h
			DD	800h
			DD	900h, 901h, 902h
			DD	0A00h
			DD	0B00h, 0B01h, 0B02h, 0B03h

DPMI_FUNCTIONS	EQU	($ - offset DpmiFunctions) / 4

	DpmiHandlers	DD	offset AllocLDTSel, offset FreeLDTSel
			DD	offset Seg2Desc, offset GetIncVal
			DD	offset LockSel, offset UnlockSel
			DD	offset GetSegBase, offset SetSegBase
			DD	offset SetSegLimit, offset SetSegAccess
			DD	offset CreateAlias, offset GetDescr
			DD	offset SetDescr, offset AllocSpecLDTDesc

			DD	offset AllocDOSMemBlk, offset FreeDOSMemBlk
			DD	offset ResizeDOSMemBlk

			DD	offset GetRMInt, offset SetRMInt
			DD	offset GetExcHandler, offset SetExcHandler
			DD	offset GetPMInt, offset SetPMInt

			DD	offset SimRMInt, offset CallRMFar
			DD	offset CallRMIret, offset AllocRMCallback
			DD	offset FreeRMCallback, offset GetStateSaveRest
			DD	offset GetRawModeSwitch

			DD	offset GetDpmiVersion

			DD	offset GetFreeMem, offset AllocMem
			DD	offset FreeMem, offset ResizeMem

			DD	offset LockRegion, offset UnlockRegion
			DD	offset MarkPageable, offset RelockRegion
			DD	offset GetPageSize

			DD	offset MarkPagingCand, offset DiscardPages
			DD	offset MarkDemandPagingCand, offset DiscardCont
			DD	offset MapPhysical

			DD	offset GetVifCli, offset GetVifSti
			DD	offset GetVif

			DD	offset GetM32Entry

			DD	offset SetDbgWatch, offset ClearDbgWatch
			DD	offset GetDbgWatchState, offset ResetDbgWatch

	DpmiRetTraps	DD	offset AllocDOSBlockRet, offset FreeDOSBlockRet
			DD	offset ResizeDOSBlockRet, offset RetFromV86Int

	PUBVAR	CurrLdtBase, DD, ?

IFDEF	LOG_DPMI
; Log strings.
	AllocSelStr	DB	"AllocSel: "
	FreeSelStr	DB	"FreeSel: "
	Seg2DescrStr	DB	"Seg2DescrSel: "
	GetIncValStr	DB	"GetIncVal: "
	GetSegBaseStr	DB	"GetSegBase: "
	SetSegBaseStr	DB	"SetSegBase: "
	SetSegLimitStr	DB	"SetSegLimit: "
	SetSegAccessStr	DB	"SetSegAccess: "
	CreateAliasStr	DB	"CreateAlias: "
	GetDescrStr	DB	"GetDescr: "
	SetDescrStr	DB	"SetDescr: "
	AllocSpecSelStr	DB	"AlloSpecLDTDesc: "

	AllocDOSMemStr	DB	"AllocDOSMemBlk: "
	FreeDOSMemStr	DB	"FreeDOSMemBlk: "
	ResizeDOSMemStr	DB	"FesizeDOSMemBlk: "

	GetRMIntStr	DB	"GetRMInt: "
	SetRMIntStr	DB	"SetRMInt: "
	GetPMExcStr	DB	"GetExcHandler: "
	SetPMExcStr	DB	"SetExcHandler: "
	GetPMIntStr	DB	"GetPMInt: "
	SetPMIntStr	DB	"SetPMInt: "

	SimRMIntStr	DB	"SimRMInt: "
	CallRMFarStr	DB	"CallRMFar: "
	CallRMIretStr	DB	"CallRMIret: "
	AllocRMCBackStr	DB	"AllocRMCallBack: "
	FreeRMCBackStr	DB	"FreeRMCallBack: "
	GetSaveRestStr	DB	"GetStateSaveRest: "
	GetRawSwitchStr	DB	"GetRawModeSwitch: "

	GetDPMIVerStr	DB	"GetDPMIVersion: "

	GetFreeMemStr	DB	"GetFreeMem: "
	AllocMemStr	DB	"AllocMem: "
	FreeMemStr	DB	"FreeMem: "
	ResizeMemStr	DB	"ResizeMem: "

	MapPhysStr	DB	"MapPhysical: "

	GetVifCliStr	DB	"GetVifCli: "
	GetVifStiStr	DB	"GetVifSti: "
	GetVifStr	DB	"GetVif: "

	RawPM2VMStr	DB	"RawPM2VM: "
	RawVM2PMStr	DB	"RawVM2PM: "

	AllocDOSBlockRetStr DB	"AllocDOSBlockRet: "
	FreeDOSBlockRetStr DB	"FreeDOSBlockRet: "
	ResizeDOSBlockRetStr DB	"ResizeDOSBlockRet: "
	RetFromV86IntStr DB	"RetFromV86Int: "
	XlatRetStr	DB	"XlatRet: "
	CallRMCallbackStr DB	"CallRMCallback: "
	RMCallbackRetStr DB	"RMCallbackRet: "
ENDIF	; LOG_DPMI

PUBVAR	CheckPt, DB, 0
	PUBVAR	LogX, DB, 0
	PUBVAR	LogY, DB, 0
	PUBVAR	LogClr, DB, 1

DATA	ENDS


CODE	SEGMENT	PARA	PUBLIC	USE16	'CODE'
ASSUME CS:CODE, DS:DATA

;-----------------------------------------------------------------------------
;
;	Real-mode initialization of DPMI server: allocate necessary GDT
; segments - CS for protected mode entry points and SS for protected mode
; locked stack.
;
;-----------------------------------------------------------------------------
PUBLIC	InitDpmiServer
InitDpmiServer	PROC
	ADD_GDT_SEGMENT	(DPMI_SERVICE_SEG SHL 4), 0FFFFh, CODE_ACCESS OR 01100000b
	or	ax, 3
	mov	PmCallbackCs, ax

	ADD_GDT_SEGMENT	(DPMI_SERVICE_SEG SHL 4), 0FFFFh, DATA_ACCESS OR 01100000b
	or	ax, 3
	mov	PmCallbackSs, ax

	ret
InitDpmiServer	ENDP

CODE	ENDS


CODE32	SEGMENT	PARA	PUBLIC	USE32	'CODE'
ASSUME	CS:CODE32, DS:FLAT


;-----------------------------------------------------------------------------
;
;	DPMI mode switches: initial, raw PM to VM and raw VM to PM.
;
;-----------------------------------------------------------------------------
PUBLIC	DpmiSwitch
DpmiSwitch	PROC	USES es eax ebx ecx edx esi edi ebp
PUSHCONTEXT	ASSUMES
ASSUME	ebp: PTR DosTask
	mov	si, ExcSeg
	mov	edi, ExcOffs
	mov	ebx, ExcEflags
	call	PointerToLinear
	push	eax
	call	LinearToPhysical
	pop	eax
	jc	err_ret			; Linear address is invalid.

	test	ExcEflags, FL_VM	; If PM, check for switch to VM.
	jz	switch_pm2vm?

	cmp	eax, VM2PM_SWITCH_ADDR
	je	switch_vm2pm?
	cmp	eax, INIT_SWITCH_ADDR
	jne	err_ret

;----------------------------------
;	Initial DPMI mode switch.
;----------------------------------

; If task made initial mode switch, return CF = 1.
	mov	ebp, CurrTaskPtr
	cmp	fs:[ebp].TaskLdt, 0
	je	@@F
	or	ExcEflags, FL_CF
	jmp	ok_ret
@@@@:
; Return CF = 1 if not enough free memory for DPMI init allocations.
	call	LeftFreePages
	shl	eax, 12
	cmp	eax, DPMI_BUF_SIZE
	jnb	@@F
	or	ExcEflags, FL_CF
	jmp	ok_ret

@@@@:
	push	fs
	pop	es
	cld

; Set initial locked stack pointers.
	mov	fs:[ebp].DpmiRmEsp, VM_LOCKED_ESP
	mov	fs:[ebp].DpmiRmStack, VM_LOCKED_STACK
	mov	fs:[ebp].DpmiPmEsp, PM_LOCKED_ESP
	mov	fs:[ebp].DpmiPmStack, PM_LOCKED_STACK

; Allocate and zero DOS memory blocks structure (up to 682 blocks).
	mov	eax, PAGE_PRESENT OR PAGE_WRITABLE
	call	HeapAllocZPage
	mov	fs:[ebp].DpmiDOSBlocks, eax

; Allocate and zero DPMI interrupts and exceptions handlers.
	mov	eax, PAGE_PRESENT OR PAGE_WRITABLE
	call	HeapAllocZPage
	mov	fs:[ebp].DpmiPmInts, eax

	mov	eax, PAGE_PRESENT OR PAGE_WRITABLE
	call	HeapAllocZPage
	mov	fs:[ebp].DpmiPmExcs, eax

; Allocate and zero DPMI callbacks.
	mov	eax, PAGE_PRESENT OR PAGE_WRITABLE
	call	HeapAllocZPage
	mov	fs:[ebp].DpmiCallbackArr, eax

; Allocate page for DPMI PM state saves.
	mov	eax, PAGE_PRESENT OR PAGE_WRITABLE
	call	HeapAllocPage
	mov	fs:[ebp].DpmiPmStateSave, eax
	
; Zero PM state save pointer.
	mov	fs:[ebp].DpmiPmStatePtr, 0

; Allocate page for DPMI RM state saves.
	mov	eax, PAGE_PRESENT OR PAGE_WRITABLE
	call	HeapAllocPage
	mov	fs:[ebp].DpmiRmStateSave, eax

; Zero RM state save pointer.
	mov	fs:[ebp].DpmiRmStatePtr, 0

; Create & load LDT.
	call	CreateLdt
	mov	fs:[ebp].TaskLdt, ax
	mov	fs:[ebp].TaskLdtLimit, 80h
	lldt	ax

; Set correct return address (emulate RETF).
	movzx	ecx, ExcSs
	shl	ecx, 4

	movzx	edx, word ptr ExcEsp
	add	ecx, edx
	mov	dx, fs:[ecx]
	mov	word ptr ExcOffs, dx
	mov	dx, fs:[ecx+2]
	mov	ExcSeg, dx
	add	word ptr ExcEsp, 4

;
;	Set ES point to owner PSP. Walk MSB chain to determine caller's 
; owning PSP.
;
	mov	edx, ListOfListsLin
	movzx	ecx, word ptr fs:[edx-2]	
	shl	ecx, 4				; ECX = MCB linear address.
	movzx	ebx, ExcSeg
	shl	ebx, 4				; EBX = caller CS lin. addr.
find_caller:
	movzx	eax, word ptr fs:[ecx+3]
	inc	eax
	shl	eax, 4				; EAX = next MCB
	add	eax, ecx
	cmp	eax, ebx
	ja	caller_found

	mov	ecx, eax
	jmp	find_caller

caller_found:
; Set FS:EBX point to LDT
	mov	ebx, CurrLdtBase
	mov	esi, ecx

; Allocate LDT descriptor for ES containing owner PSP.
	movzx	eax, word ptr fs:[ecx+1]
	shl	eax, 4
	mov	ecx, 0FFFFh
	mov	edx, DATA_ACCESS OR 01100000b
	call	AddSegment
	or	eax, 7
	mov	ExcEs, ax			; ES = caller's PSP.
	add	fs:[ebp].TaskLdtLimit, 8

; Set current process ID and task's PSP.
	mov	fs:[ebp].TaskPmPsp, ax
	mov	fs:[ebp].TaskCurrentId, ax

; Replace environment segment address in PSP with selector.
	movzx	esi, word ptr fs:[esi+1]
	shl	esi, 4				; FS:ESI -> PSP
	movzx	eax, word ptr fs:[esi+2Ch]
	shl	eax, 4
	mov	ecx, 0FFFFh
	mov	edx, DATA_ACCESS OR 01100000b
	call	AddSegment
	or	eax, 7
	mov	fs:[esi+2Ch], ax		; Store env. selector
	add	fs:[ebp].TaskLdtLimit, 8

; Allocate LDT descriptors for CS, DS, SS.
	movzx	eax, ExcSeg
	shl	eax, 4
	mov	ecx, 0FFFFh
	mov	edx, CODE_ACCESS OR 01100000b
	call	AddSegment
	or	eax, 7
	mov	ExcSeg, ax
	add	fs:[ebp].TaskLdtLimit, 8

	movzx	eax, ExcDs
	shl	eax, 4
	mov	ecx, 0FFFFh
	mov	edx, DATA_ACCESS OR 01100000b
	call	AddSegment
	or	eax, 7
	mov	ExcDs, ax
	add	fs:[ebp].TaskLdtLimit, 8

	movzx	eax, ExcSs
	shl	eax, 4
	mov	ecx, 0FFFFh
	mov	edx, DATA_ACCESS OR 01100000b
	call	AddSegment
	or	eax, 7
	mov	ExcSs, ax
	add	fs:[ebp].TaskLdtLimit, 8

; Allocate LDT descriptor for RM callback SS.
	sub	eax, eax
	mov	ecx, 0FFFFh
	mov	edx, DATA_ACCESS OR 01100000b
	call	AddSegment
	or	eax, 7
	mov	fs:[ebp].DpmiRmSs, ax

	mov	ExcFs, 0
	mov	ExcGs, 0

	and	ExcEflags, NOT (FL_VM OR FL_CF)		; Set protected mode, no error.
	mov	eax, ExcEax
	and	eax, TASK_32BIT
	mov	fs:[ebp].TaskFlags, eax

; If 32 bit task, set callback CS and callback SS to 32-bit defaults.
	test	eax, TASK_32BIT
	jz	ok_ret

	mov	ebx, GdtBase
	movzx	eax, PmCallbackCs
	and	eax, NOT 7
	or	(Descriptor386 PTR fs:[ebx][eax]).LimitHigh20, ATTR_DEF

	movzx	eax, PmCallbackSs
	and	eax, NOT 7
	or	(Descriptor386 PTR fs:[ebx][eax]).LimitHigh20, ATTR_DEF

	jmp	ok_ret

switch_vm2pm?:
;----------------------------------
; Raw VM to PM switch.
;----------------------------------
IFDEF	MONITOR_DPMI
pushad
	PM_PRINT_HEX16	8000h, LogX, LogY, LogClr
	add	LogX, 5
	cmp	LogX, 72
	jb	@@F
	mov	LogX, 0
	inc	LogY
	cmp	LogY, 25
	jb	@@F
	mov	LogY, 0
	inc	LogClr
	cmp	LogClr, 16
	jb	@@F
	mov	LogClr, 1
@@@@:
popad
ENDIF

IFDEF	LOG_DPMI
	pushad
	PRINT_LOG	RawVM2PMStr
	popad
	LOG_STATE
ENDIF

; If task didn't make initial mode switch, return error.
	mov	eax, CurrTaskPtr
	cmp	(DosTask PTR fs:[eax]).TaskLdt, 0
	je	err_ret

; Switch VM to PM (raw).
	and	ExcEflags, NOT FL_VM
	test	(DosTask PTR fs:[eax]).TaskFlags, TASK_32BIT
	jz	set_16bit_regs

; Set 32-bit regs.
	mov	ebx, ExcEbx				; New mode ESP.
	mov	ExcEsp, ebx
	mov	ebx, ExcEdi				; New mode EIP.
	mov	ExcOffs, ebx

	jmp	set_raw_regs
	
switch_pm2vm?:
	cmp	eax, PM2VM_SWITCH_ADDR
	jne	err_ret

;----------------------------------
; Raw PM to VM switch.
;----------------------------------
IFDEF	MONITOR_DPMI
pushad
	PM_PRINT_HEX16	8001h, LogX, LogY, LogClr
	add	LogX, 5
	cmp	LogX, 72
	jb	@@F
	mov	LogX, 0
	inc	LogY
	cmp	LogY, 25
	jb	@@F
	mov	LogY, 0
	inc	LogClr
	cmp	LogClr, 16
	jb	@@F
	mov	LogClr, 1
@@@@:
popad
ENDIF

IFDEF	LOG_DPMI
	pushad
	PRINT_LOG	RawPM2VMStr
	popad
	LOG_STATE
ENDIF

; Set V86 mode and stack.

; Switch PM to VM (raw).
	or	ExcEflags, FL_VM

set_16bit_regs:
	movzx	ebx, word ptr ExcEbx			; New mode ESP.
	mov	ExcEsp, ebx
	movzx	ebx, word ptr ExcEdi			; New mode EIP.
	mov	ExcOffs, ebx

; Set state registers.
set_raw_regs:
	mov	ax, word ptr ExcEax			; New mode DS.
	mov	ExcDs, ax
	mov	ax, word ptr ExcEcx			; New mode ES.
	mov	ExcEs, ax
	mov	ax, word ptr ExcEdx			; New mode SS.
	mov	ExcSs, ax
	mov	ax, word ptr ExcEsi			; New mode CS.
	mov	ExcSeg, ax

	mov	ExcFs, 0
	mov	ExcGs, 0

ok_ret:
	clc
	ret

err_ret:
	stc
	ret
POPCONTEXT	ASSUMES
DpmiSwitch	ENDP


;-----------------------------------------------------------------------------
;
;	INT 31h handler: DPMI API.
;
;	I:
;	O:	CF = 0 handled
;		CF = 1 invalid function
;
;-----------------------------------------------------------------------------
PUBLIC	Int31Handler
Int31Handler	PROC	USES eax ebx ecx edx esi edi ebp
	movzx	eax, word ptr ExcEax

IFDEF	MONITOR_DPMI
pushad
	PM_PRINT_HEX16	, LogX, LogY, LogClr
	add	LogX, 5
	cmp	LogX, 72
	jb	@@F
	mov	LogX, 0
	inc	LogY
	cmp	LogY, 25
	jb	@@F
	mov	LogY, 0
	inc	LogClr
	cmp	LogClr, 16
	jb	@@F
	mov	LogClr, 1
@@@@:
popad
ENDIF

	sub	ecx, ecx
find_func:
	cmp	eax, DpmiFunctions[ ecx * 4 ]
	je	jump_to_handler

	inc	ecx
	cmp	ecx, DPMI_FUNCTIONS
	jb	find_func

	stc
	ret

jump_to_handler:
	jmp	DpmiHandlers[ ecx * 4 ]

;-----------------------------------------------------------------------------
; Allocate LDT selectors.
;-----------------------------------------------------------------------------
AllocLDTSel::
	mov	ebx, CurrLdtBase		; -> Current LDT
	movzx	eax, word ptr ExcEcx		; # of descriptors
IFDEF	MONITOR_DPMI_VAL
pushad
	mov	bl, LogClr
	add	bl, 70h
	PM_PRINT_HEX16	, LogX, LogY
	add	LogX, 5
	cmp	LogX, 72
	jb	@@F
	mov	LogX, 0
	inc	LogY
	cmp	LogY, 25
	jb	@@F
	mov	LogY, 0
	inc	LogClr
	cmp	LogClr, 16
	jb	@@F
	mov	LogClr, 1
@@@@:
popad
ENDIF

IFDEF	LOG_DPMI
	pushad
	PRINT_LOG	AllocSelStr
	mov	edi, offset Field
	call	PmHex16ToA
	mov	Field[4], 13
	mov	Field[5], 10
	mov	eax, offset Field
	mov	ecx, 6
	mov	esi, offset Field
	call	WriteLog
	popad
	LOG_STATE
ENDIF

	call	FindNFreeDtEntries
	jnc	@@F
	jmp	ret_cf_1

@@@@:
	mov	word ptr ExcEax, ax		; Base selector
; Zero all allocated descriptors and make them present (allocated).
	movzx	ecx, word ptr ExcEcx
@@@@:
IFDEF	DPMI_COOKIE
	mov	(Descriptor386 PTR fs:[ebx][eax]).Access, DATA_ACCESS OR 01100000b
ELSE	
	mov	(Descriptor386 PTR fs:[ebx][eax]).Access, ACC_PRESENT
ENDIF	; DPMI_COOKIE
	add	eax, 8
	dec	ecx
	jnz	@@B

	or	ExcEax, 7
	jmp	ret_cf_0			; Success


;-----------------------------------------------------------------------------
; Free LDT descriptor. Task is allowed to free any descriptor in its LDT.
;-----------------------------------------------------------------------------
FreeLDTSel::

IFDEF	LOG_DPMI
	pushad
	PRINT_LOG	FreeSelStr
	mov	ax, word ptr ExcEbx
	mov	edi, offset Field
	call	PmHex16ToA
	mov	Field[4], 13
	mov	Field[5], 10
	mov	eax, offset Field
	mov	ecx, 6
	mov	esi, offset Field
	call	WriteLog
	popad
	LOG_STATE
ENDIF

; Don't allow to release CS and SS.
	movzx	eax, word ptr ExcEbx
	and	eax, NOT 7

	movzx	ebx, ExcSeg
	and	ebx, NOT 7
	cmp	eax, ebx
	je	ret_cf_0
@@@@:
	movzx	ebx, ExcSs
	and	ebx, NOT 7
	cmp	eax, ebx
	je	ret_cf_0

	movzx	eax, word ptr ExcEbx
	call	ValidateUserSel
	jnc	@@F

	jmp	ret_cf_1			; Error.

@@@@:
	mov	ebx, CurrLdtBase
	and	eax, NOT 7
	and	(Descriptor386 PTR fs:[ebx][eax]).Access, NOT ACC_PRESENT

;
; If one of user segments was pointing to the segment being freed, it is set
; to NULL segment.
;
	movzx	eax, word ptr ExcEbx
	and	eax, NOT 7

	movzx	ebx, ExcDs
	and	ebx, NOT 7
	cmp	eax, ebx
	jne	@@F
	mov	ExcDs, 0
@@@@:
	movzx	ebx, ExcEs
	and	ebx, NOT 7
	cmp	eax, ebx
	jne	@@F
	mov	ExcEs, 0
@@@@:
	movzx	ebx, ExcFs
	and	ebx, NOT 7
	cmp	eax, ebx
	jne	@@F
	mov	ExcFs, 0
@@@@:
	movzx	ebx, ExcGs
	and	ebx, NOT 7
	cmp	eax, ebx
	jne	@@F
	mov	ExcGs, 0

	jmp	ret_cf_0			; Success


;-----------------------------------------------------------------------------
;	Convert (map) RM segment to descriptor.
;-----------------------------------------------------------------------------
Seg2Desc::

IFDEF	LOG_DPMI
	pushad
	PRINT_LOG	Seg2DescrStr
	mov	ax, word ptr ExcEbx
	mov	edi, offset Field
	call	PmHex16ToA
	mov	Field[4], 13
	mov	Field[5], 10
	mov	eax, offset Field
	mov	ecx, 6
	mov	esi, offset Field
	call	WriteLog
	popad
	LOG_STATE
ENDIF

	mov	ebx, CurrLdtBase
; Look for segment already mapped.
	mov	eax, CurrTaskPtr
	movzx	esi, (DosTask PTR fs:[eax]).TaskLdtLimit
	movzx	eax, word ptr ExcEbx
	shl	eax, 4				; Linear address.
	mov	ecx, 8
seg_mapped?:
	cmp	ecx, esi
	jnb	add_sel

; Check base address.
	mov	dh, (Descriptor386 PTR fs:[ebx][ecx]).BaseHigh32
	mov	dl, (Descriptor386 PTR fs:[ebx][ecx]).BaseHigh24
	shl	edx, 16
	mov	dx, (Descriptor386 PTR fs:[ebx][ecx]).BaseLow
	cmp	eax, edx
	jne	@@F

	lea	eax, [ecx+7]
	jmp	store_sel

@@@@:
	add	ecx, 8
	jmp	seg_mapped?

add_sel:
	mov	ecx, 0FFFFh		; Limit = 64k
	mov	edx, DATA_ACCESS OR 01100000b
	call	AddSegment
	jnc	@@F
	jmp	ret_cf_1		; Error.

@@@@:
	or	eax, 7
store_sel:
	mov	word ptr ExcEax, ax
	jmp	ret_cf_0		; Success.


;-----------------------------------------------------------------------------
;	Get increment value (8).
;-----------------------------------------------------------------------------
GetIncVal::
	mov	word ptr ExcEax, 8
	jmp	ret_cf_0		; Success.


;-----------------------------------------------------------------------------
;	Lock and unlock selector functions work as Windows 95 VirtualLock():
; do nothing but return. They are mentioned "reserved" in DPMI spec.
;-----------------------------------------------------------------------------
LockSel::
UnlockSel::
	jmp	ret_cf_0		; Success.


;-----------------------------------------------------------------------------
;	Get segment base address.
;-----------------------------------------------------------------------------
GetSegBase::

IFDEF	LOG_DPMI
	pushad
	PRINT_LOG	GetSegBaseStr
	mov	ax, word ptr ExcEbx
	mov	edi, offset Field
	call	PmHex16ToA
	mov	Field[4], 13
	mov	Field[5], 10
	mov	eax, offset Field
	mov	ecx, 6
	mov	esi, offset Field
	call	WriteLog
	popad
	LOG_STATE
ENDIF

	movzx	eax, word ptr ExcEbx
	call	ValidateUserSel
	jnc	@@F
	jmp	ret_cf_1		; Error.

@@@@:
	mov	ebx, CurrLdtBase
	and	eax, NOT 7
	mov	cl, (Descriptor386 PTR fs:[ebx][eax]).BaseHigh24
	mov	ch, (Descriptor386 PTR fs:[ebx][eax]).BaseHigh32
	mov	word ptr ExcEcx, cx
	mov	dx, (Descriptor386 PTR fs:[ebx][eax]).BaseLow
	mov	word ptr ExcEdx, dx
	jmp	ret_cf_0		; Success.


;-----------------------------------------------------------------------------
;	Get segment base address.
;-----------------------------------------------------------------------------
SetSegBase::

IFDEF	LOG_DPMI
	pushad
	PRINT_LOG	SetSegBaseStr

	mov	ax, word ptr ExcEbx
	mov	edi, offset Field
	call	PmHex16ToA
	mov	Field[4], ' '
	mov	eax, offset Field
	mov	ecx, 5
	mov	esi, offset Field
	call	WriteLog

	mov	eax, ExcEcx
	shl	eax, 16
	mov	ax, word ptr ExcEdx
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

	movzx	eax, word ptr ExcEbx
	call	ValidateUserSel
	jnc	@@F
	jmp	ret_cf_1			; Error.
@@@@:

IFDEF	MONITOR_DPMI_VAL
pushad
	mov	eax, ExcEcx
	mov	esi, ExcEdx
	shl	eax, 16
	and	esi, 0FFFFh
	add	eax, esi
	mov	bl, LogClr
	add	bl, 70h
	PM_PRINT_HEX32	, LogX, LogY
	add	LogX, 9
	cmp	LogX, 72
	jb	@@F
	mov	LogX, 0
	inc	LogY
	cmp	LogY, 25
	jb	@@F
	mov	LogY, 0
	inc	LogClr
	cmp	LogClr, 16
	jb	@@F
	mov	LogClr, 1
@@@@:
popad
ENDIF
	mov	ebx, CurrLdtBase
	and	eax, NOT 7
	mov	ecx, ExcEcx
	mov	(Descriptor386 PTR fs:[ebx][eax]).BaseHigh24, cl
	mov	(Descriptor386 PTR fs:[ebx][eax]).BaseHigh32, ch
	mov	edx, ExcEdx
	mov	(Descriptor386 PTR fs:[ebx][eax]).BaseLow, dx
@@@@:
	jmp	ret_cf_0			; Success.


;-----------------------------------------------------------------------------
;	Set segment limit.
;-----------------------------------------------------------------------------
SetSegLimit::

IFDEF	LOG_DPMI
	pushad
	PRINT_LOG	SetSegLimitStr

	mov	ax, word ptr ExcEbx
	mov	edi, offset Field
	call	PmHex16ToA
	mov	Field[4], ' '
	mov	eax, offset Field
	mov	ecx, 5
	mov	esi, offset Field
	call	WriteLog

	mov	eax, ExcEcx
	shl	eax, 16
	mov	ax, word ptr ExcEdx
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

	movzx	eax, word ptr ExcEbx
	call	ValidateUserSel
	jnc	@@F
	jmp	ret_cf_1			; Error.

@@@@:
	mov	ebx, CurrLdtBase
	and	eax, NOT 7

	mov	ecx, ExcEcx
	shl	ecx, 16
	mov	cx, word ptr ExcEdx
	cmp	ecx, 100000h
	jb	gran_set

; Page granular limit.
	shr	ecx, 12
	or	ecx, ATTR_GRAN SHL 16

gran_set:
	mov	(Descriptor386 PTR fs:[ebx][eax]).LimitLow, cx
	shr	ecx, 16
	and	(Descriptor386 PTR fs:[ebx][eax]).LimitHigh20, 0F0h
	or	(Descriptor386 PTR fs:[ebx][eax]).LimitHigh20, cl
	jmp	ret_cf_0			; Success.


;-----------------------------------------------------------------------------
;	Set access rights.
;-----------------------------------------------------------------------------
SetSegAccess::

IFDEF	LOG_DPMI
	pushad
	PRINT_LOG	SetSegAccessStr

	mov	ax, word ptr ExcEbx
	mov	edi, offset Field
	call	PmHex16ToA
	mov	Field[4], ' '
	mov	eax, offset Field
	mov	ecx, 5
	mov	esi, offset Field
	call	WriteLog

	mov	eax, ExcEcx
	call	PmHex16ToA
	mov	Field[4], 13
	mov	Field[5], 10
	mov	eax, offset Field
	mov	ecx, 6
	mov	esi, offset Field
	call	WriteLog
	popad
	LOG_STATE
ENDIF

	movzx	eax, word ptr ExcEbx
	call	ValidateUserSel
	jnc	@@F
	jmp	ret_cf_1			; Error.

@@@@:
	mov	ebx, CurrLdtBase
	and	eax, NOT 7

	mov	ecx, ExcEcx

	mov	(Descriptor386 PTR fs:[ebx][eax]).Access, cl
	and	ch, 0F0h
	and	(Descriptor386 PTR fs:[ebx][eax]).LimitHigh20, 0Fh
	or	(Descriptor386 PTR fs:[ebx][eax]).LimitHigh20, ch
	jmp	ret_cf_0			; Success.


;-----------------------------------------------------------------------------
;	Create alias data descriptor.
;-----------------------------------------------------------------------------
CreateAlias::

IFDEF	LOG_DPMI
	pushad
	PRINT_LOG	CreateAliasStr

	mov	ax, word ptr ExcEbx
	mov	edi, offset Field
	call	PmHex16ToA
	mov	Field[4], 13
	mov	Field[5], 10
	mov	eax, offset Field
	mov	ecx, 6
	mov	esi, offset Field
	call	WriteLog
	popad
	LOG_STATE
ENDIF

	movzx	eax, word ptr ExcEbx
	call	ValidateUserSel
	jnc	@@F
	jmp	ret_cf_1			; Error.

@@@@:
	mov	ebx, CurrLdtBase
	and	eax, NOT 7

IF 0
; If not code segment, return fail.
	mov	cl, (Descriptor386 PTR fs:[ebx][eax]).Access
	and	cl, ACC_CODE
	cmp	cl, ACC_CODE
	je	@@F
	jmp	ret_cf_1			; Error.

@@@@:
ENDIF
	mov	ecx, eax			; Keep original code descr.
	call	FindFreeDtEntry			; Get aliad LDT entry.

; Copy source descriptor to dest.
	mov	edx, fs:[ebx][ecx]
	mov	fs:[ebx][eax], edx
	mov	edx, fs:[ebx][ecx][4]
	mov	fs:[ebx][eax][4], edx
	mov	(Descriptor386 PTR fs:[ebx][eax]).Access, DATA_ACCESS OR 01100000b
	or	eax, 7
	mov	word ptr ExcEax, ax
	jmp	ret_cf_0			; Success.


;-----------------------------------------------------------------------------
;	Get descriptor.
;-----------------------------------------------------------------------------
GetDescr::
IFDEF	LOG_DPMI
	pushad
	PRINT_LOG	GetDescrStr

	mov	ax, word ptr ExcEbx
	mov	edi, offset Field
	call	PmHex16ToA
	mov	Field[4], ' '
	mov	eax, offset Field
	mov	ecx, 5
	mov	esi, offset Field
	call	WriteLog

	mov	ax, ExcEs
	call	PmHex16ToA
	mov	Field[4], ':'
	mov	eax, offset Field
	mov	ecx, 5
	mov	esi, offset Field
	call	WriteLog

	mov	eax, ExcEdi
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

	movzx	eax, word ptr ExcEbx
	call	ValidateUserSel
	jnc	@@F
	jmp	ret_cf_1			; Error.

@@@@:
	and	eax, NOT 7

	push	eax
; Get pointer to user buffer.
	mov	si, ExcEs
	mov	edi, ExcEdi
	mov	eax, CurrTaskPtr
	test	(DosTask PTR fs:[eax]).TaskFlags, TASK_32BIT
	jnz	@@F

; 16 bit tasks only set DI.
	and	edi, 0FFFFh
@@@@:
	mov	ebx, ExcEflags
	call	PointerToLinear
	mov	edx, eax		; FS:EDX -> dest.
	call	LinearToPhysical	; Verify linear address.
	pop	eax
	jc	ret_cf_1		; Linear address is wrong.

	mov	ebx, CurrLdtBase		; FS:EBX+EAX -> source.

; Copy descriptor.
	mov	ecx, fs:[ebx][eax]
	mov	fs:[edx], ecx
	mov	ecx, fs:[ebx][eax][4]
	mov	fs:[edx][4], ecx
	jmp	ret_cf_0			; Success.


;-----------------------------------------------------------------------------
;	Set descriptor.
;-----------------------------------------------------------------------------
SetDescr::
IFDEF	LOG_DPMI
	pushad
	PRINT_LOG	SetDescrStr

	mov	ax, word ptr ExcEbx
	mov	edi, offset Field
	call	PmHex16ToA
	mov	Field[4], ' '
	mov	eax, offset Field
	mov	ecx, 5
	mov	esi, offset Field
	call	WriteLog

	mov	ax, ExcEs
	call	PmHex16ToA
	mov	Field[4], ':'
	mov	eax, offset Field
	mov	ecx, 5
	mov	esi, offset Field
	call	WriteLog

	mov	eax, ExcEdi
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

	movzx	eax, word ptr ExcEbx
	call	ValidateUserSel
	jnc	@@F
	jmp	ret_cf_1			; Error.

@@@@:
	and	eax, NOT 7
	mov	ebp, eax
; Get pointer to user buffer.
	mov	si, ExcEs
	mov	edi, ExcEdi
	mov	eax, CurrTaskPtr
	test	(DosTask PTR fs:[eax]).TaskFlags, TASK_32BIT
	jnz	@@F

; 16 bit tasks only set DI.
	and	edi, 0FFFFh
@@@@:
	mov	ebx, ExcEflags
	call	PointerToLinear

	mov	edx, eax			; FS:EDX -> source.

	call	LinearToPhysical
	jc	ret_cf_1			; Linear address is wrong.

	mov	ebx, CurrLdtBase		; FS:EBX+EBP -> dest.

; Copy descriptor.
	mov	ecx, fs:[edx]
	mov	fs:[ebx][ebp], ecx
	mov	ecx, fs:[edx][4]
	mov	fs:[ebx][ebp][4], ecx
	jmp	ret_cf_0			; Success.


;-----------------------------------------------------------------------------
;	Allocate descriptor for given selector.
;-----------------------------------------------------------------------------
AllocSpecLDTDesc::
	movzx	eax, word ptr ExcEbx
	call	ValidateUserSel
	jnc	@@F
	jmp	ret_cf_1			; Error.

@@@@:
	mov	ebx, CurrLdtBase
	and	eax, NOT 7
	test	(Descriptor386 PTR fs:[ebx][eax]).Access, ACC_PRESENT
	jz	@@F
	jmp	ret_cf_1			; Error.

@@@@:
; Allocate.
	or	(Descriptor386 PTR fs:[ebx][eax]).Access, ACC_PRESENT OR 01100000b
	jmp	ret_cf_0			; Success.


;-----------------------------------------------------------------------------
;	Allocate DOS memory block.
;-----------------------------------------------------------------------------
AllocDOSMemBlk::
IFDEF	LOG_DPMI
	pushad
	PRINT_LOG	AllocDOSMemStr

	mov	ax, word ptr ExcEbx
	mov	edi, offset Field
	call	PmHex16ToA
	mov	Field[4], 13
	mov	Field[5], 10
	mov	eax, offset Field
	mov	ecx, 6
	mov	esi, offset Field
	call	WriteLog
	popad
	LOG_STATE
ENDIF

;
; Set registers to call allocate block. Call SimulateInt from protmode.
;
	mov	byte ptr ExcEax[1], 48h
	mov	eax, 21h
	call	SimulateInt

	jmp	ok_ret				; Don't return error or success.


;-----------------------------------------------------------------------------
;	Free DOS memory block
;-----------------------------------------------------------------------------
FreeDOSMemBlk::

IFDEF	LOG_DPMI
	pushad
	PRINT_LOG	FreeDOSMemStr

	mov	ax, word ptr ExcEdx
	mov	edi, offset Field
	call	PmHex16ToA
	mov	Field[4], 13
	mov	Field[5], 10
	mov	eax, offset Field
	mov	ecx, 6
	mov	esi, offset Field
	call	WriteLog
	popad
	LOG_STATE
ENDIF

; Look in allocated selectors list for requestred selector.
	mov	eax, CurrTaskPtr
	mov	esi, (DosTask PTR fs:[eax]).DpmiDOSBlocks
	mov	eax, ExcEdx

; DosBlockSel structure keeps index, not user mode selector!
	and	eax, NOT 7
	sub	edi, edi
@@@@:
	cmp	(DosBlockSel PTR fs:[esi][edi]).wSel, ax
	je	@@F
	add	edi, SIZEOF DosBlockSel
	cmp	edi, 1000h
	jb	@@B

	mov	word ptr ExcEax, 9		; Wrong selector
	jmp	ret_cf_1			; Error.

@@@@:
;
; Set registers to call free block. Call SimulateInt from protmode.
;
	mov	byte ptr ExcEax[1], 49h
	mov	eax, 21h
	call	SimulateInt
	mov	ax, (DosBlockSel PTR fs:[esi][edi]).wSeg
	mov	ExcEs, ax

	jmp	ok_ret				; Don't return error or success.


;-----------------------------------------------------------------------------
;	Resize DOS memory block.
;-----------------------------------------------------------------------------
ResizeDOSMemBlk::
IFDEF	LOG_DPMI
	pushad
	PRINT_LOG	ResizeDOSMemStr

	mov	ax, word ptr ExcEbx
	mov	edi, offset Field
	call	PmHex16ToA
	mov	Field[4], ' '
	mov	eax, offset Field
	mov	ecx, 5
	mov	esi, offset Field
	call	WriteLog

	mov	ax, word ptr ExcEdx
	mov	edi, offset Field
	call	PmHex16ToA
	mov	Field[4], 13
	mov	Field[5], 10
	mov	eax, offset Field
	mov	ecx, 6
	mov	esi, offset Field
	call	WriteLog
	popad
	LOG_STATE
ENDIF

; Look in allocated selectors list for requestred selector.
	mov	eax, CurrTaskPtr
	mov	esi, (DosTask PTR fs:[eax]).DpmiDOSBlocks
	mov	eax, ExcEdx
	sub	edx, edx
@@@@:
	cmp	(DosBlockSel PTR fs:[esi][edx]).wSel, ax
	je	@@F
	add	edx, SIZEOF DosBlockSel
	cmp	edx, 1000h
	jb	@@B

	mov	word ptr ExcEax, 9		; Wrong selector
	jmp	ret_cf_1			; Error.

@@@@:
; Check whether there are enough free contiguous descriptors if expanding block.
	movzx	eax, (DosBlockSel PTR fs:[esi][edx]).wSeg
	shl	eax, 4
	movzx	ecx, word ptr fs:[eax-0Dh]	; Block size in MCB.
	cmp	cx, word ptr ExcEbx		; Expanding?
	jnb	do_resize			; No,

; Expanding block, check if enough descriptors.
	movzx	eax, word ptr ExcEbx
	shr	eax, (16-4)			
	inc	eax				; Number of descriptors needed.

; Look in LDT for enough descriptors.
	mov	ebx, CurrLdtBase
	movzx	ebx, (DosBlockSel PTR fs:[esi][edx]).wSel
	movzx	edi, (DosBlockSel PTR fs:[esi][edx]).wNSels
	sub	eax, edi			; Number of extra descriptors.

@@@@:
	test	(Descriptor386 PTR fs:[ebx][edi*8]).Access, ACC_PRESENT
	jnz	@@F
	dec	eax
	jnz	@@B
; Ok, go on resize.
	jmp	do_resize

; Fail - not enough descriptors.
@@@@:
	mov	word ptr ExcEax, 9		; Wrong selector.
	jmp	ret_cf_1			; Error.

do_resize:
;
; Set registers to call resize block block. Call SimulateInt from protmode.
;
	mov	eax, 21h
	call	SimulateInt
	mov	byte ptr ExcEax[1], 4Ah
	mov	di, (DosBlockSel PTR fs:[esi][edx]).wSeg
	mov	ExcEs, di

	jmp	ok_ret				; Don't return error or success.


;-----------------------------------------------------------------------------
;	Get real mode interrupt vector.
;-----------------------------------------------------------------------------
GetRMInt::
IFDEF	LOG_DPMI
	pushad
	PRINT_LOG	GetRMIntStr

	mov	ax, word ptr ExcEbx
	mov	edi, offset Field
	call	PmHex16ToA
	mov	Field[4], 13
	mov	Field[5], 10
	mov	eax, offset Field
	mov	ecx, 6
	mov	esi, offset Field
	call	WriteLog
	popad
	LOG_STATE
ENDIF


	movzx	eax, byte ptr ExcEbx		; Interrupt number
	mov	edx, fs:[eax*4]
	mov	word ptr ExcEdx, dx
	shr	edx, 16
	mov	word ptr ExcEcx, dx
	jmp	ret_cf_0			; Success.


;-----------------------------------------------------------------------------
;	Set real mode interrupt vector.
;-----------------------------------------------------------------------------
SetRMInt::
IFDEF	LOG_DPMI
	pushad
	PRINT_LOG	SetRMIntStr

	mov	ax, word ptr ExcEbx
	mov	edi, offset Field
	call	PmHex16ToA
	mov	Field[4], ' '
	mov	eax, offset Field
	mov	ecx, 5
	mov	esi, offset Field
	call	WriteLog

	mov	ax, word ptr ExcEcx
	mov	edi, offset Field
	call	PmHex16ToA
	mov	Field[4], ':'
	mov	eax, offset Field
	mov	ecx, 5
	mov	esi, offset Field
	call	WriteLog

	mov	ax, word ptr ExcEdx
	mov	edi, offset Field
	call	PmHex16ToA
	mov	Field[4], 13
	mov	Field[5], 10
	mov	eax, offset Field
	mov	ecx, 6
	mov	esi, offset Field
	call	WriteLog

	popad
	LOG_STATE
ENDIF

	movzx	eax, byte ptr ExcEbx		; Interrupt vector.
	mov	ecx, ExcEcx
	mov	edx, ExcEdx
	mov	fs:[eax*4], dx
	mov	fs:[eax*4][2], cx
	jmp	ret_cf_0			; Success.


;-----------------------------------------------------------------------------
;	Get protected mode exception vector.
;-----------------------------------------------------------------------------
GetExcHandler::

IFDEF	LOG_DPMI
	pushad
	PRINT_LOG	GetPMExcStr

	mov	ax, word ptr ExcEbx
	mov	edi, offset Field
	call	PmHex16ToA
	mov	Field[4], 13
	mov	Field[5], 10
	mov	eax, offset Field
	mov	ecx, 6
	mov	esi, offset Field
	call	WriteLog
	popad
	LOG_STATE
ENDIF

	movzx	ecx, byte ptr ExcEbx		; Exception number.
	cmp	ecx, 20h			; Check for valid exception number.
	jnb	ret_cf_1			; Error.

	mov	edx, CurrTaskPtr
	mov	eax, (DosTask PTR fs:[edx]).DpmiPmExcs

	mov	ebx, fs:[eax+ecx*8]
	mov	esi, fs:[eax+ecx*8][4]
	test	esi, esi			; If no handler installed, return "default".
	jnz	@@F

	lea	ebx, [ecx * 8 + PM_DEF_EXC_OFFS]
	mov	si, PmCallbackCs
@@@@:
	mov	word ptr ExcEdx, bx
	test	(DosTask PTR fs:[edx]).TaskFlags, TASK_32BIT
	jz	@@F

	mov	ExcEdx, ebx
@@@@:
	mov	word ptr ExcEcx, si
	jmp	ret_cf_0			; Success.


;-----------------------------------------------------------------------------
;	Set protected mode interrupt vector.
;-----------------------------------------------------------------------------
SetExcHandler::
IFDEF	LOG_DPMI
	pushad
	PRINT_LOG	SetPMExcStr

	mov	ax, word ptr ExcEbx
	mov	edi, offset Field
	call	PmHex16ToA
	mov	Field[4], ' '
	mov	eax, offset Field
	mov	ecx, 5
	mov	esi, offset Field
	call	WriteLog

	mov	ax, word ptr ExcEcx
	mov	edi, offset Field
	call	PmHex16ToA
	mov	Field[4], ':'
	mov	eax, offset Field
	mov	ecx, 5
	mov	esi, offset Field
	call	WriteLog

	mov	eax, ExcEdx
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

	movzx	ecx, byte ptr ExcEbx		; Exception number.
	cmp	ecx, 20h			; Check for valid exception number.
	jnb	ret_cf_1			; Error.

	mov	edx, CurrTaskPtr
	mov	eax, (DosTask PTR fs:[edx]).DpmiPmExcs
	mov	ebx, ExcEdx
	test	(DosTask PTR fs:[edx]).TaskFlags, TASK_32BIT
	jnz	@@F
	and	ebx, 0FFFFh
@@@@:
	mov	fs:[eax+ecx*8], ebx

	mov	ebx, ExcEcx
	mov	fs:[eax+ecx*8][4], ebx
	jmp	ret_cf_0			; Success.


;-----------------------------------------------------------------------------
;	Get protected mode interrupt vector.
;-----------------------------------------------------------------------------
GetPMInt::
IFDEF	LOG_DPMI
	pushad
	PRINT_LOG	GetPMIntStr

	mov	ax, word ptr ExcEbx
	mov	edi, offset Field
	call	PmHex16ToA
	mov	Field[4], 13
	mov	Field[5], 10
	mov	eax, offset Field
	mov	ecx, 6
	mov	esi, offset Field
	call	WriteLog

	popad
	LOG_STATE
ENDIF

	mov	edx, CurrTaskPtr
	mov	eax, (DosTask PTR fs:[edx]).DpmiPmInts

	movzx	ecx, byte ptr ExcEbx		; Interrupt vector.
	mov	ebx, fs:[eax+ecx*8]
	mov	esi, fs:[eax+ecx*8][4]
	test	esi, esi			; If no handler installed, return "default".
	jnz	@@F

	lea	ebx, [ecx * 8 + PM_DEF_INT_OFFS]
	mov	si, PmCallbackCs
@@@@:
	mov	word ptr ExcEdx, bx
	test	(DosTask PTR fs:[edx]).TaskFlags, TASK_32BIT
	jz	@@F
	mov	ExcEdx, ebx
@@@@:
	mov	word ptr ExcEcx, si
	jmp	ret_cf_0			; Success.


;-----------------------------------------------------------------------------
;	Set protected mode interrupt vector.
;-----------------------------------------------------------------------------
SetPMInt::
IFDEF	LOG_DPMI
	pushad
	PRINT_LOG	SetPMIntStr

	mov	ax, word ptr ExcEbx
	mov	edi, offset Field
	call	PmHex16ToA
	mov	Field[4], ' '
	mov	eax, offset Field
	mov	ecx, 5
	mov	esi, offset Field
	call	WriteLog

	mov	ax, word ptr ExcEcx
	mov	edi, offset Field
	call	PmHex16ToA
	mov	Field[4], ':'
	mov	eax, offset Field
	mov	ecx, 5
	mov	esi, offset Field
	call	WriteLog

	mov	eax, ExcEdx
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

	mov	edx, CurrTaskPtr
	mov	eax, (DosTask PTR fs:[edx]).DpmiPmInts
	movzx	ecx, byte ptr ExcEbx		; Interrupt vector.
	mov	ebx, ExcEdx
	test	(DosTask PTR fs:[edx]).TaskFlags, TASK_32BIT
	jnz	@@F

	and	ebx, 0FFFFh
@@@@:
	mov	fs:[eax+ecx*8], ebx

	mov	ebx, ExcEcx
; If setting interupt handler that is in PmCallbackCs, set 0s.
	cmp	bx, PmCallbackCs
	jne	@@F
	sub	ebx, ebx

@@@@:
	mov	fs:[eax+ecx*8][4], ebx
	jmp	ret_cf_0			; Success.


;-----------------------------------------------------------------------------
;	Simulate real mode interrupt.
;-----------------------------------------------------------------------------
SimRMInt::
IFDEF	LOG_DPMI
	pushad
	PRINT_LOG	SimRMIntStr

	mov	ax, word ptr ExcEbx
	mov	edi, offset Field
	call	PmHex16ToA
	mov	Field[4], ' '
	mov	eax, offset Field
	mov	ecx, 5
	mov	esi, offset Field
	call	WriteLog

	mov	ax, word ptr ExcEcx
	mov	edi, offset Field
	call	PmHex16ToA
	mov	Field[4], ' '
	mov	eax, offset Field
	mov	ecx, 5
	mov	esi, offset Field
	call	WriteLog

	mov	ax, ExcEs
	mov	edi, offset Field
	call	PmHex16ToA
	mov	Field[4], ':'
	mov	eax, offset Field
	mov	ecx, 5
	mov	esi, offset Field
	call	WriteLog

	mov	eax, ExcEdi
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

IFDEF	MONITOR_DPMI
pushad
	mov	bl, LogClr
	or	bl, 30h
	PM_PRINT_HEX16	(word ptr ExcEbx), LogX, LogY, bl
	add	LogX, 5
	cmp	LogX, 72
	jb	@@F
	mov	LogX, 0
	inc	LogY
	cmp	LogY, 25
	jb	@@F
	mov	LogY, 0
	inc	LogClr
	cmp	LogClr, 16
	jb	@@F
	mov	LogClr, 1
@@@@:
	mov	si, ExcEs
	mov	edi, ExcEdi
	and	edi, 0FFFFh
	sub	ebx, ebx
	call	PointerToLinear
	mov	ax, word ptr fs:[eax][1Ch]

	mov	bl, LogClr
	or	bl, 30h
	PM_PRINT_HEX16	, LogX, LogY, bl
	add	LogX, 5
	cmp	LogX, 72
	jb	@@F
	mov	LogX, 0
	inc	LogY
	cmp	LogY, 25
	jb	@@F
	mov	LogY, 0
	inc	LogClr
	cmp	LogClr, 16
	jb	@@F
	mov	LogClr, 1
@@@@:
	mov	si, ExcEs
	mov	edi, ExcEdi
	and	edi, 0FFFFh
	sub	ebx, ebx
	call	PointerToLinear
	mov	ax, word ptr fs:[eax][10h]

	mov	bl, LogClr
	or	bl, 30h
	PM_PRINT_HEX16	, LogX, LogY, bl
	add	LogX, 5
	cmp	LogX, 72
	jb	@@F
	mov	LogX, 0
	inc	LogY
	cmp	LogY, 25
	jb	@@F
	mov	LogY, 0
	inc	LogClr
	cmp	LogClr, 16
	jb	@@F
	mov	LogClr, 1
@@@@:
popad
ENDIF	;MONITOR_DPMI
	movzx	edx, byte ptr ExcEbx		; Int number to call

	push	edx
	call	PrepareVMCall
	pop	edx
	jc	ret_cf_1			; Wrong linear address

; Prepare return trap.
	mov	ExcSeg, XLAT_TRAP_SEG
	mov	ExcOffs, XLAT_TRAP_OFFS

; Simulate interrupt.
	mov	eax, edx
	call	SimulateInt
	jmp	ok_ret				; Don't return error or success.


;-----------------------------------------------------------------------------
;	Call real mode proc with RETF frame.
;-----------------------------------------------------------------------------
CallRMFar::

IFDEF	LOG_DPMI
	pushad
	PRINT_LOG	CallRMFarStr

	mov	ax, word ptr ExcEbx
	mov	edi, offset Field
	call	PmHex16ToA
	mov	Field[4], ' '
	mov	eax, offset Field
	mov	ecx, 5
	mov	esi, offset Field
	call	WriteLog

	mov	ax, word ptr ExcEcx
	mov	edi, offset Field
	call	PmHex16ToA
	mov	Field[4], ' '
	mov	eax, offset Field
	mov	ecx, 5
	mov	esi, offset Field
	call	WriteLog

	mov	ax, ExcEs
	mov	edi, offset Field
	call	PmHex16ToA
	mov	Field[4], ':'
	mov	eax, offset Field
	mov	ecx, 5
	mov	esi, offset Field
	call	WriteLog

	mov	eax, ExcEdi
	mov	edi, offset Field
	call	PmHex32ToA
	mov	Field[8], ' '
	mov	eax, offset Field
	mov	ecx, 9
	mov	esi, offset Field
	call	WriteLog

	mov	si, ExcEs
	mov	edi, ExcEdi
	mov	ebx, ExcEflags
	call	PointerToLinear
	mov	ebp, eax

	mov	ax, (XlatStruct PTR fs:[ebp]).wCs
	mov	edi, offset Field
	call	PmHex16ToA
	mov	Field[4], ':'
	mov	eax, offset Field
	mov	ecx, 5
	mov	esi, offset Field
	call	WriteLog

	mov	ax, (XlatStruct PTR fs:[ebp]).wIp
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

	call	PrepareVMCall
	jc	ret_cf_1			; Wrong linear address

; Prepare return trap.
	sub	ExcEsp, 4

	mov	si, ExcSs
	mov	edi, ExcEsp
	mov	ebx, ExcEflags
	call	PointerToLinear
	mov	word ptr fs:[eax], XLAT_TRAP_OFFS
	mov	word ptr fs:[eax][2], XLAT_TRAP_SEG
	jmp	ok_ret				; Don't return error or success.

;-----------------------------------------------------------------------------
;	Call real mode proc with IRET frame.
;-----------------------------------------------------------------------------
CallRMIret::

IFDEF	LOG_DPMI
	pushad
	PRINT_LOG	CallRMIretStr

	mov	ax, word ptr ExcEbx
	mov	edi, offset Field
	call	PmHex16ToA
	mov	Field[4], ' '
	mov	eax, offset Field
	mov	ecx, 5
	mov	esi, offset Field
	call	WriteLog

	mov	ax, word ptr ExcEcx
	mov	edi, offset Field
	call	PmHex16ToA
	mov	Field[4], ' '
	mov	eax, offset Field
	mov	ecx, 5
	mov	esi, offset Field
	call	WriteLog

	mov	ax, ExcEs
	mov	edi, offset Field
	call	PmHex16ToA
	mov	Field[4], ':'
	mov	eax, offset Field
	mov	ecx, 5
	mov	esi, offset Field
	call	WriteLog

	mov	eax, ExcEdi
	mov	edi, offset Field
	call	PmHex32ToA
	mov	Field[8], ' '
	mov	eax, offset Field
	mov	ecx, 9
	mov	esi, offset Field
	call	WriteLog

	mov	si, ExcEs
	mov	edi, ExcEdi
	mov	ebx, ExcEflags
	call	PointerToLinear
	mov	ebp, eax

	mov	ax, (XlatStruct PTR fs:[ebp]).wCs
	mov	edi, offset Field
	call	PmHex16ToA
	mov	Field[4], ':'
	mov	eax, offset Field
	mov	ecx, 5
	mov	esi, offset Field
	call	WriteLog

	mov	ax, (XlatStruct PTR fs:[ebp]).wIp
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

	call	PrepareVMCall
	jc	ret_cf_1			; Wrong linear address

; Prepare return trap.
	sub	ExcEsp, 6

	mov	si, ExcSs
	mov	edi, ExcEsp
	mov	ebx, ExcEflags
	call	PointerToLinear

	mov	word ptr fs:[eax], XLAT_TRAP_OFFS
	mov	word ptr fs:[eax][2], XLAT_TRAP_SEG
	mov	dx, word ptr ExcEflags
	mov	fs:[eax][4], dx
	jmp	ok_ret				; Don't return error or success.


;-----------------------------------------------------------------------------
;	Allocate real mode callback.
;-----------------------------------------------------------------------------
AllocRMCallback::
IFDEF	LOG_DPMI
	pushad
	PRINT_LOG	AllocRMCBackStr

	mov	ax, ExcDs
	mov	edi, offset Field
	call	PmHex16ToA
	mov	Field[4], ':'
	mov	eax, offset Field
	mov	ecx, 5
	mov	esi, offset Field
	call	WriteLog

	mov	eax, ExcEsi
	mov	edi, offset Field
	call	PmHex32ToA
	mov	Field[8], ' '
	mov	eax, offset Field
	mov	ecx, 9
	mov	esi, offset Field
	call	WriteLog

	mov	ax, ExcEs
	mov	edi, offset Field
	call	PmHex16ToA
	mov	Field[4], ':'
	mov	eax, offset Field
	mov	ecx, 5
	mov	esi, offset Field
	call	WriteLog

	mov	eax, ExcEdi
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

     	mov	ebp, CurrTaskPtr
; Find a free callback address.
	mov	ecx, MAX_DPMI_CALLBACKS
	mov	edx, (DosTask PTR fs:[ebp]).DpmiCallbackArr

@@@@:
	cmp	(DpmiCallback PTR fs:[edx]).wPmCs, 0
	je	@@F
	add	edx, SIZEOF DpmiCallback
	dec	ecx
	jnz	@@B

; All callbacks are allocated.
	jmp	ret_cf_1			; Error.

; Settle new callback.
@@@@:
	neg	ecx
	add	ecx, MAX_DPMI_CALLBACKS
	mov	dword ptr fs:[CALLBACK_ADDR+ecx*8], 0000FFFEh
	mov	dword ptr fs:[CALLBACK_ADDR+ecx*8][4], 09000000h	; Allocated callback.

; Store parameters in callbacks array and in return params.
	lea	ecx, [CALLBACK_OFFS + ecx * 8]
	mov	(DpmiCallback PTR fs:[edx]).wRmIp, cx
	mov	word ptr ExcEdx, cx

	mov	ecx, CALLBACK_SEG
	mov	(DpmiCallback PTR fs:[edx]).wRmCs, cx
	mov	word ptr ExcEcx, cx

	mov	eax, ExcEsi
	mov	ecx, ExcEdi
; If task is 16 bit, use zero extended SI and DI values.
	test	(DosTask PTR fs:[ebp]).TaskFlags, TASK_32BIT
	jnz	@@F
	and	eax, 0FFFFh
	and	ecx, 0FFFFh
@@@@:
	mov	(DpmiCallback PTR fs:[edx]).dwPmEip, ecx
	mov	(DpmiCallback PTR fs:[edx]).dwRegsOffs, ecx

;
; (!) DPMI sepcification requires DS:ESI -> PM callback handler. Hence, it
; cannot be called from an execute-only code segment (not mentioned in spec).
;
	mov	cx, ExcDs
	mov	(DpmiCallback PTR fs:[edx]).wPmCs, cx
	mov	cx, ExcEs
	mov	(DpmiCallback PTR fs:[edx]).wRegsSeg, cx
	jmp	ret_cf_0			; Success.


;-----------------------------------------------------------------------------
;	Free real mode callback.
;-----------------------------------------------------------------------------
FreeRMCallback::
IFDEF	LOG_DPMI
	pushad
	PRINT_LOG	FreeRMCBackStr

	mov	ax, word ptr ExcEcx
	mov	edi, offset Field
	call	PmHex16ToA
	mov	Field[4], ':'
	mov	eax, offset Field
	mov	ecx, 5
	mov	esi, offset Field
	call	WriteLog

	mov	ax, word ptr ExcEdx
	mov	edi, offset Field
	call	PmHex16ToA
	mov	Field[4], 13
	mov	Field[5], 10
	mov	eax, offset Field
	mov	ecx, 5
	mov	esi, offset Field
	call	WriteLog

	popad
	LOG_STATE
ENDIF

	mov	ebp, CurrTaskPtr
; Look for specified address.
	mov	ax, word ptr ExcEcx
	mov	bx, word ptr ExcEdx
	mov	esi, (DosTask PTR fs:[ebp]).DpmiCallbackArr
	sub	edx, edx
	mov	ecx, MAX_DPMI_CALLBACKS

check_next_callback:
	cmp	(DpmiCallback PTR fs:[esi+edx]).wRmCs, ax
	jne	@@F
	cmp	(DpmiCallback PTR fs:[esi+edx]).wRmIp, bx
	je	free_callback

@@@@:
	add	edx, SIZEOF DpmiCallback
	dec	ecx
	jnz	check_next_callback

; Address not found, return error.
	jmp	ret_cf_1			; Error.

; Delete the found callback record.
free_callback:
	mov	(DpmiCallback PTR fs:[esi+edx]).dwPmEip, 0
	mov	(DpmiCallback PTR fs:[esi+edx]).wPmCs, 0
	jmp	ret_cf_0			; Error.


;-----------------------------------------------------------------------------
;	Get state save/restore.
;-----------------------------------------------------------------------------
GetStateSaveRest::
IFDEF	LOG_DPMI
	pushad
	PRINT_LOG	GetSaveRestStr
	popad
	LOG_STATE
ENDIF

; State save buffer size.
;	mov	word ptr ExcEax, SIZEOF GEN_REG_PACK + SIZEOF DpmiState + 4
	mov	word ptr ExcEax, 0

; Real mode call address.
	mov	eax, RM_SAVE_STATE_SEG
	mov	word ptr ExcEbx, ax
	mov	eax, RM_SAVE_STATE_OFFS
	mov	word ptr ExcEcx, ax

; Protected mode call address.
	movzx	eax, PmCallbackCs
	mov	word ptr ExcEsi, ax
	mov	eax, PM_SAVE_STATE
	mov	ecx, CurrTaskPtr
	test	(DosTask PTR fs:[ecx]).TaskFlags, TASK_32BIT
	jnz	@@F

; 16 bit task, return SI:DI.
	mov	word ptr ExcEdi, ax
	jmp	ret_cf_0			; Success.

; 32 bit task, return SI:EDI.
@@@@:
	mov	ExcEdi, eax
	jmp	ret_cf_0			; Success.


;-----------------------------------------------------------------------------
;	Get raw mode switch addresses.
;-----------------------------------------------------------------------------
GetRawModeSwitch::
IFDEF	LOG_DPMI
	pushad
	PRINT_LOG	GetRawSwitchStr
	popad
	LOG_STATE
ENDIF


; Real mode switch address.
	mov	eax, VM2PM_SWITCH_SEG
	mov	word ptr ExcEbx, ax
	mov	eax, VM2PM_SWITCH_OFFS
	mov	word ptr ExcEcx, ax

; Protected mode switch address.
	movzx	eax, PmCallbackCs
	mov	word ptr ExcEsi, ax
	mov	eax, PM2VM_SWITCH_OFFS
	mov	ecx, CurrTaskPtr
	test	(DosTask PTR fs:[ecx]).TaskFlags, TASK_32BIT
	jnz	@@F

; 16 bit task, return SI:DI.
	mov	word ptr ExcEdi, ax
	jmp	ret_cf_0			; Success.

; 32 bit task, return SI:EDI.
@@@@:
	mov	ExcEdi, eax
	jmp	ret_cf_0			; Success.


;-----------------------------------------------------------------------------
;	Get DPMI version.
;-----------------------------------------------------------------------------
GetDpmiVersion::
	mov	word ptr ExcEax, 90	; Version 0.90
	mov	word ptr ExcEbx, 1	; 32-bit support, no VMem support, 
					; no switch to RM for int handling.
	mov	al, byte ptr Cpu
	mov	byte ptr ExcEcx, al	; CPU type.

	mov	word ptr ExcEdx, 0870h	; Virtual IRQ 0 = int 8, IRQ 8 = int 70h
	jmp	ret_cf_0		; Success.


;-----------------------------------------------------------------------------
;	Get free memory information.
; Only free space field is supplied. It is not guaranteed that further
; allocation of the largest block size will succeed.
;-----------------------------------------------------------------------------
GetFreeMem::

IFDEF	LOG_DPMI
	pushad
	PRINT_LOG	GetFreeMemStr

	mov	ax, word ptr ExcEs
	mov	edi, offset Field
	call	PmHex16ToA
	mov	Field[4], ':'
	mov	eax, offset Field
	mov	ecx, 5
	mov	esi, offset Field
	call	WriteLog

	mov	ax, word ptr ExcEdi
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

; Fill the structure with -1s.
	mov	edx, MEM_INFO_STRUCT_LEN - 4
	mov	eax, -1
@@@@:
	mov	fs:[MEM_INFO_STRUCT_ADDR + edx], eax
	sub	edx, 4
	jnl	@@B

	call	LeftFreePages
	mov	ecx, eax
	shl	eax, 12
; For every 4M of memory it's needed 4K for dynamic page table. This
; calculaton is roughly correct.
	shl	ecx, 2
	sub	eax, ecx
; The biggest contiguous block available for alloc is 4M - 4K bytes.
;	cmp	eax, 003FF000h
;	jna	@@F
;	mov	eax, 003FF000h
;
;@@@@:

; Free memory size in bytes.
	mov	fs:[MEM_INFO_STRUCT_ADDR], eax
; Number of free physical pages.
	shr	eax, 12
	mov	fs:[MEM_INFO_STRUCT_ADDR][14h], eax
; Free unlocked pages (contiguous).
	mov	fs:[MEM_INFO_STRUCT_ADDR][4], eax
; Free locked pages (contiguous) - the same is unlocked.
	mov	fs:[MEM_INFO_STRUCT_ADDR][8], eax
; Total number of pages (0Ch) is N/A.
; Total number of unlocked pages (10h) is N/A.
; Total number of physical pages (18h) is N/A.
; Free linear address space in pages (1Ch) is N/A.
; Size of paging file (20h) is N/A.

; Copy structure to ES:EDI.
	mov	si, ExcEs
	mov	edi, ExcEdi
	mov	ebx, CurrTaskPtr
	test	(DosTask PTR fs:[ebx]).TaskFlags, TASK_32BIT
	jnz	@@F
	and	edi, 0FFFFh
@@@@:
	call	PointerToLinear
	mov	edi, eax

	call	LinearToPhysical	; Check if lin. addr. is valid.
	jc	ret_cf_1		; Wrong linear address.

	mov	esi, MEM_INFO_STRUCT_ADDR
	mov	ecx, MEM_INFO_STRUCT_LEN

	push	es
	push	fs
	pop	es
	cld
		rep	movs byte ptr es:[edi], fs:[esi]
	pop	es

	jmp	ret_cf_0		; Success.


;-----------------------------------------------------------------------------
;	Allocate memory from global heap.
;-----------------------------------------------------------------------------
AllocMem::
IFDEF	LOG_DPMI
	pushad
	PRINT_LOG	AllocMemStr

	mov	eax, ExcEbx
	shl	eax, 16
	mov	ax, word ptr ExcEcx
	mov	edi, offset Field
	call	PmHex32ToA
	mov	eax, offset Field
	mov	Field[8], 13
	mov	Field[9], 10
	mov	ecx, 10
	mov	esi, offset Field
	call	WriteLog

	popad
	LOG_STATE
ENDIF

	mov	eax, ExcEbx
	mov	ebx, ExcEcx
	shl	eax, 16
	and	ebx, 0FFFFh
	or	eax, ebx

IFDEF	MONITOR_DPMI
pushad
	mov	bl, LogClr
	add	bl, 60h
	PM_PRINT_HEX32	, LogX, LogY
	add	LogX, 9
	cmp	LogX, 72
	jb	@@F
	mov	LogX, 0
	inc	LogY
	cmp	LogY, 25
	jb	@@F
	mov	LogY, 0
	inc	LogClr
	cmp	LogClr, 16
	jb	@@F
	mov	LogClr, 1
@@@@:
popad
ENDIF
	call	AllocDPMIMem
	jc	ret_cf_1

set_mem_address:
; Set memory address.
	mov	word ptr ExcEcx, cx
	shr	ecx, 16
	mov	word ptr ExcEbx, cx

; Set memory handle.
	mov	word ptr ExcEdi, ax
	shr	eax, 16
	mov	word ptr ExcEsi, ax
IFDEF	LOG_DPMI
	LOG_STATE	1
ENDIF
	jmp	ret_cf_0


;-----------------------------------------------------------------------------
;	Free allocated memory block.
;-----------------------------------------------------------------------------
FreeMem::
IFDEF	LOG_DPMI
	pushad
	PRINT_LOG	FreeMemStr

	mov	eax, ExcEsi
	shl	eax, 16
	mov	ax, word ptr ExcEdi
	mov	edi, offset Field
	call	PmHex32ToA
	mov	eax, offset Field
	mov	Field[8], 13
	mov	Field[9], 10
	mov	ecx, 10
	mov	esi, offset Field
	call	WriteLog

	popad
	LOG_STATE
ENDIF

	mov	eax, ExcEsi
	mov	ebx, ExcEdi
	shl	eax, 16
	and	ebx, 0FFFFh
	add	eax, ebx			; Must form and offset in
						; memory descriptors array.

; Validity of descriptor is checked by FreeDPMIMem
	call	FreeDPMIMem
	jc	ret_cf_1
	jmp	ret_cf_0


;-----------------------------------------------------------------------------
;	Resize allocated memory block.
;-----------------------------------------------------------------------------
ResizeMem::
IFDEF	LOG_DPMI
	pushad
	PRINT_LOG	ResizeMemStr

	mov	eax, ExcEbx
	shl	eax, 16
	mov	ax, word ptr ExcEcx
	mov	edi, offset Field
	call	PmHex32ToA
	mov	eax, offset Field
	mov	Field[8], ' '
	mov	ecx, 9
	mov	esi, offset Field
	call	WriteLog

	mov	eax, ExcEsi
	shl	eax, 16
	mov	ax, word ptr ExcEdi
	mov	edi, offset Field
	call	PmHex32ToA
	mov	eax, offset Field
	mov	Field[8], 13
	mov	Field[9], 10
	mov	ecx, 10
	mov	esi, offset Field
	call	WriteLog

	popad
	LOG_STATE
ENDIF

	mov	eax, ExcEsi
	mov	ebx, ExcEdi
	shl	eax, 16
	and	ebx, 0FFFFh
	lea	eax, [eax + ebx - 8000h]	; Must form and offset in
						; memory descriptors array.
	cmp	eax, DPMI_MEM_DESCRIPTORS * SIZEOF DpmiMemDescr
	jnb	ret_cf_1

; Get memory block size in ESI.
	mov	ebp, CurrTaskPtr
	mov	edx, (DosTask PTR fs:[ebp]).DpmiMemDescrArr
	mov	esi, (DpmiMemDescr PTR fs:[edx+eax]).BlockLength

; Keep new block size in EDI.
	mov	edi, ExcEbx
	mov	ebx, ExcEcx
	shl	edi, 16
	and	ebx, 0FFFFh
	add	edi, ebx

; Free memory block.
	call	FreeDPMIMem
	jc	ret_cf_1		; If failed, there was a bad handle.

; Try to allocate the new block.
	mov	eax, edi
	call	AllocDPMIMem
	jnc	set_mem_address		; At AllocMem section.

; Failed (not enough memory), reallocate the original size.
	mov	eax, esi
	call	AllocDPMIMem		; Should NEVER fail.

; Set memory handle.
	mov	word ptr ExcEdi, ax
	shr	eax, 16
	mov	word ptr ExcEsi, ax
	jmp	ret_cf_1		; return fail.


;-----------------------------------------------------------------------------
;	Page locking calls are ignored and always return true.
;-----------------------------------------------------------------------------
LockRegion::
UnlockRegion::
MarkPageable::
RelockRegion::
	jmp	ret_cf_0


;-----------------------------------------------------------------------------
;	Return page size = 4K.
;-----------------------------------------------------------------------------
GetPageSize::
	mov	word ptr ExcEbx, 0
	mov	word ptr ExcEcx, 1000h
	jmp	ret_cf_0


;-----------------------------------------------------------------------------
;	Demand page performance tuning calls are ignored and always return true.
;-----------------------------------------------------------------------------
MarkPagingCand::
DiscardPages::
MarkDemandPagingCand::
DiscardCont::
	jmp	ret_cf_0


;-----------------------------------------------------------------------------
;	Map physical address. Meanwhile this function doesn't succeed (need
; to virtualize screen).
;-----------------------------------------------------------------------------
MapPhysical::
int 2
IFDEF	LOG_DPMI
	pushad
	PRINT_LOG	MapPhysStr

	mov	eax, ExcEbx
	shl	eax, 16
	mov	ax, word ptr ExcEcx
	mov	edi, offset Field
	call	PmHex32ToA
	mov	eax, offset Field
	mov	Field[8], ' '
	mov	ecx, 9
	mov	esi, offset Field
	call	WriteLog

	mov	eax, ExcEsi
	shl	eax, 16
	mov	ax, word ptr ExcEdi
	mov	edi, offset Field
	call	PmHex32ToA
	mov	eax, offset Field
	mov	Field[8], 13
	mov	Field[9], 10
	mov	ecx, 10
	mov	esi, offset Field
	call	WriteLog

	popad

	LOG_STATE
ENDIF

	jmp	ret_cf_1


;-----------------------------------------------------------------------------
;	Get VirtualIf and clear it.
;-----------------------------------------------------------------------------
GetVifCli::
IFDEF	LOG_DPMI
	pushad
	PRINT_LOG	GetVifCliStr
	popad
	LOG_STATE
ENDIF

	sub	eax, eax
xchg_virtual_if:
	xchg	eax, VirtualIf
ret_virtual_if:
	shr	eax, 9
	mov	byte ptr ExcEax, al		; AL = previous value of VirtualIf.
	jmp	ret_cf_0


;-----------------------------------------------------------------------------
;	Get VirtualIf and set it.
;-----------------------------------------------------------------------------
GetVifSti::

IFDEF	LOG_DPMI
	pushad
	PRINT_LOG	GetVifCliStr
	popad
	LOG_STATE
ENDIF

	mov	eax, FL_IF
	jmp	xchg_virtual_if			; In GetVifCli section.


;-----------------------------------------------------------------------------
;	Get VirtualIf.
;-----------------------------------------------------------------------------
GetVif::

IFDEF	LOG_DPMI
	pushad
	PRINT_LOG	GetVifCliStr
	popad
	LOG_STATE
ENDIF

	mov	eax, VirtualIf
	jmp	ret_virtual_if			; In GetVifCli section.


;-----------------------------------------------------------------------------
;	No vendor specific entry point.
;-----------------------------------------------------------------------------
GetM32Entry::
	jmp	ret_cf_1


;-----------------------------------------------------------------------------
;	Hardware debugging functions are not supported meanwhile (DRs are
; used by system debugger).
;-----------------------------------------------------------------------------
SetDbgWatch::
ClearDbgWatch::
GetDbgWatchState::
ResetDbgWatch::
	jmp	ret_cf_1


ret_cf_0:
	and	ExcEflags, NOT FL_CF
	jmp	ok_ret
ret_cf_1:
	or	ExcEflags, FL_CF
ok_ret:
	clc
	ret

err_ret:
	stc
	ret
Int31Handler	ENDP


;-----------------------------------------------------------------------------
;
;	Validates user selector.
;
;	I: EAX = selector
;	O: CF = 0 if ok
;	      = 1 if invalid.
;
;-----------------------------------------------------------------------------
ValidateUserSel	PROC
	cmp	eax, 8
	jnb	@@F
; If zero selector, return invalid.
	stc
	ret
@@@@:
; If not LDT selector, return invalid.
	test	eax, 4
	jnz	@@F
	stc
	ret
@@@@:
	clc
	ret
ValidateUserSel	ENDP


;-----------------------------------------------------------------------------
;
;	Creates a new LDT descriptor and fills it with zeros.
;
;	I:
;	O:	CF = 0 OK, EAX = selector (offset in GDT).
;		CF = 1 can't create.
;
;-----------------------------------------------------------------------------
CreateLdt	PROC	USES es ecx edx edi
LOCAL	LdtBase: DWORD, LdtSel:DWORD
IFDEF	FAKE_WINDOWS
	mov	eax, PAGE_PRESENT OR PAGE_WRITABLE OR PAGE_USER
ELSE
	mov	eax, PAGE_PRESENT OR PAGE_WRITABLE
ENDIF
	mov	ecx, 10000h
	call	HeapAllocMem
	jnc	@@F

; Return with error.
	ret

@@@@:
	mov	LdtBase, eax
	mov	edx, CurrTaskPtr
	mov	(DosTask PTR fs:[edx]).TaskLdtBase, eax
	mov	CurrLdtBase, eax

	dec	ecx
	mov	edx, LDT_ACCESS
	call	PmAddGdtSegment
	jnc	zero_ldt

; Free allocated memory.
@@@@:
	mov	eax, LdtBase
	mov	ecx, 10000h
	call	HeapFreeMem
	stc
	ret

; Fill new LDT with zeros.
zero_ldt:
	mov	LdtSel, eax
	shr	ecx, 2
	mov	edi, LdtBase
	push	fs
	pop	es
	sub	eax, eax
	cld
		rep	stosd

	mov	eax, LdtSel
	clc
	ret
CreateLdt	ENDP


;-----------------------------------------------------------------------------
;
;	I: EAX = base address.
;	   ECX = limit
;	   DL = access rights,  DH = extended attributes.
;
;	O: CF = 0 OK, EAX = selector offset.
;	   CF = 1 can't add (all GDT is used).
;
;	Dynamically adds GDT segment. 
;	For 32-bit segments caller must supply attributes as well as limit;
;	this function will not apply D/B and G attributes if limit > 1Mb.
;
;-----------------------------------------------------------------------------
PmAddGdtSegment	PROC	USES ebx
; Descriptors below GdtPtr belong to kernel.
	mov	ebx, GdtBase
	call	AddSegment

	ret
PmAddGdtSegment	ENDP


;-----------------------------------------------------------------------------
;
;	Stores parameters into descriptor.
;
;	I: EAX = base address.
;	   ECX = limit
;	   DL = access rights,  DH = extended attributes.
;	   FS:EBX -> pointer to descriptor table.
;
;	O: CF = 0 OK, EAX = selector offset.
;	   CF = 1 - fail, all DT is used.
;
;-----------------------------------------------------------------------------
AddSegment	PROC	USES ebx ecx
LOCAL	NewSel: DWORD
	push	eax
	call	FindFreeDtEntry
	jnc	@@F
	pop	eax
	ret

@@@@:
	add	ebx, eax
	mov	NewSel, eax
	pop	eax

	mov	(Descriptor386 PTR fs:[ebx]).LimitLow, cx
	mov	(Descriptor386 PTR fs:[ebx]).BaseLow, ax
	shr	eax, 16
	mov	(Descriptor386 PTR fs:[ebx]).BaseHigh24, al
	mov	(Descriptor386 PTR fs:[ebx]).BaseHigh32, ah
	mov	(Descriptor386 PTR fs:[ebx]).Access, dl
	mov	(Descriptor386 PTR fs:[ebx]).LimitHigh20, dh

	mov	eax, NewSel
	clc
	ret
AddSegment	ENDP


;-----------------------------------------------------------------------------
;
;	Finds the first unused descriptor table entry. Unused DT entries are 
; marked not present.
;
;	I: FS:EBX -> descriptor table
;	O: CF = 0, EAX = offset of unused entry
;	   CF = 1 - all DT is used.
;
;-----------------------------------------------------------------------------
FindFreeDtEntry	PROC
	mov	eax, 8
	cmp	ebx, GdtBase
	je	find_free
	mov	eax, 80h
find_free:
	cmp	eax, 10000h
	jb	@@F
	stc
	ret
@@@@:
	test	(Descriptor386 PTR fs:[ebx][eax]).Access, ACC_PRESENT
	jz	found
	add	eax, 8
	jmp	find_free
found:
	clc
	ret
FindFreeDtEntry	ENDP


;-----------------------------------------------------------------------------
;
;	Finds the first unused descriptor table N entries. Unused DT entries 
; are marked not present.
;
;	I: FS:EBX -> descriptor table
;	   EAX = number of entries
;	O: CF = 0, EAX = offset of first entry
;	   CF = 1 - all DT is used.
;
;-----------------------------------------------------------------------------
FindNFreeDtEntries	PROC	USES ecx edx esi
	test	eax, eax
	jnz	@@F
	stc
	ret
@@@@:
	
	mov	ecx, 80h		; Skip reserved LDT descriptors.
find_free:
	cmp	ecx, 10000h
	jb	@@F
	stc
	ret
@@@@:
; Check for free selsctor.
	test	(Descriptor386 PTR fs:[ebx][ecx]).Access, ACC_PRESENT
	jz	@@F
	add	ecx, 8
	jmp	find_free
@@@@:
; Check for number of contiguous free selectors.
	mov	edx, 1
	lea	esi, [ecx+8]
check_next:
	cmp	edx, eax
	jnb	found

	test	(Descriptor386 PTR fs:[ebx][esi]).Access, ACC_PRESENT
	jnz	not_found

	inc	edx
	add	esi, 8
	jmp	check_next

not_found:
	lea	ecx, [esi+8]
	jmp	find_free

found:
	mov	eax, ecx
	clc
	ret

FindNFreeDtEntries	ENDP


;-----------------------------------------------------------------------------
;
;	Traps return from DPMI VM callback. Restores protected mode and
; segment registers.
;
;	I: FS:EAX -> faulting opcode (provides with a reason).
;
;-----------------------------------------------------------------------------
PUBLIC	DpmiCallbackRet
DpmiCallbackRet	PROC	USES eax ebx ecx edx esi edi
	movzx	eax, byte ptr fs:[eax+6]
	jmp	DpmiRetTraps[eax*4]

;-----------------------------------------------------------------------------
;	Return from allocate DOS block callback.
;-----------------------------------------------------------------------------
AllocDOSBlockRet::
	mov	eax, CurrTaskPtr

IFDEF	LOG_DPMI
	pushad
	PRINT_LOG	AllocDOSBlockRetStr

	LOG_STATE	1
	popad
ENDIF

; If CF = 1, restore state regs and return.
	test	ExcEflags, FL_CF
	jnz	restore_state_regs

; Set FS:ESI -> pointer to DOS memory blocks structure's first free element.
	mov	esi, (DosTask PTR fs:[eax]).DpmiDOSBlocks
; Find unused entry in blocks selectors structure.
	sub	eax, eax
	sub	edx, edx
@@@@:
	cmp	(DosBlockSel PTR fs:[esi][edx]).wSeg, ax
	je	@@F
	add	edx, SIZEOF DosBlockSel
	cmp	edx, 1000h
	jb	@@B

; Unlikely case that blocks number exceed 1000h / 6.
	ret

@@@@:
	add	esi, edx
; Get LDT descriptors for allocated segment block.
	mov	ebx, CurrLdtBase		; FS:EBX -> LDT
	movzx	ecx, word ptr ExcEax
	mov	edi, ecx		; EDI captures segment address.
	shl	ecx, 4			; ECX = segment's linear address.
	movzx	eax, word ptr ExcEbx
	shl	eax, 4			; EAX = first descriptor limit (bytes)
	test	eax, eax		; decrement if allocating > 0 bytes.
	jz	@@F
	dec	eax
@@@@:
	mov	edx, eax		; EDX = block size count
	shr	eax, 16			; EAX = number of descriptors to allocate.

; Store number of descriptors to allocate.
	inc	eax
	mov	(DosBlockSel PTR fs:[esi]).wNSels, ax

; Find needed number of selectors.
	call	FindNFreeDtEntries

; Store first selector of the allocated in user's EDX.
	mov	word ptr ExcEdx, ax
	or	ExcEdx, 7		; RPL = 3, TI = 1.

; Store selector in block structure.
	mov	(DosBlockSel PTR fs:[esi]).wSel, ax
	mov	(DosBlockSel PTR fs:[esi]).wSeg, di

; Set first of allocated entries to limit of all block.
	ror	edx, 16
	mov	(Descriptor386 PTR fs:[ebx][eax]).LimitHigh20, dl
	ror	edx, 16
set_lim_low:
	mov	(Descriptor386 PTR fs:[ebx][eax]).LimitLow, dx
set_access:
	mov	(Descriptor386 PTR fs:[ebx][eax]).Access, DATA_ACCESS or 01100000b
; Set base address.
	or	dword ptr (Descriptor386 PTR fs:[ebx][eax]).BaseLow, ecx
next_descr:
	sub	edx, 10000h
	jle	restore_state_regs

	add	eax, 8				; Next descriptor
	add	ecx, 10000h			; Next segment address
	cmp	edx, 10000h			; Last segment?
	jb	set_lim_low
	
	mov	(Descriptor386 PTR fs:[ebx][eax]).LimitLow, 0FFFFh
	jmp	set_access


;-----------------------------------------------------------------------------
;	Return from free DOS block callback.
;-----------------------------------------------------------------------------
FreeDOSBlockRet::
	mov	eax, CurrTaskPtr

IFDEF	LOG_DPMI
	pushad
	PRINT_LOG	FreeDOSBlockRetStr

	LOG_STATE	1
	popad
ENDIF

; If CF = 1, restore seg. regs and return.
	test	ExcEflags, FL_CF
	jnz	restore_state_regs

; Free descriptors allocated for the block.
	mov	ebx, CurrLdtBase
	mov	esi, (DosTask PTR fs:[eax]).DpmiDOSBlocks
	mov	ax, ExcEs

; Find allocated descriptors in DOS block selectors structure.
	sub	edx, edx
@@@@:
	cmp	(DosBlockSel PTR fs:[esi][edx]).wSeg, ax
	je	@@F
	add	edx, SIZEOF DosBlockSel
	cmp	edx, 1000h
	jb	@@B

; Allocated segment was not in structure (probably structure size was exceeded
; on allocation).
	ret

@@@@:
	movzx	eax, (DosBlockSel PTR fs:[esi][edx]).wNSels	; Number of selectors.
	movzx	ecx, (DosBlockSel PTR fs:[esi][edx]).wSel
@@@@:
	and	(Descriptor386 PTR fs:[ebx][ecx]).Access, NOT ACC_PRESENT
	add	ecx, 8
	dec	eax
	jnz	@@B

; Clean the remains.
	push	es

	push	fs
	pop	es

	mov	edi, esi			; EDI = remains to clean
	mov	ecx, edi			; Block structure base address.
	add	esi, SIZEOF DosBlockSel		; ESI = source
	sub	ecx, esi
	add	ecx, 400h			; ECX = number of bytes to move (1000h-(dest-source)).
	cld
		rep	movs dword ptr es:[edi], fs:[esi]
	pop	es

	jmp	restore_state_regs

;-----------------------------------------------------------------------------
;	Return from resize DOS block callback.
;-----------------------------------------------------------------------------
ResizeDOSBlockRet::
	mov	eax, CurrTaskPtr

; If CF = 1, restore seg. regs and return.
	test	ExcEflags, FL_CF
	jnz	restore_state_regs

; Check if block had expanded.
	mov	esi, (DosTask PTR fs:[eax]).DpmiDOSBlocks
; Look for resized segment.
	movzx	edi, ExcEs

	sub	edx, edx
@@@@:
	cmp	(DosBlockSel PTR fs:[esi][edx]).wSeg, di
	je	@@F
	add	edx, SIZEOF DosBlockSel
	cmp	edx, 1000h
	jb	@@B

; Segment being resized is not in DOS blocks structure.
	ret

@@@@:
	add	esi, edx
; Check its recorded number of descriptors with currently needed.
	shl	edi, 4
; EAX = block new size (from MCB).
	movzx	eax, word ptr fs:[edi-0Dh]
	shl	eax, 4

; Get previous block size in ECX. First descriptor hold size of the entire block.
	mov	ebx, CurrLdtBase
	movzx	edx, (DosBlockSel PTR fs:[esi]).wSel
	movzx	ecx, (Descriptor386 PTR fs:[ebx][edx]).LimitHigh20
	and	ecx, 0Fh
	shl	ecx, 16
	mov	cx, (Descriptor386 PTR fs:[ebx][edx]).LimitLow

	dec	eax
; Set new limit for base descriptor.
	mov	(Descriptor386 PTR fs:[ebx][edx]).LimitLow, ax
	ror	eax, 16
	mov	(Descriptor386 PTR fs:[ebx][edx]).LimitHigh20, al
	ror	eax, 16

; Compare sizes.
	cmp	eax, ecx
	jb	block_shrunk			; Block shrunk
	je	restore_state_regs		; Block left the same.

; Block expanded.
	mov	ecx, eax
	shr	ecx, 16
	inc	ecx				; ECX = new number of descriptors

; Did number of descriptors remain the same?
	cmp	cx, (DosBlockSel PTR fs:[esi]).wNSels
	jne	@@F
; Yes, only patch last descriptor's limit.
	movzx	edi, (DosBlockSel PTR fs:[esi]).wNSels
	dec	edi
	mov	(Descriptor386 PTR [ebx][edi*8]).LimitLow, ax
	jmp	restore_state_regs

@@@@:
; No, set new number of selectors. Availability of free descriptors was already
; verified.
	movzx	edi, (DosBlockSel PTR fs:[esi]).wNSels

; Set last descriptor's limit to FFFF.
	xchg	 cx, (DosBlockSel PTR fs:[esi]).wNSels
	mov	(Descriptor386 PTR [ebx][ecx*8]).LimitLow, 0FFFFh
	inc	ecx			; ECX = selectors pointer in LDT.

; Set base addresses.
	movzx	edx, (DosBlockSel PTR fs:[esi]).wSeg
	shl	edx, 4
	mov	edi, ecx
	shl	edi, 16			; Offset off base address for first descriptor being added.
	add	edx, edi

@@@@:
	or	dword ptr (Descriptor386 PTR [ebx][ecx*8]).BaseLow, edx
	cmp	eax, 10000h
	jb	@@F
	mov	(Descriptor386 PTR [ebx][ecx*8]).LimitLow, 0FFFFh
	add	edx, 10000h
	sub	eax, 10000h
	inc	ecx
	jmp	@@B

@@@@:
; Set last limit.
	mov	(Descriptor386 PTR [ebx][ecx*8]).LimitLow, ax
	jmp	restore_state_regs

block_shrunk:
; Determine number of descriptors needed.
	mov	edi, eax
	shr	edi, 16				; EDI = number of descriptors
	cmp	di, (DosBlockSel PTR fs:[esi]).wNSels
	jne	@@F

; Modify only limit for last descriptor.
	sub	eax, ecx
	add	(Descriptor386 PTR fs:[ebx][edi]).LimitLow, ax
	jmp	restore_state_regs

@@@@:
; Set limit of the last descriptor.
	and	eax, 0FFFFh
	mov	(Descriptor386 PTR fs:[ebx][edi*8]).LimitLow, ax
	mov	(Descriptor386 PTR fs:[ebx][edi*8]).LimitHigh20, 0

; Free descriptors.
	mov	eax, edi
@@@@:
	and	(Descriptor386 PTR fs:[ebx][eax*8]).Access, NOT ACC_PRESENT
	inc	eax
	cmp	ax, (DosBlockSel PTR fs:[esi]).wNSels
	jb	@@B

; Set new number or selectors.
	inc	edi
	mov	(DosBlockSel PTR fs:[esi]).wNSels, di
	jmp	restore_state_regs

;-----------------------------------------------------------------------------
;	Return from default interrupt redirected to V86 mode.
;-----------------------------------------------------------------------------
RetFromV86Int::

IFDEF	LOG_DPMI
	pushad
	PRINT_LOG	RetFromV86IntStr
	popad
	LOG_STATE
ENDIF

	mov	eax, CurrTaskPtr

IFDEF	MONITOR_DPMI
pushad
	PM_PRINT_HEX16	8002h, LogX, LogY, LogClr
	add	LogX, 5
	cmp	LogX, 72
	jb	@@F
	mov	LogX, 0
	inc	LogY
	cmp	LogY, 25
	jb	@@F
	mov	LogY, 0
	inc	LogClr
	cmp	LogClr, 16
	jb	@@F
	mov	LogClr, 1
@@@@:
popad
ENDIF

restore_state_regs:
	call	PmRestoreState

IFDEF	MONITOR_LOCKED_PM_STACK
pushad
	PM_PRINT_HEX32	ExcEsp, LogX, LogY, LogClr
	add	LogX, 9
	cmp	LogX, 72
	jb	@@F
	mov	LogX, 0
	inc	LogY
	cmp	LogY, 25
	jb	@@F
	mov	LogY, 0
	inc	LogClr
	cmp	LogClr, 16
	jb	@@F
	mov	LogClr, 1
@@@@:
popad
ENDIF

; Set protmode.
	and	ExcEflags, NOT FL_VM

; If ExcDs is E400, restore from task structure.
	cmp	ExcDs, 0E400h
	jne	@@F
	mov	eax, CurrTaskPtr
	mov	cx, (DosTask PTR fs:[eax]).TaskSregs.wDs
	mov	ExcDs, cx
@@@@:

	ret
DpmiCallbackRet	ENDP


;-----------------------------------------------------------------------------
;
;	Restore VM state after protected mode callback (interrupt handler).
;
;-----------------------------------------------------------------------------
PUBLIC	RestoreVmState
RestoreVmState	PROC	USES esi
IFDEF	MONITOR_DPMI
pushad
	PM_PRINT_HEX16	8003h, LogX, LogY, LogClr
	add	LogX, 5
	cmp	LogX, 72
	jb	@@F
	mov	LogX, 0
	inc	LogY
	cmp	LogY, 25
	jb	@@F
	mov	LogY, 0
	inc	LogClr
	cmp	LogClr, 16
	jb	@@F
	mov	LogClr, 1
@@@@:
popad
ENDIF
	call	RmRestoreState

; Set V86 mode.
	or	ExcEflags, FL_VM

	ret
RestoreVmState	ENDP


;-----------------------------------------------------------------------------
;
;	Prepare DPMI simulate interrupt/far call to real mode procedure.
;
;	I:
;	O:  CF = 0 OK
;	       = 1 wrong linear address of real mode call structure.
;
;-----------------------------------------------------------------------------
PrepareVMCall	PROC

IFDEF	MONITOR_LOCKED_PM_STACK
pushad
	PM_PRINT_HEX32	ExcEsp, LogX, LogY, LogClr
	add	LogX, 9
	cmp	LogX, 72
	jb	@@F
	mov	LogX, 0
	inc	LogY
	cmp	LogY, 25
	jb	@@F
	mov	LogY, 0
	inc	LogClr
	cmp	LogClr, 16
	jb	@@F
	mov	LogClr, 1
@@@@:
popad
ENDIF

	mov	ecx, CurrTaskPtr	; FS:ECX -> current task structure.
	mov	si, ExcEs
	mov	edi, ExcEdi		; Get ptr to "real mode call" struct.

	mov	ebx, ExcEflags
	test	(DosTask PTR fs:[ecx]).TaskFlags, TASK_32BIT
	jnz	@@F
	and	edi, 0FFFFh		; Determine DI or EDI contained offset.

@@@@:
	call	PointerToLinear
	mov	ebx, eax
	call	LinearToPhysical	; Check validity of linear address.
	jnc	@@F

	stc				; Wrong linear address.
	ret

@@@@:
; Save ptr. to translation structure.
	mov	(DosTask PTR fs:[ecx]).DpmiRmCallPtr, ebx

; Get pointer to protected mode stack in FS:EBP.
	mov	si, ExcSs
	mov	edi, ExcEsp
	mov	ebx, ExcEflags
	call	PointerToLinear
	mov	ebp, eax

; Save DPMI state information.
	mov	al, 1
	call	PmSaveState

	movzx	esi, byte ptr ExcEbx	; ESI = interrupt number.
	movzx	ecx, word ptr ExcEcx	; ECX = number of words to copy to RM stack.

	mov	eax, CurrTaskPtr
	mov	eax, (DosTask PTR fs:[eax]).DpmiRmCallPtr
; FS:EAX -> translation structure.
	LOAD_XLAT_REGS	1		; Load registers from XLAT structure.
	or	ExcEflags, FL_VM	; Set V86 mode.

; Is SS:ESP loaded with 0?
	;cmp	ExcSs, 0
	;jne	@@F
	
; Set locked RM stack.
	mov	eax, CurrTaskPtr
	mov	edx, (DosTask PTR fs:[eax]).DpmiRmEsp
	mov	ExcEsp, edx
	mov	ExcSs, VM_LOCKED_SS

@@@@:
	mov	edx, esi		; EDX keeps interrupt number.
	test	ecx, ecx
	jz	prepare_ret_trap

; Copy parameters.
	mov	si, ExcSs
	mov	edi, ExcEsp
	mov	ebx, ExcEflags
	call	PointerToLinear		; Get pointer to real mode stack.

	shl	ecx, 1
	sub	word ptr ExcEsp, cx

	mov	edi, eax
	mov	esi, ebp		; Retrieve pointer to PM stack.
@@@@:
	mov	al, fs:[ebp][ecx-1]
	mov	fs:[edi][ecx-1], al
	dec	ecx
	jnz	@@B

prepare_ret_trap:
	clc
	ret

PrepareVMCall	ENDP


;-----------------------------------------------------------------------------
;
;	Restore client state after translation services calls.
;
;-----------------------------------------------------------------------------
PUBLIC	XlatRet	
XlatRet		PROC

IFDEF	LOG_DPMI
	pushad
	PRINT_LOG	XlatRetStr
	popad
	LOG_STATE
ENDIF

IFDEF	MONITOR_DPMI
pushad
	PM_PRINT_HEX16	8004h, LogX, LogY, LogClr
	add	LogX, 5
	cmp	LogX, 72
	jb	@@F
	mov	LogX, 0
	inc	LogY
	cmp	LogY, 25
	jb	@@F
	mov	LogY, 0
	inc	LogClr
	cmp	LogClr, 16
	jb	@@F
	mov	LogClr, 1
@@@@:
popad
ENDIF

; Valid only if occured in V86 mode.
	test	ExcEflags, FL_VM
	jnz	get_rm_call_ptr
	stc
	ret

; Retrieve pointer to real mode call structure from saved reg. pack.
get_rm_call_ptr:
	mov	edx, CurrTaskPtr
	mov	eax, (DosTask PTR fs:[edx]).DpmiRmCallPtr

; Get client regs to the structure.
	STORE_XLAT_REGS

; Restore registers
	call	PmRestoreState

IFDEF	MONITOR_LOCKED_PM_STACK
pushad
	mov	edx, CurrTaskPtr
	cmp	(DosTask PTR fs:[edx]).TaskLdt, 0
	je	@@F
	PM_PRINT_HEX32	ExcEsp, LogX, LogY, LogClr
	add	LogX, 9
	cmp	LogX, 72
	jb	@@F
	mov	LogX, 0
	inc	LogY
	cmp	LogY, 25
	jb	@@F
	mov	LogY, 0
	inc	LogClr
	cmp	LogClr, 16
	jb	@@F
	mov	LogClr, 1
@@@@:
popad
ENDIF

; Set protmode.
	and	ExcEflags, NOT FL_VM

IFDEF	LOG_DPMI
	pushad
	LOG_STATE	1
	popad
ENDIF
	clc
	ret
XlatRet		ENDP


;-----------------------------------------------------------------------------
;
;	Calls real mode callback (due to breakpoints set by calls INT 31h/
; AX = 0303.
;
;	I: FS:EAX -> faulting instruction.
;	O: CF = 0 - OK
;	        1 - wrong address.
;
;-----------------------------------------------------------------------------
PUBLIC	CallRMCallback
CallRMCallback	PROC
int 3
IFDEF	LOG_DPMI
	pushad
	PRINT_LOG	CallRMCallbackStr
	popad
	LOG_STATE
ENDIF

IFDEF	MONITOR_DPMI
pushad
	PM_PRINT_HEX16	8005h, LogX, LogY, LogClr
	add	LogX, 5
	cmp	LogX, 72
	jb	@@F
	mov	LogX, 0
	inc	LogY
	cmp	LogY, 25
	jb	@@F
	mov	LogY, 0
	inc	LogClr
	cmp	LogClr, 16
	jb	@@F
	mov	LogClr, 1
@@@@:
popad
ENDIF

PUSHCONTEXT	ASSUMES
ASSUME	ebp: PTR DosTask, ebx: PTR DpmiCallback
; Valid only if occured in V86 mode.
	test	ExcEflags, FL_VM
	jnz	@@F
	stc
	ret

@@@@:
	sub	eax, (CALLBACK_SEG * 16)	; EAX = offset
	mov	ebp, CurrTaskPtr		; FS:EBP -> Current task structure.

; Find the allocated callback.
	mov	ebx, fs:[ebp].DpmiCallbackArr
	mov	ecx, MAX_DPMI_CALLBACKS

@@@@:
	cmp	ax, fs:[ebx].wRmIp
	je	@@F
	add	ebx, SIZEOF DpmiCallback
	dec	ecx
	jnz	@@B

; Error - callback not allocated.
	stc
	ret

; Allocated callback found (FS:EBX->).
@@@@:
; Get pointer to real mode call structure.
	push	ebx
	mov	si, fs:[ebx].wRegsSeg
	mov	edi, fs:[ebx].dwRegsOffs
	sub	ebx, ebx			; VM = 0
	call	PointerToLinear
	pop	ebx

; Get client regs to the structure.
	STORE_XLAT_REGS

; Set DPMI RM SS base address to RM SS.
	push	ebx
	mov	ebx, CurrLdtBase
	movzx	ecx, fs:[ebp].DpmiRmSs
	and	ecx, NOT 7
	movzx	eax, ExcSs
	shl	eax, 4
	or	dword ptr (Descriptor386 PTR fs:[ebx+ecx]).BaseLow, eax
	pop	ebx

; Load registers as needed for the callback.
	lea	eax, [ecx + 7]			; DPMI RM SS selector.
	mov	ExcDs, ax
	movzx	eax, fs:[ebx].wRegsSeg		; ES = seg. of real mode call struct.
	mov	ExcEs, ax
	movzx	eax, PmCallbackSs		; Locked DPMI SS.
	mov	ExcSs, ax

	and	ExcEflags, NOT FL_VM		; Set PM

; Set IRET stack frame.
	test	fs:[ebp].TaskFlags, TASK_32BIT
	jnz	@@F

;
; 16 bit task.
;
	movzx	eax, word ptr ExcEsp		; Real mode ESP.
	mov	word ptr ExcEsi, ax
	mov	eax, fs:[ebx].dwRegsOffs	; EDI = offset of real mode call struct.
	mov	word ptr ExcEdi, ax

	mov	eax, fs:[ebp].DpmiPmStack
	mov	word ptr fs:[eax-6], CALLBACK_RET_TRAP_OFFS	; Return EIP
	mov	cx, PmCallbackCs
	mov	fs:[eax-6][2], cx				; Return CS
	mov	cx, word ptr ExcEflags
	mov	fs:[eax-6][4], cx				; Return flags
	movzx	ecx, word ptr fs:[ebx].dwPmEip
	mov	ExcOffs, ecx				; Callback address.
	mov	ecx, 6					; Value to subtract.
	jmp	call_rm_callback

;
; 32 bit task.
;
@@@@:
	movzx	eax, word ptr ExcEsp		; Real mode ESP.
	mov	ExcEsi, eax
	mov	eax, fs:[ebx].dwRegsOffs	; EDI = offset of real mode call struct.
	mov	ExcEdi, eax

	mov	eax, fs:[ebp].DpmiPmStack
	mov	dword ptr fs:[eax-12], CALLBACK_RET_TRAP_OFFS	; Return EIP
	mov	cx, PmCallbackCs
	mov	fs:[eax-12][4], cx				; Return CS
	mov	ecx, ExcEflags
	mov	fs:[eax-12][8], ecx			; Return flags
	mov	ecx, fs:[ebx].dwPmEip
	mov	ExcOffs, ecx				; Callback address.
	mov	ecx, 12					; Value to subtract.

call_rm_callback:
	mov	eax, fs:[ebp].DpmiPmEsp
	sub	eax, ecx
	mov	ExcEsp, eax
	mov	cx, fs:[ebx].wPmCs
	mov	ExcSeg, cx				; Callback CS.

; Set FS = GS = 0.
	mov	ExcFs, 0
	mov	ExcGs, 0

	clc
	ret
POPCONTEXT	ASSUMES
CallRMCallback	ENDP


;-----------------------------------------------------------------------------
;
;	Return from "RM callback" back to V86 mode.
;
;-----------------------------------------------------------------------------
PUBLIC	RmCallbackRet
RmCallbackRet	PROC

IFDEF	LOG_DPMI
	pushad
	PRINT_LOG	RMCallbackRetStr
	popad
	LOG_STATE
ENDIF

IFDEF	MONITOR_DPMI
pushad
	PM_PRINT_HEX16	8006h, LogX, LogY, LogClr
	add	LogX, 5
	cmp	LogX, 72
	jb	@@F
	mov	LogX, 0
	inc	LogY
	cmp	LogY, 25
	jb	@@F
	mov	LogY, 0
	inc	LogClr
	cmp	LogClr, 16
	jb	@@F
	mov	LogClr, 1
@@@@:
popad
ENDIF

; Valid only if occured in protected mode.
	test	ExcEflags, FL_VM
	jz	@@F
	stc
	ret

@@@@:
; Restore real mode registers.
	mov	si, ExcEs
	mov	edi, ExcEdi
	mov	ebx, ExcEflags
	call	PointerToLinear
	LOAD_XLAT_REGS	1

	or	ExcEflags, FL_VM			; Set V86 mode.

	clc
	ret
RmCallbackRet	ENDP


;-----------------------------------------------------------------------------
;
;	Allocate DPMI memory and set the memory descriptor.
;
;	I: EAX = memory size
;	O: CF = 0 - success, EAX = handle, ECX = address.
;	        1 - fail
;
; (!) Doesn't preserve any registers.
;
;-----------------------------------------------------------------------------
PUBLIC	AllocDPMIMem
AllocDPMIMem	PROC
	mov	ebp, CurrTaskPtr
; Find free element in memory descriptors array.
	mov	ecx, DPMI_MEM_DESCRIPTORS
	mov	edx, (DosTask PTR fs:[ebp]).DpmiMemDescrArr

@@@@:
	cmp	(DpmiMemDescr PTR fs:[edx]).BlockAddress, 0
	je	@@F
	add	edx, SIZEOF DpmiMemDescr
	dec	ecx
	jnz	@@B

; All memory descriptors have exhausted.
	stc
	ret

; Allocate memory and return descriptor handle (offset).
@@@@:
	mov	ecx, eax
	mov	eax, PAGE_PRESENT OR PAGE_WRITABLE OR PAGE_USER
	call	HeapAllocMem
	jnc	dpmi_mem_alloc_ok

; Return with error.
	ret

; Set memory descriptor to allocated linear address.
dpmi_mem_alloc_ok:
	mov	(DpmiMemDescr PTR fs:[edx]).BlockAddress, eax
	mov	(DpmiMemDescr PTR fs:[edx]).BlockLength, ecx

; Return memory address.
	mov	ecx, eax
; Return memory descriptor.
	mov	eax, edx
	sub	eax, (DosTask PTR fs:[ebp]).DpmiMemDescrArr

;
; Memory handle is ORed with 8000h. This is because in XMS memory handle
; 0 has special memory.
;
	or	eax, 8000h
; No error.
	clc
	ret
AllocDPMIMem	ENDP


;-----------------------------------------------------------------------------
;
;	Free DPMI memory and reset the memory descriptor.
;
;	I: EAX = memory descriptor (handle).
;	O: CF = 0 - success
;	        1 - fail
;
; (!) Doesn't preserve any registers.
;
;-----------------------------------------------------------------------------
PUBLIC	FreeDPMIMem
FreeDPMIMem	PROC
	mov	ebp, CurrTaskPtr
	mov	edx, (DosTask PTR fs:[ebp]).DpmiMemDescrArr

; Memory handle is descriptor offset ORed with 8000h.
	lea	ebx, [eax - 8000h]

; If descriptor offset is too big, return an error.
	cmp	ebx, DPMI_MEM_DESCRIPTORS * SIZEOF DpmiMemDescr
	jnb	mem_descr_err

; If descriptor is not allocated, return an error.
	mov	eax, (DpmiMemDescr PTR fs:[edx][ebx]).BlockAddress
	test	eax, eax
	jnz	@@F

; Return error.
mem_descr_err:
	stc
	ret

; Free memory.
@@@@:
	mov	ecx, (DpmiMemDescr PTR fs:[edx][ebx]).BlockLength
	call	HeapFreeMem

	clc
	ret
FreeDPMIMem	ENDP


;-----------------------------------------------------------------------------
;
;	Called when DPMI task executes INT 21h / AH = 4Ch. Cleans up all
; allocaions, sets LDT to 0 etc.
;
;	I:	FS:EDX -> task structure
;	O:
;
;-----------------------------------------------------------------------------
PUBLIC	DpmiWashUp
DpmiWashUp	PROC	USES eax ebx ecx esi
PUSHCONTEXT	ASSUMES
ASSUME	edx: PTR DosTask
; Free allocations.
	mov	eax, fs:[edx].DpmiCallbackArr
	call	HeapFreePage
	mov	eax, fs:[edx].DpmiPmExcs
	call	HeapFreePage
	mov	eax, fs:[edx].DpmiPmInts
	call	HeapFreePage
	mov	eax, fs:[edx].DpmiDOSBlocks
	call	HeapFreePage

; Free LDT and memory allocated for LDT.
	mov	ebx, GdtBase
	movzx	ecx, fs:[edx].TaskLdt
	and	(Descriptor386 PTR fs:[ebx][ecx]).Access, NOT ACC_PRESENT
	mov	eax, CurrLdtBase
	mov	ecx, 10000h
	call	HeapFreeMem

; Clear LDT in task state.
	mov	fs:[edx].TaskLdt, 0

	ret
POPCONTEXT	ASSUMES
DpmiWashUp	ENDP


IFDEF	FAKE_WINDOWS
;-----------------------------------------------------------------------------
;
;	Fake Windows API entry point.
;
;-----------------------------------------------------------------------------
PUBLIC	WinVendorEntry
WinVendorEntry	PROC
	cmp	word ptr ExcEax, 0100h
	je	get_ldt_alias
; Unknown function call.
	or	ExcEflags, FL_CF
	ret

get_ldt_alias:
	mov	ebx, CurrLdtBase
	call	FindFreeDtEntry			; Get aliad LDT entry.

; Set data descriptor with LDT base address.
	mov	edx, ebx
	mov	(Descriptor386 PTR fs:[ebx][eax]).LimitLow, 0FFFFh
	mov	(Descriptor386 PTR fs:[ebx][eax]).LimitHigh20, 0
	mov	(Descriptor386 PTR fs:[ebx][eax]).BaseLow, dx
	shr	edx, 16
	mov	(Descriptor386 PTR fs:[ebx][eax]).BaseHigh24, dl
	mov	(Descriptor386 PTR fs:[ebx][eax]).BaseHigh32, dh
	mov	(Descriptor386 PTR fs:[ebx][eax]).Access, DATA_ACCESS OR 01100000b
	or	eax, 7
	mov	word ptr ExcEax, ax
	and	ExcEflags, NOT FL_CF
	
	ret
WinVendorEntry	ENDP
ENDIF


;-----------------------------------------------------------------------------
;
;	Save alternate mode state to user supplied buffer.
;
;	I: FS:EBP -> appropriate save buffer in task structure.
;	O:
;
;-----------------------------------------------------------------------------
PUBLIC	AltSaveState
AltSaveState	PROC

IF 0
; Save state regs into buffer pointed by ES:(E)DI.
	mov	si, ExcEs
	mov	edi, ExcEdi
	mov	ebx, ExcEflags
	test	ebx, FL_VM		; V86 mode?
	jnz	@@F			; Yes, use 16 bits.

	mov	eax, CurrTaskPtr
	test	(DosTask PTR fs:[eax]).TaskFlags, TASK_32BIT
	jnz	save_regs

@@@@:
	and	edi, 0FFFFh

save_regs:
	call	PointerToLinear

	push	es
	push	fs
	pop	es
	mov	edi, eax
	mov	esi, ebp
	mov	ecx, (SIZEOF DpmiState + SIZEOF GEN_REG_PACK + 4) / 4
	cld
		rep	movs dword ptr es:[edi], es:[esi]
	pop	es

ENDIF ;0

; Emulate RETF.
	call	EmulateRetf

	ret
AltSaveState	ENDP


;-----------------------------------------------------------------------------
;
;	Restore alternate state save buffer from user supplied buffer.
;
;	I: FS:EBP -> appropriate save buffer in task structure.
;	O:
;
;-----------------------------------------------------------------------------
PUBLIC	AltRestoreState
AltRestoreState	PROC

IF 0
; Restore general regs from buffer pointed by ES:(E)DI.
	mov	si, ExcEs
	mov	edi, ExcEdi
	mov	ebx, ExcEflags
	test	ebx, FL_VM		; V86 mode?
	jnz	@@F			; Yes, use 16 bits.

	mov	eax, CurrTaskPtr
	test	(DosTask PTR fs:[eax]).TaskFlags, TASK_32BIT
	jnz	restore_regs

@@@@:
	and	edi, 0FFFFh

restore_regs:
	call	PointerToLinear

	push	es
	push	fs
	pop	es
	mov	esi, eax
	mov	edi, ebp
	mov	ecx, (SIZEOF DpmiState + SIZEOF GEN_REG_PACK + 4) / 4
	cld
		rep	movs dword ptr es:[edi], es:[esi]
	pop	es
ENDIF ;0

emul_retf:
	call	EmulateRetf

	ret
AltRestoreState	ENDP


;-----------------------------------------------------------------------------
;
;	Emulates RETF execution.
;
;-----------------------------------------------------------------------------
PUBLIC	EmulateRetf
EmulateRetf	PROC	USES eax ebx edx esi edi

; Get pointer to stack to EDX.
	mov	si, ExcSs
	mov	edi, ExcEsp
	mov	ebx, ExcEflags
	call	PointerToLinear
	mov	edx, eax

; Check if 16 or 32 bit RETF is emulated.
	test	ebx, FL_VM
	jnz	retf_16
	mov	eax, CurrTaskPtr
	test	(DosTask PTR fs:[eax]).TaskFlags, TASK_32BIT
	jz	retf_16

; 32 bit RETF.
	mov	eax, fs:[edx]
	mov	ExcOffs, eax
	mov	eax, fs:[edx][4]
	or	eax, 3
	mov	ExcSeg, ax
	add	ExcEsp, 8
	ret

; Emulate 16 bit retf.
retf_16:
	movzx	eax, word ptr fs:[edx]
	mov	ExcOffs, eax
	mov	ax, fs:[edx][2]
	or	ax, 3
	mov	ExcSeg, ax
	add	ExcEsp, 4
	ret

EmulateRetf	ENDP


IFDEF	FAKE_WINDOWS
;-----------------------------------------------------------------------------
;
;	I:	EAX = selector
;	O:	CF = 0 success, EAX = segment
;		   = 1 failure, can't convert.
;
;	Windows sometimes automatically translates segments that are 
; parameters to V86 interrupts redirections. This violates DPMI specification
; that requires in such cases either to use translation services or to
; translate selectors to segments on client's side.
;	Unfortunately some programs rely on this feature. This function is
; called before reflecting certain interrupts to real mode under Windows
; emulating switch.
;
;-----------------------------------------------------------------------------
SelToSeg	PROC	USES ebx

; If not LDT selector, return failure.
	test	eax, 4
	jnz	@@F
	stc
	ret

@@@@:
	mov	ebx, CurrLdtBase
	and	eax, NOT 7
	add	ebx, eax

; If points to non present segment, return error.
	test	(Descriptor386 PTR fs:[ebx]).Access, ACC_PRESENT
	jnz	@@F
	stc
	ret

@@@@:
	mov	ah, (Descriptor386 PTR fs:[ebx]).BaseHigh32
	mov	al, (Descriptor386 PTR fs:[ebx]).BaseHigh24
	shl	eax, 16
	mov	ax, (Descriptor386 PTR fs:[ebx]).BaseLow

; If target descriptor address is > FFFF0, return failure.
	shr	eax, 4
	cmp	eax, 0FFFFh
	jna	@@F
	stc
	ret

@@@@:
	clc
	ret
SelToSeg	ENDP


;-----------------------------------------------------------------------------
;
;	I:	ECX = interrupt number.
;	O:
;
;	This procedure makes a decision and translates protected mode selectors
; to real mode segments if needed and if possible.
;
;-----------------------------------------------------------------------------
PUBLIC	XlatSegments
XlatSegments	PROC	USES eax ebx ecx esi edi

; Supply DS translation for INT 21h, AH = 9h
	cmp	ecx, 21h
	je	int21
	ret

int21:
	cmp	byte ptr ExcEax[1], 9
	je	ah09
	ret

ah09:
mov	ax, ExcDs
mov	ebx, ExcEdx
int 4
	movzx	eax, ExcDs
	call	SelToSeg
	jc	@@F
	mov	ExcDs, ax
	ret

@@@@:
; Copy segment to E400:0. Of course, if source segment is more than 48 K this
; won't work correctly.
	mov	si, ExcDs
	sub	edi, edi
	sub	ebx, ebx
	call	PointerToLinear

	mov	esi, eax
	mov	edi, 0E4000h
	mov	ecx, 0C000h / 4
	push	es
	push	fs
	pop	es
	cld
		rep	movs dword ptr es:[edi], es:[esi]
	pop	es

	mov	eax, CurrTaskPtr
	mov	cx, ExcDs
	mov	(DosTask PTR fs:[eax]).TaskSregs.wDs, cx
	mov	ExcDs, 0E400h

	ret

XlatSegments	ENDP

ENDIF	; FAKE_WINDOWS


;-----------------------------------------------------------------------------
;
;	I: AL = 0 - save only state regs
;		1 - save general regs also
;
;	Saves DPMI state regs in save state structure in PM.
;
;-----------------------------------------------------------------------------
PUBLIC	PmSaveState
PmSaveState	PROC	USES eax ebx edx
	mov	ebx, CurrTaskPtr
	mov	edx, (DosTask PTR fs:[ebx]).DpmiPmStateSave
	add	edx, (DosTask PTR fs:[ebx]).DpmiPmStatePtr

	call	SaveState
	add	(DosTask PTR fs:[ebx]).DpmiPmStatePtr, SIZEOF DpmiStateSave

	ret
PmSaveState	ENDP


;-----------------------------------------------------------------------------
;
;	I: AL = 0 - save only state regs
;		1 - save general regs also
;
;	Saves DPMI state regs in save state structure in RM.
;
;-----------------------------------------------------------------------------
PUBLIC	RmSaveState
RmSaveState	PROC	USES eax ebx edx
	mov	ebx, CurrTaskPtr
	mov	edx, (DosTask PTR fs:[ebx]).DpmiRmStateSave
	add	edx, (DosTask PTR fs:[ebx]).DpmiRmStatePtr

	call	SaveState
	add	(DosTask PTR fs:[ebx]).DpmiRmStatePtr, SIZEOF DpmiStateSave

	ret
RmSaveState	ENDP


;-----------------------------------------------------------------------------
;
;	I: AL = 0 - save only state regs
;		1 - save general regs also
;	   FS:EBX -> DosTask structure
;	   FS:EDX -> save structure.
;
;	Saves DPMI state regs in save state structure.
;
;-----------------------------------------------------------------------------
SaveState	PROC
; Save flag.
	mov	(DpmiStateSave PTR fs:[edx]).bFlag, al

; Save state regs.
	inc	edx
	push	eax
	SAVE_STATE_REGS
	pop	eax

; Conditionally save general regs.
	test	al, al
	jz	@@F

	add	edx, SIZEOF DpmiState
	SAVE_GENERAL_REGS

@@@@:
	ret
SaveState	ENDP


;-----------------------------------------------------------------------------
;
;	Restores DPMI state regs from save state structure in PM.
;
;-----------------------------------------------------------------------------
PUBLIC	PmRestoreState
PmRestoreState	PROC	USES eax ebx edx
	mov	ebx, CurrTaskPtr
	sub	(DosTask PTR fs:[ebx]).DpmiPmStatePtr, SIZEOF DpmiStateSave
	mov	edx, (DosTask PTR fs:[ebx]).DpmiPmStateSave
	add	edx, (DosTask PTR fs:[ebx]).DpmiPmStatePtr

	call	RestoreState
	ret
PmRestoreState	ENDP


;-----------------------------------------------------------------------------
;
;	Restores DPMI state regs from save state structure in RM.
;
;-----------------------------------------------------------------------------
PUBLIC	RmRestoreState
RmRestoreState	PROC	USES eax ebx edx
	mov	ebx, CurrTaskPtr
	sub	(DosTask PTR fs:[ebx]).DpmiRmStatePtr, SIZEOF DpmiStateSave
	mov	edx, (DosTask PTR fs:[ebx]).DpmiRmStateSave
	add	edx, (DosTask PTR fs:[ebx]).DpmiRmStatePtr

	call	RestoreState
	ret
RmRestoreState	ENDP


;-----------------------------------------------------------------------------
;
;	   FS:EBX -> DosTask structure
;	   FS:EDX -> save structure.
;
;	Restores DPMI state regs from save state structure in RM.
;
;-----------------------------------------------------------------------------
RestoreState	PROC

; Get flag.
	mov	al, (DpmiStateSave PTR fs:[edx]).bFlag

; Restore state regs.
	inc	edx
	push	eax
	RESTORE_STATE_REGS
	pop	eax

; Conditionally restore general regs.
	test	al, al
	jz	@@F
	add	edx, SIZEOF DpmiState
	RESTORE_GENERAL_REGS

@@@@:
	ret
RestoreState	ENDP


CODE32	ENDS
END
@


0.52
log
@Stack segment for Tripple-DOS changed to 32-bit default. 16-bit stack didn't work with DPMI clients that set up stack to 32 bits and ESP > 64K! Now DJGPP stubbed programs work, but there is some problem when they return.
@
text
@d12 1
a12 1
; law, shall Vadim Drubetsky aka the Black Phantoms be liable for any special,
@


0.51
log
@Added general devices synchronization mechanism.
It's implemented for COM1 and COM2.
It causes problems with a keyboard.
@
text
@d713 14
d737 32
d3094 8
@


0.50
log
@Fixed HDD/FDD synchronization problem (trapped opcodes were overwriting each other).
@
text
@@


0.49
log
@Fixes version (log for INIT.ASM)
@
text
@@


0.48
log
@Enabled XMS 3.0 inteface
@
text
@@


0.47
log
@DMA partial virtualization is made - Tripple DOS now works with floppy!
@
text
@@


0.46
log
@Fixed a bug that didn't allow Tripple DOS work with DOS loaded HIGH
@
text
@@


0.45
log
@The shareware beta release
@
text
@@


0.44
log
@Bug fixes:
1) Checks for open file name (EDX to DX) problem
2) Reporting of the protected mode exception reboot
@
text
@d3 19
d198 3
d1015 1
d1054 1
d1063 1
a1074 1
	and	ExcEflags, NOT FL_CF
a1249 1

a1273 2
; Set index of return trap.
	mov	byte ptr fs:[RET_TRAP_ADDR + 6], 0
d1303 3
d1321 1
a1325 1
	mov	byte ptr ExcEax[1], 49h
a1326 2
; Set index of return trap.
	mov	byte ptr fs:[RET_TRAP_ADDR + 6], 1
a1416 2
; Set index of return trap.
	mov	byte ptr fs:[RET_TRAP_ADDR + 6], 2
d2314 1
d2316 4
d2321 5
a2325 5
	cmp	eax, 003FF000h
	jna	@@F
	mov	eax, 003FF000h

@@@@:
d2432 3
d2444 1
a2444 1
	PRINT_LOG	AllocMemStr
d2962 9
a2970 1
; If CF = 1, restore seg. regs and return.
d2974 1
a2974 1
; FS:ESI -> pointer to DOS memory blocks structure's first free element.
d2980 1
a2980 1
	cmp	fs:[esi][edx], ax
d2998 2
d3001 1
a3007 1
	dec	eax
d3061 1
a3061 1
	cmp	(DosBlockSel PTR fs:[esi[edx]]).wSeg, ax
d3081 5
d3090 1
a3090 1
	add	ecx, 1000h			; ECX = number of bytes to move (1000h-(dest-source)).
d3092 2
a3093 1
		rep	movsb
d3519 5
@


0.43
log
@Bug fixes:
1) Lower word in translation structure on real mode stack was being destroyed - very annoying.
2) Saved exception number was moved to task structure to allow multiple DPMI tasks work.
3 copies of WCC386 worked!
@
text
@d22 1
d199 2
a200 1
; segments.
d249 1
a249 1
;
d251 1
a251 1
;
d298 17
a314 1
; Create LDT.
d367 4
d443 3
d450 1
a450 1
	cmp	LogX, 80
d466 1
d468 2
d494 3
d501 1
a501 1
	cmp	LogX, 80
d517 1
d519 2
d523 2
d576 1
a576 1
	cmp	LogX, 80
d610 2
a611 2
	mov	ebx, CurrLdtBase
	movzx	eax, word ptr ExcEcx
d618 1
a618 1
	cmp	LogX, 80
d645 1
d660 1
a660 1
	mov	(Descriptor386 PTR fs:[ebx][eax]).Access, ACC_PRESENT SHL 8
d688 1
d722 1
d800 1
d849 1
d869 1
a869 1
	cmp	LogX, 80
d923 1
d980 1
d1019 1
a1071 1
	mov	ax, word ptr ExcEdx
a1079 1
	mov	ax, word ptr ExcEdx
d1088 1
a1130 1

a1144 1
	mov	ax, word ptr ExcEdx
a1152 1
	mov	ax, word ptr ExcEdx
d1161 1
d1241 1
d1275 1
a1311 1

d1335 1
d1418 1
d1467 1
d1497 1
d1512 1
a1512 1
	mov	ebx, PM_DEF_EXC_OFFS
d1562 1
d1602 1
d1614 1
a1614 1
	mov	ebx, PM_DEF_INT_OFFS
d1663 1
d1678 6
d1734 1
d1737 69
d1807 1
d1891 1
d1979 1
a2003 1

d2046 1
d2130 1
d2142 1
a2142 1
	cmp	(DpmiCallback PTR [esi+edx]).wRmCs, ax
d2144 1
a2144 1
	cmp	(DpmiCallback PTR [esi+edx]).wRmIp, bx
d2157 2
a2158 2
	mov	(DpmiCallback PTR [esi+edx]).dwPmEip, 0
	mov	(DpmiCallback PTR [esi+edx]).wPmCs, 0
d2163 1
a2163 1
;	Get state save/restore. Save/restore is not required.
d2170 1
d2173 3
a2185 1
	mov	word ptr ExcEax, 0		; 0 bytes required.
d2209 1
a2227 1
	mov	ecx, ExcEdi
d2282 1
a2294 3
; Number of free physical page.
	mov	fs:[MEM_INFO_STRUCT_ADDR][14h], eax

d2304 3
a2307 1
	shr	eax, 12
a2309 1
	shr	eax, 12
d2322 1
a2322 1
	jz	@@F
d2365 1
d2380 1
a2380 1
	cmp	LogX, 80
d2431 1
d2479 1
d2557 1
a2557 1

d2587 1
d2601 1
d2622 1
d2638 1
a2932 3
; Restore locked VM stack.
	add	(DosTask PTR fs:[eax]).DpmiRmEsp, LOCKED_STACK_SIZE
	add	(DosTask PTR fs:[eax]).DpmiRmStack, LOCKED_STACK_SIZE
a3009 3
; Restore locked VM stack.
	add	(DosTask PTR fs:[eax]).DpmiRmEsp, LOCKED_STACK_SIZE
	add	(DosTask PTR fs:[eax]).DpmiRmStack, LOCKED_STACK_SIZE
a3057 3
; Restore locked VM stack.
	add	(DosTask PTR fs:[eax]).DpmiRmEsp, LOCKED_STACK_SIZE
	add	(DosTask PTR fs:[eax]).DpmiRmStack, LOCKED_STACK_SIZE
d3190 1
d3192 2
a3196 3
; Restore locked VM stack.
	add	(DosTask PTR fs:[eax]).DpmiRmEsp, LOCKED_STACK_SIZE
	add	(DosTask PTR fs:[eax]).DpmiRmStack, LOCKED_STACK_SIZE
d3202 1
a3202 1
	cmp	LogX, 80
d3218 2
a3219 4
	mov	eax, CurrTaskPtr
	mov	eax, (DosTask PTR fs:[eax]).DpmiRmStack
	sub	eax, SIZEOF DpmiState
	RESTORE_STATE_REGS
d3224 1
a3224 1
	cmp	LogX, 80
d3242 8
d3265 1
a3265 1
	cmp	LogX, 80
d3279 1
a3279 16

; Adjust PM locked stack.
	mov	eax, CurrTaskPtr
	add	(DosTask PTR fs:[eax]).DpmiPmEsp, LOCKED_STACK_SIZE
	add	(DosTask PTR fs:[eax]).DpmiPmStack, LOCKED_STACK_SIZE

cmp	(DosTask PTR fs:[eax]).DpmiPmEsp, PM_LOCKED_ESP
jna	@@F
mov	eax, (DosTask PTR fs:[eax]).DpmiPmEsp
int 2
@@@@:

; Restore VM state regs.
	mov	eax, (DosTask PTR fs:[eax]).DpmiPmStack
	sub	eax, SIZEOF DpmiState
	RESTORE_STATE_REGS
a3281 1
set_v86_mode:
d3303 1
a3303 1
	cmp	LogX, 80
a3317 8
; Get pointer to protected mode stack.
	mov	si, word ptr ExcSs
	mov	edi, ExcEsp
	mov	ebx, ExcEflags
	call	PointerToLinear

	mov	ebp, eax		; EBP keeps pointer to PM stack.

d3320 1
a3320 5
	mov	edi, ExcEdi

; Keep pointer to real mode call structure.
;	mov	(DosTask PTR fs:[ecx]).DpmiRmCallStrSeg, di
;	mov	(DosTask PTR fs:[ecx]).DpmiRmCallStrOffs, edi
d3325 2
a3326 1
	and	edi, 0FFFFh
d3329 1
a3329 1
	mov	ebx, eax		; FS:EBX -> translation structure.
d3337 2
d3340 6
a3345 18
; If in translation structure SS field is 0, use locked real mode stack.
	cmp	(XlatStruct PTR fs:[ebx]).wSs, 0
	jne	@@F

	mov	eax, (DosTask PTR fs:[ecx]).DpmiRmStack
	jmp	save_dpmi_state

@@@@:
	movzx	eax, (XlatStruct PTR fs:[ebx]).wSs
	movzx	edx, (XlatStruct PTR fs:[ebx]).wSp
	shl	eax, 4
	add	eax, edx

;
; Save DPMI state information on real  mode stack.
;
save_dpmi_state:
	sub	eax, 4				; For checksum
d3347 3
a3349 15
	sub	eax, SIZEOF DpmiState
; Save state registers.
	SAVE_STATE_REGS

; Save general purpose registers.
	lea	edx, [eax - SIZEOF GEN_REG_PACK]
	SAVE_GENERAL_REGS

; Calculate and store checksum.
	pushad
	mov	ebx, edx
	mov	ecx, SIZEOF GEN_REG_PACK + SIZEOF DpmiState
	CHECK_SUM
	mov	fs:[ebx], al
	popad
d3354 3
a3356 1
	mov	eax, ebx		; FS:EAX -> translation structure.
d3360 3
a3362 4
; If loaded stack is 0, set locked RM stack.
	sub	ExcEsp, SIZEOF DpmiState + SIZEOF GEN_REG_PACK + LOCKED_STACK_BARRIER
	cmp	ExcSs, 0
	jne	@@F
d3364 1
a3367 1
	sub	ExcEsp, SIZEOF DpmiState + SIZEOF GEN_REG_PACK + LOCKED_STACK_BARRIER
a3369 3
; Adjust locked VM stack.
	sub	(DosTask PTR fs:[eax]).DpmiRmEsp, LOCKED_STACK_SIZE
	sub	(DosTask PTR fs:[eax]).DpmiRmStack, LOCKED_STACK_SIZE
a3370 1

d3379 1
a3379 1
	call	PointerToLinear
d3387 2
a3388 2
	mov	al, fs:[esi]
	mov	fs:[edi], al
d3411 1
d3418 1
a3418 1
	cmp	LogX, 80
d3435 1
a3435 1
	jnz	@@F
d3439 2
a3440 1
@@@@:
d3442 1
a3442 44
	cmp	ExcSs, VM_LOCKED_SS
	jne	@@F

; Adjust RM locked stack.
	add	(DosTask PTR fs:[edx]).DpmiRmEsp, LOCKED_STACK_SIZE
	add	(DosTask PTR fs:[edx]).DpmiRmStack, LOCKED_STACK_SIZE

; Load pointer to real mode stack.
	mov	ebp, (DosTask PTR fs:[edx]).DpmiRmStack
	sub	ebp, 4				; For checksum
	sub	ebp, SIZEOF DpmiState + SIZEOF GEN_REG_PACK

; Calculate and verify checksum.
	pushad
	mov	ebx, ebp
	mov	ecx, SIZEOF GEN_REG_PACK + SIZEOF DpmiState
	CHECK_SUM
	cmp	fs:[ebx], al
	popad
	je	get_rm_call_ptr

; Fatal error: checksum doesn't match!
int 4

@@@@:
; EBP keeps pointer to real mode stack.
	movzx	ebp, ExcSs
	mov	eax, ExcEsp
	shl	ebp, 4
	add	ebp, eax

; Remove DPMI state saves from real mode stack.
	add	ExcEsp, SIZEOF DpmiState + SIZEOF GEN_REG_PACK + LOCKED_STACK_BARRIER

; Retrieve pointer to real mode call structure from real mode stack.
get_rm_call_ptr:
	mov	si, (DpmiState PTR fs:[ebp + SIZEOF GEN_REG_PACK]).Sregs.wEs
	mov	edi, (GEN_REG_PACK PTR fs:[ebp]).dwEdi
	test	(DosTask PTR fs:[edx]).TaskFlags, TASK_32BIT
	jnz	@@F
	and	edi, 0FFFFh
@@@@:
	sub	ebx, ebx		; VM = 0
	call	PointerToLinear
d3447 2
a3448 7
; Restore general purpose registers
	mov	edx, ebp
	RESTORE_GENERAL_REGS

; Restore state registers.
	lea	eax, [ebp + SIZEOF GEN_REG_PACK]
	RESTORE_STATE_REGS
d3457 1
a3457 1
	cmp	LogX, 80
d3492 1
a3492 1

d3494 1
d3496 2
d3504 1
a3504 1
	cmp	LogX, 80
a3631 10
; Adjust locked PM stack.
	sub	fs:[ebp].DpmiPmEsp, LOCKED_STACK_SIZE
	sub	fs:[ebp].DpmiPmStack, LOCKED_STACK_SIZE

cmp	(DosTask PTR fs:[ebp]).DpmiPmEsp, PM_LOCKED_STACK_BOTTOM
jnb	@@F
mov	eax, (DosTask PTR fs:[ebp]).DpmiPmEsp
int 2
@@@@:

d3647 1
d3649 2
d3657 1
a3657 1
	cmp	LogX, 80
a3678 11
; Adjust locked PM stack.
	mov	eax, CurrTaskPtr
	add	(DosTask PTR fs:[eax]).DpmiPmEsp, LOCKED_STACK_SIZE
	add	(DosTask PTR fs:[eax]).DpmiPmStack, LOCKED_STACK_SIZE

cmp	(DosTask PTR fs:[eax]).DpmiPmEsp, PM_LOCKED_ESP
jna	@@F
mov	eax, (DosTask PTR fs:[eax]).DpmiPmEsp
int 2
@@@@:

d3800 1
a3800 1
; allocaions, SETS LDT to 0 etc.
d3870 393
@


0.42
log
@1) Added XMS server
2) Memory allocation / deallocation is moved to task creation / deletion
@
text
@d20 1
d234 4
d463 3
a488 3
	cmp	eax, PM2VM_SWITCH_ADDR
	jne	err_ret

a619 1
	mov	dword ptr fs:[ebx][eax], 0
d621 1
a621 1
	mov	dword ptr fs:[ebx][eax][4], (DATA_ACCESS OR 01100000b) SHL 8
d623 1
a623 1
	mov	dword ptr fs:[ebx][eax][4], (ACC_PRESENT SHL 8)
d1070 3
a1072 1
	pop	eax			
d1145 4
d1454 2
a1455 2
	movzx	ebx, byte ptr ExcEbx		; Interrupt vector.
	cmp	ebx, 20h			; Check for valid exception number.
a1460 1
	movzx	ecx, byte ptr ExcEbx
d1518 2
a1519 2
	movzx	ebx, byte ptr ExcEbx		; Interrupt vector.
	cmp	ebx, 20h			; Check for valid exception number.
a1523 1
	movzx	ecx, byte ptr ExcEbx
a1556 1
	movzx	ebx, byte ptr ExcEbx		; Interrupt vector.
d1560 1
a1560 1
	movzx	ecx, byte ptr ExcEbx
a1616 1
	movzx	ebx, byte ptr ExcEbx		; Interrupt vector.
d1619 1
a1619 1
	movzx	ecx, byte ptr ExcEbx
d1682 1
d1733 24
d1768 1
d1820 24
d1855 1
d1943 2
a1944 3
; Store parameters in callbacks array.
	shl	ecx, 3
	add	ecx, CALLBACK_OFFS
d2152 8
d2162 2
a2170 2
	sub	edx, edx
	mov	fs:[MEM_INFO_STRUCT_ADDR + edx], eax	; Store free memory size.
d2172 13
a2184 10
; Fill all the rest with -1s.
	mov	eax, -1
@@@@:
	add	edx, 4
	cmp	edx, MEM_INFO_STRUCT_LEN
	jnb	@@F
	mov	fs:[MEM_INFO_STRUCT_ADDR + edx], eax
	jmp	@@B

@@@@:
d2196 4
a2306 2
	cmp	eax, DPMI_MEM_DESCRIPTORS * SIZEOF DpmiMemDescr
	jnb	ret_cf_1
d2308 1
d2352 1
a2352 1
	add	eax, ebx			; Must form and offset in
d2396 6
d2403 2
d3173 4
d3222 7
d3247 2
d3257 8
d3273 1
a3273 1
	sub	ExcEsp, SIZEOF DpmiState + SIZEOF GEN_REG_PACK
d3280 1
a3280 1
	sub	ExcEsp, SIZEOF DpmiState + SIZEOF GEN_REG_PACK
d3310 1
d3366 1
d3368 12
a3379 1
	jmp	get_rm_call_ptr
d3389 1
a3389 1
	add	ExcEsp, SIZEOF DpmiState + SIZEOF GEN_REG_PACK
d3720 6
d3747 9
a3755 2
	mov	ebx, eax
; If descriptor is not allocated, return an error also.
d3761 1
@


0.41
log
@Bug fixes:
1) Virtual I/O jump table (very annoying!)
2) IsFileOpen() bug if file name is 0.
@
text
@a19 1
	EXTRN	LinearToPhysical: near32
a20 1
	EXTRN	HeapAllocPage: near32
d23 1
d28 3
d59 2
d127 56
d222 1
a222 2
;	Callback for page fault. Checks if the faulting address is switch
; address and if it is, does mode siwtch for task and allocates LDT.
a260 1

a290 12
; Allocate and zero memory descriptors.
	mov	eax, PAGE_PRESENT OR PAGE_WRITABLE
	mov	ecx, DPMI_MEM_DESCRIPTORS * SIZEOF DpmiMemDescr

	call	HeapAllocMem
	mov	fs:[ebp].DpmiMemDescrArr, eax
	mov	edi, eax

	shr	ecx, 2
	sub	eax, eax
		rep	stosd

d399 14
d416 1
d433 5
d458 1
d475 5
d531 1
d548 1
d571 35
d608 1
a609 1
	jmp	ret_cf_1
d633 16
d666 16
d743 16
d768 2
a769 3
	mov	byte ptr ExcEcx, cl
	mov	cl, (Descriptor386 PTR fs:[ebx][eax]).BaseHigh32
	mov	byte ptr ExcEcx[2], cl
d779 28
d812 26
d840 1
a840 1
	mov	cl, byte ptr ExcEcx
d842 2
a843 3
	mov	cl, byte ptr ExcEcx[1]
	mov	(Descriptor386 PTR fs:[ebx][eax]).BaseHigh32, cl
	mov	dx, word ptr ExcEdx
d853 27
d889 1
a889 1
	movzx	ecx, word ptr ExcEcx
d893 1
a893 7
	jnb	page_gran

; Byte granular limit.
	mov	(Descriptor386 PTR fs:[ebx][eax]).LimitLow, cx
	shr	ecx, 16
	mov	(Descriptor386 PTR fs:[ebx][eax]).LimitHigh20, cl
	jmp	ret_cf_0			; Success.
a894 1
page_gran:
d897 3
a901 1
	or	cl, ATTR_GRAN
d911 25
d957 17
d991 2
a992 2
	mov	ecx, eax
	call	FindFreeDtEntry
d1010 34
d1082 35
a1145 1
	and	ExcEflags, NOT FL_CF
d1150 1
a1150 1
;	Allocate descriptor for diven selector.
d1175 17
d1208 17
d1259 26
d1351 17
d1380 35
d1416 1
a1416 1
	mov	ecx, ExcEbx
d1427 17
d1474 35
d1532 17
d1575 35
d1631 44
d1691 45
a1744 1

a1748 1

d1753 45
d1820 45
a1864 1
	mov	ebp, CurrTaskPtr
d1922 26
d1981 7
d1997 1
d1999 10
d2010 1
a2010 3

	mov	word ptr ExcEax, 0			; 0 bytes required.
	jmp	ret_cf_0			; Error.
d2017 7
d2034 11
d2070 26
d2098 7
d2112 2
a2113 1
	jnb	ret_cf_0		; Success.
d2117 24
d2146 19
d2170 21
d2194 1
a2194 1
set_mem_handle:
d2199 1
d2211 19
d2248 30
d2306 1
a2306 1
	jnc	set_mem_handle		; At AllocMem section.
d2311 1
a2311 1
	
d2341 1
a2341 1
;	Map physical address. Meanwhile this function doesn't succeeds (need
d2345 32
d2384 6
d2403 8
a2410 1
	mov	eax, 1
d2418 7
d2474 1
a2474 1
; If 0 selector, return invalid.
d2500 3
d2504 1
d2508 2
d2511 1
d2526 2
a2527 5
@@@@:
	call	HeapFreePage
	add	eax, 1000h
	sub	ecx, 1000h
	jnz	@@B
d2718 2
a2719 2
	add	(DosTask PTR fs:[eax]).DpmiRmEsp, SIZEOF DpmiState + 6
	add	(DosTask PTR fs:[eax]).DpmiRmStack, SIZEOF DpmiState + 6
d2798 2
a2799 2
	add	(DosTask PTR fs:[eax]).DpmiRmEsp, SIZEOF DpmiState + 6
	add	(DosTask PTR fs:[eax]).DpmiRmStack, SIZEOF DpmiState + 6
d2849 2
a2850 3
	add	(DosTask PTR fs:[eax]).DpmiRmEsp, SIZEOF DpmiState + 6
	add	(DosTask PTR fs:[eax]).DpmiRmStack, SIZEOF DpmiState + 6
	mov	eax, (DosTask PTR fs:[eax]).DpmiRmStack
d2876 1
d2878 1
a2878 1
	shl	eax, 4				; EAX = block new size.
d2981 5
d2988 2
a2989 2
	add	(DosTask PTR fs:[eax]).DpmiRmEsp, SIZEOF DpmiState + 6
	add	(DosTask PTR fs:[eax]).DpmiRmStack, SIZEOF DpmiState + 6
d2991 1
d3008 1
d3015 18
d3048 1
d3065 1
d3069 2
a3070 6
	test	(DosTask PTR fs:[eax]).TaskFlags, TASK_32BIT
	jnz	@@F
; 16 bit task.
	add	(DosTask PTR fs:[eax]).DpmiPmEsp, SIZEOF DpmiState + 6
	add	(DosTask PTR fs:[eax]).DpmiPmStack, SIZEOF DpmiState + 6
	jmp	set_v86_mode
d3072 4
a3075 1
; 32 bit task.
a3076 2
	add	(DosTask PTR fs:[eax]).DpmiPmEsp, SIZEOF DpmiState + 12
	add	(DosTask PTR fs:[eax]).DpmiPmStack, SIZEOF DpmiState + 12
d3078 1
d3097 20
d3128 5
a3141 1
	mov	eax, (DosTask PTR fs:[ecx]).DpmiRmStack
d3145 1
a3145 3
; Adjust locked VM stack.
	sub	(DosTask PTR fs:[eax]).DpmiRmEsp, SIZEOF DpmiState + SIZEOF GEN_REG_PACK + 6
	sub	(DosTask PTR fs:[eax]).DpmiRmStack, SIZEOF DpmiState + SIZEOF GEN_REG_PACK + 6
d3174 1
d3181 1
d3184 3
a3187 1
	sub	ExcEsp, SIZEOF DpmiState + SIZEOF GEN_REG_PACK
d3223 8
d3247 1
a3255 1
; If VM code was running on locked stack, adjust RM locked stack.
d3257 1
a3257 6
	movzx	eax, ExcSs
	shl	eax, 4
	add	eax, ExcEsp
	sub	eax, 6
	mov	ecx, (DosTask PTR fs:[edx]).DpmiRmStack
	cmp	eax, (DosTask PTR fs:[edx]).DpmiRmStack
d3260 8
a3267 2
	add	(DosTask PTR fs:[edx]).DpmiRmEsp, SIZEOF DpmiState + SIZEOF GEN_REG_PACK + 6
	add	(DosTask PTR fs:[edx]).DpmiRmStack, SIZEOF DpmiState + SIZEOF GEN_REG_PACK + 6
d3270 8
a3277 1
	lea	ebp, [eax + 6]		; EBP keeps pointer to real mode stack.
d3279 2
a3280 1
; Get pointer to real mode call structure.
a3289 3
; Remove DPMI state saves from real mode stack.
	add	ExcEsp, SIZEOF DpmiState + SIZEOF GEN_REG_PACK

d3301 22
d3343 6
d3365 1
d3431 1
d3433 1
a3438 2
	sub	fs:[ebp].DpmiPmEsp, 6		; Adjust locked PM ESP.
	sub	fs:[ebp].DpmiPmStack, 6		; Adjust locked PM stack.
d3440 1
a3440 1
	mov	word ptr fs:[eax], CALLBACK_RET_TRAP_OFFS	; Return EIP
d3442 1
a3442 1
	mov	fs:[eax][2], cx				; Return CS
d3444 1
a3444 1
	mov	fs:[eax][4], cx				; Return flags
d3447 1
d3450 1
d3452 1
a3458 2
	sub	fs:[ebp].DpmiPmEsp, 12		; Adjust locked PM ESP.
	sub	fs:[ebp].DpmiPmStack, 12	; Adjust locked PM stack.
d3460 1
a3460 1
	mov	dword ptr fs:[eax], CALLBACK_RET_TRAP_OFFS	; Return EIP
d3462 1
a3462 1
	mov	fs:[eax][4], cx				; Return CS
d3464 1
a3464 1
	mov	fs:[eax][8], ecx			; Return flags
d3467 1
d3470 2
d3480 10
d3503 6
d3525 1
d3536 2
a3537 2
	test	(DosTask PTR fs:[eax]).TaskFlags, TASK_32BIT
	jnz	@@F
d3539 4
a3542 6
; 16 bit task.
	add	(DosTask PTR fs:[eax]).DpmiPmEsp, 6
	add	(DosTask PTR fs:[eax]).DpmiPmStack, 6
	jmp	restore_rm_regs

; 32-bit task.
a3543 2
	add	(DosTask PTR fs:[eax]).DpmiPmEsp, 12
	add	(DosTask PTR fs:[eax]).DpmiPmStack, 12
a3544 1
restore_rm_regs:
d3570 1
d3593 3
a3595 2
	jnc	@@F
; Memory allocation failed.
d3599 1
a3599 1
@@@@:
d3618 1
a3618 1
;	I: EAX = memory descriptor
d3625 1
d3634 1
d3642 1
a3642 4
@@@@:
	call	HeapFreePage
	sub	ecx, 1000h
	jg	@@B
d3677 2
a3678 37
	mov	ecx, 10h
@@@@:
	call	HeapFreePage
	add	eax, 1000h
	dec	ecx
	jnz	@@B

; Free memory that could have been allocated with DPMI descriptors.
	mov	ecx, DPMI_MEM_DESCRIPTORS * SIZEOF DpmiMemDescr
	mov	ebx, fs:[edx].DpmiMemDescrArr

free_next_descr:
	mov	esi, (DpmiMemDescr PTR fs:[ebx]).BlockLength
	mov	eax, (DpmiMemDescr PTR fs:[ebx]).BlockAddress

	test	eax, eax
	jz	next_block

; Free pages one by one.
@@@@:
	call HeapFreePage
	add	eax, 1000h
	sub	esi, 1000h
	jg	@@B

next_block:
	sub	ecx, SIZEOF DpmiMemDescr
	jnz	free_next_descr

; Free memory allocated for DPMI memory descriptors themselves.
	mov	ecx, DPMI_MEM_DESCRIPTORS * SIZEOF DpmiMemDescr
	mov	eax, fs:[edx].DpmiMemDescrArr
@@@@:
	call	HeapFreePage
	add	eax, 1000h
	sub	ecx, 1000h
	jge	@@B
d3686 38
@


0.40
log
@DPMI server fixes:
1) Locker real mode and protected mode stacks usage fixed: reentrancy allowed.
2) Modes switches fixed.
@
text
@a2238 2
	inc	CheckPt

@


0.39
log
@Bug fixed: raw mode switches.
@
text
@d20 1
d23 1
d27 2
d124 3
d142 1
a142 1
	ADD_GDT_SEGMENT	0FFFF0h, 0FFFFh, CODE_ACCESS OR 01100000b
d146 1
a146 1
	ADD_GDT_SEGMENT	0FFFF0h, 0FFFFh, DATA_ACCESS OR 01100000b
d183 4
d202 1
d207 7
d216 1
a216 1
	call	HeapAllocPage
a217 4
	mov	edi, eax
	mov	ecx, 400h
	sub	eax, eax
		rep	stosd
d221 1
a221 1
	call	HeapAllocPage
a222 4
	mov	edi, eax
	mov	ecx, 400h
	sub	eax, eax
		rep	stosd
d225 1
a225 1
	call	HeapAllocPage
a226 4
	mov	edi, eax
	mov	ecx, 400h
	sub	eax, eax
		rep	stosd
d230 1
a230 1
	call	HeapAllocPage
a231 4
	mov	edi, eax
	mov	ecx, 400h
	sub	eax, eax
		rep	stosd
d245 2
a246 2
; Do initial switch.
	call	CreateLdt		; Create LDT.
a352 1

d356 17
d392 17
a434 1
	or	CheckPt, 1
d458 18
d507 3
d511 1
d782 1
a782 1
	push	eax
a794 2
	mov	edx, eax		; FS:EDX -> source.
	pop	eax
d796 2
a797 1
	mov	ebx, CurrLdtBase		; FS:EBX+EAX -> dest.
d801 1
a801 1
	mov	fs:[ebx][eax], ecx
d803 1
a803 1
	mov	fs:[ebx][eax][4], ecx
d834 3
a836 9
	SAVE_STATE_REGS
; Change state to virtual mode.
	mov	ExcSeg, RET_TRAP_SEG
	mov	ExcOffs, RET_TRAP_OFFS
	mov	ExcSs, VM_LOCKED_SS
	mov	ExcEsp, VM_LOCKED_ESP
	or	ExcEflags, FL_VM

; Set registers to call allocate block.
a849 13
	SAVE_STATE_REGS
; Change state to virtual mode.
	mov	ExcSeg, RET_TRAP_SEG
	mov	ExcOffs, RET_TRAP_OFFS
	mov	ExcSs, VM_LOCKED_SS
	mov	ExcEsp, VM_LOCKED_ESP
	or	ExcEflags, FL_VM

;
; Set registers to call free block.
;
	mov	byte ptr ExcEax[1], 49h

d851 1
d854 1
a854 1
	sub	edx, edx
d856 1
a856 1
	cmp	(DosBlockSel PTR fs:[esi][edx]).wSel, ax
d858 2
a859 2
	add	edx, SIZEOF DosBlockSel
	cmp	edx, 1000h
d866 3
a868 3
	mov	ax, (DosBlockSel PTR fs:[esi][edx]).wSeg
	mov	ExcEs, ax

d871 3
a883 11
	SAVE_STATE_REGS
; Change state to virtual mode.
	mov	ExcSeg, RET_TRAP_SEG
	mov	ExcOffs, RET_TRAP_OFFS
	mov	ExcSs, VM_LOCKED_SS
	mov	ExcEsp, VM_LOCKED_ESP
	or	ExcEflags, FL_VM

; Set registers to call allocate block.
	mov	byte ptr ExcEax[1], 4Ah

d885 1
d932 3
a934 3
	mov	ax, (DosBlockSel PTR fs:[esi][edx]).wSeg
	mov	ExcEs, ax

d937 3
d1075 1
d1091 1
d1110 1
d1130 2
d1163 8
a1170 1
	mov	ecx, ExcEsi
a1171 1
	mov	ecx, ExcEdi
d1174 4
d1719 5
d1726 1
a1726 1
	jnz	restore_sregs
a1728 1
	mov	eax, CurrTaskPtr
d1784 1
a1784 1
	jle	restore_sregs
d1799 5
d1806 1
a1806 1
	jnz	restore_sregs
a1809 1
	mov	eax, CurrTaskPtr
d1844 1
a1844 1
	jmp	restore_sregs
d1850 6
d1858 1
a1858 1
	jnz	restore_sregs
a1860 1
	mov	eax, CurrTaskPtr
d1901 1
a1901 1
	je	restore_sregs			; Block left the same.
d1915 1
a1915 1
	jmp	restore_sregs
d1947 1
a1947 1
	jmp	restore_sregs
d1959 1
a1959 1
	jmp	restore_sregs
d1978 1
a1978 1
	jmp	restore_sregs
d1984 26
a2009 1
restore_sregs:
d2021 1
a2021 1
;	Restore VM state after PM callback.
d2026 33
d2060 1
d2062 1
a2074 4
; Save state registers.
	SAVE_STATE_REGS
	SAVE_GENERAL_REGS

d2081 1
a2081 1
	mov	ebp, eax		; Keep pointer to PM stack.
d2083 1
a2083 1
	mov	eax, CurrTaskPtr
d2087 1
a2087 1
	test	(DosTask PTR fs:[eax]).TaskFlags, TASK_32BIT
d2091 31
a2121 1
	call	PointerToLinear		; FS:EAX -> translation structure.
d2124 3
a2126 1
	LOAD_XLAT_REGS
d2128 9
a2136 1
	mov	edx, esi		; Keep interrupt number.
d2138 4
d2175 17
d2199 16
d2216 6
a2221 3
	mov	eax, CurrTaskPtr
	mov	si, (DosTask PTR fs:[eax]).DpmiAltState.Sregs.wEs
	mov	edi, (DosTask PTR fs:[eax]).DpmiAltRegs.dwEdi
d2224 4
d2230 3
a2232 1
; Restore task state.
d2234 3
d2239 2
d2261 17
d2311 1
a2311 1
	sub	ebx, ebx		; VM = 0
d2318 1
a2318 1
; Set RM SS base address to RM SS.
a2330 2
	movzx	eax, word ptr ExcEsp		; Real mode ESP.
	mov	ExcEsi, eax
a2332 2
	mov	eax, fs:[ebx].dwRegsOffs	; EDI = offset of real mode call struct.
	mov	ExcEdi, eax
d2336 1
a2336 1
	and	ExcEflags, NOT FL_VM		; Set VM
d2343 8
a2350 1
	mov	eax, VM_LOCKED_ESP - 6
d2362 8
a2369 1
	mov	eax, VM_LOCKED_ESP - 12
d2400 17
d2424 16
a2557 1

@


0.38
log
@Bugs fixed:
1) PointerToLinear() check
2) Default interrupt redirection to V86 mode
@
text
@a118 2
	HeapAllocs	DD	0

d361 9
a371 2
	jmp	ok_ret

d379 6
a392 2
	mov	ebx, ExcEbx				; New mode ESP.
	mov	ExcEsp, ebx
a394 2
	mov	ebx, ExcEdi				; New mode EIP.
	mov	ExcOffs, ebx
d399 1
a1047 1
	or	CheckPt, 1
a1251 1
	inc	HeapAllocs
a2286 1
	mov	eax, HeapAllocs
@


0.37
log
@Bug fixed: reflecting PM to VM interrupt.
@
text
@d1088 1
a1088 1
	mov	edx, (Dostask PTR fs:[ebp]).DpmiCallbackArr
d1157 1
a1157 1
	mov	(DpmiCallback PTR [esi+edx]).dwPmEIp, 0
d2194 1
a2194 1
	mov	edx, (Dostask PTR fs:[ebp]).DpmiMemDescrArr
d2225 1
a2225 1
	sub	eax, (Dostask PTR fs:[ebp]).DpmiMemDescrArr
d2245 1
a2245 1
	mov	edx, (Dostask PTR fs:[ebp]).DpmiMemDescrArr
a2337 5

; Set V86 mode.
	or	ExcEflags, FL_VM
	mov	ExcSs, VM_LOCKED_SS
	mov	ExcEsp, VM_LOCKED_ESP
@


0.36
log
@Bug fixes:
1) CreatePageTable() called from HeapAllocMem()
2) Zero allocated PDB for new task
@
text
@d115 1
a115 1
			DD	offset ResizeDOSBlockRet
a1656 1

d1912 4
d2341 2
@


0.35
log
@HeapAllocMem() bug fixed; free DPMI memory allocated fixed.
@
text
@d119 2
d418 2
a419 1
	je	jmp2handler
d427 2
a428 3
jmp2handler:
	jmp	DpmiHandlers[ecx*4]

d567 1
a567 1
	mov	cl, byte ptr ExcEcx[2]
d606 2
a607 1
	mov	(Descriptor386 PTR fs:[ebx][eax]).LimitHigh20, cl
d627 1
d1245 1
d1249 5
d2181 1
a2181 1
;	O: CF = 0 - success, EAX = handle.
d2218 2
d2222 1
d2278 1
a2278 1

@


0.34
log
@Bug fixes:
1) Initial pages map allocation
2) Translation services params
3) DPMI clean up memory release -- almost
4) INT 21h AH=4Ch in protected mode.
@
text
@a42 1
	EXTRN	FirstTask: dword
d237 1
d251 1
d2268 1
d2290 1
a2290 1
	cmp	ecx, DPMI_MEM_DESCRIPTORS * SIZEOF DpmiMemDescr
d2297 3
d2307 1
@


0.33
log
@Initial full release - all DPMI functions are written! Half are not tet.
@
text
@d118 2
d234 1
d281 1
a281 1
	call	GetLdtPtr
d426 1
d431 1
a431 1
	call	GetLdtPtr
d436 1
a436 2
	or	ExcEflags, FL_CF
	jmp	ok_ret
a437 1
	and	ExcEflags, NOT FL_CF		; Success
d449 2
a450 1
	jmp	ok_ret
d460 1
a460 2
	or	ExcEflags, FL_CF
	jmp	ok_ret
d463 1
a463 1
	call	GetLdtPtr
d466 2
a467 2
	and	ExcEflags, NOT FL_CF		; Success
	jmp	ok_ret
d473 1
a473 1
	call	GetLdtPtr
d504 1
a504 3

	or	ExcEflags, FL_CF
	jmp	ok_ret
d510 2
a511 2
	and	ExcEflags, NOT FL_CF
	jmp	ok_ret
d518 2
a519 2
	and	ExcEflags, NOT FL_CF
	jmp	ok_ret
d527 2
a528 1
	jmp	ok_ret
d537 1
a538 2
	or	ExcEflags, FL_CF
	jmp	ok_ret
d540 1
a540 1
	call	GetLdtPtr
d548 2
a549 2
	and	ExcEflags, NOT FL_CF
	jmp	ok_ret
d558 1
a558 3

	or	ExcEflags, FL_CF
	jmp	ok_ret
d560 1
a560 1
	call	GetLdtPtr
d569 2
a570 2
	and	ExcEflags, NOT FL_CF
	jmp	ok_ret
d579 1
a580 2
	or	ExcEflags, FL_CF
	jmp	ok_ret
d582 1
a582 1
	call	GetLdtPtr
d595 1
a595 2
	and	ExcEflags, NOT FL_CF
	jmp	ok_ret
d604 2
a605 2
	and	ExcEflags, NOT FL_CF
	jmp	ok_ret
d614 1
a615 2
	or	ExcEflags, FL_CF
	jmp	ok_ret
d617 1
a617 1
	call	GetLdtPtr
d624 2
a625 2
	and	ExcEflags, NOT FL_CF
	jmp	ok_ret
d634 1
a635 2
	or	ExcEflags, FL_CF
	jmp	ok_ret
d637 1
a637 1
	call	GetLdtPtr
d645 1
a645 3

	or	ExcEflags, FL_CF
	jmp	ok_ret
d660 2
a661 1
	jmp	ok_ret
d670 1
a671 2
	or	ExcEflags, FL_CF
	jmp	ok_ret
d691 1
a691 1
	call	GetLdtPtr		; FS:EBX+EAX -> source.
d698 2
a699 2
	and	ExcEflags, NOT FL_CF
	jmp	ok_ret
d708 1
a709 2
	or	ExcEflags, FL_CF
	jmp	ok_ret
d728 1
a728 1
	call	GetLdtPtr		; FS:EBX+EAX -> dest.
d736 2
a737 1
	jmp	ok_ret
d746 1
a747 2
	or	ExcEflags, FL_CF
	jmp	ok_ret
d749 1
a749 1
	call	GetLdtPtr
a750 2

	call	GetLdtPtr
d753 1
a754 3
	or	ExcEflags, FL_CF
	jmp	ok_ret

d758 2
a759 2
	and	ExcEflags, NOT FL_CF
	jmp	ok_ret
d780 2
a781 1
	jmp	ok_ret
a810 1
	or	ExcEflags, FL_CF		; Error
d812 1
a812 1
	jmp	ok_ret
d823 2
a824 1
	jmp	ok_ret
a851 1
	or	ExcEflags, FL_CF		; Error
d853 1
a853 1
	jmp	ok_ret
d869 1
a869 1
	call	GetLdtPtr
a883 1
	or	ExcEflags, FL_CF
d885 1
a885 1
	jmp	ok_ret
d896 2
a897 1
	jmp	ok_ret
d908 2
a909 2
	and	ExcEflags, NOT FL_CF
	jmp	ok_ret
d920 2
a921 2
	and	ExcEflags, NOT FL_CF
	jmp	ok_ret
d929 1
a929 3
	jb	@@F
	or	ExcEflags, FL_CF
	jmp	ok_ret
a930 1
@@@@:
d950 2
a951 2
	and	ExcEflags, NOT FL_CF
	jmp	ok_ret
d959 1
a959 3
	jb	@@F
	or	ExcEflags, FL_CF
	jmp	ok_ret
a960 1
@@@@:
d973 1
a973 2
	and	ExcEflags, NOT FL_CF
	jmp	ok_ret
d999 2
a1000 2
	and	ExcEflags, NOT FL_CF
	jmp	ok_ret
d1020 1
a1020 2
	and	ExcEflags, NOT FL_CF
	jmp	ok_ret
d1027 1
a1027 48
; Save state registers.
	SAVE_STATE_REGS
	SAVE_GENERAL_REGS

; Get pointer to protected mode stack.
	mov	si, word ptr ExcSs
	mov	edi, ExcEsp
	mov	ebx, ExcEflags
	call	PointerToLinear

	mov	ebp, eax		; Keep pointer to PM stack.

	mov	eax, CurrTaskPtr
	mov	si, word ptr ExcEsi
	mov	edi, ExcEdi
	mov	ebx, ExcEflags
	test	(DosTask PTR fs:[eax]).TaskFlags, TASK_32BIT
	jnz	@@F
	and	edi, 0FFFFh
@@@@:
	call	PointerToLinear		; FS:EAX -> translation structure.
	movzx	esi, byte ptr ExcEbx	; ESI = interrupt number.
	movzx	ecx, word ptr ExcEcx	; ECX = number of words to copy to RM stack.
	LOAD_XLAT_REGS
	or	ExcEflags, FL_VM	; Set V86 mode.
	mov	edx, esi		; Keep interrupt number.

	test	ecx, ecx
	jz	prepare_ret_trap

; Copy parameters.
	mov	si, ExcSs
	mov	edi, ExcEsp
	mov	ebx, ExcEflags
	call	PointerToLinear

	shl	ecx, 1
	sub	word ptr ExcEsp, cx

	mov	edi, eax
	mov	esi, ebp		; Retrieve pointer to PM stack.
@@@@:
	mov	al, fs:[esi]
	mov	fs:[edi], al
	dec	ecx
	jnz	@@B

prepare_ret_trap:
d1036 1
a1036 1
	jmp	ok_ret
d1043 1
a1043 46
; Save state registers.
	SAVE_STATE_REGS
	SAVE_GENERAL_REGS

; Get pointer to protected mode stack.
	mov	si, word ptr ExcSs
	mov	edi, ExcEsp
	mov	ebx, ExcEflags
	call	PointerToLinear

	mov	ebp, eax		; Keep pointer to PM stack.

	mov	eax, CurrTaskPtr
	mov	si, word ptr ExcEsi
	mov	edi, ExcEdi
	mov	ebx, ExcEflags
	test	(DosTask PTR fs:[eax]).TaskFlags, TASK_32BIT
	jnz	@@F
	and	edi, 0FFFFh
@@@@:
	call	PointerToLinear		; FS:EAX -> translation structure.
	movzx	ecx, word ptr ExcEcx	; ECX = number of words to copy to RM stack.
	LOAD_XLAT_REGS	1		; Load CS:IP
	or	ExcEflags, FL_VM	; Set V86 mode.

	test	ecx, ecx
	jz	prepare_retf_trap

; Copy parameters.
	mov	si, ExcSs
	mov	edi, ExcEsp
	mov	ebx, ExcEflags
	call	PointerToLinear

	shl	ecx, 1
	sub	word ptr ExcEsp, cx

	mov	edi, eax
	mov	esi, ebp		; Retrieve pointer to PM stack.
@@@@:
	mov	al, fs:[esi]
	mov	fs:[edi], al
	dec	ecx
	jnz	@@B

prepare_retf_trap:
d1054 1
a1054 1
	jmp	ok_ret
d1061 1
a1061 46
; Save state registers.
	SAVE_STATE_REGS
	SAVE_GENERAL_REGS

; Get pointer to protected mode stack.
	mov	si, word ptr ExcSs
	mov	edi, ExcEsp
	mov	ebx, ExcEflags
	call	PointerToLinear

	mov	ebp, eax		; Keep pointer to PM stack.

	mov	eax, CurrTaskPtr
	mov	si, word ptr ExcEsi
	mov	edi, ExcEdi
	mov	ebx, ExcEflags
	test	(DosTask PTR fs:[eax]).TaskFlags, TASK_32BIT
	jnz	@@F
	and	edi, 0FFFFh
@@@@:
	call	PointerToLinear		; FS:EAX -> translation structure.
	movzx	ecx, word ptr ExcEcx	; ECX = number of words to copy to RM stack.
	LOAD_XLAT_REGS	1		; Load CS:IP
	or	ExcEflags, FL_VM	; Set V86 mode.

	test	ecx, ecx
	jz	prepare_iret_trap

; Copy parameters.
	mov	si, ExcSs
	mov	edi, ExcEsp
	mov	ebx, ExcEflags
	call	PointerToLinear

	shl	ecx, 1
	sub	word ptr ExcEsp, cx

	mov	edi, eax
	mov	esi, ebp		; Retrieve pointer to PM stack.
@@@@:
	mov	al, fs:[esi]
	mov	fs:[edi], al
	dec	ecx
	jnz	@@B

prepare_iret_trap:
d1074 1
a1074 1
	jmp	ok_ret
d1093 1
a1093 3
	or	ExcEflags, FL_CF
	jmp	ok_ret

d1121 1
a1122 3
	and	ExcEflags, NOT FL_CF
	jmp	ok_ret

d1148 1
a1148 2
	or	ExcEflags, FL_CF
	jmp	ok_ret
d1154 1
a1155 3
	and	ExcEflags, NOT FL_CF
	jmp	ok_ret

d1174 1
a1174 2
	and	ExcEflags, NOT FL_CF
	jmp	ok_ret
d1192 1
a1193 3
	and	ExcEflags, NOT FL_CF
	jmp	ok_ret

d1206 1
a1206 3

	and	ExcEflags, FL_CF	; Success.
	jmp	ok_ret
d1225 1
a1225 1
	jnb	ret_cf_0		; Return success.
a1431 20
;	Get ptr to current task's LDT.
;
;	I:
;	O:	FS:EBX -> LDT
;
;-----------------------------------------------------------------------------
GetLdtPtr	PROC	USES eax edx
	mov	eax, CurrTaskPtr
	movzx	eax, (DosTask PTR fs:[eax]).TaskLdt
	mov	edx, GdtBase
	mov	bl, (Descriptor386 PTR fs:[edx][eax]).BaseHigh24
	mov	bh, (Descriptor386 PTR fs:[edx][eax]).BaseHigh32
	shl	ebx, 16
	mov	bx, (Descriptor386 PTR fs:[edx][eax]).BaseLow
	ret
GetLdtPtr	ENDP


;-----------------------------------------------------------------------------
;
d1441 1
a1441 1
	mov	eax, PAGE_PRESENT
d1450 1
d1677 1
a1677 1
	call	GetLdtPtr		; FS:EBX -> LDT
d1735 1
a1735 1
	call	GetLdtPtr
d1806 1
a1806 1
	call	GetLdtPtr
d1929 59
d2074 1
a2074 1
	mov	ebx, fs:[ebp].TaskLdtBase
d2261 1
a2261 1
DpmiWashUp	PROC	USES eax ebx ecx
d2266 1
a2266 1
	mov	eax, fs:[edx].DpmiPmInts
d2270 2
d2279 1
a2279 6
	movzx	eax, (Descriptor386 PTR fs:[ebx][ecx]).BaseHigh32
	mov	ecx, dword ptr (Descriptor386 PTR fs:[ebx][ecx]).BaseHigh32
	shl	eax, 24
	and	ecx, 0FFFFFFh
	or	eax, ecx

d2286 30
@


0.32
log
@Translation services work.
@
text
@d50 4
d160 2
d177 1
a177 1
	cmp	(DosTask PTR fs:[ebp]).TaskLdt, 0
d195 1
a195 1
	mov	eax, PAGE_PRESENT OR PAGE_USER OR PAGE_WRITABLE
d197 1
a197 1
	mov	(DosTask PTR fs:[ebp]).DpmiDOSBlocks, eax
d204 9
a212 1
	mov	eax, PAGE_PRESENT OR PAGE_USER OR PAGE_WRITABLE
d214 1
a214 1
	mov	(DosTask PTR fs:[ebp]).DpmiPmInts, eax
d216 1
a216 1
	shr	ecx, 2
d220 2
a221 1
	mov	eax, PAGE_PRESENT OR PAGE_USER OR PAGE_WRITABLE
d223 5
a227 1
	mov	(DosTask PTR fs:[ebp]).DpmiPmExcs, eax
d229 5
d241 2
a242 2
	mov	(DosTask PTR fs:[ebp]).TaskLdt, ax
	mov	(DosTask PTR fs:[ebp]).TaskLdtLimit, 80h
d289 1
a289 1
	add	(DosTask PTR fs:[ebp]).TaskLdtLimit, 8
d301 1
a301 1
	add	(DosTask PTR fs:[ebp]).TaskLdtLimit, 8
d311 1
a311 1
	add	(DosTask PTR fs:[ebp]).TaskLdtLimit, 8
d320 1
a320 1
	add	(DosTask PTR fs:[ebp]).TaskLdtLimit, 8
d329 9
a337 1
	add	(DosTask PTR fs:[ebp]).TaskLdtLimit, 8
d342 1
a342 1
	and	ExcEflags, NOT FL_VM		; Set protected mode.
d345 1
a345 2
	or	eax, TASK_RAW_PMODE
	mov	(DosTask PTR fs:[ebp]).TaskFlags, eax
a353 1
; Switch VM to PM.
d355 4
d364 21
a384 1
; Switch PM to VM.
d393 1
d1235 3
d1239 50
d1290 35
d1326 20
d1347 15
d1363 3
d1367 11
d1379 5
d1385 18
d1404 18
d1423 17
d1441 24
d1466 19
d1490 2
d1493 3
d1500 7
d1508 1
d1510 4
d1515 12
d1528 7
d1536 3
d1540 3
d1544 2
d1547 4
d1555 1
d1557 6
d2123 15
d2145 1
d2148 231
@


0.31
log
@1) Interrupt redirection works
2) HeapAllocMem() bug fixes
DPMI traps fixed
@
text
@d45 1
d113 3
d156 1
a156 1
	movzx	esi, ExcSeg
d170 1
a170 1
	TASK_PTR	CurrentTask, ebp
d199 1
a199 2
	mov	ecx, PM_INTS * 8
	call	HeapAllocMem
d207 1
a207 2
	mov	ecx, PM_EXCS * 8
	call	HeapAllocMem
d320 1
a320 1
	TASK_PTR	CurrentTask
d352 1
a352 1
Int31Handler	PROC	USES eax ebx ecx edx esi edi
d418 1
a418 1
	TASK_PTR	CurrentTask
d632 1
a632 1
	TASK_PTR	CurrentTask
d670 1
a670 1
	TASK_PTR	CurrentTask
d892 1
a892 1
	TASK_PTR	CurrentTask, edx
d925 1
a925 1
	TASK_PTR	CurrentTask, edx
d946 1
a946 1
	TASK_PTR	CurrentTask, edx
d972 1
a972 1
	TASK_PTR	CurrentTask, edx
d989 3
d993 62
d1056 62
d1119 61
d1261 1
a1261 1
	TASK_PTR	CurrentTask
d1290 3
d1303 1
d1340 1
a1340 1
PmAddGdtSegment	PROC	USES ebx ecx esi
d1500 1
a1500 1
	TASK_PTR	CurrentTask
d1577 1
a1577 1
	TASK_PTR	CurrentTask
d1623 1
a1623 1
	TASK_PTR	CurrentTask
a1759 1
	TASK_PTR	CurrentTask
d1770 18
d1791 3
d1796 32
a1827 1
DpmiWashUp	PROC
d1829 1
@


0.30
log
@DOS block functions are written and work. Callback to real mode mechanism established. Tests are still brief.
@
text
@d13 2
d16 2
a18 1

d51 3
d115 25
d184 1
a184 1
; Allocate and zero DOS memory blocks structure (up to 2k blocks).
d195 1
a195 1
	mov	ecx, RM_INT_HANDLERS * 256 * 8
a196 9
	mov	(DosTask PTR fs:[ebp]).DpmiRmInts, eax
	mov	edi, eax
	shr	ecx, 2
	sub	eax, eax
		rep	stosd

	mov	eax, PAGE_PRESENT OR PAGE_USER OR PAGE_WRITABLE
	mov	ecx, PM_INT_HANDLERS * 256 * 8
	call	HeapAllocMem
d204 1
a204 1
	mov	ecx, PM_EXC_HANDLERS * 256 * 8
d207 1
d736 1
a736 3

	clc
	ret
d779 1
a780 3
	clc
	ret

d853 1
d855 11
a865 2
	clc
	ret
d867 3
a869 1
GetRMInt::
d871 11
d883 32
d916 26
d943 25
d969 17
d1293 1
d1550 1
a1550 18
; Restore state regs from alternate save structure.
	TASK_PTR	CurrentTask
	mov	edx, (DosTask PTR fs:[eax]).TaskAltEip
	mov	ExcOffs, edx
	mov	edx, (DosTask PTR fs:[eax]).TaskAltEsp
	mov	ExcEsp, edx
	mov	dx, (DosTask PTR fs:[eax]).TaskAltSregs.wCs
	mov	ExcSeg, dx
	mov	dx, (DosTask PTR fs:[eax]).TaskAltSregs.wDs
	mov	ExcDs, dx
	mov	dx, (DosTask PTR fs:[eax]).TaskAltSregs.wEs
	mov	ExcEs, dx
	mov	dx, (DosTask PTR fs:[eax]).TaskAltSregs.wFs
	mov	ExcFs, dx
	mov	dx, (DosTask PTR fs:[eax]).TaskAltSregs.wGs
	mov	ExcGs, dx
	mov	dx, (DosTask PTR fs:[eax]).TaskAltSregs.wSs
	mov	ExcSs, dx
d1557 16
@


0.29
log
@First DPMI selector functions work (Hello, world).
@
text
@d18 1
d20 2
d103 3
d120 1
a120 1
DpmiSwitch	PROC	USES eax ebx ecx edx esi edi
d134 55
a188 4
; If task made initial mode switch, return error.
	TASK_PTR	CurrentTask, edi
	cmp	(DosTask PTR fs:[edi]).TaskLdt, 0
	jne	err_ret
d192 2
a193 2
	mov	(DosTask PTR fs:[edi]).TaskLdt, ax
	mov	(DosTask PTR fs:[edi]).TaskLdtLimit, 80h
d240 1
a240 1
	add	(DosTask PTR fs:[edi]).TaskLdtLimit, 8
d252 1
a252 1
	add	(DosTask PTR fs:[edi]).TaskLdtLimit, 8
d262 1
a262 1
	add	(DosTask PTR fs:[edi]).TaskLdtLimit, 8
d271 1
a271 1
	add	(DosTask PTR fs:[edi]).TaskLdtLimit, 8
d280 1
a280 1
	add	(DosTask PTR fs:[edi]).TaskLdtLimit, 8
d289 1
a289 1
	mov	(DosTask PTR fs:[edi]).TaskFlags, eax
d291 1
a291 2
	clc
	ret
d300 1
a300 2
	clc
	ret
d307 1
d327 1
a327 1
Int31Handler	PROC	USES eax ebx ecx
d438 1
a438 1
	or	ExcEflags, FL_CF
a600 1
	call	GetLdtPtr
d617 3
a619 1
	pop	eax			; FS:EBX+EAX -> source.
a639 1
	call	GetLdtPtr
a640 1

d655 1
a655 1
	pop	eax			; FS:EBX+EAX -> dest.
d657 2
d690 1
a690 1
	or	(Descriptor386 PTR fs:[ebx][eax]).Access, ACC_PRESENT
a692 1
	
d694 3
d698 22
d721 44
d766 68
d835 3
d1141 302
@


0.28
log
@Initial DPMI switch works.
@
text
@d28 4
d33 3
d44 56
d114 1
a114 1
DpmiSwitch	PROC	USES eax ebx ecx edx esi
d129 2
a130 2
	TASK_PTR	CurrentTask, edx
	cmp	(DosTask PTR fs:[edx]).TaskLdt, 0
d135 2
a136 1
	mov	(DosTask PTR fs:[edx]).TaskLdt, ax
d172 2
a173 7
	TASK_PTR	CurrentTask
	movzx	eax, (DosTask PTR fs:[eax]).TaskLdt
	mov	edx, GdtBase
	mov	bl, (Descriptor386 PTR fs:[edx][eax]).BaseHigh24
	mov	bh, (Descriptor386 PTR fs:[edx][eax]).BaseHigh32
	shl	ebx, 16
	mov	bx, (Descriptor386 PTR fs:[edx][eax]).BaseLow
a174 1
	mov	esi, ecx
d183 1
d195 1
d205 1
d214 1
d223 1
d229 4
d265 4
d271 422
a692 1
Int31Handler	PROC
d699 47
d808 1
a808 1
PmAddGdtSegment	PROC	USES ebx ecx
d859 2
a860 2
;	Finds the first unused descriptor table entry. Unused DT entries will
; be marked not present.
d868 4
a871 1
	mov	eax, 8		; Don't check zero descriptor.
d886 57
@
