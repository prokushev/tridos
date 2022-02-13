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
;				X86.INC
;				-------
;	General x86 definitions for Tripple-DOS. Contains needed constant 
; definitions and macros.
;
;	For MASM v6.1x.
;
; 	24/08/95
;
;	Black Phantom.
;
;=============================================================================

;-----------------------------------------------------------------------------
;	CPU control registers.
;-----------------------------------------------------------------------------
CR0_PG	EQU	80000000h	; Paging enable
CR0_CD	EQU	40000000h	; Caching disable
CR0_NW	EQU	20000000h	; Non-write through
CR0_PE	EQU	00000001h	; Protection enable (protected mode).

;-----------------------------------------------------------------------------
;	Eflags register.
;-----------------------------------------------------------------------------
FL_VM	EQU	00020000h	; VM flag
FL_NT	EQU	00004000h	; NT flag
FL_CF	EQU	00000001h	; C flag
FL_PF	EQU	00000004h	; P flag
FL_AF	EQU	00000010h	; AC flag
FL_ZF	EQU	00000040h	; Z flag
FL_SF	EQU	00000080h	; S flag
FL_TF	EQU	00000100h	; T flag
FL_IF	EQU	00000200h	; I flag
FL_DF	EQU	00000400h	; D flag
FL_OF	EQU	00000800h	; O flag
FL_RF	EQU	00010000h	; R flag

;
;	Opcodes that generate #GP in VM when IOPL < 3.
;
	OP_INT		EQU	0CDh
	OP_IRET		EQU	0CFh
	OP_CLI		EQU	0FAh
	OP_STI		EQU	0FBh
	OP_PUSHF	EQU	9Ch
	OP_POPF		EQU	9Dh

;
;	I/O opcodes.
;
	OP_IN8_IMM	EQU	0E4h
	OP_IN16_IMM	EQU	0E5h
	OP_IN8_DX	EQU	0ECh
	OP_IN16_DX	EQU	0EDh
	OP_INSB		EQU	6Ch
	OP_INSW		EQU	6Dh
	OP_OUT8_IMM	EQU	0E6h
	OP_OUT16_IMM	EQU	0E7h
	OP_OUT8_DX	EQU	0EEh
	OP_OUT16_DX	EQU	0EFh
	OP_OUTSB	EQU	6Eh
	OP_OUTSW	EQU	6Fh
	OP_OPER_PREFIX	EQU	66h
	OP_ADDR_PREFIX	EQU	67h
	OP_REPNZ_PREFIX	EQU	0F2h
	OP_REPZ_PREFIX	EQU	0F3h
	OP_CS_PREFIX	EQU	2Eh
	OP_SS_PREFIX	EQU	36h
	OP_DS_PREFIX	EQU	3Eh
	OP_ES_PREFIX	EQU	26h
	OP_FS_PREFIX	EQU	64h
	OP_GS_PREFIX	EQU	65h

;
;	DTR structure (GDTR/IDTR).
;
DTR	STRUC
	Limit	DW	?
	Base	DD	?
DTR	ENDS

;
;	Descriptor structure.
;
Descriptor286	STRUCT
	Limit		DW	?
	BaseLow		DW	?
	BaseHigh	DB	?
	Access		DB	?
	Reserved	DW	?
Descriptor286	ENDS

;
;	386 Descriptor structure.
;
Descriptor386	STRUCT
	LimitLow	DW	?
	BaseLow		DW	?
	BaseHigh24	DB	?
	Access		DB	?
	LimitHigh20	DB	?
	BaseHigh32	DB	?
Descriptor386	ENDS

;
;	Interrupt, exception and call gate structure.
;
Gate286		STRUCT
	DestOff		DW	?
	DestSel		DW	?
	NParams		DB	?
	Access		DB	?
	Reserved	DW	?
Gate286		ENDS


;
;	386 Interrupt, exception and call gate structure.
;
Gate386		STRUCT
	DestOff		DW	?
	DestSel		DW	?
	NParams		DB	?
	Access		DB	?
	DestOff32	DW	?
Gate386		ENDS


;
;	286 TSS segment structure.
;
Tss286		STRUCT
	Link		DW	?

	Sp0		DW	?
	Ss0		DW	?
	Sp1		DW	?
	Ss1		DW	?
	Sp2		DW	?
	Ss3		DW	?

	rIp		DW	?
	rFlags		DW	?
	rAx		DW	?
	rCx		DW	?
	rDx		DW	?
	rBx		DW	?
	rSp		DW	?
	rBp		DW	?
	rSi		DW	?
	rDi		DW	?
	rEs		DW	?
	rCs		DW	?
	rSs		DW	?
	rDs		DW	?
	rLdtr		DW	?
Tss286		ENDS

	TSS286_SIZE	EQU	SIZEOF Tss286


;
;	386 TSS segment structure.
;
Tss386		STRUCT
	Link		DW	?
			DW	?
	Esp0		DD	?
	Ss0		DW	?
			DW	?
	Esp1		DD	?
	Ss1		DW	?
			DW	?
	Esp2		DD	?
	Ss2		DW	?
			DW	?

	rCr3		DD	?
	rEip		DD	?
	rEflags		DD	?
	rEax		DD	?
	rEcx		DD	?
	rEdx		DD	?
	rEbx		DD	?
	rEsp		DD	?
	rEbp		DD	?
	rEsi		DD	?
	rEdi		DD	?

	rEs		DW	?
			DW	?
	rCs		DW	?
			DW	?
	rSs		DW	?
			DW	?
	rDs		DW	?
			DW	?
	rFs		DW	?
			DW	?
	rGs		DW	?
			DW	?
	rLdtr		DW	?
			DW	?

	bTrace		DW	?
	IoTableBase	DW	?

Tss386		ENDS

	TSS386_SIZE	EQU	SIZEOF Tss386
	INT_PERM_SIZE	EQU	32
	IO_PERM_SIZE	EQU	8192
	IO_PERM_START	EQU	TSS386_SIZE + INT_PERM_SIZE
	FULL_TSS_SIZE	EQU	TSS386_SIZE + INT_PERM_SIZE + IO_PERM_SIZE

;
;	Constants definition.
;

; Access rights
	ACC_PRESENT		EQU	10000000b
	ACC_CODE		EQU	00011000b
	ACC_CONFORM_CODE	EQU	00000100b
	ACC_READABLE_CODE	EQU	00000010b
	ACC_DATA		EQU	00010000b
	ACC_EXPDOWN_DATA	EQU	00000100b
	ACC_WRITABLE_DATA	EQU	00000010b
	ACC_ACCESSED_SEGMENT	EQU	00000001b
	ACC_INT_GATE		EQU	00000110b
	ACC_CALL_GATE		EQU	00000100b
	ACC_TRAP_GATE		EQU	00000111b
	ACC_INT386_GATE		EQU	00001110b
	ACC_CALL386_GATE	EQU	00001100b
	ACC_TRAP386_GATE	EQU	00001111b
	ACC_TASK_GATE		EQU	00000101b
	ACC_TSS			EQU	00000001b
	ACC_TSS386		EQU	00001001b
	ACC_LDT			EQU	00000010b

; Segment attributes (386+)
	ATTR_DEF		EQU	01000000b	; D/B attr.
	ATTR_GRAN		EQU	10000000b	; Granularity bit.
	FLAT_ATTR		EQU	ATTR_DEF or ATTR_GRAN

; Live segments access rights
	DATA_ACCESS	=	ACC_PRESENT or ACC_DATA or ACC_WRITABLE_DATA
	CODE_ACCESS	=	ACC_PRESENT or ACC_CODE or ACC_READABLE_CODE
	INT_ACCESS	=	ACC_PRESENT or ACC_INT_GATE
	TRAP_ACCESS	=	ACC_PRESENT or ACC_TRAP_GATE
	INT_386_ACCESS	=	ACC_PRESENT or ACC_INT386_GATE
	TRAP_386_ACCESS	=	ACC_PRESENT or ACC_TRAP386_GATE
	TSS_ACCESS	=	ACC_PRESENT or ACC_TSS
	TASK_GATE_ACCESS = 	ACC_PRESENT or ACC_TASK_GATE
	TSS386_ACCESS	=	ACC_PRESENT or ACC_TSS386
	LDT_ACCESS	=	ACC_PRESENT or ACC_LDT

; Page dir/page table entries attributes.
	PAGE_PRESENT	EQU	001h
	PAGE_WRITABLE	EQU	002h
	PAGE_USER	EQU	004h
	PAGE_ACCESSED	EQU	020h
	PAGE_DIRTY	EQU	040h

; Necessary segments.
	INIT_CS		=	08h	; Initial CS seg
	INIT_DS		=	10h	; Initial DS, ES seg
	INIT_SS		=	18h	; Initial SS seg
	FLAT_DS		=	20h	; Flat data segment
	CODE_32		=	28h	; 32-bit code segment
	GENERAL_TSS	=	30h	; TSS for all tasks
	VIDEO_TXT	=	38h	; Text video segment
	VIDEO_GFX	=	40h	; Gfx. video segment

; Linear addresses base.
	OS_BASE		=	40000000h	; OS base linear address.
	OS_VIDEO_BUF	=	60000000h	; Global OS video buffer.
	OS_1ST_MB	=	70000000h	; Global mapping for 1st Mb.
	OS_HEAP		=	80000000h	; OS heap base linear address
	OS_HEAP_SIZE	=	40000000h	; OS heap size.
	OS_DYN_PAGETBLS	=	0C0000000h	; Space for dynamic page tables.

; Stacks definitions.
	STK_SIZE	=	16384	; Total stack size
	EXC_STK		=	15360	; Exception stack (PL0)
	DBG_STK		=	3072	; Debug stack
	VM_STK		=	1024	; Stack for calling VM int. callbacks.

	CPL0_STK_SIZE	=	512	; Stack size for nested interrupts.

; Size & address constants.
	REAL_MODE_LIMIT	EQU	0FFFFh

; Redirected interrupts.
	PM_IRQ0		=	20h	; IDT entry for IRQ 0.
	PM_IRQ8		=	28h	; IDT entry for IRQ 8.


;
; Macro definitions.
;

JmpFar		MACRO Segm:REQ, Offs:REQ
;
; JMP Segm:Offs
;
	DB	0EAh		; machine-code JMP far
	DW	Offs
	DW	Segm
ENDM

CallFar		MACRO	Segm:REQ, Offs:REQ
;
; JMP Segm:Offs
;
	DB	09Ah		; machine-code CALL far
	DW	Offs
	DW	Segm
ENDM

JmpFar_16_32	MACRO	Segm:REQ, Offs:REQ
;
; JMP Segm:Offs from 16-bit to 32-bit segment.
;
	DB	66h
	DB	0EAh		; machine-code JMP far
	DD	Offs
	DW	Segm
ENDM

JmpFar_32_16	MACRO	Segm:REQ, Offs:REQ
;
; JMP Segm:Offs from 32-bit to 16-bit segment.
;
	DB	66h
	DB	0EAh		; machine-code JMP far
	DW	Offs
	DW	Segm
ENDM

CallFar_16_32	MACRO	Segm:REQ, Offs:REQ
;
; CALL Segm:Offs from 16-bit to 32-bit segment.
;
	DB	66h
	DB	9Ah		; machine-code CALL far
	DD	Offs
	DW	Segm
ENDM

CallFar_32_16	MACRO	Segm:REQ, Offs:REQ
;
; CALL Segm:Offs from 32-bit to 16-bit segment.
;
	DB	66h
	DB	9Ah		; machine-code CALL far
	DW	Offs
	DW	Segm
ENDM


;
; Add GDT segment.
;
ADD_GDT_SEGMENT	MACRO	Base, Limit, Access, Attr
IFNB	<Base>
	mov	eax, Base
ENDIF
	mov	ecx, Limit
	mov	dl, Access
IFNB	<Attr>
	mov	dh, Attr
ELSE
	sub	dh, dh
ENDIF
	call	AddGdtSegment
ENDM

;
; CPUID for assembler that doesn't support mnemonic.
;
IF	@Version	LT	611

CPUID		MACRO
	DB	0Fh, 0A2h	; CPUID instruction
ENDM

ENDIF
