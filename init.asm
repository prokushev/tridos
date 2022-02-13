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
;				INIT.ASM
;				--------
;	Initialization routines and data for Tripple-DOS. 
;	Error handling during initialization.
;
;	For MASM v6.1x.
;
;=============================================================================

	EXTRN	SetupVideo: near
	EXTRN	InitPIC: near
	EXTRN	EnableA20: near
	EXTRN	PmWriteStr: near
	EXTRN	SetupIdt: near
	EXTRN	InitPagesMap: near
	EXTRN	SetupExcTraps: near
	EXTRN	InitDpmiServer: near

	EXTRN	OsStartPage: dword
	EXTRN	OsEndPage: dword
	EXTRN	PagesMap: dword
	EXTRN	PagesMapSeg: word
	EXTRN	PagesCtl: dword
	EXTRN	PagesCtlSeg: word
	EXTRN	PdbLin: dword
	EXTRN	OsHeapBitmap: dword
	EXTRN	OsHeapBitmapSeg: word
	EXTRN	ExcTrapsList: dword
	EXTRN	DynPagesTbl2: dword
	EXTRN	DynPagesTbl2Seg: word
	EXTRN	DmaBufSeg: word
	EXTRN	DmaBufAddr: dword

	EXTRN	TickToSec: dword
	EXTRN	SliceTicks: dword

	EXTRN	CrtId: byte

	INCLUDE	INIT.INC
	INCLUDE	X86.INC
	INCLUDE PHLIB.INC
	INCLUDE	DEVICES.INC
	INCLUDE	DEF.INC

	EXTRN	DoubleFaultEntry: Gate386

DATA	SEGMENT	PARA	PUBLIC	USE16	'DATA'
	CfgFile		DB	"TRIDOS.CFG", 0
	Buf		DB	MAX_CFG_LINE + 1 DUP (?)
	TickToSecStr	DB	"TickToSec", 0
	TickToSliceStr	DB	"SliceTicks", 0

	PUBVAR		GdtBase, DD, ?	; Base linear GDT address.
	TempGdt		DTR	<>	; Gdt DTR.
	TempIdt		DTR	<>	; Temporary IDT for reloading.
	GdtSeg		DW	?	; Base segment of GDT
	PUBVAR		GdtPtr, DW, 8	; Pointer for dynamically creating GDT.

	PUBVAR		SysPdb, DD, ?	; Base address of system PD.
	PUBVAR		SysPagesCtl, DD, ?	; Linear address of system
						; pages control array.
	PUBVAR		SysPdbLin, DD, ?	; System PDB linear address.
	PUBVAR		Pdb, DD, ?	; Base address of current PD.
	PUBVAR		PdbSeg, DW, ?	; Base segment addr. of PD

	PUBVAR		TssBase	, DD, ?	; Base address of TSS
	PUBVAR		OrigTssBase, DD, ?
	TssSeg		DW	?	; Base segment addr. of TSS

	ErrLvl		DW	?	; Current error level during init.
	PUBVAR		Cpu, DW, ?	; CPU type.
	Video		DB	?	; Video adapter type.
	PUBVAR		MemSize, DD, ?	; Extended memory size (starting at
					; 100000h)
	PUBVAR		Start32Esp, DD, ?

	CrLf		DB	0Dh, 0Ah, 0
	MemStr		DB	"Found extended memory (in K): ", 0
	FreeMemStr	DB	"Left free low memory (in bytes): ", 0

	ErrStr		DB	"Error ", 0

PUBLIC	Field
	Field		DB	100 DUP (0)

	PUBVAR		QuitPm, DB, 0		; When 1, system task exits.
	PUBVAR		ListOfLists, DW, ?	; DOS List of lists.
			DW	?
	PUBVAR		ListOfListsLin, DD, ?	; DOS List of lists lin. addr.
	PUBVAR		CurrDrive, DB, ?	; Keeps current drive from
						; start.

; Selectors.
	InitCodeSel	DW	?
	InitDataSel	DW	?
	PUBVAR		InitStkSel, DW, 0
	FlatDataSel	DW	?
	TssSel		DW	?
	Code32Sel	DW	?
	DblFaultTssSel	DW	?

; Real mode IDT.
	RmIdt		DTR	< 3FFh, 0 >
; Error messages.
	GdtErrMsg	DB	": Cannot dynamically allocate GDT", 0
	CpuErrMsg	DB	": CPU 386 or better required", 0
	CpuModeErrMsg	DB	": CPU is already in protected mode", 0
	TssErrMsg	DB	": Cannot dynamically allocate TSS", 0
	ExcTrapsErrMsg	DB	": Cannot dynamically allocate exception traps list", 0
	VideoErrMsg	DB	": A VGA compatible display adapter is required!", 0
	PdErrMsg	DB	": Cannot dynamically allocate memory tables", 0
	NoXmemErrMsg	DB	": Not detected enough physical memory. At least 4M is required", 0
InitErrors	LABEL	INIT_ERROR
	CpuErr		INIT_ERROR	< 1, CpuErrMsg >
	CpuModeErr	INIT_ERROR	< 2, CpuModeErrMsg >
	GdtErr		INIT_ERROR	< 3, GdtErrMsg >
	TssErr		INIT_ERROR	< 4, TssErrMsg >
	ExcTrapsErr	INIT_ERROR	< 5, ExcTrapsErrMsg >
	VideoErr	INIT_ERROR	< 6, VideoErrMsg >
	PdErr		INIT_ERROR	< 7, PdErrMsg >
	NoXmemErr	INIT_ERROR	< 8, NoXmemErrMsg >

	LogStartMsg	DB	"Log initialized", 13, 10, 0
LOG_START_MSG_L	=	$ - offset LogStartMsg

	BiosMemBuf	DB	200 DUP (?)
	BiosMemBufLen	DW	?

; DPMI service page
	PUBVAR		DpmiSrvSeg, DW, ?
	PUBVAR		DpmiSrvAddr, DD, ?
DATA	ENDS


STK	SEGMENT	PARA	STACK	USE16	'STACK'
	DB	STK_SIZE	DUP (?)
STK	ENDS


GDT_SEG	SEGMENT	PARA	PUBLIC	USE16	'BSS'
	DB	10000h DUP (?)
GDT_SEG	ENDS


TSS	SEGMENT	PARA	PUBLIC	USE16	'BSS'
	GeneralTss	Tss386	<>
	IntPermTable	DB	INT_PERM_SIZE DUP (?)
	IoPermTable	DB	IO_PERM_SIZE DUP (?)

ALIGN	8
	DoubleFaultTss	Tss386	<>
TSS	ENDS


INIT_PAGES	SEGMENT	PARA	PUBLIC	USE16	'BSS'
	DB	0E400h + 1000h DUP (?)		; Extra page for alignment.
;	DB	10000h DUP (?)
INIT_PAGES	ENDS


CODE	SEGMENT	PARA	PUBLIC	USE16	'CODE'
ASSUME CS:CODE, DS:DATA, SS:STK

IF	@Version	LT	611
.486p
ELSE
.586p
ENDIF

;-----------------------------------------------------------------------------
;
;	Entry point.
;
;-----------------------------------------------------------------------------
Init		PROC	near
PUBLIC	_main
_main	label far
; Initialize real-mode segment registers.
	mov	ax, DATA
	mov	ds, ax
	mov	es, ax

	call	ParseCfg

; Set init level 1.
	mov	ErrLvl, 1
; Check CPU.
	call	CpuType
	mov	Cpu, ax
	cmp	al, 3
	jnb	cpu_ok
	call	InitErrHandler
cpu_ok:
; Check CPU mode.
	inc	ErrLvl			; Init level 2.
	smsw	ax
	test	ax, 1
	jz	cpu_mode_ok
	call	InitErrHandler
cpu_mode_ok:
; Get default drive.
	mov	ah, 19h
	int	21h
	mov	CurrDrive, al
; Get list of lists.
	sub	eax, eax
	sub	ebx, ebx
	mov	ah, 52h
	int	21h
	mov	ListOfLists, bx
	mov	ListOfLists[2], es
	mov	ax, es
	shl	eax, 4
	add	eax, ebx
	mov	ListOfListsLin, eax
; Init DMA buffer.
	mov	ah, 48h
	mov	bx, 2000h
	int	21h
	and	ax, 0F000h
	add	ax, 1000h
	mov	DmaBufSeg, ax
	movzx	eax, ax
	shl	eax, 4
	mov	DmaBufAddr, eax
; Setup GDT.
	inc	ErrLvl			; Init level 3.
	call	GetGdtBase
	call	SetupGdt
; Initialize DPMI server.
	call	InitDpmiServer
; Setup necessary TSS fields.
	inc	ErrLvl			; Init level 4.
	call	SetupTss
; Init exceptions trap list.
	inc	ErrLvl			; Init level 5.
	call	SetupExcTraps
; Setup video adapter & video memory for protmode.
	inc	ErrLvl			; Init level 6.
	call	SetupVideo
	cmp	CrtId, 5
; Enable A20 line.
	call	EnableA20
; Check extended memory size.
;	cli
;	call	PmGetMemSize
	call	BiosGetMemSize
	mov	MemSize, eax
	call	FindDpmiSrvPage
	mov	DpmiSrvSeg, ax
	movzx	eax, ax
	shl	eax, 4
	mov	DpmiSrvAddr, eax
IFDEF	DEBUG_BUILD
;	sti
; Report found physical memory.
	push	ds
	pop	es
	mov	eax, MemSize
        shl     eax, 2                  ; EAX = # of Kbytes
	mov	edx, eax
	ror	edx, 16
	mov	di, offset Field
	call	LongUIToA
	mov	si, offset MemStr
	call	PrintString
	mov	si, di
	call	PrintString

	mov	si, offset CrLf
	call	PrintString

sub	ah, ah
int	16h
ENDIF	; DEBUG_BUILD

; Set MemSize to actual memory size (add 1Mb).
	add	MemSize, 100h
; Setup page tables.
	inc	ErrLvl			; Init level 7.
	call	SetupPageTables
; Setup memory pages map.
	call	InitPagesMap

IFDEF	DEBUG_BUILD
; Report left free low memory.
	push	ds
	pop	es
	mov	di, offset Field
	mov	dx, 0Ah
	sub	ax, ax
	sub	ax, word ptr OsEndPage
	sbb	dx, word ptr OsEndPage[2]
	call	LongUIToA
	mov	si, offset FreeMemStr
	call	PrintString
	mov	si, di
	call	PrintString
ENDIF	; DEBUG_BUILD

	inc	ErrLvl			; Init level 8.
	cmp	MemSize, 400000h SHR 12	; At least 4M is required!
	jnb	@F
	call	InitErrHandler
@@:

; Enter protmode.
	cli
	call	SetPm

	JmpFar_16_32	CODE_32, offset Start32
Start16::
	cli
	call	SetRm
	sti

; Clear screen - set mode 3.
	mov	ax, 3
	int	10h

	mov	ax, 4C00h	; Normal return to DOS
	int	21h

Init		ENDP


SKIP_WH_SPACES	MACRO	p:REQ
LOCAL	l1, l2, l3
l1:
	cmp	byte ptr [p], ' '
	je	l2
	cmp	byte ptr [p], 9
	je	l2
	cmp	byte ptr [p], 10
	je	l2
	jmp	l3
l2:
	inc	p
	jmp	l1
l3:
ENDM


GET_INT		MACRO	fmt, src, dest:REQ
LOCAL	to_end
 IFNB	<fmt>
 	mov	si, fmt
 ENDIF
 IFNB	<src>
 	mov	di, src
 ENDIF

	call	StrLen
	mov	cx, ax
		repe	cmpsb
	jne	to_end
	SKIP_WH_SPACES	di
	cmp	byte ptr [ di ], '='
	jne	to_end
	inc	di
	SKIP_WH_SPACES	di
	mov	si, di
	call	AToLongUI
	mov	word ptr dest, ax
	mov	word ptr dest[2], dx
to_end:
ENDM


;-----------------------------------------------------------------------------
;
;	Parses the config file TRIDOS.CFG
;
;-----------------------------------------------------------------------------
ParseCfg	PROC
LOCAL	stop: byte
	mov	dx, offset CfgFile
	mov	ax, 3D00h
	int	21h
	jnc	@F
	ret		; If .CFG file not found - defaults are ready.
@@:
	mov	bx, ax
	mov	stop, 0

next_line:
	mov	ax, 4201h
	sub	cx, cx
	sub	dx, dx
	int	21h

	push	dx
	push	ax

	mov	ah, 3Fh
	mov	dx, offset Buf
	mov	cx, MAX_CFG_LINE
	int	21h

	cmp	ax, cx
	je	@F
	mov	stop, 1
@@:
	mov	di, offset Buf
	mov	cx, MAX_CFG_LINE
	mov	al, 13
	cld
		repne	scasb
	jne	@F
	dec	di
@@:
	mov	byte ptr es:[ di ], 0
	sub	cx, MAX_CFG_LINE
	neg	cx
	inc	cx

	pop	ax
	pop	dx
	add	ax, cx
	adc	dx, 0

	mov	cx, dx
	mov	dx, ax
	mov	ax, 4200h
	int	21h
	
; Compare Buf against setup param
	GET_INT	(offset TickToSecStr), (offset Buf), TickToSec
	GET_INT	(offset TickToSliceStr), (offset Buf), SliceTicks
next1:
	cmp	stop, 0
	je	next_line

	ret
ParseCfg	ENDP


;-----------------------------------------------------------------------------
;
;	Determines the base of dynamic GDT
;
;-----------------------------------------------------------------------------
GetGdtBase	PROC	USES es
; Maximum GDT size - 64k.
	mov	eax, GDT_SEG
	mov	GdtSeg, ax

; Set 0 descriptor in GDT GDTR value.
	mov	es, ax
	shl	eax, 4
	mov	GdtBase, eax
	mov	(DTR PTR es:[0]). Limit, 0FFFFh
	mov	(DTR PTR es:[0]). Base, eax

; Fill GDT with 0s.
	mov	di, 8
	mov	cx, 0FFF8h SHR 2
	sub	eax, eax
	cld
		rep	stosd

	ret
GetGdtBase	ENDP


;-----------------------------------------------------------------------------
;
;	I: EAX = base address.
;	   ECX = limit
;	   DL = access rights,  DH = extended attributes.
;
;	O: AX = selector value (RPL = DPL).
;
;	Dynamically adds GDT segment. 
;	For 32-bit segments caller must supply attributes as well as limit;
;	this function will not apply D/B and G attributes if limit > 1Mb.
;
;-----------------------------------------------------------------------------
AddGdtSegment	PROC	near
	push	es
	mov	es, GdtSeg
	mov	si, GdtPtr
; Create segment.
	mov	(Descriptor386 PTR es:[si]).BaseLow, ax		; Base addr.
	ror	eax, 16
	mov	(Descriptor386 PTR es:[si]).BaseHigh24, al
	mov	(Descriptor386 PTR es:[si]).BaseHigh32, ah
	mov	(Descriptor386 PTR es:[si]).LimitLow, cx	; Limit
	ror	ecx, 16
	and	cl, 0Fh
	mov	(Descriptor386 PTR es:[si]).LimitHigh20, cl
	mov	(Descriptor386 PTR es:[si]).Access, dl		; Access rights.
	or	(Descriptor386 PTR es:[si]).LimitHigh20, dh	; Attr.
; Set AX = selector.
	mov	ax, dx
	shr	ax, 5
	and	ax, 3
	add	ax, GdtPtr
; Advance GDR ptr.
	add	GdtPtr, 8
; Advance GDT limit.
	pop	es
	ret
AddGdtSegment	ENDP


;-----------------------------------------------------------------------------
;
;	Setup the required GDT segments.
;
;-----------------------------------------------------------------------------
SetupGdt	PROC	near
; Setup code segment.
	sub	eax, eax
	mov	ax, cs
	shl	eax, 4		; Base addr.
	ADD_GDT_SEGMENT	, 0FFFFh, CODE_ACCESS
	mov	InitCodeSel, ax

; Setup data segment
	sub	eax, eax
	mov	ax, ds
	shl	eax, 4		; Base addr.
	ADD_GDT_SEGMENT	, 0FFFFh, DATA_ACCESS
	mov	InitDataSel, ax

;
; Setup stack segment. Stack segment must have ATTR_DEF = 1 for 32-bit DPMI
; clients.
;
	sub	eax, eax
	mov	ax, ss
	shl	eax, 4		; Base addr.
	ADD_GDT_SEGMENT	, 0FFFFh, DATA_ACCESS, FLAT_ATTR
	mov	InitStkSel, ax

; Setup FLAT data segment.
	sub	eax, eax	; Base = 00000000h
	ADD_GDT_SEGMENT	, 0FFFFFFFFh, DATA_ACCESS, FLAT_ATTR
	mov	FlatDataSel, ax

; Setup 32-bit code segment.
	mov	eax, CODE32
	shl	eax, 4
	ADD_GDT_SEGMENT	, 0FFFFFFFFh, CODE_ACCESS, FLAT_ATTR
	mov	Code32Sel, ax

	ret
SetupGdt	ENDP


;-----------------------------------------------------------------------------
;
;	Setup page tables:
;	1) Map 1st megabyte 1-to-1 for switch to protmode and back.
;	2) Map OS module (code and data) to 2nd Gb (OS_BASE)
;	3) Adjust OS segments by OS_BASE.
;
; (!)	All allocations must be done prior to setting up page tables.
;
;-----------------------------------------------------------------------------
SetupPageTables	PROC	near
LOCAL	pInitPages: WORD			; Segment address.
LOCAL	OsBasePageTbl: DWORD

	mov	ax, INIT_PAGES

	and	eax, 0000FF00h
	shl	eax, 4
	add	eax, 1000h	; Align to 4 K.
	mov	SysPdb, eax	; Pdb -> page dir.
	shr	eax, 4
	mov	PdbSeg, ax

	mov	pInitPages, ax
	add	pInitPages, 100h

	;
	; Set all page dir entries to 0s (non-present).
	;
	mov	es, PdbSeg
	sub	di, di
	mov	cx, 400h
	sub	eax, eax
	cld
		rep	stosd

	;
	; Allocate first page table for OS heap (OS_HEAP).
	;
	movzx	eax, pInitPages
	add	pInitPages, 100h
	shl	eax, 4

	or	eax, PAGE_PRESENT OR PAGE_WRITABLE OR PAGE_USER
	mov	es:[OS_HEAP SHR 20], eax	; Set OS heap base.

	;
	; Allocate page table for OS video buffer.
	;
	movzx	eax, pInitPages
	add	pInitPages, 100h

	mov	cx, ax
	shl	eax, 4
	or	eax, PAGE_PRESENT OR PAGE_WRITABLE
	mov	es:[OS_VIDEO_BUF SHR 20], eax	; Set OS video buffer base.

	;
	; Allocate page table for global 1st Mb mapping.
	;
	movzx	eax, pInitPages
	add	pInitPages, 100h

	mov	bx, ax
	shl	eax, 4
	or	eax, PAGE_PRESENT OR PAGE_WRITABLE
	mov	es:[OS_1ST_MB SHR 20], eax	; Set 1st Mb mapping PT base.

	;
	; Allocate a page table for dynamic page tables.
	;
	movzx	eax, pInitPages
	add	pInitPages, 100h

	mov	DynPagesTbl2Seg, ax
	shl	eax, 4
	mov	edi, eax
	or	edi, PAGE_PRESENT OR PAGE_WRITABLE
	sub	eax, OsStartPage
	or	eax, OS_BASE
	mov	DynPagesTbl2, eax
	mov	es:[OS_DYN_PAGETBLS SHR 20], edi

	;
	; Map video buffer to OS_VIDEO_BUF.
	;
	mov	es, cx
	sub	di, di
	mov	eax, 0A0000h OR PAGE_PRESENT OR PAGE_WRITABLE	; U/S = 0.
map_vbuf:
	mov	es:[di], eax
	add	eax, 1000h
	add	di, 4
	cmp	eax, 0A0000h + 20000h
	jb	map_vbuf

	;
	; Map 1st Mb to OS_1ST_MB.
	;
	mov	es, bx
	sub	di, di
	mov	eax, PAGE_PRESENT OR PAGE_WRITABLE	; U/S = 0.
map_1st_mb:
	mov	es:[di], eax
	add	eax, 1000h
	add	di, 4
	cmp	eax, 110000h
	jb	map_1st_mb

	;
	; Allocate pages map.
	;
	mov	ah, 48h
	mov	ebx, MemSize
	shr	ebx, 3 + 4
	inc	bx
	int	21h

	jnc	alloc_ok
	call	InitErrHandler
alloc_ok:
	mov	PagesMapSeg, ax

;
; Get program's start and end pages. All dynamically allocated memory must be
; included (system tables). Use INT 21h/AH=52H to get first MCB and walk
; through all MCBs until the last free block which will be appended to
; free pages.
;
; (!) All dynamic system tables must be allocated BEFORE this point.
;

; Get program's PSP.
	mov	ah, 62h
	int	21h			; Get current process ID.
	mov	cx, bx

	mov	ah, 52h
	int	21h
	mov	dx, es:[bx-2]		; ES = 1st MCB.
	sub	ax, ax			; AX will contain first MCB belonging
					; to multitasker.

walk_mcb_loop:
	mov	es, dx
	cmp	byte ptr es:[0], 'Z'
	je	end_walk_mcb

	test	ax, ax
	jnz	@F

	cmp	cx, es:[1]
	jne	@F

	mov	ax, es
	inc	ax

@@:
	add	dx, es:[3]
	inc	dx
	jmp	walk_mcb_loop

end_walk_mcb:
; DX = MCB of last (free) block.
	cmp	word ptr es:[1], 0	; Is the last block free?
	je	@F
	add	dx, es:[3]
@@:
	inc	dx
	and	edx, 0000FF00h	
	shl	edx, 4
	add	edx, 1000h	; Align to 4 K. Keep in EDX high page bound.
	add	edx, 1000h	; Reserve.

set_os_end_page:
	mov	edx, 0A0000h
	mov	OsEndPage, edx	; Store end page

	and	eax, 0000FF00h
	shl	eax, 4
	mov	OsStartPage, eax	; Store first page.

; Store linear addresses of pages map.
	movzx	eax, PagesMapSeg
	shl	eax, 4
	sub	eax, OsStartPage
	or	eax, OS_BASE
	mov	PagesMap, eax

	;
	; Allocate page table control array.
	;
	movzx	eax, pInitPages
	add	pInitPages, 100h

	mov	PagesCtlSeg, ax
	shl	eax, 4
	sub	eax, OsStartPage
	or	eax, OS_BASE
	mov	SysPagesCtl, eax

	;
	; Allocate OS heap allocation bitmap.
	;
	movzx	eax, pInitPages
	add	pInitPages, 800h

	mov	OsHeapBitmapSeg, ax
	shl	eax, 4
	sub	eax, OsStartPage
	or	eax, OS_BASE
	mov	OsHeapBitmap, eax

;
; 1) Map 1st Mb 1-to-1. 
; There is only 1 page table required. It will have 256 entries.
;
	movzx	eax, pInitPages
	add	pInitPages, 40h
	shl	eax, 4

; Fill page directory entry.
	push	es
	mov	es, PdbSeg		; ES:0 -> page dir.
	mov	es:[0], eax	; Store page table address.
; Set page table attributes.
	or	byte ptr es:[0], PAGE_PRESENT OR PAGE_WRITABLE OR PAGE_USER

; Set page table entries.
	shr	eax, 4
	mov	es, ax		; ES:0 -> page table #0.
IFNDEF	PROVIDE_HIMEM
	mov	cx, 100000h SHR 12	; Number of pages to map.
ELSE
	mov	cx, 110000h SHR 12	; Number of pages to map.
ENDIF	;PROVIDE_HIMEM
	sub	si, si		; SI -> page table entry.
map_pages_loop:
	movzx	eax, si
	shl	eax, 10
	mov	es:[si], eax
; Set page attributes.
	or	byte ptr es:[si], PAGE_PRESENT OR PAGE_WRITABLE OR PAGE_USER
	add	si, 4
	dec	cx
	jnz	map_pages_loop
	
;
; 2) Map the entire module to start of 2nd GB.
;

	;
	; Fill page table
	;
; Set ES:[SI] -> page dir entry.
	mov	es, PdbSeg
	mov	si, OS_BASE SHR 20
; Allocate page table entries. ECX = start page, EDX = end page.
	mov	ebx, OsEndPage
	sub	ebx, OsStartPage
	shr	ebx, 10 + 4
	add	ebx, 101h		; +4k for page table must be page-
					; aligned (!)
	mov	ah, 48h
	int	21h
	jnc	set_os_base_page_table
	call	InitErrHandler
set_os_base_page_table:
	and	eax, 0000FF00h	
	shl	eax, 4
	add	eax, 1000h	; Align to 4 K.
; Set page dir. entry.
	mov	es:[si], eax
	or	byte ptr es:[si], PAGE_PRESENT OR PAGE_WRITABLE OR PAGE_USER
; Set page table entries.
	shr	eax, 4
	mov	es, ax			; ES:0 -> page table entries.
	sub	si, si			; ES:SI -> page table entry to map.

; Adjust OsEndPage.
;	add	OsEndPage, 2000h	; Add 2 pages for page table itself.
;	add	edx, 2000h
	mov	ecx, OsStartPage

map_os_base_pages:
	mov	es:[si], ecx
	or	byte ptr es:[si], PAGE_PRESENT OR PAGE_WRITABLE
	add	si, 4
	add	ecx, 1000h
	cmp	ecx, edx
	jb	map_os_base_pages

;
; 3) Adjust init. segments and system tables base addresses.
;
	mov	es, GdtSeg
	mov	ecx, OsStartPage
; Adjust code segment.
	mov	ax, cs
	movzx	eax, ax
	shl	eax, 4
	sub	eax, ecx
	or	eax, OS_BASE
	mov	(Descriptor386 PTR es:[INIT_CS]).BaseLow, ax
	ror	eax, 16
	mov	(Descriptor386 PTR es:[INIT_CS]).BaseHigh24, al
	mov	(Descriptor386 PTR es:[INIT_CS]).BaseHigh32, ah
; Adjust data segment.
	mov	ax, ds
	movzx	eax, ax
	shl	eax, 4
	sub	eax, ecx
	or	eax, OS_BASE
	mov	(Descriptor386 PTR es:[INIT_DS]).BaseLow, ax
	ror	eax, 16
	mov	(Descriptor386 PTR es:[INIT_DS]).BaseHigh24, al
	mov	(Descriptor386 PTR es:[INIT_DS]).BaseHigh32, ah
; Adjust stack segment.
	mov	ax, ss
	movzx	eax, ax
	shl	eax, 4
	sub	eax, ecx
	or	eax, OS_BASE
	mov	(Descriptor386 PTR es:[INIT_SS]).BaseLow, ax
	ror	eax, 16
	mov	(Descriptor386 PTR es:[INIT_SS]).BaseHigh24, al
	mov	(Descriptor386 PTR es:[INIT_SS]).BaseHigh32, ah
; Adjust 32-bit code segment.
	mov	ax, CODE32
	movzx	eax, ax
	shl	eax, 4
	sub	eax, ecx
	or	eax, OS_BASE
	mov	(Descriptor386 PTR es:[CODE_32]).BaseLow, ax
	ror	eax, 16
	mov	(Descriptor386 PTR es:[CODE_32]).BaseHigh24, al
	mov	(Descriptor386 PTR es:[CODE_32]).BaseHigh32, ah

; Adjust TSSes.
	;
	; General TSS.
	;
	mov	si, TssSel
	mov	es, GdtSeg
	mov	eax, TssBase
	sub	eax, ecx
	or	eax, OS_BASE
	mov	TssBase, eax
	mov	(Descriptor386 PTR es:[si]).BaseLow, ax
	ror	eax, 16
	mov	(Descriptor386 PTR es:[si]).BaseHigh24, al
	mov	(Descriptor386 PTR es:[si]).BaseHigh32, ah

	;
	; Double fault TSS.
	;
	mov	si, DblFaultTssSel
	mov	es, GdtSeg
	mov	eax, TssBase			; Already adjusted!
	add	eax, offset DoubleFaultTss

	mov	(Descriptor386 PTR es:[si]).BaseLow, ax
	ror	eax, 16
	mov	(Descriptor386 PTR es:[si]).BaseHigh24, al
	mov	(Descriptor386 PTR es:[si]).BaseHigh32, ah

; Set SysPdb in CR3 field in double fault TSS.
	mov	ax, TSS
	mov	es, ax
	mov	eax, SysPdb
	mov	es:DoubleFaultTss.rCr3, eax

; Adjust exception traps.
	mov	eax, ExcTrapsList
	sub	eax, ecx
	or	eax, OS_BASE
	mov	ExcTrapsList, eax
to_ret:
	pop	es
	ret
SetupPageTables	ENDP


;-----------------------------------------------------------------------------
;
;	Sets up TSS in GDT.
;
;	There are two TSSes. Task switches will be done in software. One TSS
; is kept to do cross-privilege level control tranfers and the second - to
; do double fault handling.
;
;-----------------------------------------------------------------------------
SetupTss	PROC	USES es
	mov	eax, TSS
PUSHCONTEXT	ASSUMES
ASSUME	ES:TSS

	mov	TssSeg, ax
	mov	es, ax
	shl	eax, 4
	mov	TssBase, eax
	mov	OrigTssBase, eax

; Set TSS entry in GDT.
	mov	ecx, FULL_TSS_SIZE - 1
	mov	dx, TSS386_ACCESS
	call	AddGdtSegment
	mov	TssSel, ax

; Zero defined part of general TSS.
	sub	di, di
	sub	eax, eax
	mov	cx, TSS386_SIZE / 4
		rep	stos dword ptr es:[di]

; Set level 0 stack.
	mov	GeneralTss.Esp0, EXC_STK
	mov	GeneralTss.Ss0, INIT_SS
; Set I/O permition bitmap base.
	mov	GeneralTss.IoTableBase, IO_PERM_START
; Enable access to ports.
	mov	di, offset IoPermTable
	sub	eax, eax
	mov	cx, IO_PERM_SIZE / 4
	cld
		rep	stos dword ptr es:[di]

; Zero defined part of double fault TSS.
	mov	di, offset DoubleFaultTss
	sub	eax, eax
	mov	cx, TSS386_SIZE / 4
		rep	stos dword ptr es:[di]

; Set double fault TSS entry in GDT.
	mov	eax, TssBase
	add	eax, offset DoubleFaultTss

	mov	ecx, TSS386_SIZE
	mov	dx, TSS386_ACCESS
	call	AddGdtSegment
	mov	DblFaultTssSel, ax

	mov	ds:DoubleFaultEntry.DestSel, ax

; Set double fault SS:ESP.
	mov	DoubleFaultTss.rEsp, EXC_STK
	mov	DoubleFaultTss.rSs, INIT_SS

; Set double fault CS:EIP.
	mov	DoubleFaultTss.rCs, CODE_32

	mov	DoubleFaultTss.rEip, offset DoubleFault

; Set DS, ES
	mov	DoubleFaultTss.rDs, INIT_DS
	mov	DoubleFaultTss.rEs, INIT_DS

; Set ES, FS, GS.
	mov	DoubleFaultTss.rFs, FLAT_DS
	mov	DoubleFaultTss.rGs, FLAT_DS

; Set eflags.
	mov	DoubleFaultTss.rEflags, 0

; Set I/O permition bitmap base.
	mov	DoubleFaultTss.IoTableBase, IO_PERM_START

POPCONTEXT	ASSUMES
	ret
SetupTss	ENDP


;-----------------------------------------------------------------------------
;
;	Initializes CPU in protected mode.
;
;-----------------------------------------------------------------------------
SetPm		PROC
; Init PIC for protmode.
	mov	ah, PM_IRQ0
	mov	dx, PIC_MASTER
	call	InitPIC
	mov	ah, PM_IRQ8
	mov	dx, PIC_SLAVE
	call	InitPIC
; Clear nested task flag (!)
	pushf
	pop	ax
	and	ax, NOT FL_NT
	push	ax
	popf
; Load GDTR
	push	es
	mov	es, GdtSeg
	lgdt	fword ptr es:[0]
	pop	es
; Setup IDT
	call	SetupIdt
; Load CR3 (PDBR).
	mov	eax, SysPdbLin
	mov	PdbLin, eax
	mov	eax, SysPagesCtl
	mov	PagesCtl, eax
	mov	eax, SysPdb
	mov	Pdb, eax
	mov	cr3, eax
; Set protected mode with paging.
	mov	eax, cr0
	or	eax, CR0_PE OR CR0_PG
	mov	cr0, eax
; Clear prefetch queue (?)
	JmpFar	INIT_CS, offset pm_entry
pm_entry::
; Setup segment registers.
	mov	ax, INIT_DS
	mov	ds, ax
	mov	es, ax
	mov	ss, InitStkSel
	mov	ax, FLAT_DS
	mov	fs, ax
	mov	gs, ax
; Load task register.
	mov	ax, TssSel
	ltr	ax
; Reload GDT.
	sgdt	fword ptr TempGdt
	mov	eax, OsStartPage
	sub	TempGdt.Base, eax
	or	TempGdt.Base, OS_BASE

	mov	eax, TempGdt.Base
	mov	GdtBase, eax		; Save new GDT base address.

		DB	66h
	lgdt	fword ptr TempGdt	; Use 48-bit, not 40-bit form.
; Reload IDT
	sidt	fword ptr TempIdt
	mov	eax, OsStartPage
	sub	TempIdt.Base, eax
	or	TempIdt.Base, OS_BASE
	
		DB	66h
	lidt	fword ptr TempIdt      ; Use 48-bit, not 40-bit form.
	ret
SetPm		ENDP


;-----------------------------------------------------------------------------
;
;	Returns to real mode.
;
;-----------------------------------------------------------------------------
SetRm		PROC

; Reset SS to have ATTR_DEF = 0.
	mov	eax, GdtBase
	sub	ecx, ecx
	mov	cx, ss
	and	ecx, NOT 7
	and	(Descriptor386 PTR fs:[eax][ecx]).LimitHigh20, NOT FLAT_ATTR
	mov	ax, ss
	mov	ss, ax

IF 1
; Set code segment in area mapped 1-to-1.
	mov	ax, FLAT_DS
	mov	es, ax
	mov	eax, GdtBase
	add	eax, INIT_CS
	mov	cl, (Descriptor386 PTR es:[eax]).BaseHigh24
	mov	ch, (Descriptor386 PTR es:[eax]).BaseHigh32
	shl	ecx, 16
	mov	cx, (Descriptor386 PTR es:[eax]).BaseLow
	and	ecx, NOT OS_BASE
	add	ecx, OsStartPage
	mov	(Descriptor386 PTR es:[eax]).BaseLow, cx
	shr	ecx, 16
	mov	(Descriptor386 PTR es:[eax]).BaseHigh24, cl
	mov	(Descriptor386 PTR es:[eax]).BaseHigh32, ch

	push	cs
	push	offset start_in1to1
	retf

start_in1to1:
ENDIF

; Set segment registers to 16-bit segments.
	mov	ax, INIT_DS
	mov	ds, ax
	mov	es, ax
	sub	ax, ax
	mov	fs, ax
	mov	gs, ax

; Init PIC for real mode.
	mov	ah, 8h
	mov	dx, PIC_MASTER
	call	InitPIC
	mov	ah, 70h
	mov	dx, PIC_SLAVE
	call	InitPIC

	sub	al, al
	out	21h, al			; Enable interrupts
	out	0A1h, al

; Set RM GDT.
;	sub	eax, eax
;	mov	TempGdt.Base, eax
;	mov	TempGdt.Limit, ax
;		DB	66h
;	lgdt	fword ptr TempGdt
; Set IDT to real mode IDT

		DB	66h
	lidt	fword ptr RmIdt		; Use 48-bit, not 40-bit form.

; Set real mode.
	mov	eax, cr0
	and	eax, NOT (CR0_PE OR CR0_PG)
	mov	cr0, eax
; Clear prefetch queue (?)

	JmpFar	CODE, rm_entry
rm_entry::

; Set DS, ES and SS to initial values. FS = GS = 0.
	mov	ax, DATA
	mov	ds, ax
	mov	es, ax
	mov	ax, STK
	mov	ss, ax
	sub	ax, ax
;	mov	fs, ax
	mov	gs, ax

	ret
SetRm		ENDP


;-----------------------------------------------------------------------------
;
;	I:  ErrLvl value (global var.)
;	O:  Displays message with error no. and exits
;
;	Generic init. error handler.
;
;-----------------------------------------------------------------------------
PUBLIC	InitErrHandler
InitErrHandler	PROC	near
	push	ds
	pop	es
; Print "Error ".
	mov	si, offset ErrStr
	call	PrintString
; Print error level.
	mov	bx, ErrLvl
	dec	bx
	imul	bx, bx, SIZEOF (INIT_ERROR)
	mov	ax, InitErrors[bx].Level
	mov	di, offset Field
	call	Hex16ToA
	mov	si, di
	call	PrintString
; Print error message.
	mov	si, InitErrors[bx].Msg
	call	PrintString
; Exit wih errorlevel = init (err) level MOD 256.
	mov	ah, 4Ch
	mov	al, byte ptr ErrLvl
	int	21h
InitErrHandler	ENDP


;-----------------------------------------------------------------------------
;
;  I:	nothing
;  O:	AX = CPU type
;	AL = 0	-	8086/88 (compat.)
;	AL = 1	-	80186/88 (compat.)
;	AL = 2	-	80286
;	AL = 3	-	80386
;	AL = 4	-	80486
;	AL = 5	-	Pentium
;	AL = 6	-	P6
;	AL > 6	-	CPUID capable CPUs.
;
;	Retrevies the CPU type.
;	AH may contain the sub-model (for CPUID supporting processors).
;    
;-----------------------------------------------------------------------------
CpuType		PROC	near
	push	bp
	mov	bp, sp
	sub	sp, 4		; For variables.

	push	sp		; CPU before 286 should first decrease SP
	pop	ax		; and then put the value on stack (BUG).
	cmp	ax, sp
	je	hi186
	;
	; CPU is below 286. Now determine whether it's 86 or 186.
	;
	mov	ax, 1		; Assume CPU is 186.
	push	cx
	mov	cl, 80h		; 8086/88 uses all 8 bits of CL for shift
	shr	ax, cl		; while higher CPUs use only 5 bits.
	pop	cx		; So if CPU is 8086/88, AL becomes 0.
	jmp	to_ret
hi186:
	pushf
	pop	ax
	mov	cx, ax
	xor	ch, 70h		; 80286 doesn't allow to set FLAGS bits
	push	cx		; 12 - 14 via POPF.
	popf
	pushf
	pop	cx
	cmp	ax, cx
	mov	ax, 2
	jz	to_ret
	;
	; CPU is 80386+. Here it's safe to use 386 instructions.
	;
	push	eax		; Save 32-bit registers.
	push	ecx
	pushfd
	pop	eax
	xor	eax, 40000h	; Try to toggle AC bit of EFLAGS (object-alignment
	push	eax		; cause exception). This flag is defined on
	popfd			; 80486+, so it won't be set on 386.
	pushfd
	pop	ecx
	xor	eax, ecx	; If EAX != ECX, AC bit hasn't been toggled
	pop	ecx		; and processor is 386.
	pop	eax
	mov	ax, 3
	jnz	to_ret
	;
	; Processor is 80486+.
	;
	push	eax
	push	ecx
	pushfd
	pop	eax
	xor	eax, 200000h	; Try to toggle ID bit of EFLAGS (CPUID instr.
	push	eax		; support). If it can be toggled, then
	popfd			; processor supports CPUID instruction
	pushfd
	pop	ecx
	xor	eax, ecx	; If EAX != ECX, ID bit hasn't been toggled
	pop	ecx		; and processor is 486.
	pop	eax
	mov	ax, 4
	jnz	to_ret
	;
	; Processor supports CPUID. 'Cause some latest models of 80486 do
	; support the CPUID instruction and future processors would probably
	; also do that, issue this instruction will determine the processor
	; correctly at last.
	;
	and	eax, 0FFFF0000h
	mov	[bp-4], eax
	push	ebx
	push	ecx
	push	edx
	sub	eax, eax

	CPUID			; with EAX = 0, CPUID returns the higher
				; function number in EAX that is supported.
	mov	eax, 1
	CPUID			; Issue this function.
				; AH has the exact value of CPU identification.
	xchg	al, ah
	mov	[bp-4], ax	; Store the correct value of AX.
	pop	edx		
	pop	ecx
	pop	ebx
	mov	eax, [bp-4]	; AL contains the CPU id.
to_ret:
	mov	sp, bp
	pop	bp
	ret
CpuType		ENDP


;-----------------------------------------------------------------------------
;
;	O: EAX = number of pages of memory above 1 M.
;
;	Determines size of extended memory. Uses BIOSes INT 15h services to
; return extended memory size.
;
;-----------------------------------------------------------------------------
BiosGetMemSize	PROC	USES es ebx ecx edx di

; Try INT 15h, AX = E820.
	mov	eax, 0E820h
	sub	ebx, ebx
	mov	ecx, 20
	mov	edx, 'SMAP'
	mov	di, DATA
	mov	es, di
	mov	di, offset BiosMemBuf
	int	15h
	cmp	eax, 'SMAP'
	jne	no_e820

loop_e820:
	add	di, cx
	test	ebx, ebx
	jz	get_e820
	mov	cx, 20
	mov	eax, 0E820h
	int	15h
	jmp	loop_e820

get_e820:
	sub	di, offset BiosMemBuf
	mov	BiosMemBufLen, di

; Calculate memory from info returned by INT 15 / AX = E820.
	sub	eax, eax
	sub	di, di

calc_e820:
	cmp	dword ptr BiosMemBuf[ di ], 100000h
	jb	@F
	cmp	dword ptr BiosMemBuf[ di ][ 16 ], 1
	jne	@F
	add	eax, dword ptr BiosMemBuf[ di ][ 8 ]
@@:
	add	di, 20
	cmp	di, BiosMemBufLen
	jb	calc_e820

ret_e820:
	shr	eax, 12
	ret

no_e820:

; Try INT 15h / AX = E801
	mov	ax, 0E801h
	int	15h
	jc	no_e801

; Calculate extended memory size.
	test	ax, ax
	jnz	use_ax_bx
	test	bx, bx
	jnz	use_ax_bx
	mov	ax, cx
	mov	bx, dx

use_ax_bx:
	and	eax, 0FFFFh
	and	ebx, 0FFFFh
	shr	eax, 2
	shl	ebx, 4
	add	eax, ebx
	ret

no_e801:

; An old system, try INT 15h / AH = 88h. If >64M memory installed, will not
; report correctly. Also some systems were ovserved not to return CF
; correctly.
	clc				; Some systems preserve carry flag.
	mov	ah, 88h
	int	15h
	jc	no_88
	and	eax, 0FFFFh
	shr	eax, 2
	ret
no_88:
	sub	eax, eax
	ret

BiosGetMemSize	ENDP


;-----------------------------------------------------------------------------
;
;	O: EAX = number of pages of memory above 1 M.
;
;	Determines size of extended memory.
;
;	(!) Interrupts must be off on entry.
;	(!) A20 line must be enabled.
;
;-----------------------------------------------------------------------------
PmGetMemSize	PROC	near USES fs ecx edx esi
	;
	; Switch to protected mode with no paging.
	;
; Load GDTR
	mov	fs, GdtSeg
	lgdt	fword ptr fs:[0]
; Switch to protmode
	mov	eax, cr0
	or	eax, CR0_PE OR CR0_CD	; Disable caching.
	mov	cr0, eax
	wbinvd
	jmp	@F
@@:
	;
	; Test first byte of each 4 Kb page: read, not byte, write, then 
	; read again If two read bytes are equal then this 4 Kb of memory is 
	; not present, finish.
	;
	mov	fs, FlatDataSel

	mov	esi, 100000h
	sub	eax, eax
test_mem_loop:
; Dummy read from address 0 for not fully terminated buses.
	mov	ch, fs:[0]

	mov	cl, fs:[esi]
	mov	ch, cl
	not	ch
	mov	fs:[esi], ch

; Dummy read from address 0 for not fully terminated buses.
	mov	ch, fs:[0]

	mov	ch, fs:[esi]
	cmp	cl, ch
	mov	fs:[esi], cl
	je	end_test_mem

	inc	eax

cmp	eax, 1000000h SHR 12
jnb	end_test_mem

	;
	; This check is applied for boards that disable some address lines.
	; Each time the new address line is used, the memory found "present" 
	; is checked VS memory at address 00000000.
	;
	lea	edx, [esi-1000h]

; If new Addr. line is not used, go on
	test	edx, esi
	jnz	mem_rotate_checked

	mov	cl, fs:[esi]
	mov	ch, fs:[0]
	cmp	cl, ch
	jne	mem_rotate_checked

	mov	ch, cl
	not	cl
	mov	fs:[esi], cl
	cmp	cl, fs:[0]
	mov	fs:[esi], ch
	je	end_test_mem

mem_rotate_checked:
	add	esi, 1000h
	jnc	test_mem_loop
end_test_mem:
	;
	; Switch back to real mode.
	;
	mov	ecx, cr0
        and     ecx, NOT (CR0_PE OR CR0_CD)     ; Enable caching
	mov	cr0, ecx
	jmp	@F
@@:

	ret
PmGetMemSize	ENDP


;-----------------------------------------------------------------------------
;
;	O: AX = segment address for DPMI service page (unused 8K).
;
;-----------------------------------------------------------------------------
FindDpmiSrvPage	PROC	USES es si
	mov	si, 0C000h

skip_bioses:
	mov	es, si
	sub	si, si
	cmp	word ptr es:[si], 0AA55h
	je	skip
	cmp	word ptr es:[si+800h], 0AA55h
	je	skip
	cmp	word ptr es:[si+1000], 0AA55h
	je	skip
	cmp	word ptr es:[si+1800h], 0AA55h
	je	skip

	mov	ax, es
	clc
	ret
	
skip:
	mov	si, es
	add	si, 1000h
	cmp	si, 0F000h
	jb	skip_bioses

	stc
	ret
FindDpmiSrvPage	ENDP


CODE	ENDS


	EXTRN	AllocPage: near32
	EXTRN	MapPage: near32
	EXTRN	PmWriteStr32: near32

IFDEF	DEBUG_BUILD
	EXTRN	InitDbg: near32
ENDIF	; DEBUG_BUILD

	EXTRN	InitCore: near32
	EXTRN	AddExcTrap: near32
	EXTRN	ExcRedirect: near32
	EXTRN	InitPIT: near32
	EXTRN	InitCom1: near32
	EXTRN	WriteLog: near32

	EXTRN	DoubleFault: near32

	EXTRN	KeyReady: byte
	EXTRN	KeyPressed: byte

	EXTRN	VBufTextSel: WORD

CODE32	SEGMENT	PARA	PUBLIC	USE32	'CODE'
ASSUME	CS:CODE32, DS:FLAT
Start32::

	mov	Start32Esp, esp

IFDEF	DEBUG_BUILD
	call	InitDbg
ENDIF	; DEBUG_BUILD

; Initialize V86 mode GP emulation. Set ExcRedirect callback.
	mov	eax, 0Dh	; Trap #GP.
	mov	ecx, offset ExcRedirect
	call	AddExcTrap

; Initialize system core.
	call	InitCore

; Initialize PIT.
	push	edx
	mov	eax, PIT_FREQUENCY
	sub	edx, edx
	div	TickToSec
	pop	edx
	sub	bl, bl
	call	InitPIT

IFDEF	DEBUG_BUILD
; Initialize COM1.
	call	InitCom1
	mov	esi, offset LogStartMsg
	mov	ecx, LOG_START_MSG_L
	call	WriteLog
ENDIF

EXTRN	core_start: near32
	jmp	core_start
PUBLIC	end_pmode
end_pmode:
; Reinitialize PIT for real-mode values (counter 0).
	sub	eax, eax
	sub	bl, bl
	call	InitPIT

	JmpFar_32_16	INIT_CS, offset Start16

CODE32	ENDS


END	Init
