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
	je	@F

	mov	word ptr ExcEax, 1
	clc
	ret

@@:
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
	jne	@F

	mov	word ptr ExcEax, 0		; Error
	mov	byte ptr ExcEbx, 93h		; Reason: HMA was not allocated
	clc
	ret

@@:
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
	jmp	@F

src_addr_from_handle:
	movzx	esi, (XmemMovStruct PTR fs:[ebp]).SrcHandle
	and	esi, NOT 8000h		; Form an offset from handle.
	mov	edi, CurrTaskPtr
	add	esi, (DosTask PTR fs:[edi]).DpmiMemDescrArr
	mov	ecx, (DpmiMemDescr PTR fs:[esi]).BlockAddress
	add	ecx, (XmemMovStruct PTR fs:[ebp]).SrcOffs

@@:
; Get dest address in EDX.
	cmp	(XmemMovStruct PTR fs:[ebp]).DestHandle, 0
	jne	dest_addr_from_handle

	mov	si, word ptr (XmemMovStruct PTR fs:[ebp]).DestOffs[2]
	movzx	edi, word ptr (XmemMovStruct PTR fs:[ebp]).DestOffs
	mov	ebx, ExcEflags
	call	PointerToLinear
	mov	edx, eax
	jmp	@F

dest_addr_from_handle:
	movzx	esi, (XmemMovStruct PTR fs:[ebp]).DestHandle
	and	esi, NOT 8000h		; Form an offset from handle.
	mov	edi, CurrTaskPtr
	add	esi, (DosTask PTR fs:[edi]).DpmiMemDescrArr
	mov	edx, (DpmiMemDescr PTR fs:[esi]).BlockAddress
	add	edx, (XmemMovStruct PTR fs:[ebp]).DestOffs

@@:
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
