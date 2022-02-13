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
