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
	je	@F
	or	ExcEflags, FL_CF
	jmp	ok_ret
@@:
; Return CF = 1 if not enough free memory for DPMI init allocations.
	call	LeftFreePages
	shl	eax, 12
	cmp	eax, DPMI_BUF_SIZE
	jnb	@F
	or	ExcEflags, FL_CF
	jmp	ok_ret

@@:
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
	jnc	@F
	jmp	ret_cf_1

@@:
	mov	word ptr ExcEax, ax		; Base selector
; Zero all allocated descriptors and make them present (allocated).
	movzx	ecx, word ptr ExcEcx
@@:
IFDEF	DPMI_COOKIE
	mov	(Descriptor386 PTR fs:[ebx][eax]).Access, DATA_ACCESS OR 01100000b
ELSE	
	mov	(Descriptor386 PTR fs:[ebx][eax]).Access, ACC_PRESENT
ENDIF	; DPMI_COOKIE
	add	eax, 8
	dec	ecx
	jnz	@B

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
@@:
	movzx	ebx, ExcSs
	and	ebx, NOT 7
	cmp	eax, ebx
	je	ret_cf_0

	movzx	eax, word ptr ExcEbx
	call	ValidateUserSel
	jnc	@F

	jmp	ret_cf_1			; Error.

@@:
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
	jne	@F
	mov	ExcDs, 0
@@:
	movzx	ebx, ExcEs
	and	ebx, NOT 7
	cmp	eax, ebx
	jne	@F
	mov	ExcEs, 0
@@:
	movzx	ebx, ExcFs
	and	ebx, NOT 7
	cmp	eax, ebx
	jne	@F
	mov	ExcFs, 0
@@:
	movzx	ebx, ExcGs
	and	ebx, NOT 7
	cmp	eax, ebx
	jne	@F
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
	jne	@F

	lea	eax, [ecx+7]
	jmp	store_sel

@@:
	add	ecx, 8
	jmp	seg_mapped?

add_sel:
	mov	ecx, 0FFFFh		; Limit = 64k
	mov	edx, DATA_ACCESS OR 01100000b
	call	AddSegment
	jnc	@F
	jmp	ret_cf_1		; Error.

@@:
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
	jnc	@F
	jmp	ret_cf_1		; Error.

@@:
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
	jnc	@F
	jmp	ret_cf_1			; Error.
@@:

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
	mov	ebx, CurrLdtBase
	and	eax, NOT 7
	mov	ecx, ExcEcx
	mov	(Descriptor386 PTR fs:[ebx][eax]).BaseHigh24, cl
	mov	(Descriptor386 PTR fs:[ebx][eax]).BaseHigh32, ch
	mov	edx, ExcEdx
	mov	(Descriptor386 PTR fs:[ebx][eax]).BaseLow, dx
@@:
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
	jnc	@F
	jmp	ret_cf_1			; Error.

@@:
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
	jnc	@F
	jmp	ret_cf_1			; Error.

@@:
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
	jnc	@F
	jmp	ret_cf_1			; Error.

@@:
	mov	ebx, CurrLdtBase
	and	eax, NOT 7

IF 0
; If not code segment, return fail.
	mov	cl, (Descriptor386 PTR fs:[ebx][eax]).Access
	and	cl, ACC_CODE
	cmp	cl, ACC_CODE
	je	@F
	jmp	ret_cf_1			; Error.

@@:
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
	jnc	@F
	jmp	ret_cf_1			; Error.

@@:
	and	eax, NOT 7

	push	eax
; Get pointer to user buffer.
	mov	si, ExcEs
	mov	edi, ExcEdi
	mov	eax, CurrTaskPtr
	test	(DosTask PTR fs:[eax]).TaskFlags, TASK_32BIT
	jnz	@F

; 16 bit tasks only set DI.
	and	edi, 0FFFFh
@@:
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
	jnc	@F
	jmp	ret_cf_1			; Error.

@@:
	and	eax, NOT 7
	mov	ebp, eax
; Get pointer to user buffer.
	mov	si, ExcEs
	mov	edi, ExcEdi
	mov	eax, CurrTaskPtr
	test	(DosTask PTR fs:[eax]).TaskFlags, TASK_32BIT
	jnz	@F

; 16 bit tasks only set DI.
	and	edi, 0FFFFh
@@:
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
	jnc	@F
	jmp	ret_cf_1			; Error.

@@:
	mov	ebx, CurrLdtBase
	and	eax, NOT 7
	test	(Descriptor386 PTR fs:[ebx][eax]).Access, ACC_PRESENT
	jz	@F
	jmp	ret_cf_1			; Error.

@@:
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
@@:
	cmp	(DosBlockSel PTR fs:[esi][edi]).wSel, ax
	je	@F
	add	edi, SIZEOF DosBlockSel
	cmp	edi, 1000h
	jb	@B

	mov	word ptr ExcEax, 9		; Wrong selector
	jmp	ret_cf_1			; Error.

@@:
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
@@:
	cmp	(DosBlockSel PTR fs:[esi][edx]).wSel, ax
	je	@F
	add	edx, SIZEOF DosBlockSel
	cmp	edx, 1000h
	jb	@B

	mov	word ptr ExcEax, 9		; Wrong selector
	jmp	ret_cf_1			; Error.

@@:
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

@@:
	test	(Descriptor386 PTR fs:[ebx][edi*8]).Access, ACC_PRESENT
	jnz	@F
	dec	eax
	jnz	@B
; Ok, go on resize.
	jmp	do_resize

; Fail - not enough descriptors.
@@:
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
	jnz	@F

	lea	ebx, [ecx * 8 + PM_DEF_EXC_OFFS]
	mov	si, PmCallbackCs
@@:
	mov	word ptr ExcEdx, bx
	test	(DosTask PTR fs:[edx]).TaskFlags, TASK_32BIT
	jz	@F

	mov	ExcEdx, ebx
@@:
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
	jnz	@F
	and	ebx, 0FFFFh
@@:
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
	jnz	@F

	lea	ebx, [ecx * 8 + PM_DEF_INT_OFFS]
	mov	si, PmCallbackCs
@@:
	mov	word ptr ExcEdx, bx
	test	(DosTask PTR fs:[edx]).TaskFlags, TASK_32BIT
	jz	@F
	mov	ExcEdx, ebx
@@:
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
	jnz	@F

	and	ebx, 0FFFFh
@@:
	mov	fs:[eax+ecx*8], ebx

	mov	ebx, ExcEcx
; If setting interupt handler that is in PmCallbackCs, set 0s.
	cmp	bx, PmCallbackCs
	jne	@F
	sub	ebx, ebx

@@:
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

@@:
	cmp	(DpmiCallback PTR fs:[edx]).wPmCs, 0
	je	@F
	add	edx, SIZEOF DpmiCallback
	dec	ecx
	jnz	@B

; All callbacks are allocated.
	jmp	ret_cf_1			; Error.

; Settle new callback.
@@:
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
	jnz	@F
	and	eax, 0FFFFh
	and	ecx, 0FFFFh
@@:
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
	jne	@F
	cmp	(DpmiCallback PTR fs:[esi+edx]).wRmIp, bx
	je	free_callback

@@:
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
	jnz	@F

; 16 bit task, return SI:DI.
	mov	word ptr ExcEdi, ax
	jmp	ret_cf_0			; Success.

; 32 bit task, return SI:EDI.
@@:
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
	jnz	@F

; 16 bit task, return SI:DI.
	mov	word ptr ExcEdi, ax
	jmp	ret_cf_0			; Success.

; 32 bit task, return SI:EDI.
@@:
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
@@:
	mov	fs:[MEM_INFO_STRUCT_ADDR + edx], eax
	sub	edx, 4
	jnl	@B

	call	LeftFreePages
	mov	ecx, eax
	shl	eax, 12
; For every 4M of memory it's needed 4K for dynamic page table. This
; calculaton is roughly correct.
	shl	ecx, 2
	sub	eax, ecx
; The biggest contiguous block available for alloc is 4M - 4K bytes.
;	cmp	eax, 003FF000h
;	jna	@F
;	mov	eax, 003FF000h
;
;@@:

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
	jnz	@F
	and	edi, 0FFFFh
@@:
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
	jnb	@F
; If zero selector, return invalid.
	stc
	ret
@@:
; If not LDT selector, return invalid.
	test	eax, 4
	jnz	@F
	stc
	ret
@@:
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
	jnc	@F

; Return with error.
	ret

@@:
	mov	LdtBase, eax
	mov	edx, CurrTaskPtr
	mov	(DosTask PTR fs:[edx]).TaskLdtBase, eax
	mov	CurrLdtBase, eax

	dec	ecx
	mov	edx, LDT_ACCESS
	call	PmAddGdtSegment
	jnc	zero_ldt

; Free allocated memory.
@@:
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
	jnc	@F
	pop	eax
	ret

@@:
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
	jb	@F
	stc
	ret
@@:
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
	jnz	@F
	stc
	ret
@@:
	
	mov	ecx, 80h		; Skip reserved LDT descriptors.
find_free:
	cmp	ecx, 10000h
	jb	@F
	stc
	ret
@@:
; Check for free selsctor.
	test	(Descriptor386 PTR fs:[ebx][ecx]).Access, ACC_PRESENT
	jz	@F
	add	ecx, 8
	jmp	find_free
@@:
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
@@:
	cmp	(DosBlockSel PTR fs:[esi][edx]).wSeg, ax
	je	@F
	add	edx, SIZEOF DosBlockSel
	cmp	edx, 1000h
	jb	@B

; Unlikely case that blocks number exceed 1000h / 6.
	ret

@@:
	add	esi, edx
; Get LDT descriptors for allocated segment block.
	mov	ebx, CurrLdtBase		; FS:EBX -> LDT
	movzx	ecx, word ptr ExcEax
	mov	edi, ecx		; EDI captures segment address.
	shl	ecx, 4			; ECX = segment's linear address.
	movzx	eax, word ptr ExcEbx
	shl	eax, 4			; EAX = first descriptor limit (bytes)
	test	eax, eax		; decrement if allocating > 0 bytes.
	jz	@F
	dec	eax
@@:
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
@@:
	cmp	(DosBlockSel PTR fs:[esi][edx]).wSeg, ax
	je	@F
	add	edx, SIZEOF DosBlockSel
	cmp	edx, 1000h
	jb	@B

; Allocated segment was not in structure (probably structure size was exceeded
; on allocation).
	ret

@@:
	movzx	eax, (DosBlockSel PTR fs:[esi][edx]).wNSels	; Number of selectors.
	movzx	ecx, (DosBlockSel PTR fs:[esi][edx]).wSel
@@:
	and	(Descriptor386 PTR fs:[ebx][ecx]).Access, NOT ACC_PRESENT
	add	ecx, 8
	dec	eax
	jnz	@B

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
@@:
	cmp	(DosBlockSel PTR fs:[esi][edx]).wSeg, di
	je	@F
	add	edx, SIZEOF DosBlockSel
	cmp	edx, 1000h
	jb	@B

; Segment being resized is not in DOS blocks structure.
	ret

@@:
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
	jne	@F
; Yes, only patch last descriptor's limit.
	movzx	edi, (DosBlockSel PTR fs:[esi]).wNSels
	dec	edi
	mov	(Descriptor386 PTR [ebx][edi*8]).LimitLow, ax
	jmp	restore_state_regs

@@:
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

@@:
	or	dword ptr (Descriptor386 PTR [ebx][ecx*8]).BaseLow, edx
	cmp	eax, 10000h
	jb	@F
	mov	(Descriptor386 PTR [ebx][ecx*8]).LimitLow, 0FFFFh
	add	edx, 10000h
	sub	eax, 10000h
	inc	ecx
	jmp	@B

@@:
; Set last limit.
	mov	(Descriptor386 PTR [ebx][ecx*8]).LimitLow, ax
	jmp	restore_state_regs

block_shrunk:
; Determine number of descriptors needed.
	mov	edi, eax
	shr	edi, 16				; EDI = number of descriptors
	cmp	di, (DosBlockSel PTR fs:[esi]).wNSels
	jne	@F

; Modify only limit for last descriptor.
	sub	eax, ecx
	add	(Descriptor386 PTR fs:[ebx][edi]).LimitLow, ax
	jmp	restore_state_regs

@@:
; Set limit of the last descriptor.
	and	eax, 0FFFFh
	mov	(Descriptor386 PTR fs:[ebx][edi*8]).LimitLow, ax
	mov	(Descriptor386 PTR fs:[ebx][edi*8]).LimitHigh20, 0

; Free descriptors.
	mov	eax, edi
@@:
	and	(Descriptor386 PTR fs:[ebx][eax*8]).Access, NOT ACC_PRESENT
	inc	eax
	cmp	ax, (DosBlockSel PTR fs:[esi]).wNSels
	jb	@B

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

restore_state_regs:
	call	PmRestoreState

IFDEF	MONITOR_LOCKED_PM_STACK
pushad
	PM_PRINT_HEX32	ExcEsp, LogX, LogY, LogClr
	add	LogX, 9
	cmp	LogX, 72
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

; Set protmode.
	and	ExcEflags, NOT FL_VM

; If ExcDs is E400, restore from task structure.
	cmp	ExcDs, 0E400h
	jne	@F
	mov	eax, CurrTaskPtr
	mov	cx, (DosTask PTR fs:[eax]).TaskSregs.wDs
	mov	ExcDs, cx
@@:

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

	mov	ecx, CurrTaskPtr	; FS:ECX -> current task structure.
	mov	si, ExcEs
	mov	edi, ExcEdi		; Get ptr to "real mode call" struct.

	mov	ebx, ExcEflags
	test	(DosTask PTR fs:[ecx]).TaskFlags, TASK_32BIT
	jnz	@F
	and	edi, 0FFFFh		; Determine DI or EDI contained offset.

@@:
	call	PointerToLinear
	mov	ebx, eax
	call	LinearToPhysical	; Check validity of linear address.
	jnc	@F

	stc				; Wrong linear address.
	ret

@@:
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
	;jne	@F
	
; Set locked RM stack.
	mov	eax, CurrTaskPtr
	mov	edx, (DosTask PTR fs:[eax]).DpmiRmEsp
	mov	ExcEsp, edx
	mov	ExcSs, VM_LOCKED_SS

@@:
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
@@:
	mov	al, fs:[ebp][ecx-1]
	mov	fs:[edi][ecx-1], al
	dec	ecx
	jnz	@B

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
	je	@F
	PM_PRINT_HEX32	ExcEsp, LogX, LogY, LogClr
	add	LogX, 9
	cmp	LogX, 72
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

PUSHCONTEXT	ASSUMES
ASSUME	ebp: PTR DosTask, ebx: PTR DpmiCallback
; Valid only if occured in V86 mode.
	test	ExcEflags, FL_VM
	jnz	@F
	stc
	ret

@@:
	sub	eax, (CALLBACK_SEG * 16)	; EAX = offset
	mov	ebp, CurrTaskPtr		; FS:EBP -> Current task structure.

; Find the allocated callback.
	mov	ebx, fs:[ebp].DpmiCallbackArr
	mov	ecx, MAX_DPMI_CALLBACKS

@@:
	cmp	ax, fs:[ebx].wRmIp
	je	@F
	add	ebx, SIZEOF DpmiCallback
	dec	ecx
	jnz	@B

; Error - callback not allocated.
	stc
	ret

; Allocated callback found (FS:EBX->).
@@:
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
	jnz	@F

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
@@:
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

; Valid only if occured in protected mode.
	test	ExcEflags, FL_VM
	jz	@F
	stc
	ret

@@:
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

@@:
	cmp	(DpmiMemDescr PTR fs:[edx]).BlockAddress, 0
	je	@F
	add	edx, SIZEOF DpmiMemDescr
	dec	ecx
	jnz	@B

; All memory descriptors have exhausted.
	stc
	ret

; Allocate memory and return descriptor handle (offset).
@@:
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
	jnz	@F

; Return error.
mem_descr_err:
	stc
	ret

; Free memory.
@@:
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
	jnz	@F			; Yes, use 16 bits.

	mov	eax, CurrTaskPtr
	test	(DosTask PTR fs:[eax]).TaskFlags, TASK_32BIT
	jnz	save_regs

@@:
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
	jnz	@F			; Yes, use 16 bits.

	mov	eax, CurrTaskPtr
	test	(DosTask PTR fs:[eax]).TaskFlags, TASK_32BIT
	jnz	restore_regs

@@:
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
	jnz	@F
	stc
	ret

@@:
	mov	ebx, CurrLdtBase
	and	eax, NOT 7
	add	ebx, eax

; If points to non present segment, return error.
	test	(Descriptor386 PTR fs:[ebx]).Access, ACC_PRESENT
	jnz	@F
	stc
	ret

@@:
	mov	ah, (Descriptor386 PTR fs:[ebx]).BaseHigh32
	mov	al, (Descriptor386 PTR fs:[ebx]).BaseHigh24
	shl	eax, 16
	mov	ax, (Descriptor386 PTR fs:[ebx]).BaseLow

; If target descriptor address is > FFFF0, return failure.
	shr	eax, 4
	cmp	eax, 0FFFFh
	jna	@F
	stc
	ret

@@:
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
	jc	@F
	mov	ExcDs, ax
	ret

@@:
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
	jz	@F

	add	edx, SIZEOF DpmiState
	SAVE_GENERAL_REGS

@@:
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
	jz	@F
	add	edx, SIZEOF DpmiState
	RESTORE_GENERAL_REGS

@@:
	ret
RestoreState	ENDP


CODE32	ENDS
END
