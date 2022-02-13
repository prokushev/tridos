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
;				TASKMAN.INC
;				-----------
;
;	Include file for task manager (definitions etc.)
;
;=============================================================================

IFNDEF	TASKMAN_INC
 TASKMAN_INC	EQU	1

	INCLUDE		CORE.INC

;
; STRUCTURES.
;
DpmiState	STRUC
	Sregs		SREG_PACK <>	; DPMI alternate mode segment regs.
 	dwEip		DD	?	; DPMI alternate mode EIP.
	dwEsp		DD	?	; DPMI alternate mode ESP.
DpmiState	ENDS


DosTask		STRUC
	TaskPdb		DD	?	; CR3 value to be loaded for task.
	TaskPdbLin	DD	?	; Task's PDB's linear address.
	TaskPageCtl	DD	?	; Linear address of page ctl. array.
	TaskMapping	DD	?	; Linear alias for pages in 1st Mb.
	TaskRegs	REG_PACK <>	; Task's registers state.
	TaskSregs	SREG_PACK <>	; Task's segment registers state.
	TaskVirtualIf	DD	?	; Virtual IF to be saved.
	TaskVirtualIp	DD	?	; Virtual pending ints. to be saved.
	TaskVirtualIsr	DD	?	; Virtual in-service interrupt reg.
	TaskVirtualImr	DD	?	; Virtual interrupt mask reg.
IFDEF	BORROWED_TICKS
	BorrowedTicks	DD	?	; Ticks that a task 'borrows'.
ENDIF
	TaskVideoState	DD	?	; Keeps video state (h/w and color).

	TaskTickCount	DD	?	; Counts task ticks (virtual timer).
	TaskTicksReport	DD	?	; PIT 0 counter.
	TaskPITCh0Sel	DB	?	; Select virtual timer channel 0.

	TaskState	DB	?	; Keeps task state.
	TaskBlock	DB	?	; Task block reason.
	TaskCurrDrive	DB	?	; Keeps current drive per task.
	TaskErrCode	DB	?	; Keeps last error code.
	TaskOpenFiles	DD	?	; Keeps count of open files.
	TaskOFTable	DD	?	; Table of files opened by task.
	Int21TrapOp	DD	?	; 8 bytes keep INT 21h return
			DD	?	; opcode.
	DosFunc		DW	?	; DOS function number is saved.
	TaskPmPsp	DW	?	; Task's protected mode PSP.
	TaskCurrentId	DW	?	; For emulation of DOS PID functions.

	TaskLdt		DW	?	; LDT is allocated when task switches
					; to PM via DPMI.
	TaskLdtBase	DD	?	; LDT base.
	TaskLdtLimit	DW	?	; Actual limit of Task LDT.
	TaskFlags	DD	?	; Task execution flags.

	DpmiDOSBlocks	DD	?	; Array of selectors allocated for DOS blocks.
	DpmiPmInts	DD	?	; Protmode ints callback vectors.
	DpmiPmExcs	DD	?	; Protmode exceptions callback vectors.
	DpmiCallbackArr	DD	?	; Array of DPMI callback addresses allocated.
	DpmiRmSs	DW	?	; Selector for real mode SS for translation services.
	DpmiMemDescrArr	DD	?	; Array of DPMI memory descriptors.

	DpmiRmEsp	DD	?	; Locked RM ESP for real mode callbacks.
	DpmiRmStack	DD	?	; Locked RM stack linear address.
	DpmiPmEsp	DD	?	; Locked PM ESP for protected mode callbacks.
	DpmiPmStack	DD	?	; Locked PM stack linear address.

	DpmiServicePage	DD	?	; linear address of a 4K memory for DPMI needs.
	XmsHmaFlag	DB	?	; if 0, HMA is available.

	DpmiPmStateSave	DD	?	; Save state in PM when doing mode switches.
	DpmiPmStatePtr	DD	?	; Pointer to state saved in PM
	DpmiRmStateSave	DD	?	; Save state in RM when doing mode switches.
	DpmiRmStatePtr	DD	?	; Pointer to state saved in RM
	DpmiRmCallPtr	DD	?	; Pointer to user supplied real mode call structure.

DosTask		ENDS


DpmiStateSave	STRUC
	bFlag	DB	?	; 0 if only DpmiState structure is saved,
				; 1 if general regs also
	sState	DpmiState	<>
	sRegs	GEN_REG_PACK	<>
DpmiStateSave	ENDS



	MAX_FNAME_LEN	EQU	67	; Maximum path name length in DOS.
	CDS_ENTRY_SIZE	EQU	58h	; CDS array element size.

OpenFileRecord	STRUC
	Handle		DW	?
	Owner		DD	?
	FileName	DB	MAX_FNAME_LEN DUP (?)
OpenFileRecord	ENDS

; Maximum number of tasks (consider increasing?)
;	MAX_TASKS	EQU	1000h / SIZEOF DosTask
	MAX_TASKS	EQU	100	; Maximum of 100 tasks.

; Task's states.
	TASK_RUNNING	EQU	1	; Task is currently running.
	TASK_READY	EQU	2	; Task is ready to run.
	TASK_BLOCKED	EQU	4	; Task is blocked (waits for semaphore)
	TASK_WAITING	EQU	8	; Task waits for event.
	TASK_RESUMED	EQU	10h	; Task has received an awaited event.
	TASK_LOCKED	EQU	20h	; Task is locked (cannot be preempted).

; Task's block reasons.
	HDD_SEMA4	EQU	1	; HDD is busy.
	FDD_SEMA4	EQU	2	; FDD is busy.

; Task's awaited events.
	KBD_INPUT	EQU	4	; Waiting for keyboard input.
	INT28_WAIT	EQU	8	; Waiting for DOS busy to begone.
	DMA_REQUEST	EQU	10h	; Waiting for DMA mem write to complete.
	SOME_SEMA4	EQU	20h	; Waiting on some semaphore.

; Task execution flags.
	TASK_32BIT	EQU	1	; 1 = 32 bit task, 0 = 16 bit.

	TASK_RM_STATE_NEED_SAVE	EQU	2	; 1 = real mode state save needed.
	TASK_RM_REGS_NEED_SAVE	EQU	4	; 1 = real mode general regs save needed.
	TASK_PM_STATE_NEED_SAVE	EQU	8	; 1 = protected mode state save needed.
	TASK_PM_REGS_NEED_SAVE	EQU	10h	; 1 = protected mode general regs save needed.

	TASK_RM_STATE_SAVED	EQU	20h	; 1 = real mode state saved.
	TASK_RM_REGS_SAVED	EQU	40h	; 1 = real mode general regs saved.
	TASK_PM_STATE_SAVED	EQU	80h	; 1 = protected mode state saved.
	TASK_PM_REGS_SAVED	EQU	100h	; 1 = protected mode general regs saved.

; DPMI memory size.
	DPMI_MEM_SIZE		EQU	3000h		; In bytes
	DPMI_MEM_PAGES		EQU	3		; In pages

; Needed memory amount to create a new task.

; 0A0000h bytes of base memory.
	TASK_MEMORY_SIZE	=	0A0000h	
; 40000h for additional VGA memory.
	TASK_MEMORY_SIZE	=	TASK_MEMORY_SIZE + 40000h
; 1 page for open files structure
	TASK_MEMORY_SIZE	=	TASK_MEMORY_SIZE + 1000h
; 1 page for page directory
	TASK_MEMORY_SIZE	=	TASK_MEMORY_SIZE + 1000h
; 1 page for pages ctl. array
	TASK_MEMORY_SIZE	=	TASK_MEMORY_SIZE + 1000h
; 1 page for 1st MB page table
	TASK_MEMORY_SIZE	=	TASK_MEMORY_SIZE + 1000h
; 1 page for 1st MB alias mapping
	TASK_MEMORY_SIZE	=	TASK_MEMORY_SIZE + 1000h
; 1 page for VGA regs save/restore.
	TASK_MEMORY_SIZE	=	TASK_MEMORY_SIZE + 1000h
; If providing HIMEM, 64K for HMA.
IFDEF	PROVIDE_HIMEM
	TASK_MEMORY_SIZE	=	TASK_MEMORY_SIZE + 10000h
ENDIF

; And memory for DPMI server needs.
	TASK_MEMORY_SIZE	=	TASK_MEMORY_SIZE + DPMI_MEM_SIZE


TASK_PTR	MACRO	Task, Dest
 IFNB	<Task>
 	mov	eax, SIZEOF DosTask
	mul	Task
 ELSE
 	mov	edx, SIZEOF DosTask
	mul	edx
 ENDIF
	add	eax, FirstTask
 IFNB	<Dest>
 	mov	Dest, eax
 ENDIF
ENDM


Sema4		STRUCT
	ResourceId	DD	?	; Resource that the semaphore guides.
	Owner		DD	?	; Task that owns a semaphore.
	SleepN		DD	?	; Number of tasks that sleep on semaphore.
	TasksSleep	DD	MAX_TASKS DUP (?)	; Array of tasks.
	State		DB	?	; Semaphore's state
Sema4		ENDS

ENDIF	; TASKMAN_INC
