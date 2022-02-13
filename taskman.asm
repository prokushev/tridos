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
;				TASKMAN.ASM
;				-----------
;
;	Task (DOS boxes management) module.
;
;	(!) HddSema4 is handled appropriate only for single CPU machine.
;
;=============================================================================
.486p
	INCLUDE	TASKMAN.INC
	INCLUDE	x86.INC
	INCLUDE	DEF.INC
	INCLUDE	PHLIB32.MCR
	INCLUDE	DPMI.INC


DATA	SEGMENT	PARA	PUBLIC	USE16	'DATA'
	PUBVAR		TempPdb, DD, ?

	PUBVAR	NumOfTasks, DD, 0	; Number of active tasks.
	PUBVAR	FirstTask, DD, 0	; Ptr to page of tasks.
	PUBVAR	CurrentTask, DD, 0 	; Currently running task.
	PUBVAR	CurrTaskPtr, DD, 0	; Pointer to current task.
	PUBVAR	ForegroundTask, DD, 0	; Task owning I/O focus.
	PUBVAR	GpCount, DD, 0		; Counts how much times VM #GP occured.

	PUBVAR	VirtualIf, DD, 0 	; Virtual interrupt flag.
	PUBVAR	FakeIopl, DD, 3000h	; IOPL value as set by app.

	PUBVAR	Int13RetOp, DB, ?	; HDD semaphore: 8 bytes of client opcode to be
		DB	7 DUP (?)	; replaced with entry invalid opcode.
		DB	8 DUP (?)	; the same for FDD.

	PUBVAR	NextToRun, DD, -1	; Next task to run.

	PUBVAR	HddSema4, DB, 0		; HDD is a shared
				 	; resource.
	PUBVAR	HddSema4Own, DD, ?	; Task owning HDD semaphore.
	PUBVAR	FddSema4, DB, 0		; FDD is a shared
				 	; resource.
	PUBVAR	FddSema4Own, DD, ?	; Task owning FDD semaphore.

	DosFunc	DW	?		; Save called DOS function for trap.
	ErrCode	DB	0		; Extended error handled if non-0.

	TestFName	DB	100 DUP (?) ; Keeps full file name during
					; comparison.

IFDEF	DOUBLE_SHELL
	ComSpecStr	DB	"COMSPEC=", 0
	PspSeg		DW	?
	Dta		DB	512 DUP (?)

	ExecPrmBlock	DW	0
			DW	CmdTail, DATA
			DW	5Ch, ?
			DW	6Ch, ?
			DW	?, ?, ?, ?
	CmdTail		DB	0, 0Dh, 0Ah
ENDIF	; DOUBLE_SHELL
; Keep DPMI traps. Will be copied to DPMI service page.

DpmiTraps	LABEL	BYTE

	DpmiTrap	2, 0		; Init mode switch
	DpmiTrap	2, 1		; Raw PM to VM mode switch
	DpmiTrap	2, 2		; Raw VM to PM mode switch
	DpmiTrap	3		; Return from int redirected to VM
	DpmiTrap	4		; Return from PM exception handler

; Default exception handlers.
EXC_HANDLER = 0
WHILE	EXC_HANDLER LT 32
	DpmiTrap	5, EXC_HANDLER
EXC_HANDLER = EXC_HANDLER + 1
ENDM

; Default interrupt handler
INT_HANDLER = 0
WHILE	INT_HANDLER LT 256
DpmiTrap	6, INT_HANDLER
INT_HANDLER = INT_HANDLER + 1
ENDM

	DpmiTrap	7		; Return from PM interrupt handler
	DpmiTrap	8		; Return from translation services
	DpmiTrap	0Ah		; Return from RM callback handler
	DpmiTrap	0Dh		; VM save state proc (saves PM state)
	DpmiTrap	0Eh		; PM save state proc (saves VM state)

; Placeholder for memory info structure.
REPEAT	3
	DpmiTrap	0
ENDM

;IFDEF	FAKE_WINDOWS
	DpmiTrap	0Bh		; Windows "vendor API entry point".
;ENDIF
;IFDEF	PROVIDE_HIMEM
	DpmiTrap	0Ch		; XMS server entry point.
;ENDIF

DPMI_TRAPS_SIZE	=	$ - DpmiTraps	; Multiple of Qwords.


	ReflectPM2PMStr DB	"ReflectPM2PM: "
	ReflectPM2VMStr DB	"ReflectPM2VM: "
	ReflectVM2PMStr DB	"ReflectVM2PM: "
	ReflectVM2VMStr DB	"ReflectVM2VM: "

DATA	ENDS


	EXTRN	PointerToLinear: near32
	EXTRN	HeapAllocPage: near32
	EXTRN	HeapAllocZPage: near32
	EXTRN	HeapAllocMem: near32
	EXTRN	HeapFreePage: near32
	EXTRN	HeapFreeMem: near32
	EXTRN	LinearToPhysical: near32
	EXTRN	LeftFreePages: near32
	EXTRN	AddExcTrap: near32
	EXTRN	SaveClientRegs: near32
	EXTRN	RestoreClientRegs: near32
	EXTRN	SetClientRegs: near32
	EXTRN	PmHex32ToA: near32
	EXTRN	PmWriteStr32: near32
	EXTRN	PmStrCmp: near32
	EXTRN	PmToUpper: near32
	EXTRN	SaveVideoContext: near32
	EXTRN	RestoreVideoContext: near32
	EXTRN	SaveVideoMemory: near32
	EXTRN	RestoreVideoMemory: near32
	EXTRN	TrapVideoPorts: near32
	EXTRN	TrapGenDevPorts: near32
	EXTRN	RelGenDevSema4s: near32
	EXTRN	SkipPrefixes: near32
	EXTRN	Int31Handler: near32
	EXTRN	DpmiWashUp: near32
	EXTRN	WriteLog: near32

	EXTRN	PmSaveState: near32
	EXTRN	RmSaveState: near32
	EXTRN	PmRestoreState: near32
	EXTRN	RmRestoreState: near32


	EXTRN	SysPdb: dword
	EXTRN	Pdb: dword
	EXTRN	SysPdbLin: dword
	EXTRN	PdbLin: dword
	EXTRN	SysPagesCtl: dword
	EXTRN	PagesCtl: dword
	EXTRN	OsHeapEnd: dword

	EXTRN	SystemTask: dword

	EXTRN	ExcCode: dword
	EXTRN	ExcOffs: dword
	EXTRN	ExcSeg: word
	EXTRN	ExcEflags: dword
	EXTRN	ExcEax: dword
	EXTRN	ExcEbx: dword
	EXTRN	ExcEcx: dword
	EXTRN	ExcEdx: dword
	EXTRN	ExcEsp: dword
	EXTRN	ExcEbp: dword
	EXTRN	ExcEsi: dword
	EXTRN	ExcEdi: dword
	EXTRN	ExcDs: word
	EXTRN	ExcEs: word
	EXTRN	ExcFs: word
	EXTRN	ExcGs: word
	EXTRN	ExcSs: word

	EXTRN	VirtualIp: dword
	EXTRN	VirtualIsr: dword
	EXTRN	VirtualImr: dword

	EXTRN	OperandSize: byte
	EXTRN	AddressSize: byte
	EXTRN	SegPrefix: byte
	EXTRN	RepPrefix: byte

	EXTRN	CurrDrive: byte
	EXTRN	ListOfListsLin: dword
	EXTRN	Field: byte

	EXTRN	KbdQHead: dword
	EXTRN	KbdQTail: dword
	EXTRN	KeyboardQ: byte

	EXTRN	Cpu: word

	EXTRN	PmCallbackCs: word
	EXTRN	PmCallbackSs: word
	EXTRN	CurrLdtBase: dword

	EXTRN	TicksReport: dword

	EXTRN	DpmiSrvAddr: dword
	EXTRN	DpmiSrvSeg: word

	EXTRN	DmaIoRange: DWORD

IFDEF	MONITOR_DPMI
	EXTRN	LogX: byte
	EXTRN	LogY: byte
	EXTRN	LogClr: byte
ENDIF

CODE32	SEGMENT	PARA	PUBLIC	USE32	'CODE'
ASSUME	CS:CODE32, DS:FLAT

;-----------------------------------------------------------------------------
;
;	Creates new DOS task. Allocates pages and copies original DOS to it.
;
;	I:
;	O:	CF = 0	created
;		   = 1	error (not enough memory).
;
;	(!) Process creator must execute in system context to be able to fork
; a copy of original DOS. 
;	(!) For DOS structures array one page is allocated so meanwhile only
; up to MAX_TASKS.
;
;-----------------------------------------------------------------------------
CreateDosTask	PROC	USES es eax ebx ecx edx esi edi ebp
	cmp	NumOfTasks, MAX_TASKS
	jb	create_task
	stc
	ret

create_task:
	call	LeftFreePages		; Check if enough free pages left.
	cmp	eax, TASK_MEMORY_SIZE SHR 12
	jnb	enough_free

; Return error.
	ret				; CF = 1 already.

enough_free:
	mov	ax, FLAT_DS
	mov	es, ax

	mov	eax, SysPdbLin
	mov	PdbLin, eax
	mov	eax, SysPagesCtl
	mov	PagesCtl, eax
	mov	eax, SysPdb
	mov	cr3, eax		; Set system context.

; ES:ESI -> new task's structure.
	TASK_PTR	NumOfTasks, esi	; es:ESI -> task being created.

; Set borrowed ticks to 0.
IFDEF	BORROWED_TICKS
	mov	(DosTask PTR es:[esi]).BorrowedTicks, 0
ENDIF

; Set current drive.
	mov	al, CurrDrive
	mov	(DosTask PTR es:[esi]).TaskCurrDrive, al

; Set error code to 0.
	mov	(DosTask PTR es:[esi]).TaskErrCode, 0

; Set task's LDT to 0. It may be further used to verify whether the task
; already made initial switch (will be non-0). One task can have only one LDT.
	mov	(DosTask PTR es:[esi]).TaskLdt, 0

; Set DOS flags to 0.
	mov	(DosTask PTR es:[esi]).TaskFlags, 0

; Set HMA available flag to 0 (available)
	mov	(DosTask PTR es:[esi]).XmsHmaFlag, 0

; Set task's PIT 0 counter to basic TicksReport (65536).
	mov	eax, TicksReport
	mov	(DosTask PTR es:[esi]).TaskTicksReport, eax

; Reset task tick count.
	mov	(DosTask PTR es:[esi]).TaskTickCount, 0

; Reset task virtual PIT channel 0 select.
	mov	(DosTask PTR es:[esi]).TaskPITCh0Sel, 0

; Allocate page for task's open files table.
	mov	eax, PAGE_PRESENT OR PAGE_WRITABLE
	call	HeapAllocPage
	mov	(DosTask PTR es:[esi]).TaskOFTable, eax
	mov	(DosTask PTR es:[esi]).TaskOpenFiles, 0

; Allocate page for task's PDB.
	mov	eax, PAGE_PRESENT OR PAGE_WRITABLE
	call	HeapAllocZPage
	mov	(DosTask PTR es:[esi]).TaskPdbLin, eax	; PDB lin. addr.
; ES:EBX -> new task's PDB.
	mov	ebx, eax

	call	LinearToPhysical			; Get physical address
	mov	(DosTask PTR es:[esi]).TaskPdb, eax	; PDB ctl. phys. addr.

; Allocate page for task's ctl. array.
	mov	eax, PAGE_PRESENT OR PAGE_WRITABLE
	call	HeapAllocPage
	mov	(DosTask PTR es:[esi]).TaskPageCtl, eax	; Page ctl. lin. addr.
; ES:EDX -> new task's pages control array.
	mov	edx, eax

; Allocate page table for 1st Mb.
	mov	eax, PAGE_PRESENT OR PAGE_WRITABLE
	call	HeapAllocZPage
	mov	es:[edx], eax			; Lin. addr. of page table

	call	LinearToPhysical
	or	eax, PAGE_PRESENT OR PAGE_WRITABLE OR PAGE_USER
	mov	es:[ebx], eax			; Phys. addr. of page table

; ES:EDX = linear address of first page table.
	mov	edx, es:[edx]

; Allocate 1st Mb alias mapping table.
	mov	eax, PAGE_PRESENT OR PAGE_WRITABLE
	call	HeapAllocPage
	mov	(DosTask PTR es:[esi]).TaskMapping, eax
; ES:EDI -> new task's alias mapped 1st MB.
	mov	edi, eax

; Allocate save/restore video space.
	mov	eax, PAGE_PRESENT OR PAGE_WRITABLE
	call	HeapAllocPage
	mov	(DosTask PTR es:[esi]).TaskVideoState, eax

;
; Allocate pages for base and video memory. All those pages will be double-
; mapped.
;
	sub	ecx, ecx			; Pages count
alloc_pages:
	mov	eax, PAGE_PRESENT OR PAGE_WRITABLE
	call	HeapAllocPage			; Alloc page in 1st Mb.
	mov	es:[edi+ecx*4], eax		; Store linear address

	call	LinearToPhysical
	or	eax, PAGE_PRESENT OR PAGE_WRITABLE OR PAGE_USER
	mov	es:[edx+ecx*4], eax		; Store page w/ attributes.

	inc	ecx
	cmp	ecx, (0A0000h + 40000h) SHR 12		; Number of pages to
							; allocate.
	jb	alloc_pages

IFDEF	PROVIDE_HIMEM
;
; Allocate pages for HMA.
;
	mov	ecx, 100000h SHR 12
alloc_hma_pages:
	mov	eax, PAGE_PRESENT OR PAGE_WRITABLE
	call	HeapAllocPage			; Alloc page in 1st Mb.
	mov	es:[edi+ecx*4], eax		; Store linear address

	call	LinearToPhysical
	or	eax, PAGE_PRESENT OR PAGE_WRITABLE OR PAGE_USER
	mov	es:[edx+ecx*4], eax		; Store page w/ attributes.

	inc	ecx
	cmp	ecx, 110000h SHR 12		; Number of pages to allocate.
	jb	alloc_hma_pages
ENDIF	; PROVIDE_HIMEM

;
; Map all shared memory areas equally.
;
	mov	edx, (DosTask PTR es:[esi]).TaskPageCtl
	mov	ecx, PdbLin

; Map OS pages in new task.
	mov	eax, es:[ecx + (OS_BASE SHR 20)]
	mov	es:[ebx + (OS_BASE SHR 20)], eax

; Map OS video buffer in new task.
	mov	eax, es:[ecx + (OS_VIDEO_BUF SHR 20)]
	mov	es:[ebx + (OS_VIDEO_BUF SHR 20)], eax

; Map OS global 1st Mb mapping in new task.
	mov	eax, es:[ecx + (OS_1ST_MB SHR 20)]
	mov	es:[ebx + (OS_1ST_MB SHR 20)], eax

; Map OS heap pages in app.
	mov	edi, OS_HEAP
map_os_heap:
	mov	ebp, edi
	shr	ebp, 20
	mov	eax, es:[ecx + ebp]			
	mov	es:[ebx + ebp], eax
	add	edi, 400000h
	cmp	edi, OsHeapEnd
	jb	map_os_heap

	mov	ecx, PagesCtl

	mov	eax, es:[ecx + (OS_BASE SHR 20)]	; Mark OS pages in new
	mov	es:[edx + (OS_BASE SHR 20)], eax	; task's pages ctl.

	mov	edi, OS_HEAP
mark_os_heap:
	mov	ebp, edi
	shr	ebp, 20
	mov	eax, es:[ecx + ebp]			; Mark OS heap pages
	mov	es:[edx + ebp], eax			; in app's pages ctl.
	add	edi, 400000h
	cmp	edi, OsHeapEnd
	jb	mark_os_heap

;
; Map heap page tables in new task. Scan all the physically allocated entries,
; copy them and the correspondent PagesCtl entries.
;
	mov	ecx, PdbLin
	mov	ebp, PagesCtl
	mov	edi, OS_DYN_PAGETBLS SHR 22
map_dyn_pagetbls:
	mov	eax, es:[ecx + edi*4]
	test	eax, PAGE_PRESENT
	jz	dyn_pagetbls_mapped
	mov	es:[ebx + edi*4], eax
	mov	eax, es:[ebp + edi*4]
	mov	es:[edx + edi*4], eax
	inc	edi
	jmp	map_dyn_pagetbls
dyn_pagetbls_mapped:

;
; Map A0000 - FFFFF 1-to-1 (for active task). For background task video 
; memory will be virtualized.
;
	mov	edx, (DosTask PTR es:[esi]).TaskPageCtl
	mov	edx, es:[edx]
	mov	ecx, 0A0000h SHR 12
map_rom:
	mov	eax, ecx
	shl	eax, 12
	or	eax, PAGE_PRESENT OR PAGE_USER OR PAGE_WRITABLE	; Read-only pages.
	mov	es:[edx+ecx*4], eax		; Store page w/ attributes.
	inc	ecx
	cmp	ecx, 100000h SHR 12
	jb	map_rom
IFNDEF	PROVIDE_HIMEM
;
; Map HMA to low memory (00000h) to emulate A20 off.
;
	mov	ecx, 100000h SHR 12
map_hma:
	mov	eax, ecx
	and	eax, NOT 100000h		; Clear A20.
	shl	eax, 12
	or	eax, PAGE_PRESENT OR PAGE_USER OR PAGE_WRITABLE	; Read-only pages.
	mov	es:[edx+ecx*4], eax		; Store page w/ attributes.
	inc	ecx
	cmp	ecx, 110000h SHR 12
	jb	map_hma
ENDIF	; PROVIDE_HIMEM

;
; Allocate memory for DPMI server needs: mode switch, RM temp stack.
;
	mov	eax, PAGE_PRESENT OR PAGE_WRITABLE
	mov	ecx, DPMI_MEM_SIZE
	call	HeapAllocMem

	mov	ebx, (DosTask PTR es:[esi]).TaskMapping
	sub	ebp, ebp

map_dpmi_page:
;	mov	es:[ebx+(DPMI_SERVICE_PAGE SHR 10)][ebp*4], eax	; Store linear address
	push	ebx
	mov	ecx, DpmiSrvAddr
	shr	ecx, 10
	add	ebx, ecx
	mov	es:[ebx][ebp*4], eax	; Store linear address
	pop	ebx

; Clear page.
	mov	edi, eax
	mov	ecx, 400h			; Number of dwords in 1 page.
	push	eax
	sub	eax, eax
		rep	stosd
	pop	eax

	call	LinearToPhysical

; Map page for DPMI server needs.
	or	eax, PAGE_PRESENT OR PAGE_USER OR PAGE_WRITABLE

;	mov	es:[edx+(DPMI_SERVICE_PAGE SHR 10)][ebp*4], eax	; Store physical address
	push	edx
	mov	ecx, DpmiSrvAddr
	shr	ecx, 10
	add	edx, ecx
	mov	es:[edx][ebp*4], eax	; Store linear address
	pop	edx

;	mov	eax, es:[ebx+(DPMI_SERVICE_PAGE SHR 10)][ebp*4]
	push	ebx
	mov	ecx, DpmiSrvAddr
	shr	ecx, 10
	add	ebx, ecx
	mov	eax, es:[ebx][ebp*4]	; Get linear address
	pop	ebx

	add	eax, 1000h
	inc	ebp
	cmp	ebp, DPMI_MEM_PAGES
	jb	map_dpmi_page

; Copy DPMI traps to service page.
	push	esi
	push	edi
	push	ecx
	mov	esi, offset DpmiTraps

;	mov	edi, es:[ebx+(DPMI_SERVICE_PAGE SHR 10)]	; Read linear address
	mov	ecx, DpmiSrvAddr
	shr	ecx, 10
	mov	edi, es:[ebx][ecx]			; Read linear address

	mov	ecx, DPMI_TRAPS_SIZE / 4
	cld
		rep	movsd
	pop	ecx
	pop	edi
	pop	esi

IF 0
	mov	dword ptr fs:[eax], 0000FFFEh		; Invalid opcode
	mov	dword ptr fs:[eax][4], 02000000h	; DPMI, init mode switch
	mov	dword ptr fs:[eax+10h], 0000FFFEh	; Invalid opcode
	mov	dword ptr fs:[eax+10h][4], 02010000h	; Raw pm to vm mode switch
	mov	dword ptr fs:[eax+20h], 0000FFFEh	; Invalid opcode
	mov	dword ptr fs:[eax+20h][4], 02020000h	; Raw vm to pm mode switch
	mov	dword ptr fs:[eax+30h], 0000FFFEh	; Invalid opcode
	mov	dword ptr fs:[eax+30h][4], 03000000h	; Trap return from VM callback
	mov	dword ptr fs:[eax+40h], 0000FFFEh	; Invalid opcode
	mov	dword ptr fs:[eax+40h][4], 04000000h	; Trap return from PM "exception handler".
	mov	dword ptr fs:[eax+50h], 0000FFFEh	; Invalid opcode
	mov	dword ptr fs:[eax+50h][4], 05000000h	; Trap "default exception handler".
	mov	dword ptr fs:[eax+60h], 0000FFFEh	; Invalid opcode
	mov	dword ptr fs:[eax+60h][4], 06000000h	; Trap "default interrupt handler".
	mov	dword ptr fs:[eax+70h], 0000FFFEh	; Invalid opcode
	mov	dword ptr fs:[eax+70h][4], 07000000h	; Trap return from PM "interrupt handler".
	mov	dword ptr fs:[eax+80h], 0000FFFEh	; Invalid opcode
	mov	dword ptr fs:[eax+80h][4], 08000000h	; Trap return from translation services.
	mov	dword ptr fs:[eax+90h], 0000FFFEh	; Invalid opcode
	mov	dword ptr fs:[eax+90h][4], 0A000000h	; Trap return from PM "callback" (breakpoint handler).
	mov	dword ptr fs:[eax+0A0h], 0000FFFEh	; Invalid opcode
	mov	dword ptr fs:[eax+0A0h][4], 0D000000h	; RM save state proc.
	mov	dword ptr fs:[eax+0B0h], 0000FFFEh	; Invalid opcode
	mov	dword ptr fs:[eax+0B0h][4], 0E000000h	; PM save state proc.

IFDEF	FAKE_WINDOWS
	mov	dword ptr fs:[eax+0F0h], 0000FFFEh	; Invalid opcode
	mov	dword ptr fs:[eax+0F0h][4], 0B000000h	; Windows "vendor API entry point".
ENDIF
	mov	dword ptr fs:[eax+100h], 0000FFFEh	; Invalid opcode
	mov	dword ptr fs:[eax+100h][4], 0C000000h	; XMS server entry point.
ENDIF

; Allocate and zero memory descriptors.
	mov	eax, PAGE_PRESENT OR PAGE_WRITABLE
	mov	ecx, DPMI_MEM_DESCRIPTORS * SIZEOF DpmiMemDescr

	call	HeapAllocMem
	mov	(DosTask PTR es:[esi]).DpmiMemDescrArr, eax
	mov	edi, eax

	shr	ecx, 2
	sub	eax, eax
		rep	stosd

;
; Copy original DOS base memory and video pages.
;
	mov	ebx, (DosTask PTR es:[esi]).TaskMapping
	sub	edx, edx
	sub	esi, esi
	cld
dup_dos:
	mov	edi, es:[ebx+edx*4]		; es:EDI -> dest page
	mov	ecx, 400h			; Number of dwords in 1 page.
		rep	movs dword ptr es:[edi], es:[esi]

	inc	edx
	cmp	edx, 0A0000h SHR 12		; EDX = pages count
if 0
	cmp	edx, (0A0000h + 40000h) SHR 12		; EDX = pages count
endif
	jb	dup_dos

IFDEF	PROVIDE_HIMEM
;
; Copy original HMA.
;
	mov	edx, 100000h SHR 12
	mov	esi, 100000h
dup_hma:
	mov	edi, es:[ebx+edx*4]		; es:EDI -> dest page
	mov	ecx, 400h			; Number of dwords in 1 page.
		rep	movs dword ptr es:[edi], es:[esi]

	inc	edx
	cmp	edx, 110000h SHR 12		; EDX = pages count
	jb	dup_hma
ENDIF	; PROVIDE_HIMEM

; Increment number of tasks.
	inc	NumOfTasks
	clc
	ret
CreateDosTask	ENDP


;-----------------------------------------------------------------------------
;
;	Destroys DOS task (frees its memory) and transfers control to a
; system core.
;
;	I: EAX = number of task to destroy.
;	O:
;
;	(!) Must be called outside task's address space.
;
;-----------------------------------------------------------------------------
DismemberDosTask	PROC	USES eax ecx edx edi
PUSHCONTEXT	ASSUMES
ASSUME	edx: PTR DosTask
	cmp	eax, NumOfTasks
	jb	destroy_task
	ret

destroy_task:
; FS:EDX -> DOS task being dismembered.
	TASK_PTR	, edx

; If it's DPMI task, clean up.
	cmp	fs:[edx].TaskLdt, 0
	je	free_video_state
	call	DpmiWashUp

free_video_state:
; Free task's video state save space.
	mov	eax, fs:[edx].TaskVideoState
	call	HeapFreePage

	mov	edi, fs:[edx].TaskMapping
; Free page allocated for DPMI needs.
;	mov	eax, fs:[edi+(DPMI_SERVICE_PAGE SHR 10)]
	push	edi
	mov	ecx, DpmiSrvAddr
	shr	ecx, 12
	mov	eax, fs:[edi][ecx*4]
	pop	edi

	mov	ecx, DPMI_MEM_SIZE
	call	HeapFreeMem

; Free memory that could have been allocated with DPMI descriptors.
	mov	esi, DPMI_MEM_DESCRIPTORS * SIZEOF DpmiMemDescr
	mov	ebx, fs:[edx].DpmiMemDescrArr

free_next_descr:
	mov	ecx, (DpmiMemDescr PTR fs:[ebx]).BlockLength
	mov	eax, (DpmiMemDescr PTR fs:[ebx]).BlockAddress

	test	eax, eax
	jz	next_block

; Free memory.
	call HeapFreeMem

next_block:
	sub	esi, SIZEOF DpmiMemDescr
	jnz	free_next_descr

; Free memory allocated for DPMI memory descriptors themselves.
	mov	ecx, DPMI_MEM_DESCRIPTORS * SIZEOF DpmiMemDescr
	mov	eax, fs:[edx].DpmiMemDescrArr
	call	HeapFreeMem

; Free memory allocated for task's base and video memory.
	mov	eax, fs:[edi]			; Get linear address
	mov	ecx, 0A0000h + 40000h
	call	HeapFreeMem

IFDEF	PROVIDE_HIMEM
; Free pages allocated for HMA memory.
	mov	ecx, (10000h SHR 12) - 1	; Number of pages.
free_himem:
	mov	eax, fs:[edi+ecx*4+(100000h SHR 12)*4]	; Get linear address
	call	HeapFreePage

	dec	ecx
	jnl	free_himem
ENDIF	; PROVIDE_HIMEM

; Free page allocated for task alias mapping.
	mov	eax, edi
	call	HeapFreePage

; Free page allocated for task's 1Mb page table.
	mov	edi, fs:[edx].TaskPageCtl
	mov	eax, fs:[edi]
	call	HeapFreePage

; Free page allocated for task's page control array.
	mov	eax, edi
	call	HeapFreePage

; Free page allocated for task's PDB.
	mov	eax, fs:[edx].TaskPdbLin
	call	HeapFreePage

; Free page allocated for task's open files table.
	mov	eax, fs:[edx].TaskOFTable
	call	HeapFreePage

	ret
POPCONTEXT	ASSUMES
DismemberDosTask	ENDP


;-----------------------------------------------------------------------------
;
;	Deletes a DOS task from an array of tasks.
;
;	I: EAX = number of task to delete
;	O:
;
;-----------------------------------------------------------------------------
DeleteTask	PROC	USES es eax ecx edx esi edi
	cmp	eax, NumOfTasks
	jb	delete_task
	ret

delete_task:
; If foreground task is above task being deleted, decrement it.
	cmp	eax, ForegroundTask
	ja	@F
	dec	ForegroundTask
@@:

; If current task is above task being deleted, decrement it.
	cmp	eax, CurrentTask
	ja	@F
	dec	CurrentTask
	sub	CurrTaskPtr, SIZEOF DosTask

; If next to run task is above task being deleted, decrement it.
	cmp	eax, NextToRun
	ja	@F
	dec	NextToRun
@@:

; If INT 13h semaphore owner is above task being deleted, decrement it.
	cmp	HddSema4, 0
	je	@F
	cmp	eax, HddSema4Own
	ja	@F
	dec	HddSema4Own
@@:

	cmp	FddSema4, 0
	je	@F
	cmp	eax, FddSema4Own
	ja	@F
	dec	FddSema4Own
@@:
; If there are tasks above the one being deleted waiting for DMA retirement,
; move them down.
	lea	ecx, [eax+1]
@@:
	cmp	ecx, NumOfTasks
	jnb	@F
	cmp	DmaIoRange[ ecx * 8 ][ 4 ], 0
	je	next_io_range
	mov	edx, DmaIoRange[ ecx * 8 ]
	mov	DmaIoRange[ ecx * 8 ][ -8 ], edx
	mov	edx, DmaIoRange[ ecx * 8 ][ 4 ]
	mov	DmaIoRange[ ecx * 8 ][ -8 ][ 4 ], edx
	mov	DmaIoRange[ ecx * 8 ][ 4 ], 0
next_io_range:
	inc	ecx
	jmp	@B
@@:
	mov	cx, FLAT_DS
	mov	es, cx

	mov	ecx, NumOfTasks
	sub	ecx, eax
	dec	ecx			; ECX = tasks count to move

	TASK_PTR			; eax = offset of the task being
					; deleted.
	mov	edi, eax		; Task to be deleted
	lea	esi, [eax + SIZEOF DosTask]	; Next task

	mov	eax, SIZEOF DosTask
	mul	ecx			; eax = number of bytes to move
	mov	ecx, eax

	cld
		rep	movs byte ptr es:[edi], es:[esi]

	dec	NumOfTasks
	ret
DeleteTask	ENDP


;-----------------------------------------------------------------------------
;
;	Starts a new DOS task.
;
;	I:
;	O: CF = 1 - task can't be created.
;
;	(!) Sets I/O focus to the new task.
;
;-----------------------------------------------------------------------------
PUBLIC	StartTask
StartTask	PROC	USES eax ecx edx
	call	CreateDosTask
	jnc	task_created
	ret

task_created:
; Remove deleted flag set (if any).
	mov	eax, NumOfTasks
	dec	eax

; If first task, only fork it.
	test	eax, eax
	jz	fork_first_task
; Otherwise, switch focus and task context.
	push	eax

	mov	eax, ForegroundTask
	call	SaveOldFocus
	mov	eax, CurrentTask
	call	SaveOldContext

; Mark old current task as ready.
	mov	eax, CurrTaskPtr
	and	(DosTask PTR fs:[eax]).TaskState, NOT TASK_RUNNING

	pop	eax

fork_first_task:
	mov	CurrentTask, eax
	mov	ForegroundTask, eax

	mov	ecx, eax
	sub	eax, eax
	call	TrapVideoPorts		; Free all video ports.
	call	TrapGenDevPorts		; Trap general devices ports.

	TASK_PTR	ecx		; eax = offset of the task to run
	mov	CurrTaskPtr, eax

; Set task's status to running.
	mov	(DosTask PTR fs:[eax]).TaskState, TASK_RUNNING
	mov	(DosTask PTR fs:[eax]).TaskBlock, 0

; Load task's PDBR.
	mov	edx, (DosTask PTR fs:[eax]).TaskPdbLin
	mov	PdbLin, edx
	mov	edx, (DosTask PTR fs:[eax]).TaskPageCtl
	mov	PagesCtl, edx
	mov	edx, (DosTask PTR fs:[eax]).TaskPdb
	mov	Pdb, edx
	mov	cr3, edx

; System task to 0.
	mov	SystemTask, 0

; Switch to virtual mode.
	sub	eax, eax
	mov	ExcGs, ax
	mov	ExcFs, ax
	mov	ax, DATA
	mov	ExcDs, ax
	mov	ExcEs, ax
	mov	ax, STK
	mov	ExcSs, ax
	mov	ExcEsp, VM_STK

; Set VirtualIF to 1.
	mov	VirtualIf, FL_IF
; No pending interrupts.
	mov	VirtualIp, 0
; No in-service interrupts.
	mov	VirtualIsr, 0
; All interrupts enabled.
	mov	VirtualImr, 0
; Clear keyboard queue.
	mov	eax, KbdQHead
	mov	KbdQTail, eax

; Eflags reg., IOPL=0, IF = 1
	mov	ExcEflags, FL_VM OR FL_IF
	mov	ax, CODE
	mov	ExcSeg, ax
	mov	eax, offset TaskV86Entry
	mov	ExcOffs, eax

	clc
	ret
StartTask	ENDP


;-----------------------------------------------------------------------------
;
;	Stops DOS task, dismembers it and deletes it.
;
;	I: EAX = number of task to stop.
;	O:
;
;	(!) If task to stop is the only DOS task in system, must be called in
; system context.
;
;-----------------------------------------------------------------------------
PUBLIC	StopTask
StopTask	PROC	USES ecx edx
	cmp	eax, NumOfTasks
	jb	stop_task
	ret

stop_task:
; Release general devices semaphores that a task could have held.
	xchg	eax, CurrentTask
	push	eax
	call	RelGenDevSema4s
	pop	eax
	xchg	eax, CurrentTask

; If INT 13h semaphore is owned by task being deleted, force it free. 
; Else just switch to next task.
	cmp	FddSema4, 0
	je	hdd?
	cmp	eax, FddSema4Own
	jne	hdd?

;
; That's an ugly hack. Int13Sema4s() expects CurrentTask to be holding some
; of the semaphores. Should be replaced in the future by the normal
; semaphores.
;
	xchg	eax, CurrentTask
	push	eax
	sub	eax, eax
	call	Int13Sema4s
	pop	eax
	xchg	eax, CurrentTask

	jmp	single?

hdd?:
	cmp	HddSema4, 0
	je	single?
	cmp	eax, HddSema4Own
	jne	single?

; The second part of an ugly hack.
	xchg	eax, CurrentTask
	push	eax
	sub	eax, eax
	call	Int13Sema4s
	pop	eax
	xchg	eax, CurrentTask


single?:
	cmp	NumOfTasks, 1
	jne	not_single

	mov	ecx, SysPdbLin
	mov	PdbLin, ecx
	mov	ecx, SysPagesCtl
	mov	PagesCtl, ecx
	mov	ecx, SysPdb
	mov	Pdb, ecx
	mov	cr3, ecx
	jmp	dismember_task

not_single:
; If task to delete is foreground task, switch focus and clear keyboard queue.
	cmp	eax, ForegroundTask
	jne	is_current?

	mov	ecx, KbdQHead
	mov	KbdQTail, ecx
	call	FocusToNextTask

is_current?:
; If task being stopped is current, force next task.
	cmp	eax, CurrentTask
	jne	dismember_task

; Force task switch.
	push	eax
	mov	eax, CurrentTask
	inc	eax
	cmp	eax, NumOfTasks
	jb	@F
	sub	eax, eax
@@:
	call	SwitchTaskTo		; Force task switch
	pop	eax

dismember_task:
; Dismember task.
	call	DismemberDosTask
; Delete task from task list.
	call	DeleteTask

	ret
StopTask	ENDP


;-----------------------------------------------------------------------------
;
;	Saves context of the task being switched from.
;
;	I:
;	O:
;
;-----------------------------------------------------------------------------
SaveOldContext	PROC	USES es eax ebx ecx edx
PUSHCONTEXT	ASSUMES
ASSUME	edx: PTR DosTask
	mov	edx, CurrTaskPtr

; Set ES to flat segment.
	mov	ax, FLAT_DS
	mov	es, ax

; Save regsiters.
	lea	ebx, es:[edx].TaskRegs
	lea	ecx, es:[edx].TaskSregs
	call	SaveClientRegs

; Save interrupts state.
	mov	eax, VirtualIf
	mov	es:[edx].TaskVirtualIf, eax
	mov	eax, VirtualIp
	mov	es:[edx].TaskVirtualIp, eax
	mov	eax, VirtualIsr
	mov	es:[edx].TaskVirtualIsr, eax
	mov	eax, VirtualImr
	mov	es:[edx].TaskVirtualImr, eax

	ret
POPCONTEXT	ASSUMES
SaveOldContext	ENDP


;-----------------------------------------------------------------------------
;
;	Switches task using regular basis.
;
;	I: EAX = task to switch to.
;	O: CF = 0 OK
;	      = 1 fail: task # > than number of tasks or blocked. Not switched.
;
;-----------------------------------------------------------------------------
PUBLIC	SwitchTask
SwitchTask	PROC	USES eax edx
; Check if task # is correct
	cmp	eax, NumOfTasks
	jb	task_num_ok
	stc
	ret

task_num_ok:
	cmp	eax, CurrentTask
	jne	@F
	clc
	ret

@@:
; If destination task is blocked, return with CF = 1.
	push	eax
	TASK_PTR
	test	(DosTask PTR fs:[eax]).TaskState, TASK_BLOCKED
	pop	eax
	jz	do_switch

	stc
	ret

do_switch:
	call	SwitchTaskTo
	clc
	ret
SwitchTask	ENDP


;-----------------------------------------------------------------------------
;
;	Switches current (running) tasks: address space & context (not I/O
; focus).
;
;	I: EAX = task to switch to.
;	O: CF = 0 OK
;	      = 1 fail (task # > than number of tasks). Not switched.
;
;	(!) Since tasks table is mapped in every address space may run in
; task's space.
;	(!) Interrupts must be disabled.
;	(!) Forces task switch even if target task is blocked.
;
;-----------------------------------------------------------------------------
PUBLIC	SwitchTaskTo
SwitchTaskTo	PROC	USES es eax ebx ecx edx
PUSHCONTEXT	ASSUMES
ASSUME	edx: PTR DosTask
; Check if task # is correct
	cmp	eax, NumOfTasks
	jb	task_num_ok
	stc
	ret

task_num_ok:
; Save registers context of current task.
	call	SaveOldContext

; Update current task.
	xchg	eax, CurrentTask
	mov	edx, CurrTaskPtr
; Mark retired task as not running.
	and	fs:[edx].TaskState, NOT TASK_RUNNING

; Load running task ptr.
	TASK_PTR	CurrentTask, edx
	mov	CurrTaskPtr, edx
	or	fs:[edx].TaskState, TASK_RUNNING
; If the new task is a foreground task, allow video ports. Else trap them.
	mov	eax, CurrentTask
	cmp	eax, ForegroundTask
	mov	eax, 0
	je	@F
	mov	eax, -1
@@:
	call	TrapVideoPorts

; Trap general devices ports in the new task.
	call	TrapGenDevPorts

; Restore registers of task to switch to.
	mov	ax, FLAT_DS
	mov	es, ax
	lea	ebx, es:[edx].TaskRegs
	lea	ecx, es:[edx].TaskSregs
	call	RestoreClientRegs

; Restore interrupts state.
	mov	eax, es:[edx].TaskVirtualIf
	mov	VirtualIf, eax
	mov	eax, es:[edx].TaskVirtualIp
	mov	VirtualIp, eax
	mov	eax, es:[edx].TaskVirtualIsr
	mov	VirtualIsr, eax
	mov	eax, es:[edx].TaskVirtualImr
	mov	VirtualImr, eax

; Switch to task's address space.
	mov	eax, es:[edx].TaskPdbLin
	mov	PdbLin, eax
	mov	eax, es:[edx].TaskPageCtl
	mov	PagesCtl, eax
	mov	eax, es:[edx].TaskPdb
	mov	Pdb, eax
	mov	cr3, eax		; Load PDBR

; Restore DPMI related state.
	cmp	es:[edx].TaskLdt, 0
	je	@F
	lldt	es:[edx].TaskLdt
	mov	eax, es:[edx].TaskLdtBase
	mov	CurrLdtBase, eax
@@:

	clc
	ret
POPCONTEXT	ASSUMES
SwitchTaskTo	ENDP


;-----------------------------------------------------------------------------
;
;	Saves focus context of a task.
;
;	I:
;	O:
;
; (!) Changes context.
;
;-----------------------------------------------------------------------------
SaveOldFocus	PROC	USES es eax ebx ecx edx esi edi
PUSHCONTEXT	ASSUMES
ASSUME	edx: PTR DosTask
	TASK_PTR	ForegroundTask, edx ; ES:EDX -> old foreground's task
					; structure.
; Set ES to flat segment.
	mov	ax, FLAT_DS
	mov	es, ax

; Switch to last foreground's task space.
	mov	eax, es:[edx].TaskPdbLin
	mov	PdbLin, eax
	mov	eax, es:[edx].TaskPageCtl
	mov	PagesCtl, eax
	mov	eax, es:[edx].TaskPdb
	mov	Pdb, eax
	mov	cr3, eax

; Save task's video context.
	mov	edi, es:[edx].TaskVideoState
	call	SaveVideoContext
	call	SaveVideoMemory
; Map old foreground's memory A0000h - BFFFFh to virtual (take from task's
; alias mapping).
	mov	edi, es:[edx].TaskPageCtl
	mov	edi, es:[edi]
	mov	esi, es:[edx].TaskMapping
	mov	ecx, 0A0000h SHR 12

map_virtual_screen:
	mov	eax, es:[esi+ecx*4]
	call	LinearToPhysical
	or	eax, PAGE_PRESENT OR PAGE_WRITABLE OR PAGE_USER
	mov	es:[edi+ecx*4], eax
	inc	ecx
	cmp	ecx, (0A0000h + 20000h) SHR 12
	jb	map_virtual_screen

	ret
POPCONTEXT	ASSUMES
SaveOldFocus	ENDP


;-----------------------------------------------------------------------------
;
;	Switches current foreground tasks: I/O focus (not address space & 
; context).
;
;	I: EAX = task to switch focus to.
;	O: CF = 0 - OK.
;	        1 - error (not switched).
;
;	(!) This also immediately switches to a task brought to the
; foreground.
;
;-----------------------------------------------------------------------------
PUBLIC	SwitchFocusTo
SwitchFocusTo	PROC	USES es eax ebx ecx edx esi edi

; Check if task # is correct
	cmp	eax, NumOfTasks
	jb	task_num_ok
	stc
	ret

task_num_ok:
; Save video context of foreground task. 
	call	SaveOldFocus

; If old foreground task  was running, trap video ports.
	push	eax
	mov	eax, ForegroundTask
	cmp	eax, CurrentTask
	jne	@F

	mov	eax, -1
	call	TrapVideoPorts
@@:
	pop	eax

; Update foreground task.
	mov	ForegroundTask, eax

; If new foreground task is running, allow video ports.
	push	eax
	mov	eax, ForegroundTask
	cmp	eax, CurrentTask
	jne	@F

	sub	eax, eax
	call	TrapVideoPorts
@@:
	pop	eax
	TASK_PTR	, edx		; ES:EDX -> new foreground's task
					; structure.
	mov	ax, FLAT_DS
	mov	es, ax

; Map new foreground's memory A0000h - BFFFFh to physical 1-to-1. Doing it in
; alien address space saves reload of PDB.
	mov	edi, (DosTask PTR es:[edx]).TaskPageCtl
	mov	edi, es:[edi]
	mov	ecx, 0A0000h SHR 12

map_physical_screen:
	mov	eax, ecx
	shl	eax, 12
	or	eax, PAGE_PRESENT OR PAGE_WRITABLE OR PAGE_USER
	mov	es:[edi+ecx*4], eax
	inc	ecx
	cmp	ecx, (0A0000h + 20000h) SHR 12
	jb	map_physical_screen

; Switch to new foreground's task space.
	mov	eax, (DosTask PTR es:[edx]).TaskPdbLin
	mov	PdbLin, eax
	mov	eax, (DosTask PTR es:[edx]).TaskPageCtl
	mov	PagesCtl, eax
	mov	eax, (DosTask PTR es:[edx]).TaskPdb
	mov	Pdb, eax
	mov	cr3, eax

; Restore task's video context.
	mov	esi, (DosTask PTR es:[edx]).TaskVideoState
	call	RestoreVideoContext
; Restore task's video memory.
	call	RestoreVideoMemory

	mov	eax, CurrTaskPtr
	mov	edx, (DosTask PTR es:[eax]).TaskPdbLin
	mov	PdbLin, edx
	mov	edx, (DosTask PTR es:[eax]).TaskPageCtl
	mov	PagesCtl, edx
	mov	edx, (DosTask PTR es:[eax]).TaskPdb
	mov	Pdb, edx
	mov	edx, (DosTask PTR fs:[eax]).TaskPdb
	mov	cr3, edx

	clc
	ret
SwitchFocusTo	ENDP


;-----------------------------------------------------------------------------
;
;	I:
;	O: EAX = number of not blocked tasks.
;
;	Returns number of not blocked (runnable) tasks.
;
;-----------------------------------------------------------------------------
NonBlockedTasks	PROC	USES ecx edx
	mov	ecx, FirstTask
	sub	edx, edx
	sub	eax, eax

check_task:
	test	(DosTask PTR fs:[ecx]).TaskState, TASK_BLOCKED
	jnz	next_task
	inc	eax
next_task:
	add	ecx, SIZEOF DosTask
	inc	edx
	cmp	edx, NumOfTasks
	jb	check_task

	ret
NonBlockedTasks	ENDP


;-----------------------------------------------------------------------------
;
;	Switches to next task in tasks list.
;
;	I:
;	O:
;
; (!) Doesn't switch if Int 13 semaphore is not free. Increments borrowed
; ticks counter instead.
;
;-----------------------------------------------------------------------------
IFDEF	BORROWED_TICKS
; Borrowed ticks strategy.
PUBLIC	NextTask
NextTask	PROC	USES	eax ebx ecx edx esi edi
; If only one task exists, return.
	cmp	NumOfTasks, 1
	ja	@F
	ret
@@:
; If current task is locked, return.
;	mov	eax, CurrTaskPtr
;	test	(DosTask PTR fs:[eax]).TaskState, TASK_LOCKED
;	jz	@F
;	ret
;@@:
; If all tasks are blocked, return.
	call	NonBlockedTasks
	test	eax, eax
	jnz	@F
	ret
@@:
	cmp	NextToRun, -1
	jne	switch?

; If (NextToRun == -1), update it with valid value.
	mov	eax, CurrentTask
	inc	eax
	cmp	eax, NumOfTasks
	jb	@F
	sub	eax, eax
@@:
	mov	NextToRun, eax
switch?:
	mov	eax, NextToRun
; If next task (in EAX) doesn't have borrowed ticks, switch to it.
	mov	ecx, eax
	TASK_PTR
	test	(DosTask PTR fs:[eax]).TaskState, TASK_BLOCKED
	jz	init_borrowed 
	mov	esi, 0FFFFFFFFh			; Impossible value for borrowed ticks.
	jmp	find_less_borrowed

; The task has borrowed ticks. Verify what task has the least number of
; borrowed ticks and switch to it. Decrement borrowed ticks of former next.
; EBX is a tested task pointer, EDI holds next task on exit. ESI holds tick
; counter of the former candidate. ECX is a task that was supposed to be
; next.
init_borrowed:
	mov	esi, (DosTask PTR fs:[eax]).BorrowedTicks
find_less_borrowed:
	mov	ebx, ecx
	mov	edi, ecx

find_next_task:
	test	esi, esi		; If 0 borrowed ticks found, switch.
	jz	next_task_found

	inc	ebx
	cmp	ebx, NumOfTasks
	jb	@F
	sub	ebx, ebx
@@:
	cmp	ebx, ecx
	je	next_task_found

; If task is not blocked and borrowed ticks are less, set values.
	TASK_PTR	ebx
	test	(DosTask PTR fs:[eax]).TaskState, TASK_BLOCKED
	jnz	find_next_task
	cmp	esi, (DosTask PTR fs:[eax]).BorrowedTicks
	jna	find_next_task

	mov	edi, ebx
	jmp	find_next_task
next_task_found:
	mov	eax, edi
	call	SwitchTask

; If next task to switch to is NextToRun anyway, update next to run.
	cmp	eax, NextToRun
	je	update_next_to_run

	TASK_PTR	NextToRun
	dec	(DosTask PTR fs:[eax]).BorrowedTicks
	ret

; Update NextToRun task.
update_next_to_run:
	mov	eax, NextToRun
	inc	eax
	cmp	eax, NumOfTasks
	jb	@F
	sub	eax, eax
@@:
	mov	NextToRun, eax
	ret
NextTask	ENDP

ELSE
; No borrowed ticks strategy.

PUBLIC	NextTask
NextTask	PROC	USES	eax ebx ecx edx esi edi
; If only one task exists, return.
	cmp	NumOfTasks, 1
	ja	@F
	ret
@@:
; If current task is locked, return.
;	mov	eax, CurrTaskPtr
;	test	(DosTask PTR fs:[eax]).TaskState, TASK_LOCKED
;	jz	@F
;	ret
;@@:
; If all tasks are blocked, return.
	call	NonBlockedTasks
	test	eax, eax
	jnz	first_run?
	ret

first_run?:
	cmp	NextToRun, -1
	jne	switch?

; If (NextToRun == -1), update it with valid value.
	mov	eax, CurrentTask
	inc	eax
	cmp	eax, NumOfTasks
	jb	@F
	sub	eax, eax
@@:
	mov	NextToRun, eax
switch?:
	mov	eax, NextToRun
find_non_blocked:
	call	SwitchTask
	jnc	update_next_to_run

	inc	eax
	cmp	eax, NumOfTasks
	jb	@F
	sub	eax, eax
@@:
	jmp	find_non_blocked	; Should not dead lock here.

; Update NextToRun task.
update_next_to_run:
	mov	eax, NextToRun
	inc	eax
	cmp	eax, NumOfTasks
	jb	@F
	sub	eax, eax
@@:
	mov	NextToRun, eax
	ret
NextTask	ENDP

ENDIF

;-----------------------------------------------------------------------------
;
;	Switches focus to next task in tasks list.
;
;	I:
;	O:
;
;-----------------------------------------------------------------------------
PUBLIC	FocusToNextTask
FocusToNextTask	PROC	USES eax
	mov	eax, ForegroundTask
	inc	eax
	cmp	eax, NumOfTasks
	jb	@F
	sub	eax, eax
@@:
	call	SwitchFocusTo
	ret
FocusToNextTask	ENDP


;-----------------------------------------------------------------------------
;
;	Callback for excetions traps. Traps GPF.
;
;-----------------------------------------------------------------------------
PUBLIC	ExcRedirect
ExcRedirect	PROC	USES eax ebx ecx edx esi edi ebp

; Check if the exception was in VM.
	test	ExcEflags, FL_VM
	jnz	check_opcode
; Check if exception was in CPL 3 code.
	test	ExcSeg, 3
	jnz	check_opcode
	stc
	ret

; Check if was due to sensitive instructions.
check_opcode:

	mov	si, ExcSeg
	mov	edi, ExcOffs
	mov	ebx, ExcEflags
	call	PointerToLinear

	mov	ebx, eax
	call	SkipPrefixes	; Skip & set prefixes.

; ECX keeps pointer to faulting opcode. Required for HddSema4s.
	mov	ecx, eax

	neg	ebx
	lea	ebp, [ebx+eax]	; EBP keeps number of bytes to skip.
	mov	eax, fs:[eax]	; Get 2 bytes of opcode.

	cmp	al, OP_CLI
	jne	sti?

; Do CLI for a client.
	mov	VirtualIf, 0
	inc	ebp
	add	ExcOffs, ebp

	clc
	ret

sti?:
	cmp	al, OP_STI
	jne	int?

; Do STI for a client.
	mov	VirtualIf, FL_IF
	inc	ebp
	add	ExcOffs, ebp

	clc
	ret

int?:
	cmp	al, OP_INT
	jne	iret?

; If system task is running, go ahead.
	cmp	SystemTask, 0
	jne	default_int

; Check if specific handling is applied.
	cmp	ah, 13h
	je	handle_int_13
	cmp	ah, 15h
	je	handle_int_15
	cmp	ah, 16h
	je	handle_int_16
	cmp	ah, 28h
	je	handle_int_28
	cmp	ah, 21h
	je	handle_int_21
	cmp	ah, 2Fh
	je	handle_int_2f
	cmp	ah, 31h
	je	handle_int_31
	jmp	default_int

; INT 13h specific handling.
handle_int_13:
	test	byte ptr ExcEdx, 80h
	jnz	hdd

; Floppy access.
	cmp	FddSema4, 0
	je	acquire_int13_sema4
	mov	edx, CurrentTask
	cmp	edx, FddSema4Own
	je	default_int
; If INT 13h is called by not INT 13h owner, block the caller.
	mov	eax, CurrTaskPtr
	or	(DosTask PTR fs:[eax]).TaskState, TASK_BLOCKED
	or	(DosTask PTR fs:[eax]).TaskBlock, FDD_SEMA4
	clc
	ret

hdd:
	cmp	HddSema4, 0
	je	acquire_int13_sema4
	mov	edx, CurrentTask
	cmp	edx, HddSema4Own
	je	default_int
; If INT 13h is called by not INT 13h owner, block the caller.
	mov	eax, CurrTaskPtr
	or	(DosTask PTR fs:[eax]).TaskState, TASK_BLOCKED
	or	(DosTask PTR fs:[eax]).TaskBlock, HDD_SEMA4
	clc
	ret

acquire_int13_sema4:
; Acquire INT 13h semaphore.
	push	eax
	mov	eax, 1
	call	Int13Sema4s
	pop	eax
	jmp	default_int

; INT 15h specific handling.
handle_int_15:
	jmp	default_int

; INT 16h specific handling.
handle_int_16:
	cmp	byte ptr ExcEax[1], 0		; AH = 0?
	je	@F
	cmp	byte ptr ExcEax[1], 10h		; AH = 10h?
	jne	default_int

@@:
; If keyboard buffer is not empty, go on.
	mov	cx, fs:[41Ah]
	cmp	cx, fs:[41Ch]
	jne	default_int
; If empty but keyboard interrupt is pending, go on (don't lock).
	test	VirtualIp, 2
	jnz	default_int

; Lock task on INT 16h.
	mov	eax, CurrTaskPtr
; If all tasks are blocked, don't lock, just let caller loop on GPF.
	or	(DosTask PTR fs:[eax]).TaskState, TASK_BLOCKED
	or	(DosTask PTR fs:[eax]).TaskBlock, KBD_INPUT
	call	NextTask
	clc
	ret

; INT 28h specific handling.
handle_int_28:
; If INT 28h handler is not IRET, go on.
	movzx	edx, word ptr fs:[28h*4+2]
	movzx	ecx, word ptr fs:[28h*4]
	shl	edx, 4
	add	edx, ecx
	cmp	byte ptr fs:[edx], OP_IRET
	jne	default_int

check_kbd_buf:
; If keyboard buffer is not empty, go on.
	mov	cx, fs:[41Ah]
	cmp	cx, fs:[41Ch]
	jne	default_int

; If empty but keyboard interrupt is pending, go on.
	test	VirtualIp, 2
	jnz	default_int

; Release processor to another task - DOS is idle.
	add	ebp, 2
	add	ExcOffs, ebp
	call	NextTask
	clc
	ret

; INT 21h specific handling.
handle_int_21:
	mov	ecx, ExcEax
	cmp	ch, 0Eh
	jne	@F

; Set default drive. Keep track of default drives for every task.
	push	eax
	mov	eax, CurrTaskPtr
	mov	dl, byte ptr ExcEdx
	mov	(DosTask PTR fs:[eax]).TaskCurrDrive, dl
	pop	eax
	jmp	default_int

@@:
	cmp	ch, 4Ch
	jne	@F

; If INT 21h/4Ch is executed in protected mode, call DPMI clean up.
	mov	edx, CurrTaskPtr
	cmp	(DosTask PTR fs:[edx]).TaskLdt, 0
	je	default_int

	test	ExcEflags, FL_VM
	jnz	default_int

	call	DpmiWashUp
; Set V86 mode.
	or	ExcEflags, FL_VM
; Set locked RM stack.
	mov	ExcSs, VM_LOCKED_SS
	mov	eax, CurrTaskPtr
	mov	eax, (DosTask PTR fs:[eax]).DpmiRmEsp
	mov	ExcEsp, eax

	mov	ah, 21h			; Get interrupt number in AH.
	jmp	default_int

@@:
	cmp	ch, 50h
	jne	@F

	mov	ecx, CurrTaskPtr
	cmp	(DosTask PTR fs:[ecx]).TaskLdt, 0
	mov	ah, 21h			; Get interrupt number in AH.
	je	default_int

	mov	eax, ExcEbx
	mov	(DosTask PTR fs:[ecx]).TaskCurrentId, ax
	add	ebp, 2
	add	ExcOffs, ebp
	clc
	ret

@@:
	cmp	ch, 51h
	je	get_curr_pid
	cmp	ch, 62h
	jne	@F

get_curr_pid:
	mov	ecx, CurrTaskPtr
	cmp	(DosTask PTR fs:[ecx]).TaskLdt, 0
	mov	ah, 21h			; Get interrupt number in AH.
	je	default_int

	mov	ax, (DosTask PTR fs:[ecx]).TaskCurrentId
	mov	word ptr ExcEbx, ax
	add	ebp, 2
	add	ExcOffs, ebp
	clc
	ret

@@:
mov	ah, 21h
jmp	default_int
; For any function that opens file a file is written to open file structure.
; No suppositions are made if the file was already opened by this task.
	cmp	ch, 3Ch
	je	test_open
	cmp	ch, 3Dh
	jne	@F
	test	cl, 3
	jz	default_int
	jmp	test_open
@@:
	je	test_open
	cmp	ch, 41h
	je	test_open
	cmp	cx, 4301h
	je	test_open
	cmp	cx, 6C00h
	je	test_open
	cmp	ch, 3Eh
	je	set_int21_trap
	jmp	default_int
test_open:

; Check if sharing violation is not occuring.
	call	IsFileOpen
	jnc	set_int21_trap

; Deny access. Return sharing violation error.
	or	ExcEflags, FL_CF
	mov	ExcEax, 5
	mov	eax, CurrTaskPtr
	mov	(DosTask PTR fs:[eax]).TaskErrCode, 5
	add	ebp, 2
	add	ExcOffs, ebp
	ret

set_int21_trap:
; Set return trap for INT 21h.
	push	eax

	mov	si, ExcSeg
	mov	edi, ExcOffs
	mov	ebx, ExcEflags
	call	PointerToLinear
	mov	edx, eax

	mov	eax, CurrTaskPtr
	mov	(DosTask PTR fs:[eax]).DosFunc, cx

; Trap return instruction.
	mov	ecx, fs:[edx+2]
	mov	(DosTask PTR fs:[eax]).Int21TrapOp, ecx
	mov	ecx, fs:[edx+2][4]
	mov	(DosTask PTR fs:[eax]).Int21TrapOp[4], ecx
; Write invalid opcode instead.
	mov	dword ptr fs:[edx+2], 0000FFFEh
	mov	dword ptr fs:[edx+2][4], 00210000h

;	or	(DosTask PTR fs:[eax]).TaskState, TASK_LOCKED

	pop	eax
	jmp	default_int

handle_int_2f:
;	test	ExcEflags, FL_VM
;	jnz	@F
;	mov	ecx, ExcEax
;int 3
;@@:

IFDEF	FAKE_WINDOWS
IF 0
; Fake report Windows 3.0. This code disables Watcom's W32RUN from running.
	cmp	word ptr ExcEax, 1600h
	jne	@F
	mov	word ptr ExcEax, 0003h
	add	ebp, 2
	add	ExcOffs, ebp
	clc
	ret

@@:
ENDIF
; Fake Windows vendor specific entry point.
	cmp	word ptr ExcEax, 168Ah
	jne	normal_func

	mov	si, ExcDs
	mov	edi, ExcEsi
	mov	ebx, ExcEflags
	mov	ecx, CurrTaskPtr
	test	(DosTask PTR fs:[ecx]).TaskFlags, TASK_32BIT
	jnz	@F
	and	edi, 0FFFFh
@@:
	call	PointerToLinear

; Is vendor name "MS-DOS"?
	cmp	dword ptr fs:[eax], 'M' + ('S' SHL 8) + ('-' SHL 16) + ('D' SHL 24 )
	jne	wrong_vendor_name
	cmp	word ptr fs:[eax][4], 'O' + ('S' SHL 8)
	jne	wrong_vendor_name

; Return LDT alias entry point.
	mov	ax, PmCallbackCs
	mov	ExcEs, ax
	mov	eax, WIN_VENDOR_API_ENTRY
	test	(DosTask PTR fs:[ecx]).TaskFlags, TASK_32BIT
	jnz	@F
	mov	ExcEdi, eax
	jmp	ret_vendor_api
@@:
	mov	word ptr ExcEdi, ax

ret_vendor_api:
	and	ExcEflags, NOT FL_CF
	add	ebp, 2
	add	ExcOffs, ebp
	clc
	ret

wrong_vendor_name:
	or	ExcEflags, FL_CF
	add	ebp, 2
	add	ExcOffs, ebp
	clc
	ret

normal_func:
ENDIF

;
;	For the preliminary release the DPMI support is eliminated
; pending further development and testing.
;
; (!) v0.48 - XMS is enabled.
;

	cmp	word ptr ExcEax, 4300h		; XMS installation check.
	je	xms_install_check
	cmp	word ptr ExcEax, 4310h		; XMS get entry
	je	xms_get_entry
;jmp	default_int
	cmp	word ptr ExcEax, 1687h		; DPMI get info and entry.
	je	get_entry
	cmp	word ptr ExcEax, 1686h		; DPMI get current mode.
	je	get_current_mode
	jmp	default_int

xms_get_entry:
;	mov	ExcEs, XMS_ENTRY_SEG		; XMS server entry point
	mov	cx, DpmiSrvSeg
	mov	ExcEs, cx
	mov	word ptr ExcEbx, XMS_ENTRY_OFFS
	add	ebp, 2
	add	ExcOffs, ebp
	clc
	ret

xms_install_check:
	mov	byte ptr ExcEax, 80h		; XMS is present.
	add	ebp, 2
	add	ExcOffs, ebp
	clc
	ret

get_current_mode:
; Get current mode.
	mov	word ptr ExcEax, 0		; Protected mode
	test	ExcEflags, FL_VM
	jz	@F
	inc	word ptr ExcEax			; V86 mode
@@:
	add	ebp, 2
	add	ExcOffs, ebp
	clc
	ret
	
get_entry:
	mov	word ptr ExcEax, 0		; DPMI support
	mov	word ptr ExcEbx, 1		; 32-bit support
	mov	al, byte ptr Cpu
	mov	byte ptr ExcEcx, al		; CPU type
	mov	word ptr ExcEdx, 90		; DPMI version
	mov	word ptr ExcEsi, 0		; No paragraphs to allocate
	mov	ExcEs, INIT_SWITCH_SEG
	mov	word ptr ExcEdi, INIT_SWITCH_OFFS ; Switch address.

	add	ebp, 2
	add	ExcOffs, ebp
	clc
	ret

handle_int_31:
; If INT 31h in V86 mode, resirect.
	test	ExcEflags, FL_VM
	jnz	default_int

	add	ebp, 2
	add	ExcOffs, ebp
	call	Int31Handler
	clc
	ret

default_int:
; Do INT xx for VM client.
	add	ebp, 2
	add	ExcOffs, ebp

	movzx	eax, ah
	call	SimulateInt
	clc
	ret				; Done

iret?:
	cmp	al, OP_IRET
	jne	pushf?

; If in protected mode unhandled exception.
;	test	ExcEflags, FL_VM
;	jz	violate

; Emulate IRET for VM client.
	mov	al, OperandSize
	call	EmulateIret

	clc
	ret

pushf?:
	cmp	al, OP_PUSHF
	jne	popf?

	mov	si, ExcSs
	mov	edi, ExcEsp
	mov	ebx, ExcEflags
	call	PointerToLinear		; FS:EAX points to VM client's stack.

	cmp	OperandSize, 0
	je	@F

; Emulate PUSHFD.
	sub	word ptr ExcEsp, 4	; Adjust client SP

	and	ebx, NOT (FL_IF OR FL_VM)
	or	ebx, VirtualIf		; Merge with VirtualIf.
	or	ebx, FakeIopl		; Merge with fake IOPL.
	mov	fs:[eax-4], bx		; "Push" client flags.
	inc	ebp
	add	ExcOffs, ebp
	clc
	ret

@@:
; Emulate PUSHF.
	sub	word ptr ExcEsp, 2	; Adjust client SP

	and	ebx, NOT FL_IF		; Clear IF.
	or	ebx, VirtualIf		; Merge with VirtualIf.
	or	ebx, FakeIopl		; Merge with fake IOPL.

	mov	fs:[eax-2], bx		; "Push" client flags
	inc	ebp
	add	ExcOffs, ebp
	clc
 	ret

popf?:
	cmp	al, OP_POPF
	jne	violate

	mov	si, ExcSs
	mov	edi, ExcEsp
	mov	ebx, ExcEflags
	call	PointerToLinear		; FS:EAX points to VM client's stack.

	mov	edx, fs:[eax]		; Get (E)flags in (E)DX.
	mov	FakeIopl, edx		; Save fake IOPL value.
	and	FakeIopl, 3000h

	and	edx, NOT 3000h		; IOPL = 0.
; Set VirtualIf appropriately.
	mov	VirtualIf, 0
	test	edx, FL_IF
	jz	@F
	mov	VirtualIf, FL_IF
@@:
	or	edx, FL_IF
	cmp	OperandSize, 0
	je	@F

; Emulate POPFD.
	and	edx, NOT FL_VM
	and	ExcEflags, FL_VM
	or	ExcEflags, edx		; "Pop" client flags, merge with VM.
	add	word ptr ExcEsp, 4	; Adjust client SP
	inc	ebp
	add	ExcOffs, ebp
	clc
 	ret

@@:
; Emulate POPF.
	mov	word ptr ExcEflags, dx	; "Pop" client flags
	add	word ptr ExcEsp, 2	; Adjust client SP
	inc	ebp
	add	ExcOffs, ebp
	clc
 	ret

violate:
	stc
	ret

ExcRedirect	ENDP


;-----------------------------------------------------------------------------
;
;	Emulates IRET(d) instruction.
;
;	I:	AL = 0 - 16-bit IRET
;		    = 1 - 32-bit IRET.
;	O:
;
;-----------------------------------------------------------------------------
PUBLIC	EmulateIret
EmulateIret	PROC	USES eax ebx ecx edx esi edi
	mov	cl, al		; Keep operand size.

; Do IRET for the VM client.
	mov	si, ExcSs
	mov	edi, ExcEsp
	mov	ebx, ExcEflags
	call	PointerToLinear		; FS:EAX points to VM client's stack.

	test	cl, cl
	jz	emul_iret

; Emulate IRETD.
	mov	edx, fs:[eax]		; "POP" client EIP
	mov	ExcOffs, edx
	mov	edx, fs:[eax+4]		; "POP" client CS
	mov	ExcSeg, dx

	mov	edx, fs:[eax+8]		; "POP" client flags
	mov	FakeIopl, edx		; Alter fake IOPL.
	and	FakeIopl, 3000h
	and	edx, NOT 3000h		; IOPL = 0

; Set VirtualIf appropriately.
	mov	VirtualIf, edx
	and	VirtualIf, FL_IF

	or	edx, FL_IF		; Real IF will always be 1.
	and	ExcEflags, FL_VM
	and	edx, NOT FL_VM
	or	ExcEflags, edx		; Merge with previous VM value
	add	ExcEsp, 12		; Adjust client SP
	jmp	done

emul_iret:
; Emulate IRET.
	mov	edx, fs:[eax]		; "POP" client IP
	mov	word ptr ExcOffs, dx
	mov	edx, fs:[eax+2]		; "POP" client CS
	mov	ExcSeg, dx

	mov	edx, fs:[eax+4]		; "POP" client flags
	mov	FakeIopl, edx		; Alter fake IOPL.
	and	FakeIopl, 3000h
	and	edx, NOT 3000h		; IOPL = 0
; Set VirtualIf appropriately.
	mov	VirtualIf, edx
	and	VirtualIf, FL_IF

	or	edx, FL_IF		; Real IF will always be 1.
	mov	word ptr ExcEflags, dx
	add	ExcEsp, 6		; Adjust client SP

done:
	ret				; Done

EmulateIret	ENDP


;-----------------------------------------------------------------------------
;
;	Simulates client interrupt.
;
;	I: EAX = int. number.
;	O:
;
;	(!) Can reflect VM to VM, VM to PM, PM to VM or PM to PM.
;
;-----------------------------------------------------------------------------
PUBLIC	SimulateInt
SimulateInt	PROC	near32	USES eax ebx ecx edx esi edi ebp
	mov	ecx, eax

; If system task, reflect to VM.
	cmp	SystemTask, 0
	jne	reflect_to_vm

; If DPMI not initialized, reflect to VM.
	mov	eax, CurrTaskPtr
	cmp	(DosTask PTR fs:[eax]).TaskLdt, 0
	je	reflect_to_vm

; If DPMI handler is not installed, reflect DPMI to VM (check from what later).
	mov	ebp, (DosTask PTR fs:[eax]).DpmiPmInts
	cmp	dword ptr fs:[ebp+ecx*8][4], 0
	je	reflect_dpmi2vm

; Interrupt hook is installed. If arrived from PM, go to PM handler.
	test	ExcEflags, FL_VM
	jz	reflect_pm2pm

; If occured in VM, only interrupt 1Ch, 23h and 24h and h/w ints go to PM handler.
	cmp	ecx, 1Ch
	je	reflect_vm2pm
	cmp	ecx, 23h
	je	reflect_vm2pm
	cmp	ecx, 24h
	je	reflect_vm2pm
	cmp	ecx, 8
	jb	reflect_to_vm
	cmp	ecx, 0Fh
	jna	reflect_vm2pm
	cmp	ecx, 70h
	jb	reflect_to_vm
	cmp	ecx, 77h
	jna	reflect_vm2pm
	jmp	reflect_to_vm

reflect_dpmi2vm:
	test	ExcEflags, FL_VM
	jz	reflect_pm2vm

IFDEF	LOG_DPMI
	pushad
	mov	eax, ecx
	PRINT_LOG	ReflectVM2VMStr
	mov	edi, offset Field
	call	PmHex32ToA
	mov	Field[8], ' '
	mov	eax, offset Field
	mov	ecx, 9
	mov	esi, offset Field
	call	WriteLog

	mov	eax, ExcEax
	mov	edi, offset Field
	call	PmHex32ToA
	mov	Field[8], 13
	mov	Field[9], 10
	mov	eax, offset Field
	mov	ecx, 10
	mov	esi, offset Field
	call	WriteLog

	popad
	LOG_STATE	1
ENDIF
	jmp	reflect_to_vm

PUBLIC	SimulatePmInt
SimulatePmInt::
; Set stack frame.
	push	eax
	push	ebx
	push	ecx
	push	edx
	push	esi
	push	edi
	push	ebp

; If interrupt handler is not installed, jump to unhandled exception.
	mov	ebx, CurrTaskPtr
	mov	ebp, (DosTask PTR fs:[ebx]).DpmiPmInts
	cmp	dword ptr fs:[ebp+eax*8][4], 0

EXTRN	unhandled_exc: near32
	je	unhandled_exc

; Keep interrupt number in ECX.
	mov	ecx, eax

; Reflect PM to PM.
reflect_pm2pm:

IFDEF	LOG_DPMI
	pushad
	mov	eax, ecx
	PRINT_LOG	ReflectPM2PMStr
	mov	edi, offset Field
	call	PmHex32ToA
	mov	Field[8], ' '
	mov	eax, offset Field
	mov	ecx, 9
	mov	esi, offset Field
	call	WriteLog

	mov	eax, ExcEax
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

IFDEF MONITOR_DPMI
extrn	LogX: byte
extrn	LogY: byte
extrn	LogClr: byte

pushad
	PM_PRINT_HEX16	0A001h, LogX, LogY, LogClr
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

; Interrupts 0..7 are called with virtual interrupts disabled
	cmp	ecx, 7
	jna	@F
	mov	VirtualIf, 0
@@:
	test	(DosTask PTR fs:[eax]).TaskFlags, TASK_32BIT
	jz	pm_int_16bit

; 32 bit task.
	sub	ExcEsp, 12
	mov	si, ExcSs
	mov	edi, ExcEsp
	mov	ebx, ExcEflags
	call	PointerToLinear

	mov	ebx, ExcOffs
	mov	fs:[eax], ebx		; Return EIP
	mov	bx, ExcSeg
	mov	fs:[eax][4], bx		; Return CS

; Merge eflags with VirtualIf.
	mov	ebx, ExcEflags
	and	ebx, NOT FL_IF
	or	ebx, VirtualIf

	mov	fs:[eax][8], ebx	; Return Eflags
	jmp	reflect_to_pm

; 16 bit task.
pm_int_16bit:
	sub	ExcEsp, 6
	mov	si, ExcSs
	mov	edi, ExcEsp
	mov	ebx, ExcEflags
	call	PointerToLinear

	mov	ebx, ExcOffs
	mov	fs:[eax], bx		; Return IP
	mov	bx, ExcSeg
	mov	fs:[eax][2], bx		; Return CS

; Merge eflags with VirtualIf.
	mov	ebx, ExcEflags
	and	ebx, NOT FL_IF
	or	ebx, VirtualIf

	mov	fs:[eax][4], bx		; Return flags
	jmp	reflect_to_pm

; Reflect interrupt that occured in VM to PM.
reflect_vm2pm:

IFDEF	LOG_DPMI
	pushad
	mov	eax, ecx
	PRINT_LOG	ReflectVM2PMStr
	mov	edi, offset Field
	call	PmHex32ToA
	mov	Field[8], ' '
	mov	eax, offset Field
	mov	ecx, 9
	mov	esi, offset Field
	call	WriteLog

	mov	eax, ExcEax
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

IFDEF MONITOR_DPMI
extrn	LogX: byte
extrn	LogY: byte
extrn	LogClr: byte

pushad
	PM_PRINT_HEX16	0A002h, LogX, LogY, LogClr
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

	pushad
	sub	al, al
	call	RmSaveState
	popad

	mov	esi, CurrTaskPtr

; Load protected mode stack.
	mov	eax, (DosTask PTR fs:[esi]).DpmiPmStack

	test	(DosTask PTR fs:[esi]).TaskFlags, TASK_32BIT
	jz	@F

;
; VM to 32 bit task.
;

; Put return address on stack.
	mov	dword ptr fs:[eax-12], PM_RET_INT_OFFS
	mov	bx, PmCallbackCs
	mov	fs:[eax-12][4], bx
	mov	ebx, ExcEflags
	and	ebx, NOT FL_VM
	mov	fs:[eax-12][8], ebx
	mov	eax, 12			; Number of bytes to subtract.
	jmp	zero_seg_regs

;
; VM to 16-bit task.
;
@@:
	mov	word ptr fs:[eax-6], PM_RET_INT_OFFS
	mov	bx, PmCallbackCs
	mov	fs:[eax-6][2], bx
	mov	ebx, ExcEflags
	mov	fs:[eax-6][4], bx
	mov	eax, 6			; Number of bytes to subtract.

; Set data segment regs to 0, set SS:ESP and Eflags to protected mode.
zero_seg_regs:
	mov	ExcDs, 0
	mov	ExcEs, 0
	mov	ExcFs, 0
	mov	ExcGs, 0

	mov	bx, PmCallbackSs
	or	bx, 3
	mov	ExcSs, bx
	mov	ebx, (DosTask PTR fs:[esi]).DpmiPmEsp

	sub	ebx, eax
	mov	ExcEsp, ebx
	and	ExcEflags, NOT FL_VM

reflect_to_pm:
	mov	eax, fs:[ebp+ecx*8]
	mov	ExcOffs, eax
	mov	ebx, fs:[ebp+ecx*8][4]
	or	ebx, 3
	mov	ExcSeg, bx

; For interrupts 0-5, 7 clear TF and IF.
	cmp	ecx, 6
	jb	goto_handler
	cmp	ecx, 7
	je	goto_handler

; For others don't change state of TF and virtual IF.
	ret

;
;	Entry point for default DPMI interrupt handler.
;
PUBLIC	SimulateV86Int
SimulateV86Int::
; Set stack frame.
	push	eax
	push	ebx
	push	ecx
	push	edx
	push	esi
	push	edi
	push	ebp

reflect_pm2vm:
; ECX = interrupt #.

IFDEF	LOG_DPMI
	pushad
	mov	eax, ecx
	PRINT_LOG	ReflectPM2VMStr
	mov	edi, offset Field
	call	PmHex32ToA
	mov	Field[8], ' '
	mov	eax, offset Field
	mov	ecx, 9
	mov	esi, offset Field
	call	WriteLog

	mov	eax, ExcEax
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

IFDEF MONITOR_DPMI
extrn	LogX: byte
extrn	LogY: byte
extrn	LogClr: byte

pushad

	PM_PRINT_HEX16	0A000h, LogX, LogY, LogClr
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

pushad
	mov	bl, LogClr
	or	bl, 70h
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

pushad
	mov	bl, LogClr
	or	bl, 70h
	PM_PRINT_HEX16	word ptr ExcEax, LogX, LogY, bl
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

pushad
	mov	bl, LogClr
	or	bl, 70h
	PM_PRINT_HEX16	word ptr ExcEbx, LogX, LogY, bl
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

endif

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

IFDEF	FAKE_WINDOWS
; Try to translate selectors to segments.
EXTRN	XlatSegments: near32
;	call	XlatSegments
ENDIF

	pushad
	sub	al, al
	call	PmSaveState
	popad

; Change stack to locked RM stack.
	mov	eax, CurrTaskPtr		; EAX -> current task.
	mov	ebx, (DosTask PTR fs:[eax]).DpmiRmEsp
	mov	ExcEsp, ebx
	mov	ExcSs, VM_LOCKED_SS

; Set segment registers to some distinct values.
	mov	ExcDs, VM_LOCKED_SS
	mov	ExcEs, VM_LOCKED_SS
	mov	ExcFs, VM_LOCKED_SS
	mov	ExcGs, VM_LOCKED_SS

; Set up return trap index.
	cmp	ecx, 21h
	jne	set_gen_ret_trap
	cmp	byte ptr ExcEax[1], 48h
	jne	@F

; Set index of return trap - return from DOS alloc.
	mov	byte ptr fs:[RET_TRAP_ADDR + 6], 0
	jmp	set_ret_trap_addr

@@:
	cmp	byte ptr ExcEax[1], 49h
	jne	@F

; Set index of return trap - return from DOS free.
	mov	byte ptr fs:[RET_TRAP_ADDR + 6], 1
	jmp	set_ret_trap_addr

@@:
	cmp	byte ptr ExcEax[1], 4Ah
	jne	set_gen_ret_trap

; Set index of return trap - return from DOS resize.
	mov	byte ptr fs:[RET_TRAP_ADDR + 6], 2
	jmp	set_ret_trap_addr

; Set up return trap for generic interrupt.
set_gen_ret_trap:
	mov	byte ptr fs:[RET_TRAP_ADDR + 6], 3

set_ret_trap_addr:
; Set up return trap address.
	mov	ExcSeg, RET_TRAP_SEG
	mov	ExcOffs, RET_TRAP_OFFS
; Change state to virtual mode.
	or	ExcEflags, FL_VM

reflect_to_vm:
	mov	eax, fs:[ecx*4]		; Get interrupt vector address.
	sub	word ptr ExcEsp, 6	; Adjust client SP
	movzx	ebx, ExcSs
	shl	ebx, 4
	movzx	edx, word ptr ExcEsp
	add	ebx, edx		; FS:EBX points to VM client's stack.
	mov	edx, ExcEflags
; Merge with VirtualIf.
	and	edx, NOT FL_IF
	or	edx, VirtualIf
	mov	fs:[ebx+4], dx		; "Push" client flags
	mov	dx, ExcSeg
	mov	fs:[ebx+2], dx		; "Push" client CS
	mov	edx, ExcOffs
	mov	fs:[ebx], dx		; "Push" client return IP

	ror	eax, 16
	mov	ExcSeg, ax		; Store segment part of return
					; address to go to int handler.
	shr	eax, 16
	mov	ExcOffs, eax

goto_handler:
	and	ExcEflags, NOT FL_TF	; clear TF on handler entry
	mov	VirtualIf, 0		; Virtual CLI.
	ret
SimulateInt	ENDP


;-----------------------------------------------------------------------------
;
;	INT 13h return callback. Restores trapped instruction and releases
; INT 13h semaphore.
;
;	I:
;	O:
;
;-----------------------------------------------------------------------------
PUBLIC	Int13RetTrap
Int13RetTrap	PROC	USES eax ebx ecx edx esi edi

; Copy saved opcode back.
	mov	si, ExcSeg
	mov	edi, ExcOffs
	mov	ebx, ExcEflags
	call	PointerToLinear
	mov	ecx, eax

	mov	eax, CurrentTask
	cmp	eax, HddSema4Own
	jne	@F

; Opcode was trapped with HDD semaphore.
	mov	eax, dword ptr Int13RetOp
	mov	fs:[ecx], eax
	mov	eax, dword ptr Int13RetOp[4]
	mov	fs:[ecx][4], eax
	jmp	rel_int13_sema4

@@:
; Opcode was trapped with FDD semaphore.
	mov	eax, dword ptr Int13RetOp[8]
	mov	fs:[ecx], eax
	mov	eax, dword ptr Int13RetOp[8][4]
	mov	fs:[ecx][4], eax

rel_int13_sema4:
	sub	eax, eax
	call	Int13Sema4s

; If current task (that owned a semaphore) has borrowed ticks, NextTask().
IFDEF	BORROWED_TICKS
	mov	eax, CurrTaskPtr
	cmp	(DosTask PTR fs:[eax]).BorrowedTicks, 0
	je	ok_ret
ENDIF
	call	NextTask

	ret
Int13RetTrap	ENDP


;-----------------------------------------------------------------------------
;
;	Deals with INT 13h semaphores (gets/releases).
;
;	I: EAX = 1	-	acquire semaphore
;	         0	-	release semaphore
;
;	On input FS:ECX -> faulting instruction.
;
;-----------------------------------------------------------------------------
PUBLIC	Int13Sema4s
Int13Sema4s	PROC	USES eax ebx ecx edx
	test	eax, eax
	jz	rel_sema4
	
; Acquire semaphore.
	mov	edx, ExcEdx
	test	edx, 80h		; Try to access HDD?
	jnz	@F

	xchg	al, FddSema4
	test	al, al
	jnz	fail_ret

	mov	eax, fs:[ecx+2]
	mov	dword ptr Int13RetOp[8], eax
	mov	eax, fs:[ecx+2][4]
	mov	dword ptr Int13RetOp[8][4], eax
	jmp	trap_ret_instr

@@:
	xchg	al, HddSema4
	test	al, al
	jnz	fail_ret

	mov	eax, fs:[ecx+2]
	mov	dword ptr Int13RetOp, eax
	mov	eax, fs:[ecx+2][4]
	mov	dword ptr Int13RetOp[4], eax

; Trap return instruction.
trap_ret_instr:
; Write invalid opcode instead.
	mov	dword ptr fs:[ecx+2], 0000FFFEh
	mov	dword ptr fs:[ecx+2][4], 00130000h

; Set semaphore owner.
	test	edx, 80h		; Try to access HDD?
	jnz	@F

	mov	eax, CurrentTask
	mov	FddSema4Own, eax
	jmp	ok_ret

@@:
	mov	eax, CurrentTask
	mov	HddSema4Own, eax
	jmp	ok_ret

rel_sema4:
;
;	Release semaphore. The following assumes that one task can't hold
; both HddSema4 and FddSema4, i.e. that INT 13h cannot be called recursively.
;
	cmp	HddSema4, 0
	je	release_fdd

	mov	ebx, HddSema4Own
	cmp	ebx, CurrentTask
	jne	release_fdd

	xchg	al, HddSema4
	mov	ebx, HDD_SEMA4
	jmp	release_sema4

release_fdd:
	mov	ebx, FddSema4Own
	cmp	ebx, CurrentTask
	jne	ok_ret

	xchg	al, FddSema4
	mov	ebx, FDD_SEMA4

release_sema4:
	mov	edx, ebx
	not	edx
; Release all blocked on HDD semaphore tasks from block.
	mov	eax, FirstTask
	mov	ecx, NumOfTasks
rel_blocked_tasks:
	test	(DosTask PTR fs:[eax]).TaskState, TASK_BLOCKED
	jz	@F
	test	(DosTask PTR fs:[eax]).TaskBlock, bl
	jz	@F
	and	(DosTask PTR fs:[eax]).TaskBlock, dl
	jnz	@F
	and	(DosTask PTR fs:[eax]).TaskState, NOT TASK_BLOCKED
@@:
	add	eax, SIZEOF DosTask
	dec	ecx
	jnz	rel_blocked_tasks

ok_ret:
	clc
	ret
fail_ret:
; Should not occur(!)
	stc
	ret
Int13Sema4s	ENDP


;-----------------------------------------------------------------------------
;
;	Checks if file requested to be open is opened by another task.
;
;	I:
;	O:	CF = 0 - not used, allow open
;		   = 1 - fail with access denied error.
;
;-----------------------------------------------------------------------------
IsFileOpen	PROC	USES eax ebx ecx edx esi edi ebp
; Set GS:ESI -> file name.
	mov	si, ExcDs
	movzx	edi, word ptr ExcEdx
	mov	ebx, ExcEflags
	call	PointerToLinear

	mov	esi, eax
; Copy it to test buffer. Now ES:EDI -> file name.
	mov	edi, offset TestFName
	mov	ecx, MAX_FNAME_LEN
	call	FullFileName
; ECX opened files tested.

	mov	edx, FirstTask		; FS:EDX -> task structure being tested.
	mov	ebx, NumOfTasks		; EBX - tasks count.
tasks_loop:
	mov	ecx, (DosTask PTR fs:[edx]).TaskOpenFiles
	test	ecx, ecx
	jz	next_task_i

; FS:EBP -> table to be tested.
	mov	ebp, (DosTask PTR fs:[edx]).TaskOFTable
	mov	eax, CurrentTask
	cmp	eax, (OpenFileRecord PTR fs:[ebp]).Owner
	je	next_task_i		; Owner task is allowed open.

	cld

files_loop:
; GS:ESI -> file name to check with.
	lea	esi, (OpenFileRecord PTR fs:[ebp]).FileName
	push	ecx
	push	edi

	push	es
	push	edi
	push	gs
	pop	es
	mov	edi, esi
	sub	al, al
	mov	ecx, MAX_FNAME_LEN
		repne	scasb
	pop	edi
	pop	es

	not	ecx
	add	ecx, MAX_FNAME_LEN

		repe	cmps	byte ptr gs:[esi], es:[edi]
	pop	edi
	pop	ecx
	je	deny_open

	add	ebp, SIZEOF OpenFileRecord
	dec	ecx
	jnz	files_loop

next_task_i:
	add	edx, SIZEOF DosTask
	dec	ebx
	jnz	tasks_loop

	clc
	ret

deny_open:
	stc
	ret
IsFileOpen	ENDP


;-----------------------------------------------------------------------------
;
;	Callback for open/create file calls (called back by exc. 6 handler).
;
;	I:
;	O:
;
;-----------------------------------------------------------------------------
PUBLIC	Int21RetTrap
Int21RetTrap	PROC	USES es eax ebx ecx edx esi edi ebp
; Copy saved opcode back.
	mov	eax, CurrTaskPtr
	movzx	edx, ExcSeg
	shl	edx, 4
	add	edx, ExcOffs
	mov	ecx, (DosTask PTR fs:[eax]).Int21TrapOp
	mov	fs:[edx], ecx
	mov	ecx, (DosTask PTR fs:[eax]).Int21TrapOp[4]
	mov	fs:[edx][4], ecx

;	and	(DosTask PTR fs:[eax]).TaskState, NOT TASK_LOCKED

; If call failed, don't do further checks.
	test	ExcEflags, FL_CF
	jz	@F
; Return without any action.
	ret

@@:
; Set ES = FLAT_DS.
	push	fs
	pop	es
; Check called DOS function.

	mov	ax, (DosTask PTR fs:[eax]).DosFunc
	cmp	ah, 3Ch			; Create file.
	je	add_open
	cmp	ah, 3Dh			; Open file.
	je	add_open
	cmp	ax, 6C00h		; Ext. open/create.
	je	add_open

	cmp	ah, 3Eh			; Close file.
	je	@F
	ret

@@:
; Set FS:EBX -> current task's open file table.
	mov	edx, CurrTaskPtr
	mov	ebx, (DosTask PTR fs:[edx]).TaskOFTable
; Find handle being closed.
	mov	eax, ExcEbx
	mov	ecx, (DosTask PTR fs:[edx]).TaskOpenFiles	; ECX = count.
	test	ecx, ecx
	jnz	find_record
	ret

find_record:
	cmp	ax, (OpenFileRecord PTR fs:[ebx]).Handle
	jne	@F

; Delete record pointed by EBX.
	mov	edi, ebx
	lea	esi, [edi+SIZEOF OpenFileRecord]
	neg	ecx
	add	ecx, (DosTask PTR fs:[edx]).TaskOpenFiles
	dec	(DosTask PTR fs:[edx]).TaskOpenFiles	; Dec. open files.

	mov	eax, SIZEOF OpenFileRecord
	mul	ecx
	mov	ecx, eax
	cld
		rep	movs	byte ptr es:[edi], es:[esi]
	ret

@@:
	add	ebx, SIZEOF OpenFileRecord
	dec	ecx
	jnz	find_record

; Return if record is not found.
	ret

add_open:
; Copy file to current task's OF table.
	movzx	esi, ExcDs
	shl	esi, 4
	movzx	eax, word ptr ExcEdx
	add	esi, eax		; ES:ESI -> source name.

; Set FS:EBX -> current task's open file table.
	mov	ebp, CurrTaskPtr
	mov	ebx, (DosTask PTR fs:[ebp]).TaskOFTable

; FS:EBX+EAX -> relevant entry.
	mov	eax, SIZEOF OpenFileRecord
	mul	(DosTask PTR fs:[ebp]).TaskOpenFiles

; If page size is reached, don't protect file.
	cmp	eax, 1000h
	jnb	@F

; Copy file name.
	lea	edi, (OpenFileRecord PTR [ebx+eax]).FileName
	call	FullFileName

; Copy file handle.
	mov	cx, word ptr ExcEax
	mov	(OpenFileRecord PTR fs:[ebx+eax]).Handle, cx
; Copy owner task.
	mov	ecx, CurrentTask
	mov	(OpenFileRecord PTR fs:[ebx+eax]).Owner, ecx
; Increment recorder files counter.
	inc	(DosTask PTR fs:[ebp]).TaskOpenFiles

@@:
	ret

Int21RetTrap	ENDP


;-----------------------------------------------------------------------------
;
;	Copies ASCIIZ string with max. length limited (including 0).
;
;	I:	GS:ESI -> source
;		ES:EDI -> dest
;		ECX = maximum length (not including 0).
;	O:
;
; (!) It's a helper routine, allowed to destroy regs.
;
;-----------------------------------------------------------------------------
CopyAsciiz	PROC
	lea	ebx, [ecx-1]

	push	es
	push	edi
	push	gs
	pop	es
	mov	edi, esi
	sub	al, al
	mov	ecx, ebx
		repne	scasb
	not	ecx
	add	ecx, ebx
	pop	edi
	pop	es

; If ECX = 0, skip copy.
	jz	store_0

@@:
	lods	byte ptr gs:[esi]
	call	PmToUpper
	stosb
	dec	ecx
	jnz	@B

store_0:
	sub	al, al
	stosb

	ret
CopyAsciiz	ENDP


;-----------------------------------------------------------------------------
;
;	Returns full path name of given file name, based on current drive,
; current directory and file name gotten.
;
;	I:	GS:ESI -> source file name.
;		ES:EDI -> destination to contain name.
;	O:
;
;-----------------------------------------------------------------------------
FullFileName	PROC	USES eax ebx ecx edx esi edi
;If full path name, just copy it.
	cld
	cmp	word ptr gs:[esi+1], ('\' SHL 8 ) + ':'
	je	copy_src

; Get drive (specified or current).
	cmp	byte ptr gs:[esi+1], ':'
	je	@F

	mov	al, CurrDrive
	add	al, 'A'
	jmp	drive_gotten
@@:
	mov	al, gs:[esi]
	add	esi, 2
	call	PmToUpper

drive_gotten:
	stosb					; Store drive letter.
	mov	word ptr es:[edi], ('\' SHL 8 ) + ':'
	add	edi, 2
	cmp	byte ptr gs:[esi], '\'
	jne	@F
	inc	esi
	jmp	copy_src

@@:
;
; Get current dir.
;	(!) The following code relies on the fact that CDS resides at offset 
; 16h of list of lists. This causes backward compatibility only till DOS 3.1.
; Also assumed is that CDS structure size is 58h; that limits compatibility
; to DOS 4.0
;
	and	eax, 0FFh
	sub	eax, 'A'			; EAX = drive.

	mov	ebx, ListOfListsLin		; FS:EAX -> list of lists.
	movzx	ecx, word ptr fs:[ebx+16h][2]
	shl	ecx, 4
	movzx	edx, word ptr fs:[ebx+16h]
	add	ecx, edx
	mov	edx, CDS_ENTRY_SIZE
	mul	edx				; FS:EAX+ECX -> curr. dir. struct.

	push	esi
	lea	esi, [eax+ecx+3]
	mov	ecx, MAX_FNAME_LEN
	call	CopyAsciiz
	mov	byte ptr es:[edi], '\'
	inc	edi
	pop	esi				; Restore ptr to file name.

; Copy from GS:ESI (source) to ES:EDI.
copy_src:

	mov	ecx, MAX_FNAME_LEN
	call	CopyAsciiz
	ret
FullFileName	ENDP


;-----------------------------------------------------------------------------
;
;	Release a semaphore. If a semaphore was acquired by that task, it is
; released. The next task (the first that was sleeping on it) is getting the
; semaphore. Else, nothing is done.
;
;	I:	EAX - task that tries to release the semaphore.
;		GS:ECX -> semaphore structure.
;	O:	AL = result value of the sempahore. 1 means it's released, 0
; means nothing is done.
;
; (!) Tripple-DOS can't run on SMP, so no need to keep semaphore handling
; strictly atomic.
;
;-----------------------------------------------------------------------------
PUBLIC	Sema4Up
Sema4Up		PROC	USES ebx edx esi
	mov	bl, (Sema4 PTR gs:[ecx]).State
	test	bl, bl
	je	ret_state

	cmp	(Sema4 PTR gs:[ecx]).Owner, eax
	je	change_state

;
; If a task isn't device's owner, look it up in the queue. If it's there,
; remove it. Else, just return state.
;
	sub	ebx, ebx
	mov	edx, (Sema4 PTR gs:[ecx]).TasksSleep
@@:
	cmp	ebx, (Sema4 PTR gs:[ecx]).SleepN
	jnb	ret_state
	cmp	eax, (Sema4 PTR gs:[ecx]).TasksSleep[ebx*4]
	je	@F
	inc	ebx
	jmp	@B

@@:
; Unblock task.
	TASK_PTR
	and	(DosTask PTR fs:[eax]).TaskBlock, NOT SOME_SEMA4
	jnz	@F
	and	(DosTask PTR fs:[eax]).TaskState, NOT TASK_BLOCKED
@@:
; Remove it from wait queue.
	inc	ebx
	cmp	ebx, (Sema4 PTR gs:[ecx]).SleepN
	jnb	@F
	mov	eax, (Sema4 PTR gs:[ecx]).TasksSleep[ebx*4]
	mov	eax, (Sema4 PTR gs:[ecx]).TasksSleep[ebx*4][-4]
	jmp	@B
@@:
	dec	(Sema4 PTR gs:[ecx]).SleepN
	dec	(Sema4 PTR gs:[ecx]).State
	mov	bl, (Sema4 PTR gs:[ecx]).State
	jmp	ret_state

change_state:
; Change state.
;	mov	(Sema4 PTR gs:[ecx]).State, bl
;	cmp	(Sema4 PTR gs:[ecx]).SleepN, 0

; Wake up the first task that waits, make it the semaphore owner.
	mov	eax, (Sema4 PTR gs:[ecx]).TasksSleep
	mov	(Sema4 PTR gs:[ecx]).Owner, eax

	TASK_PTR
;
; Check how the task can be blocked on more than one event?! If it is
; possible, then only the ready-to-run task can acquire the semaphore!
;
	and	(DosTask PTR fs:[eax]).TaskBlock, NOT SOME_SEMA4
	jnz	@F
	and	(DosTask PTR fs:[eax]).TaskState, NOT TASK_BLOCKED
@@:
	sub	ebx, ebx
	dec	(Sema4 PTR gs:[ecx]).State
	dec	(Sema4 PTR gs:[ecx]).SleepN
	jz	ret_state

; The Q of sleeping tasks must be handled.

	mov	edx, (Sema4 PTR gs:[ecx]).SleepN
	lea	esi, (Sema4 PTR gs:[ecx]).TasksSleep
@@:
	mov	eax, gs:[esi][4]
	mov	gs:[esi], eax
	add	esi, 4
	dec	edx
	jnz	@B

ret_state:
	mov	al, bl
	ret
Sema4Up		ENDP


;-----------------------------------------------------------------------------
;
;	Try to get a semaphore. If a semaphore's state is 0 (avail), it is
; acquired. Else, a task is blocked. If a task already owns this semaphore,
; the task will be terminated.
;
;	I:	EAX - task that tries to get the semaphore.
;		GS:ECX -> semaphore structure.
;	O:	AL = previous value of the sempahore. 0 means it's acquired, 1
; means the task went to sleep.
;
; (!) Tripple-DOS can't run on SMP, so no need to keep semaphore handling
; strictly atomic.
;
;-----------------------------------------------------------------------------
PUBLIC	Sema4Down
Sema4Down	PROC	USES ebx edx
	mov	bl, (Sema4 PTR gs:[ecx]).State
	test	bl, bl
	jnz	sleep

; Semaphore was available, get it.
	mov	(Sema4 PTR gs:[ecx]).Owner, eax
	jmp	ret_state

sleep:
;
; Semaphore was N/A, go to sleep and put the task in semaphore's sleep list.
; Meanwhile a check for double acquiring of the semaphore is omitted.
;

	mov	edx, (Sema4 PTR gs:[ecx]).SleepN
	mov	(Sema4 PTR gs:[ecx]).TasksSleep[edx*4], eax
	inc 	(Sema4 PTR gs:[ecx]).SleepN
	TASK_PTR
	mov	(DosTask PTR fs:[eax]).TaskState, TASK_BLOCKED
	mov	(DosTask PTR fs:[eax]).TaskBlock, SOME_SEMA4
	call	NextTask

ret_state:
	mov	al, bl
	inc	bl
	mov	(Sema4 PTR gs:[ecx]).State, bl
	ret
Sema4Down	ENDP


CODE32	ENDS


CODE	SEGMENT	PARA	PUBLIC	USE16	'CODE'
ASSUME	CS:CODE, DS:DATA, SS:STK

TaskV86Entry::
; Set video mode 3.
	mov	ax, 3
	int	10h

IFDEF	DOUBLE_SHELL
; Get PSP.
	mov	ah, 62h
	int	21h
	mov	PspSeg, bx

	mov	ds, bx
; Find COMSPEC.
	mov	es, ds:[2Ch]
	sub	di, di
	sub	al, al

	mov	dx, DATA
	mov	ds, dx

find_comspec_loop:
	mov	si, offset ComSpecStr
	cld
	mov	cx, 8
		repe	cmpsb
	je	comspec_found

		repne	scasb	; scan for terminated 0.
	jmp	find_comspec_loop
comspec_found:
	mov	ax, es
	mov	ds, ax
	mov	dx, di

	mov	ax, DATA
	mov	es, ax
	mov	bx, offset ExecPrmBlock
	mov	ax, es:PspSeg
	mov	es:[bx+4], ax
	mov	es:[bx+8], ax

	mov	ax, 4b00h
	int	21h		; Start command.com
ENDIF	; DOUBLE_SHELL

; End current task so that the parent task will remain.
	mov	ah, 4Ch
	int	21h

CODE	ENDS


STK	SEGMENT	PARA	STACK	USE16 'STACK'
STK	ENDS


END
