head	0.53;
access;
symbols;
locks
	BlackPhantom:0.53
	BlackPhantom:0.43; strict;
comment	@;; @;


0.53
date	2002.05.12.23.10.02;	author BlackPhantom;	state Exp;
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
date	2001.01.19.19.22.34;	author BlackPhantom;	state Exp;
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
next	;


desc
@XMS 3.0 server.
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
;				XMS.ASM
;				-------
;
;	XMS server for Tripple-DOS. Conforms to XMS specification 3.0. XMS 
; memory allocation functions are front ends to DPMI memory allocation
; functions.
;
;	For MASM v6.1x.
;
;=============================================================================

.486p

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

	EXTRN	CurrTaskPtr: dword

	EXTRN	Field: byte

	EXTRN	LeftFreePages: near32
	EXTRN	AllocDPMIMem: near32
	EXTRN	FreeDPMIMem: near32
	EXTRN	PointerToLinear: near32
	EXTRN	WriteLog: near32
	EXTRN	PmHex16ToA: near32

	INCLUDE		TASKMAN.INC
	INCLUDE		DPMI.INC


XmemMovStruct	STRUC
	Len		DD	?
	SrcHandle	DW	?
	SrcOffs		DD	?
	DestHandle	DW	?
	DestOffs	DD	?
XmemMovStruct	ENDS


DATA	SEGMENT	PARA	PUBLIC	USE16	'DATA'

	XmsFunctions	DD	0, 1, 2, 3, 7, 8, 9, 0Ah, 0Bh
			DD	88h, 89h

XMS_FUNCTIONS	EQU	($ - offset XmsFunctions) / 4

	XmsHandlers	DD	offset GetXmsVersion
			DD	offset RequestHMA, offset ReleaseHMA
			DD	offset GlobalA20Enable
			DD	offset QueryA20, offset QueryXMem
			DD	offset AllocXMem, offset FreeXMem
			DD	offset MoveXMem
			DD	offset QueryXmem32, offset AllocXMem32

IFDEF	LOG_DPMI
	GetXmsVerStr	DB	"GetXmsVersion: "
	ReqHMAStr	DB	"RequestHMA: "
	RelHMAStr	DB	"ReleaseHMA: "
	GlobA20EnStr	DB	"GlobalA20Enable: "
	QueryA20Str	DB	"QueryA20: "
	QueryXMemStr	DB	"QueryXMem: "
	AllocXMemStr	DB	"AllocXmem: "
	FreeXMemStr	DB	"FreeXMem: "
	MoveXMemStr	DB	"MoveXMem: "
	QueryXMem32Str	DB	"QueryXMem32: "
	AllocXMem32Str	DB	"AllocXmem32: "
	UnsupportStr	DB	"Unsupported: "
ENDIF	; LOG_DPMI

DATA	ENDS


CODE32	SEGMENT	PARA	PUBLIC	USE32	'CODE'
ASSUME	CS:CODE32, DS:FLAT

;-----------------------------------------------------------------------------
;
;	XMS server entry point. Called by invalid opcode handler.
;
;-----------------------------------------------------------------------------
PUBLIC	XmsEntry
XmsEntry	PROC

; Emulate RETF.
	mov	si, ExcSs
	mov	edi, ExcEsp
	mov	ebx, ExcEflags
	call	PointerToLinear

	movzx	edx, word ptr fs:[eax]
	mov	ExcOffs, edx
	mov	dx, fs:[eax][2]
	mov	ExcSeg, dx
	add	ExcEsp, 4

; Look for requested function in XMS functions list.
	mov	edi, offset XmsFunctions
	movzx	eax, byte ptr ExcEax[1]		; Get function number from AH.
	mov	ecx, XMS_FUNCTIONS
	cld
		repne	scasd
	jne	not_implemented

; Jump to handler.
	not	ecx
	jmp	XmsHandlers[ ecx * 4 + XMS_FUNCTIONS * 4 ]

GetXmsVersion::
IFDEF	LOG_DPMI
	pushad
	PRINT_LOG	GetXmsVerStr
	popad
ENDIF
	mov	word ptr ExcEax, 0300h		; XMS version 3.00
	mov	word ptr ExcEbx, 0100h		; Driver version 1.00
	mov	word ptr ExcEdx, 1		; HMA exists
	clc
	ret

RequestHMA::
IFDEF	LOG_DPMI
	pushad
	PRINT_LOG	ReqHMAStr
	popad
ENDIF
; If HMA is not available, return error.
	mov	eax, CurrTaskPtr
	cmp	(DosTask PTR fs:[eax]).XmsHmaFlag, 0
	je	@@F

	mov	word ptr ExcEax, 1
	clc
	ret

@@@@:
	mov	word ptr ExcEax, 0		; Error
	mov	byte ptr ExcEbx, 91h		; Reason: HMA is busy
	clc
	ret
	
ReleaseHMA::
IFDEF	LOG_DPMI
	pushad
	PRINT_LOG	RelHMAStr
	popad
ENDIF
; If HMA is available, return error.
	mov	eax, CurrTaskPtr
	cmp	(DosTask PTR fs:[eax]).XmsHmaFlag, 0
	jne	@@F

	mov	word ptr ExcEax, 0		; Error
	mov	byte ptr ExcEbx, 93h		; Reason: HMA was not allocated
	clc
	ret

@@@@:
	mov	word ptr ExcEax, 1
	clc
	ret

GlobalA20Enable::
IFDEF	LOG_DPMI
	pushad
	PRINT_LOG	GlobA20EnStr
	popad
ENDIF
	mov	word ptr ExcEax, 1		; A20 is enabled.
	clc
	ret

QueryA20::
IFDEF	LOG_DPMI
	pushad
	PRINT_LOG	QueryA20Str
	popad
ENDIF
; Always return true.
	mov	word ptr ExcEax, 1		; A20 is enabled.
	mov	byte ptr ExcEbx, 0		; Success.
	clc
	ret

QueryXMem::
IFDEF	LOG_DPMI
	pushad
	PRINT_LOG	QueryXMemStr
	popad
ENDIF
	call	LeftFreePages
	test	eax, eax
	jz	no_free_xms

; Record information.
	shl	eax, 2				; Convert pages -> kb.
	mov	word ptr ExcEdx, ax		; Total extended memory.
	mov	word ptr ExcEax, ax		; Largest available block
	clc
	ret

; Extended memory has exhausted.
no_free_xms:
	mov	word ptr ExcEax, 0		; 0 kbytes largest block.
	mov	word ptr ExcEdx, 0		; 0 kbytes available at all.
	mov	byte ptr ExcEbx, 0A0h		; All Xmem is allocated.
	clc
	ret
	
AllocXMem::
IFDEF	LOG_DPMI
	pushad
	PRINT_LOG	AllocXMemStr
	popad
ENDIF
	mov	eax, ExcEdx
	and	eax, 0FFFFh
	shl	eax, 10
	call	AllocDPMIMem
	jc	no_free_xms			; Doesn't report all handles in use.

; Return handle.
	mov	word ptr ExcEax, 1		; Success
	mov	word ptr ExcEdx, ax		; Handle
	clc
	ret

FreeXMem::
IFDEF	LOG_DPMI
	pushad
	PRINT_LOG	FreeXMemStr
	popad
ENDIF
	mov	eax, ExcEdx
	and	eax, 0FFFFh
	call	FreeDPMIMem
	jnc	xmem_freed

; Error, handle is invalid.
	mov	word ptr ExcEax, 0		; Error
	mov	byte ptr ExcEbx, 0A2h		; Invalid handle
	clc
	ret

xmem_freed:
	mov	word ptr ExcEax, 1		; Success
	clc
	ret

MoveXMem::
IFDEF	LOG_DPMI
	pushad
	PRINT_LOG	MoveXMemStr
	popad
ENDIF
; Get pointer to XMEM move structure.
	mov	si, ExcDs
	movzx	edi, word ptr ExcEsi
	mov	ebx, ExcEflags
	call	PointerToLinear
	mov	ebp, eax

; Get source address in ECX.
	cmp	(XmemMovStruct PTR fs:[ebp]).SrcHandle, 0
	jne	src_addr_from_handle

	mov	si, word ptr (XmemMovStruct PTR fs:[ebp]).SrcOffs[2]
	movzx	edi, word ptr (XmemMovStruct PTR fs:[ebp]).SrcOffs
	mov	ebx, ExcEflags
	call	PointerToLinear
	mov	ecx, eax
	jmp	@@F

src_addr_from_handle:
	movzx	esi, (XmemMovStruct PTR fs:[ebp]).SrcHandle
	and	esi, NOT 8000h		; Form an offset from handle.
	mov	edi, CurrTaskPtr
	add	esi, (DosTask PTR fs:[edi]).DpmiMemDescrArr
	mov	ecx, (DpmiMemDescr PTR fs:[esi]).BlockAddress
	add	ecx, (XmemMovStruct PTR fs:[ebp]).SrcOffs

@@@@:
; Get dest address in EDX.
	cmp	(XmemMovStruct PTR fs:[ebp]).DestHandle, 0
	jne	dest_addr_from_handle

	mov	si, word ptr (XmemMovStruct PTR fs:[ebp]).DestOffs[2]
	movzx	edi, word ptr (XmemMovStruct PTR fs:[ebp]).DestOffs
	mov	ebx, ExcEflags
	call	PointerToLinear
	mov	edx, eax
	jmp	@@F

dest_addr_from_handle:
	movzx	esi, (XmemMovStruct PTR fs:[ebp]).DestHandle
	and	esi, NOT 8000h		; Form an offset from handle.
	mov	edi, CurrTaskPtr
	add	esi, (DosTask PTR fs:[edi]).DpmiMemDescrArr
	mov	edx, (DpmiMemDescr PTR fs:[esi]).BlockAddress
	add	edx, (XmemMovStruct PTR fs:[ebp]).DestOffs

@@@@:
; Move block. Try to make it faster.
	push	es
	push	fs
	pop	es

	cld
	mov	esi, ecx
	mov	edi, edx
	mov	ecx, (XmemMovStruct PTR fs:[ebp]).Len
	push	ecx
	shr	ecx, 2
		rep	movs dword ptr es:[edi], fs:[esi]
	pop	ecx
	and	ecx, 3
		rep	movs byte ptr es:[edi], fs:[esi]

	pop	es

; Function succeeded.
	mov	word ptr ExcEax, 1		; Function succeeded.
	clc
	ret

QueryXmem32::
IFDEF	LOG_DPMI
	pushad
	PRINT_LOG	QueryXMem32Str
	popad
ENDIF
	mov	ExcEcx, 0FFFFFFFFh		; Highest possible address.
	call	LeftFreePages
	test	eax, eax
	jz	no_free_xms32

; Record information.
	shl	eax, 2				; Convert pages -> kb.
	mov	ExcEdx, eax			; Total extended memory.
	mov	ExcEax, eax			; Largest available block
	clc
	ret

; Extended memory has exhausted.
no_free_xms32:
	mov	ExcEax, 0			; 0 kbytes largest block.
	mov	ExcEdx, 0			; 0 kbytes available at all.
	mov	byte ptr ExcEbx, 0A0h		; All Xmem is allocated.
	clc
	ret
	
AllocXMem32::
IFDEF	LOG_DPMI
	pushad
	PRINT_LOG	AllocXMem32Str
	popad
ENDIF
	mov	eax, ExcEdx			; Takes a 32-bit number of Kb.
	shl	eax, 10
	call	AllocDPMIMem
	jc	no_free_xms			; Doesn't report all handles in use.

; Return handle.
	mov	word ptr ExcEax, 1		; Success
	mov	word ptr ExcEdx, ax		; Handle
	clc
	ret

not_implemented:
IFDEF	LOG_DPMI
	pushad
	PRINT_LOG	GetXmsVerStr
	mov	ax, word ptr ExcEax
	mov	edi, offset Field
	call	PmHex16ToA
	mov	Field[4], 13
	mov	Field[5], 10
	mov	esi, offset Field
	call	WriteLog
	popad
ENDIF
	mov	word ptr ExcEax, 0		; Function fail
	mov	byte ptr ExcEbx, 80h		; Reason: not implemented
	clc
	ret

XmsEntry	ENDP


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
@@


0.50
log
@Fixed HDD/FDD synchronization problem (trapped opcodes were overwriting each other).
@
text
@@


0.49
log
@Fixes version includes:
1) variable mapping of DPMI service pages at C0000, D0000, E0000 instead of a hardcoded address.
2) added 2 32-bit XMS functions and XMS service table is fixed.
3) detection and diagnostic is improved.
@
text
@@


0.48
log
@Enabled XMS 3.0 inteface
@
text
@d78 2
a79 1
	XmsFunctions	DD	0, 1, 2, 3, 7, 8, 9, 0Ah, 0Bh, 0Ch, 0Dh, 0Eh, 0Fh
d89 1
d101 2
d315 1
d335 1
d358 43
@


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
@a228 6
	cmp	eax, 1000h			; If not less than 4 M, cut
						; the largest block.
	jb	@@F
	mov	eax, 0FFFh

@@@@:
@


0.44
log
@Bug fixes:
1) Checks for open file name (EDX to DX) problem
2) Reporting of the protected mode exception reboot
@
text
@d3 19
d25 3
a27 2
;	XMS server for MULTIX32. Conforms to XMS specification 3.0. XMS memory
; allocation functions are front ends to DPMI memory allocation functions.
a61 2
	EXTRN	EmulateRetf: near32

d117 10
a126 1
	call	EmulateRetf
d364 1
a364 1
	PRINT_LOG	UnsupportStr
@


0.43
log
@Bug fixes:
1) Lower word in translation structure on real mode stack was being destroyed - very annoying.
2) Saved exception number was moved to task structure to allow multiple DPMI tasks work.
3 copies of WCC386 worked!
@
text
@d42 2
d99 1
a99 10
	mov	si, ExcSs
	mov	edi, ExcEsp
	mov	ebx, ExcEflags
	call	PointerToLinear

	movzx	edx, word ptr fs:[eax]
	mov	ExcOffs, edx
	mov	dx, fs:[eax][2]
	mov	ExcSeg, dx
	add	ExcEsp, 4
d337 1
a337 1
	PRINT_LOG	GetXmsVerStr
@


0.42
log
@1) Added XMS server
2) Memory allocation / deallocation is moved to task creation / deletion
@
text
@d34 2
d41 1
d79 1
d96 12
d275 1
a275 2
	mov	edi, ExcEsi
	and	edi, 0FFFFh
d293 1
d312 1
d319 4
d329 1
a329 1
		rep	movsd
d332 8
a339 1
		rep	movsb
d342 12
@
