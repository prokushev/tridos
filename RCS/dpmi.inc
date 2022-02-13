head	0.53;
access;
symbols;
locks
	BlackPhantom:0.50
	BlackPhantom:0.53; strict;
comment	@# @;


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
date	2001.01.19.19.25.00;	author BlackPhantom;	state Exp;
branches;
next	0.48;

0.48
date	2000.12.27.05.37.22;	author BlackPhantom;	state Exp;
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
@DPMI 0.9 server definitions.
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
;				DPMI.INC
;				--------
;
;	DPMI 0.9 server include file.
;
;=============================================================================

;
;	Constants.
;

; DPMI service page address.
DPMI_SERVICE_PAGE	EQU	0D0000h
DPMI_SERVICE_SEG	EQU	0D000h
DPMI_SERVICE_OFFS	EQU	0h

; Address to call for initial switch to protmode.
INIT_SWITCH_SEG		EQU	DPMI_SERVICE_SEG
INIT_SWITCH_OFFS	EQU	DPMI_SERVICE_OFFS + 0h
INIT_SWITCH_ADDR	EQU	(INIT_SWITCH_SEG SHL 4) + INIT_SWITCH_OFFS

; Address to jump for raw PM to VM switch.
PM2VM_SWITCH_OFFS	EQU	DPMI_SERVICE_OFFS + 10h
PM2VM_SWITCH_ADDR	EQU	DPMI_SERVICE_PAGE + 10h

; Address to jump for raw VM to PM switch.
VM2PM_SWITCH_SEG	EQU	DPMI_SERVICE_SEG
VM2PM_SWITCH_OFFS	EQU	DPMI_SERVICE_OFFS + 20h
VM2PM_SWITCH_ADDR	EQU	(VM2PM_SWITCH_SEG SHL 4) + VM2PM_SWITCH_OFFS

; Address that traps return from real mode procedure. Used only by system.
RET_TRAP_SEG		EQU	DPMI_SERVICE_SEG
RET_TRAP_OFFS		EQU	DPMI_SERVICE_OFFS + 30h
RET_TRAP_ADDR		EQU	(RET_TRAP_SEG SHL 4) + RET_TRAP_OFFS

; Address that traps return from redirected exceptions (i.e. when DPMI client
; executes normal RETF).
PM_RET_TRAP_OFFS	EQU	DPMI_SERVICE_OFFS + 40h

; Address used for "default exception handlers" that may be chained by DPMI
; client exception handler. There are 20h exception traps.
PM_DEF_EXC_OFFS		EQU	DPMI_SERVICE_OFFS + 50h

; Address used for "default interrupt handler" that may be chained by DPMI
; client interrupt handler. There are 100h interrupt traps.
PM_DEF_INT_OFFS		EQU	DPMI_SERVICE_OFFS + 250h

; Address that traps return from redirected interrupts - when control must
; be returned to V86 mode.
PM_RET_INT_OFFS		EQU	DPMI_SERVICE_OFFS + 1250h

; Address that traps return from real mode far procs and interrupt procs
; explicitly invoked by protmode client.
XLAT_TRAP_SEG		EQU	DPMI_SERVICE_SEG
XLAT_TRAP_OFFS		EQU	DPMI_SERVICE_OFFS + 1260h
XLAT_TRAP_ADDR		EQU	(XLAT_TRAP_SEG SHL 4) + XLAT_TRAP_OFFS

; Address is used to trap return from allocated callback and transfer control
; back to V86 mode.
CALLBACK_RET_TRAP_OFFS	EQU	DPMI_SERVICE_OFFS + 1270h

; Address used as call to state save in real mode ("save protected mode 
; state"). Points to RETF.
RM_SAVE_STATE_SEG 	EQU	DPMI_SERVICE_SEG
RM_SAVE_STATE_OFFS	EQU	DPMI_SERVICE_OFFS + 1280h

; Address used as call to state save in protected mode ("save real mode 
; state"). Points to RETF.
PM_SAVE_STATE		EQU	DPMI_SERVICE_OFFS + 1290h

; Locked real and protected mode stack that is used during callbacks.
; 8K size (4K for VM, 4K for PM).
VM_LOCKED_SS		EQU	DPMI_SERVICE_SEG
VM_LOCKED_ESP		EQU	DPMI_SERVICE_OFFS + 2FFEh
VM_LOCKED_STACK_BOTTOM	EQU	DPMI_SERVICE_OFFS + 2800h
VM_LOCKED_STACK		EQU	(VM_LOCKED_SS SHL 4) + VM_LOCKED_ESP

PM_LOCKED_ESP		EQU	DPMI_SERVICE_OFFS + 27FCh
PM_LOCKED_STACK_BOTTOM	EQU	DPMI_SERVICE_OFFS + 1800h
PM_LOCKED_STACK		EQU	DPMI_SERVICE_PAGE + 1FFCh

; Locked real and protected mode stack size (for nesting).
LOCKED_STACK_SIZE	EQU	1000h

; Memory information structure. 30h size.
MEM_INFO_STRUCT_ADDR	EQU	DPMI_SERVICE_PAGE + 12A0h
MEM_INFO_STRUCT_LEN	EQU	30h

PM_EXCS			EQU	20h		; Number of PM exceptions.
PM_INTS			EQU	100h		; Number of PM interrupts.

; Windows "vendor API entry point".
WIN_VENDOR_API_ENTRY	EQU	DPMI_SERVICE_OFFS + 12D0h

; XMS API entry point.
XMS_ENTRY_SEG		EQU	DPMI_SERVICE_SEG
XMS_ENTRY_OFFS		EQU	DPMI_SERVICE_OFFS + 12E0h
XMS_ENTRY_ADDR		EQU	(XMS_ENTRY_SEG SHL 4) + XMS_ENTRY_OFFS

; Array of allocatable real mode callbacks.
CALLBACK_SEG		EQU	DPMI_SERVICE_SEG
CALLBACK_OFFS		EQU	DPMI_SERVICE_OFFS + 12F0h	; Start of array.
CALLBACK_ENDOFFS	EQU	DPMI_SERVICE_OFFS + 17F0h	; End of array.
CALLBACK_ADDR		EQU	(CALLBACK_SEG SHL 4) + CALLBACK_OFFS
MAX_DPMI_CALLBACKS	EQU	(CALLBACK_ENDOFFS - CALLBACK_OFFS) / 8	; Maximum number of callbacks per task.

; Barrier on locked stack for saved registers integrity.
LOCKED_STACK_BARRIER	EQU	4


;
;	Structures.
;

; Association of selectors to segments (DOS alloc functions).
DosBlockSel	STRUC
	wSeg	DW	?			; Segment address.
	wSel	DW	?			; First selector.
	wNSels	DW	?			; Numbers of contiguous selectors.
DosBlockSel	ENDS


; Structure for translation services.
XlatStruct	STRUC
	dwEdi	DD	?
	dwEsi	DD	?
	dwEbp	DD	?
	dwBlank	DD	?
	dwEbx	DD	?
	dwEdx	DD	?
	dwEcx	DD	?
	dwEax	DD	?
	wFlags	DW	?
	wEs	DW	?
	wDs	DW	?
	wFs	DW	?
	wGs	DW	?
	wIp	DW	?
	wCs	DW	?
	wSp	DW	?
	wSs	DW	?
XlatStruct	ENDS


; Association of real mode addresses to protected mode addresses to call back.
DpmiCallback	STRUC
	wRmIp		DW	?
	wRmCs		DW	?
	dwPmEip		DD	?
	wPmCs		DW	?
	dwRegsOffs	DD	?
	wRegsSeg	DW	?
DpmiCallback	ENDS


; Memory allocation descriptor.
DpmiMemDescr	STRUC
	BlockAddress	DD	?
	BlockLength	DD	?
DpmiMemDescr	ENDS

; DPMI invalid opcode trap.
DpmiTrap	MACRO	TrapCode:REQ, TrapSubCode
	DW	0FFFEh		; Invalid opcode.
	DD	0		; 0

IFNB <TrapSubCode>
	DB	TrapSubCode
ELSE
	DB	0
ENDIF
	DB	TrapCode

; Reserved field.
	DB	8 DUP (?)
ENDM

; Maximum number of blocks per task.
DPMI_MEM_DESCRIPTORS	=	2048

; Actual LDT size.
LDT_SIZE		=	10000h

; Memory required for each DPMI task.
DPMI_BUF_SIZE		EQU	(PM_INTS + PM_EXCS) * 8 + 1000h * 2 + LDT_SIZE + DPMI_MEM_DESCRIPTORS * SIZEOF DpmiMemDescr + 1

;
;	Macros
;

; Save state regs into alternate save structure.
SAVE_STATE_REGS	MACRO
PUSHCONTEXT	ASSUMES
ASSUME	edx: PTR DpmiState
	mov	eax, ExcOffs
	mov	fs:[edx].dwEip, eax
	mov	eax, ExcEsp
	mov	fs:[edx].dwEsp, eax
	mov	ax, ExcSeg
	mov	fs:[edx].Sregs.wCs, ax
	mov	ax, ExcDs
	mov	fs:[edx].Sregs.wDs, ax
	mov	ax, ExcEs
	mov	fs:[edx].Sregs.wEs, ax
	mov	ax, ExcFs
	mov	fs:[edx].Sregs.wFs, ax
	mov	ax, ExcGs
	mov	fs:[edx].Sregs.wGs, ax
	mov	ax, ExcSs
	mov	fs:[edx].Sregs.wSs, ax
POPCONTEXT	ASSUMES
ENDM


; Restore state regs from alternate save structure.
RESTORE_STATE_REGS	MACRO
PUSHCONTEXT	ASSUMES
ASSUME	edx: PTR DpmiState
	mov	eax, fs:[edx].dwEip
	mov	ExcOffs, eax
	mov	eax, fs:[edx].dwEsp
	mov	ExcEsp, eax
	mov	ax, fs:[edx].Sregs.wCs
	mov	ExcSeg, ax
	mov	ax, fs:[edx].Sregs.wDs
	mov	ExcDs, ax
	mov	ax, fs:[edx].Sregs.wEs
	mov	ExcEs, ax
	mov	ax, fs:[edx].Sregs.wFs
	mov	ExcFs, ax
	mov	ax, fs:[edx].Sregs.wGs
	mov	ExcGs, ax
	mov	ax, fs:[edx].Sregs.wSs
	mov	ExcSs, ax
POPCONTEXT	ASSUMES
ENDM


RESTORE_16BIT_EXC_STACK	MACRO
	mov	edx, CurrTaskPtr
	mov	edx, (DosTask PTR fs:[edx]).DpmiPmStack
	lea	edx, [edx-0Ah]
	movzx	esi, word ptr fs:[edx]
	mov	ExcOffs, esi
 	mov	si, fs:[edx][2]
	mov	ExcSeg, si
	mov	si, fs:[edx][4]
	mov	word ptr VirtualIf, si
	and	VirtualIf, FL_IF		; Update virtualized IF.
	or	si, FL_IF
	mov	word ptr ExcEflags, si
	mov	si, fs:[edx][6]
	mov	word ptr ExcEsp, si
	mov	si, fs:[edx][8]
	mov	word ptr ExcSs, si
ENDM


RESTORE_32BIT_EXC_STACK	MACRO
	mov	edx, CurrTaskPtr
	mov	edx, (DosTask PTR fs:[edx]).DpmiPmStack
	lea	edx, [edx-14h]
	mov	esi, fs:[edx]
	mov	ExcOffs, esi
	mov	esi, fs:[edx][4]
	mov	ExcSeg, si
	mov	esi, fs:[edx][8]
	mov	VirtualIf, esi
	and	VirtualIf, FL_IF		; Update virtualized IF.
	or	esi, FL_IF
	mov	ExcEflags, esi
	mov	esi, fs:[edx][0Ch]
	mov	ExcEsp, esi
	mov	esi, fs:[edx][10h]
	mov	ExcSs, esi
ENDM


LOAD_XLAT_REGS	MACRO	LoadCsIp
PUSHCONTEXT	ASSUMES
ASSUME	eax:PTR XlatStruct
	mov	edx, fs:[eax].dwEax
	mov	ExcEax, edx
	mov	edx, fs:[eax].dwEbx
	mov	ExcEbx, edx
	mov	edx, fs:[eax].dwEcx
	mov	ExcEcx, edx
	mov	edx, fs:[eax].dwEdx
	mov	ExcEdx, edx
	mov	edx, fs:[eax].dwEbp
	mov	ExcEbp, edx
	mov	edx, fs:[eax].dwEsi
	mov	ExcEsi, edx
	mov	edx, fs:[eax].dwEdi
	mov	ExcEdi, edx

	mov	dx, fs:[eax].wFlags
; Set virtual IF accordingly.
	mov	VirtualIf, edx
	and	VirtualIf, FL_IF
; Real IF will always be 1.
	or	edx, FL_IF
	mov	word ptr ExcEflags, dx

	mov	dx, fs:[eax].wDs
	mov	ExcDs, dx
	mov	dx, fs:[eax].wEs
	mov	ExcEs, dx
	mov	dx, fs:[eax].wFs
	mov	ExcFs, dx
	mov	dx, fs:[eax].wFs
	mov	ExcFs, dx

	movzx	edx, fs:[eax].wSp
	mov	ExcEsp, edx
	mov	dx, fs:[eax].wSs
	mov	ExcSs, dx

IFNB	<LoadCsIp>
	movzx	edx, fs:[eax].wIp
	mov	ExcOffs, edx
	mov	dx, fs:[eax].wCs
	mov	ExcSeg, dx
ENDIF

POPCONTEXT	ASSUMES
ENDM


STORE_XLAT_REGS	MACRO
PUSHCONTEXT	ASSUMES
ASSUME	eax:PTR XlatStruct
	mov	edx, ExcEax
	mov	fs:[eax].dwEax, edx
	mov	edx, ExcEbx
	mov	fs:[eax].dwEbx, edx
	mov	edx, ExcEcx
	mov	fs:[eax].dwEcx, edx
	mov	edx, ExcEdx
	mov	fs:[eax].dwEdx, edx
	mov	edx, ExcEbp
	mov	fs:[eax].dwEbp, edx
	mov	edx, ExcEsi
	mov	fs:[eax].dwEsi, edx
	mov	edx, ExcEdi
	mov	fs:[eax].dwEdi, edx

	mov	edx, ExcEflags
; Merge with virtual IF.
	and	edx, NOT FL_IF
	or	edx, VirtualIf
	mov	fs:[eax].wFlags, dx

	mov	dx, ExcDs
	mov	fs:[eax].wDs, dx
	mov	dx, ExcEs
	mov	fs:[eax].wEs, dx
	mov	dx, ExcFs
	mov	fs:[eax].wFs, dx
	mov	dx, ExcGs
	mov	fs:[eax].wGs, dx

;	mov	dx, ExcSs
;	mov	fs:[eax].wSs, dx
;	mov	dx, word ptr ExcEsp
;	mov	fs:[eax].wSp, dx

	mov	dx, ExcSeg
	mov	fs:[eax].wCs, dx
	mov	dx, word ptr ExcOffs
	mov	fs:[eax].wIp, dx
POPCONTEXT	ASSUMES
ENDM


; Save general purpose registers for translation services.
SAVE_GENERAL_REGS	MACRO
PUSHCONTEXT	ASSUMES
ASSUME	edx:PTR GEN_REG_PACK
	mov	eax, ExcEax
	mov	fs:[edx].dwEax, eax
	mov	eax, ExcEbx
	mov	fs:[edx].dwEbx, eax
	mov	eax, ExcEcx
	mov	fs:[edx].dwEcx, eax
	mov	eax, ExcEdx
	mov	fs:[edx].dwEdx, eax
	mov	eax, ExcEbp
	mov	fs:[edx].dwEbp, eax
	mov	eax, ExcEsi
	mov	fs:[edx].dwEsi, eax
	mov	eax, ExcEdi
	mov	fs:[edx].dwEdi, eax
	mov	eax, ExcEflags
	and	eax, NOT FL_IF
	or	eax, VirtualIf
	mov	fs:[edx].dwEflags, eax
POPCONTEXT	ASSUMES
ENDM


; Restore general purpose registers for translation services.
RESTORE_GENERAL_REGS	MACRO
PUSHCONTEXT	ASSUMES
ASSUME	edx:PTR GEN_REG_PACK
	mov	eax, fs:[edx].dwEax
	mov	ExcEax, eax
	mov	eax, fs:[edx].dwEbx
	mov	ExcEbx, eax
	mov	eax, fs:[edx].dwEcx
	mov	ExcEcx, eax
	mov	eax, fs:[edx].dwEdx
	mov	ExcEdx, eax
	mov	eax, fs:[edx].dwEbp
	mov	ExcEbp, eax
	mov	eax, fs:[edx].dwEsi
	mov	ExcEsi, eax
	mov	eax, fs:[edx].dwEdi
	mov	ExcEdi, eax
	mov	eax, fs:[edx].dwEflags
	mov	VirtualIf, eax
	and	VirtualIf, FL_IF
	or	eax, FL_IF
	mov	ExcEflags, eax
POPCONTEXT	ASSUMES
ENDM


; Print log (for debug purposes).
PRINT_LOG	MACRO	LogStr
	mov	esi, offset LogStr
	mov	ecx, SIZEOF LogStr
	call	WriteLog
ENDM


; Calculate checksum (MOD 256). FS:EBX -> start, ECX = length.
; Store right above the checksumed area.
CHECK_SUM	MACRO
LOCAL	chksum_loop
	sub	al, al
chksum_loop:
	add	al, fs:[ebx]
	inc	ebx
	dec	ecx
	jnz	chksum_loop
ENDM


; Data for logging entire state.
DATA	SEGMENT	PARA	PUBLIC	USE16	'DATA'
	LogEaxStr	DB	"EAX="
	LogEbxStr	DB	"EBX="
	LogEcxStr	DB	"ECX="
	LogEdxStr	DB	"EDX="
	LogEsiStr	DB	"ESI="
	LogEdiStr	DB	"EDI="
	LogEbpStr	DB	"EBP="

	LogSsEspStr	DB	"SS:ESP="
	LogCsEipStr	DB	"CS:EIP="

	LogDsStr	DB	"DS="
	LogEsStr	DB	"ES="
	LogFsStr	DB	"FS="
	LogGsStr	DB	"GS="

	LogEflagsStr	DB	"Eflags="
DATA	ENDS


; Helper macro
LOG_REG	MACRO	RegName, Bits
	PRINT_LOG	Log&RegName&Str
	mov	edi, offset Field
IF	Bits EQ	32
	mov	eax, Exc&RegName
ELSE
	mov	ax, word ptr Exc&RegName
ENDIF
	call	PmHex&Bits&ToA
	mov	esi, offset Field
IF	Bits EQ	32
	mov	ecx, 9
	mov	Field[8], ' '
ELSE
	mov	ecx, 5
	mov	Field[4], ' '
ENDIF

	call	WriteLog
ENDM

; Logs the entire state - general purpose, segment regs and Eflags.
LOG_STATE	MACRO	Do
 IFNB	<Do>
	pushad

; Print new line.
	mov	Field, 13
	mov	Field[1], 10
	mov	esi, offset Field
	mov	ecx, 2
	call	WriteLog
; Print new line.
	mov	Field, 13
	mov	Field[1], 10
	mov	esi, offset Field
	mov	ecx, 2
	call	WriteLog

; Log general purpose registers.
	LOG_REG	Eax, 32
	LOG_REG	Ebx, 32
	LOG_REG	Ecx, 32
	LOG_REG	Edx, 32
	LOG_REG	Esi, 32
	LOG_REG	Edi, 32
	LOG_REG	Ebp, 32

; Log segment registers.
	LOG_REG	Ds, 16
	LOG_REG	Es, 16
	LOG_REG	Fs, 16
	LOG_REG	Gs, 16

; Log Eflags.
	LOG_REG	Eflags, 32

; Log SS:ESP.
	PRINT_LOG	LogSsEspStr
	mov	edi, offset Field
	mov	ax, word ptr ExcSs
	call	PmHex16ToA
	mov	Field[4], ':'
	mov	edi, offset Field[5]
	mov	eax, ExcEsp
	call	PmHex32ToA
	mov	Field[5][8], ' '
	mov	esi, offset Field
	mov	ecx, 14
	call	WriteLog

; Log CS:EIP.
	PRINT_LOG	LogCsEipStr
	mov	edi, offset Field
	mov	ax, ExcSeg
	call	PmHex16ToA
	mov	Field[4], ':'
	mov	edi, offset Field[5]
	mov	eax, ExcOffs
	call	PmHex32ToA
	mov	Field[5][8], ' '
	mov	esi, offset Field
	mov	ecx, 14
	call	WriteLog

; Print new line.
	mov	Field, 13
	mov	Field[1], 10
	mov	esi, offset Field
	mov	ecx, 2
	call	WriteLog
; Print new line.
	mov	Field, 13
	mov	Field[1], 10
	mov	esi, offset Field
	mov	ecx, 2
	call	WriteLog

	popad
 ENDIF	;LOG_DPMI_STATE

ENDM
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
@d34 2
a35 2
DPMI_SERVICE_PAGE	EQU	0E0000h
DPMI_SERVICE_SEG	EQU	0E000h
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
@Enabled XMS 3.0 interface
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
a43 2
; Address used for "default exception handler" that may be chained by DPMI
; client exception handler.
d47 2
a48 2
; client interrupt handler.
PM_DEF_INT_OFFS		EQU	DPMI_SERVICE_OFFS + 60h
d52 1
a52 1
PM_RET_INT_OFFS		EQU	DPMI_SERVICE_OFFS + 70h
d57 1
a57 1
XLAT_TRAP_OFFS		EQU	DPMI_SERVICE_OFFS + 80h
d62 1
a62 1
CALLBACK_RET_TRAP_OFFS	EQU	DPMI_SERVICE_OFFS + 90h
d67 1
a67 1
RM_SAVE_STATE_OFFS	EQU	DPMI_SERVICE_OFFS + 0A0h
d71 1
a71 1
PM_SAVE_STATE		EQU	DPMI_SERVICE_OFFS + 0B0h; Junk far call to be called in protmode.
d74 1
a74 1
; 2K size (1K for VM, 1K for PM).
d76 2
a77 2
VM_LOCKED_ESP		EQU	DPMI_SERVICE_OFFS + 8FFEh
VM_LOCKED_STACK_BOTTOM	EQU	DPMI_SERVICE_OFFS + 5000h
a78 1
VM_LOCKED_STACK_SIZE	EQU	4000h
d80 3
a82 4
PM_LOCKED_ESP		EQU	DPMI_SERVICE_OFFS + 4FFCh
PM_LOCKED_STACK_BOTTOM	EQU	DPMI_SERVICE_OFFS + 7F0h
PM_LOCKED_STACK		EQU	DPMI_SERVICE_PAGE + 4FFCh
PM_LOCKED_STACK_SIZE	EQU	4000h
d88 1
a88 1
MEM_INFO_STRUCT_ADDR	EQU	DPMI_SERVICE_PAGE + 0C0h
d95 1
a95 1
WIN_VENDOR_API_ENTRY	EQU	DPMI_SERVICE_OFFS + 0F0h
d99 1
a99 1
XMS_ENTRY_OFFS		EQU	DPMI_SERVICE_OFFS + 100h
d104 2
a105 2
CALLBACK_OFFS		EQU	DPMI_SERVICE_OFFS + 110h	; Start of array.
CALLBACK_ENDOFFS	EQU	DPMI_SERVICE_OFFS + 7F0h	; End of array.
d110 1
a110 1
LOCKED_STACK_BARRIER	EQU	256
d164 15
d196 17
a212 17
ASSUME	eax: PTR DpmiState
	mov	edx, ExcOffs
	mov	fs:[eax].dwEip, edx
	mov	edx, ExcEsp
	mov	fs:[eax].dwEsp, edx
	mov	dx, ExcSeg
	mov	fs:[eax].Sregs.wCs, dx
	mov	dx, ExcDs
	mov	fs:[eax].Sregs.wDs, dx
	mov	dx, ExcEs
	mov	fs:[eax].Sregs.wEs, dx
	mov	dx, ExcFs
	mov	fs:[eax].Sregs.wFs, dx
	mov	dx, ExcGs
	mov	fs:[eax].Sregs.wGs, dx
	mov	dx, ExcSs
	mov	fs:[eax].Sregs.wSs, dx
d220 17
a236 17
ASSUME	eax: PTR DpmiState
	mov	edx, fs:[eax].dwEip
	mov	ExcOffs, edx
	mov	edx, fs:[eax].dwEsp
	mov	ExcEsp, edx
	mov	dx, fs:[eax].Sregs.wCs
	mov	ExcSeg, dx
	mov	dx, fs:[eax].Sregs.wDs
	mov	ExcDs, dx
	mov	dx, fs:[eax].Sregs.wEs
	mov	ExcEs, dx
	mov	dx, fs:[eax].Sregs.wFs
	mov	ExcFs, dx
	mov	dx, fs:[eax].Sregs.wGs
	mov	ExcGs, dx
	mov	dx, fs:[eax].Sregs.wSs
	mov	ExcSs, dx
a242 2
	add	(DosTask PTR fs:[edx]).DpmiPmStack, LOCKED_STACK_SIZE
	add	(DosTask PTR fs:[edx]).DpmiPmEsp, LOCKED_STACK_SIZE
a262 2
	add	(DosTask PTR fs:[edx]).DpmiPmStack, LOCKED_STACK_SIZE
	add	(DosTask PTR fs:[edx]).DpmiPmEsp, LOCKED_STACK_SIZE
d276 1
a276 1
	mov	esi, fs:[edx+10h]
d397 2
d423 3
d449 127
@


0.42
log
@1) Added XMS server
2) Memory allocation / deallocation is moved to task creation / deletion
@
text
@d111 3
d239 3
d261 3
d291 5
d341 4
a344 1
	mov	dx, word ptr ExcEflags
d387 2
d411 2
d417 1
d422 13
@


0.41
log
@Bug fixes:
1) Virtual I/O jump table (very annoying!)
2) IsFileOpen() bug if file name is 0.
@
text
@d33 1
a33 2
; Address that traps return from real mode procedure. Used only by system
; (DOS memory block allocation services).
d76 2
a77 2
VM_LOCKED_ESP		EQU	DPMI_SERVICE_OFFS + 0FEEh
VM_LOCKED_STK_BOTTOM	EQU	DPMI_SERVICE_OFFS + 0BF0h
d79 1
d81 7
a87 3
PM_LOCKED_ESP		EQU	DPMI_SERVICE_OFFS + 0BEEh
PM_LOCKED_STK_BOTTOM	EQU	DPMI_SERVICE_OFFS + 7F0h
PM_LOCKED_STACK		EQU	VM_LOCKED_STACK - 400h
d96 8
d106 1
a106 1
CALLBACK_OFFS		EQU	DPMI_SERVICE_OFFS + 0F0h	; Start of array.
a172 3
; If defined, server offers slightly more than DPMI specification requires.
DPMI_COOKIE		EQU	1

d227 2
a228 1
	add	(DosTask PTR fs:[edx]).DpmiPmStack, 0Ah
d246 2
a247 1
	add	(DosTask PTR fs:[edx]).DpmiPmStack, 14h
d249 1
a249 1
	lea	edx, [edx-0Ah]
d393 7
@


0.40
log
@DPMI server fixes:
1) Locker real mode and protected mode stacks usage fixed: reentrancy allowed.
2) Modes switches fixed.
@
text
@@


0.39
log
@Bug fixed: raw mode switches.
@
text
@d14 5
d20 2
a21 2
INIT_SWITCH_SEG		EQU	0FFFFh
INIT_SWITCH_OFFS	EQU	0F010h
d25 2
a26 2
PM2VM_SWITCH_OFFS	EQU	0F020h
PM2VM_SWITCH_ADDR	EQU	10F010h
d29 2
a30 2
VM2PM_SWITCH_SEG	EQU	0FFFFh
VM2PM_SWITCH_OFFS	EQU	0F030h
d35 2
a36 2
RET_TRAP_SEG		EQU	0FFFFh
RET_TRAP_OFFS		EQU	0F040h
d41 1
a41 1
PM_RET_TRAP_OFFS	EQU	0F050h
d45 1
a45 1
PM_DEF_EXC_OFFS		EQU	0F060h
d49 1
a49 1
PM_DEF_INT_OFFS		EQU	0F070h
d53 1
a53 1
PM_RET_INT_OFFS		EQU	0F080h
d57 2
a58 2
XLAT_TRAP_SEG		EQU	0FFFFh
XLAT_TRAP_OFFS		EQU	0F090h
d63 1
a63 1
CALLBACK_RET_TRAP_OFFS	EQU	0F0A0h
d67 2
a68 2
RM_SAVE_STATE_SEG 	EQU	0FFFFh
RM_SAVE_STATE_OFFS	EQU	0F0B0h
d72 1
a72 1
PM_SAVE_STATE		EQU	0F0C0h		; Junk far call to be called in protmode.
d74 10
a83 4
; Locked real and protected mode stack that is used during callbacks. 2K size.
VM_LOCKED_SS		EQU	0FFFFh
VM_LOCKED_ESP		EQU	0FFFEh
DPMI_LOCKED_STACK	EQU	(VM_LOCKED_SS SHL 4) + VM_LOCKED_ESP
d86 1
a86 1
MEM_INFO_STRUCT_ADDR	EQU	10F0C0h
d93 3
a95 3
CALLBACK_SEG		EQU	0FFFFh
CALLBACK_OFFS		EQU	0F100h		; Start of array.
CALLBACK_ENDOFFS	EQU	0F800h		; End of array.
d159 4
a162 1
DPMI_BUF_SIZE		EQU	(PM_INTS + PM_EXCS) * 8 + 1000h * 2 + LDT_SIZE + DPMI_MEM_DESCRIPTORS * SIZEOF DpmiMemDescr
d171 1
a171 2
ASSUME	eax: PTR DosTask
	mov	eax, CurrTaskPtr
d173 1
a173 1
	mov	fs:[eax].DpmiAltState.dwEip, edx
d175 1
a175 1
	mov	fs:[eax].DpmiAltState.dwEsp, edx
d177 1
a177 1
	mov	fs:[eax].DpmiAltState.Sregs.wCs, dx
d179 1
a179 1
	mov	fs:[eax].DpmiAltState.Sregs.wDs, dx
d181 1
a181 1
	mov	fs:[eax].DpmiAltState.Sregs.wEs, dx
d183 1
a183 1
	mov	fs:[eax].DpmiAltState.Sregs.wFs, dx
d185 1
a185 1
	mov	fs:[eax].DpmiAltState.Sregs.wGs, dx
d187 1
a187 1
	mov	fs:[eax].DpmiAltState.Sregs.wSs, dx
d195 2
a196 3
ASSUME	eax: PTR DosTask
	mov	eax, CurrTaskPtr
	mov	edx, fs:[eax].DpmiAltState.dwEip
d198 1
a198 1
	mov	edx, fs:[eax].DpmiAltState.dwEsp
d200 1
a200 1
	mov	dx, fs:[eax].DpmiAltState.Sregs.wCs
d202 1
a202 1
	mov	dx, fs:[eax].DpmiAltState.Sregs.wDs
d204 1
a204 1
	mov	dx, fs:[eax].DpmiAltState.Sregs.wEs
d206 1
a206 1
	mov	dx, fs:[eax].DpmiAltState.Sregs.wFs
d208 1
a208 1
	mov	dx, fs:[eax].DpmiAltState.Sregs.wGs
d210 1
a210 1
	mov	dx, fs:[eax].DpmiAltState.Sregs.wSs
d217 4
a220 1
	mov	edx, DPMI_LOCKED_STACK - 0Ah
d235 4
a238 1
	mov	edx, DPMI_LOCKED_STACK - 14h
a252 1
LOCAL	end_macro, set_locked_stack
d282 2
a283 5
	cmp	dword ptr fs:[eax].wSp, 0
	je	set_locked_stack

	mov	dx, fs:[eax].wSp
	mov	word ptr ExcEsp, dx
a285 1
	jmp	end_macro
a286 7
set_locked_stack:
	mov	edx, VM_LOCKED_ESP
	mov	ExcEsp, edx
	mov	edx, VM_LOCKED_SS
	mov	ExcSs, dx
end_macro:

d328 5
d344 1
a344 3
ASSUME	edx:PTR REG_PACK
	mov	eax, CurrTaskPtr
	lea	edx, (DosTask PTR fs:[eax]).DpmiAltRegs
d366 1
a366 3
ASSUME	edx:PTR REG_PACK
	mov	eax, CurrTaskPtr
	lea	edx, (DosTask PTR fs:[eax]).DpmiAltRegs
@


0.38
log
@Bugs fixed:
1) PointerToLinear() check
2) Default interrupt redirection to V86 mode
@
text
@@


0.37
log
@Bug fixed: reflecting PM to VM interrupt.
@
text
@@


0.36
log
@Bug fixes:
1) CreatePageTable() called from HeapAllocMem()
2) Zero allocated PDB for new task
@
text
@@


0.35
log
@HeapAllocMem() bug fixed; free DPMI memory allocated fixed.
@
text
@@


0.34
log
@Bug fixes:
1) Initial pages map allocation
2) Translation services params
3) DPMI clean up memory release -- almost
4) INT 21h AH=4Ch in protected mode.
@
text
@@


0.33
log
@Initial full release - all DPMI functions are written! Half are not tet.
@
text
@d13 19
a31 10
INIT_SWITCH_SEG		EQU	0FFFFh		; Init. mode switch seg.
INIT_SWITCH_OFFS	EQU	0F010h		; Init. mode switch offs.
INIT_SWITCH_ADDR	EQU	(INIT_SWITCH_SEG SHL 4) + INIT_SWITCH_OFFS	; Init. mode switch addr.
PM2VM_SWITCH_OFFS	EQU	0F020h		; Raw PM to VM switch addr (offs).
PM2VM_SWITCH_ADDR	EQU	10F010h		; Raw PM to VM switch addr.
VM2PM_SWITCH_SEG	EQU	0FFFFh		; Raw VM to PM switch addr (seg).
VM2PM_SWITCH_OFFS	EQU	0F030h		; Raw VM to PM switch addr (offs).
VM2PM_SWITCH_ADDR	EQU	(VM2PM_SWITCH_SEG SHL 4) + VM2PM_SWITCH_OFFS	; Raw VM to PM switch addr.
RET_TRAP_SEG		EQU	0FFFFh		; Trap for return from RM callbacks seg.
RET_TRAP_OFFS		EQU	0F040h		; Trap for return from RM callbacks offs.
d33 21
a53 6
PM_RET_TRAP_OFFS	EQU	0F050h		; Trap for return form PM callbacks (exception) offs.
PM_DEF_EXC_OFFS		EQU	0F060h		; Trap for DPMI default exception handler.
PM_DEF_INT_OFFS		EQU	0F070h		; Trap for DPMI default interrupt handler.
PM_RET_INT_OFFS		EQU	0F080h		; Trap for return form PM callbacks (interrupt) offs.
XLAT_TRAP_SEG		EQU	0FFFFh		; Trap return from translation services seg.
XLAT_TRAP_OFFS		EQU	0F090h		; Trap return from translation services offs.
d55 12
a66 3
CALLBACK_RET_TRAP_OFFS	EQU	0F0A0h		; Trap return from DPMI callback offs.
RM_SAVE_STATE_SEG 	EQU	0FFFFh		; Junk far call to be called in real mode (seg).
RM_SAVE_STATE_OFFS	EQU	0F0B0h		; Junk far call to be called in real mode (offs).
d68 4
a71 2
VM_LOCKED_SS		EQU	0FFFFh		; Locked VM SS for callbacks.
VM_LOCKED_ESP		EQU	0FFFEh		; Locked VM ESP for callbacks.
d74 2
a75 1
MEM_INFO_STRUCT_ADDR	EQU	10F0C0h		; Free memory information structure.
d78 2
a79 2
PM_EXCS			EQU	20h		; PM exceptions.
PM_INTS			EQU	100h		; PM interrupts.
d81 4
a84 3
CALLBACK_SEG		EQU	0FFFFh		; Segment of first allocatable callback
CALLBACK_OFFS		EQU	0F100h		; Offset off first allocatable callback
CALLBACK_ENDOFFS	EQU	0F800h
@


0.32
log
@Translation services work.
@
text
@d16 1
d18 3
a20 1
VM2PM_SWITCH_ADDR	EQU	10F020h		; Raw VM to PM switch addr.
d28 2
a29 2
XLAT_TRAP_SEG		EQU	0FFFFh		; Trap for return from translation services seg.
XLAT_TRAP_OFFS		EQU	0F090h		; Trap for return from translation services offs.
d31 4
d39 3
d45 5
a49 1
DPMI_BUF_SIZE		EQU	(PM_INTS + PM_EXCS) * 8 + 1
d86 27
d284 5
@


0.31
log
@1) Interrupt redirection works
2) HeapAllocMem() bug fixes
DPMI traps fixed
@
text
@d25 3
d38 5
a42 1
; Structures.
d50 27
a76 1
; Macros
d78 3
a80 2
; Save state regs into alternate save structure.
	TASK_PTR	CurrentTask
d82 1
a82 1
	mov	(DosTask PTR fs:[eax]).DpmiAltState.dwEip, edx
d84 1
a84 1
	mov	(DosTask PTR fs:[eax]).DpmiAltState.dwEsp, edx
d86 1
a86 1
	mov	(DosTask PTR fs:[eax]).DpmiAltState.Sregs.wCs, dx
d88 1
a88 1
	mov	(DosTask PTR fs:[eax]).DpmiAltState.Sregs.wDs, dx
d90 1
a90 1
	mov	(DosTask PTR fs:[eax]).DpmiAltState.Sregs.wEs, dx
d92 1
a92 1
	mov	(DosTask PTR fs:[eax]).DpmiAltState.Sregs.wFs, dx
d94 1
a94 1
	mov	(DosTask PTR fs:[eax]).DpmiAltState.Sregs.wGs, dx
d96 2
a97 1
	mov	(DosTask PTR fs:[eax]).DpmiAltState.Sregs.wSs, dx
d101 1
d103 4
a106 3
; Restore state regs from alternate save structure.
	TASK_PTR	CurrentTask
	mov	edx, (DosTask PTR fs:[eax]).DpmiAltState.dwEip
d108 1
a108 1
	mov	edx, (DosTask PTR fs:[eax]).DpmiAltState.dwEsp
d110 1
a110 1
	mov	dx, (DosTask PTR fs:[eax]).DpmiAltState.Sregs.wCs
d112 1
a112 1
	mov	dx, (DosTask PTR fs:[eax]).DpmiAltState.Sregs.wDs
d114 1
a114 1
	mov	dx, (DosTask PTR fs:[eax]).DpmiAltState.Sregs.wEs
d116 1
a116 1
	mov	dx, (DosTask PTR fs:[eax]).DpmiAltState.Sregs.wFs
d118 1
a118 1
	mov	dx, (DosTask PTR fs:[eax]).DpmiAltState.Sregs.wGs
d120 1
a120 1
	mov	dx, (DosTask PTR fs:[eax]).DpmiAltState.Sregs.wSs
d122 1
d153 139
@


0.30
log
@DOS block functions are written and work. Callback to real mode mechanism established. Tests are still brief.
@
text
@d18 2
a19 2
RET_TRAP_SEG		EQU	0FFFFh		; Trap for return from callbacks seg.
RET_TRAP_OFFS		EQU	0F040h		; Trap for return from callbacks offs.
d21 4
d27 1
d29 2
a30 3
RM_INT_HANDLERS		EQU	16		; Maximum 16 RM int. handlers chained.
PM_INT_HANDLERS		EQU	16		; Maximum 16 PM int. handlers chained.
PM_EXC_HANDLERS		EQU	16		; Maximum 16 PM exc. handlers chained.
d32 1
a32 1
DPMI_BUF_SIZE		EQU	(RM_INT_HANDLERS + PM_INT_HANDLERS + PM_EXC_HANDLERS) * 256 * 8 + 1
d48 1
a48 1
	mov	(DosTask PTR fs:[eax]).TaskAltEip, edx
d50 1
a50 1
	mov	(DosTask PTR fs:[eax]).TaskAltEsp, edx
d52 1
a52 1
	mov	(DosTask PTR fs:[eax]).TaskAltSregs.wCs, dx
d54 1
a54 1
	mov	(DosTask PTR fs:[eax]).TaskAltSregs.wDs, dx
d56 1
a56 1
	mov	(DosTask PTR fs:[eax]).TaskAltSregs.wEs, dx
d58 1
a58 1
	mov	(DosTask PTR fs:[eax]).TaskAltSregs.wFs, dx
d60 1
a60 1
	mov	(DosTask PTR fs:[eax]).TaskAltSregs.wGs, dx
d62 1
a62 1
	mov	(DosTask PTR fs:[eax]).TaskAltSregs.wSs, dx
d65 51
@


0.29
log
@First DPMI selector functions work (Hello, world).
@
text
@d18 5
d24 37
a60 1
ATTR_MAPPED	EQU	00010000b	; Segment is obtained through seg2descr function.
@


0.28
log
@Initial DPMI switch works.
@
text
@d18 2
@
