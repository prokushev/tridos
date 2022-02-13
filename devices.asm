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
;				DEVICES.ASM
;				-----------
;
;	Devices management code for the Tripple-DOS project.
;
;=============================================================================
	EXTRN	AddGdtSegment: near

	EXTRN	Field:byte
	EXTRN	TssBase: dword
	EXTRN	ForegroundTask: dword
	EXTRN	CurrentTask: dword
	EXTRN	CurrTaskPtr: dword
	EXTRN	FirstTask: dword
	EXTRN	VirtualIp: dword
	EXTRN	VirtualIsr: dword
	EXTRN	VirtualImr: dword
	EXTRN	ExcSeg: word
	EXTRN	ExcOffs: dword
	EXTRN	ExcEax: dword
	EXTRN	ExcEbx: dword
	EXTRN	ExcEcx: dword
	EXTRN	ExcEdx: dword
	EXTRN	ExcEsi: dword
	EXTRN	ExcEdi: dword
	EXTRN	ExcEsp: dword
	EXTRN	ExcEbp: dword
	EXTRN	ExcSs: dword
	EXTRN	ExcDs: dword
	EXTRN	ExcEs: dword
	EXTRN	ExcFs: dword
	EXTRN	ExcGs: dword
	EXTRN	ExcEflags: dword

	EXTRN	FddSema4Own: dword

	INCLUDE	PHLIB.INC
	INCLUDE	DEF.INC
	INCLUDE	DEVICES.INC
	INCLUDE	X86.INC
	INCLUDE	TASKMAN.INC
	INCLUDE	CORE.INC
	INCLUDE	PHLIB32.MCR
	INCLUDE	DPMI.INC

	EXTRN	InitErrHandler: near16

	EXTRN	PointerToLinear: near32
	EXTRN	LinearToPhysical: near32
	EXTRN	WriteLog: near32
	EXTRN	SwitchTask: near32
	EXTRN	Sema4Down: near32
	EXTRN	Sema4Up: near32

DATA	SEGMENT	PARA	PUBLIC	USE16	'DATA'
; Video data.
	PUBVAR		CrtId, DB, ?	; Id of the video adapter.
	VideoTxtBuf	DD	?	; Base address for text video buffer.
	VideoGfxBuf	DD	?	; Base address for gfx. video buffer.
	PUBVAR	VBufTextSel, DW, ?	; GDT selector for text video buffer.
	PUBVAR	VBufGfxSel, DW,	?	; GDT selector for gfx. video buffer.
	CrtBase		DW	?	; Base addr. for CRT controller.
	PUBVAR	Rows, DB, ROWS_PER_SCR	; Rows per screen
	PUBVAR	Columns, DB, COLS_PER_ROW	; Columns per row.

	CursorX		DB	0
	CursorY		DB	0

	TempMemMode	DB	?	; Temporary memory mode reg.
	TempMisc	DB	?	; Temporary gfx. misc. reg.

; I/O opcodes help data.
	PUBVAR	OperandSize, DB, ?	; 16/32 bits operand.
	PUBVAR	AddressSize, DB, ?	; 16/32 bits addressing.
	PUBVAR	SegPrefix, DB, ?	; Segment prefix.
	PUBVAR	RepPrefix, DB, ?	; REP prefix specified.

	IoOpcodes	DB	OP_IN8_DX, OP_IN8_IMM, OP_IN16_DX
			DB	OP_IN16_IMM, OP_INSB, OP_INSW
			DB	OP_OUT8_DX, OP_OUT8_IMM, OP_OUT16_DX
			DB	OP_OUT16_IMM, OP_OUTSB, OP_OUTSW
IO_OPCODES	=	$ - offset IoOpcodes

	IoOpcodesJmpTbl	DD	offset _op_in8_dx, offset _op_in8_imm
			DD	offset _op_in16_dx, offset _op_in16_imm
			DD	offset _op_insb, offset _op_insw
			DD	offset _op_out8_dx, offset _op_out8_imm
			DD	offset _op_out16_dx, offset _op_out16_imm
			DD	offset _op_outsb, offset _op_outsw

; Is saved at initial I/O instruction checking.
	IoOpcodesIndex	DD	?

; Keyboard data.
	PUBVAR	KeyExtCode, DB, ?	; Extended key pressed.
	PUBVAR	KeyPressed, DB, ?	; Key pressed.
	PUBVAR	KeyReady, DB, ?		; Key ready flag.
	PUBVAR	ShiftKeys, DB, ?	; Shift keys state.

	PUBVAR	KeyboardQ, DB, ?	; Keyboard queue.
		DB	KEYBOARD_Q_SIZE - 1 DUP (?)
	PUBVAR	KbdQHead, DD, 0		; Pointer to queue head.
	PUBVAR	KbdQTail, DD, 0		; Pointer to queue tail.
	PUBVAR	TempScanCode, DB, ?	; Keeps scan code temporarily.

PUBLIC	ShiftScanTbl
	ShiftScanTbl	DD	Key_LShift, Key_RShift, Key_LAlt, Key_RAlt
			DD	Key_LCtrl, Key_RCtrl, Key_CapsLock, Key_NumLock

PUBLIC	ShiftBitCode	
	ShiftBitCode	DB	Kbd_LShift, Kbd_RShift, Kbd_LAlt, Kbd_RAlt
			DB	Kbd_LCtrl, Kbd_RCtrl, Kbd_CapsLock, Kbd_NumLock

	ScanTbl		DB	1, 2, 3, 4, 5, 6, 7, 8, 9, 0Ah, 0Bh
			DB	1Eh, 30h, 2Eh, 20h, 12h, 21h, 22h, 23h, 17h
			DB	24h, 25h, 26h, 32h, 31h, 18h, 19h, 10h, 13h
			DB	1Fh, 14h, 16h, 2Fh, 11h, 2Dh, 15h, 2Ch, 39h
			DB	1Ch, 0Eh, 0Ch, 0Dh, 1Ah, 1Bh, 27h, 28h, 29h
			DB	2Bh, 33h, 34h, 35h
CHAR_TBL_LEN	EQU	$ - ScanTbl

	AsciiTbl	DB	27, '1', '2', '3', '4', '5', '6', '7', '8', '9', '0'
			DB	'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i'
			DB	'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r'
			DB	's', 't', 'u', 'v', 'w', 'x', 'y', 'z', ' '
			DB	0Dh, 08h, '-', '=', '[', ']', ';', "'", '`'
			DB	'\', ',', '.', '/'

	ShiftAsciiTbl	DB	27, '!', '@', '#', '$', '%', '^', '&', '*', '(', ')'
			DB	'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I'
			DB	'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R'
			DB	'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', ' '
			DB	0Dh, 08h, '_', '+', '{', '}', ':', '"', '~'
			DB	'|', '<', '>', '?'

; PIT data.
	PUBVAR	TickCount, DWORD, ?
	PUBVAR	TicksReport, DWORD, ?
	PUBVAR	TickToSec, DWORD, PIT_TICK_TO_SEC

; DMA data.
	PUBVAR	DmaBufSeg, DW, ?
	PUBVAR	DmaBufAddr, DD, ?	; 64K buffer, paragraph aligned

	Dma1BaseAddr	DD	4 DUP (?)
	Dma1Count	DD	4 DUP (?)
	Dma1FlipFlops	DD	?
	Dma1PageAddress	DD	DMA_CH0_PAGE, DMA_CH1_PAGE, DMA_CH2_PAGE, DMA_CH3_PAGE

	DmaCtl		DB	?
	DmaStatus	DB	?
	DmaWriteReq	DB	?
	DmaMask		DB	?
	DmaMode		DB	?
	DmaMasterClear	DB	?
	DmaClearMask	DB	?
	DmaWriteMask	DB	?

	DmaMaskReg	DB	0

PUBLIC	DmaIoRange
	DmaIoRange	DD	MAX_TASKS * 2 DUP ( 0 )

	DmaCount	DB	0
	RetireDmaFlag	DB	0

	FdcStatus	DB	?

; General devices data.
PUBLIC	GenDevices
GenDevices	LABEL	GenDevice
PUBLIC	Com1
	Com1	GenDevice < 8,\
		3F8h, 3F9h, 3FAh, 3FBh, 3FCh, 3FDh, 3FEh, 3FFh,\
		@REPEAT_DATUM	(MAX_PORTS - 8, -1 )\
		4, <> >
PUBLIC	Com2
	Com2	GenDevice < 8,\
		2F8h, 2F9h, 2FAh, 2FBh, 2FCh, 2FDh, 2FEh, 2FFh,\
		@REPEAT_DATUM	(MAX_PORTS - 8, -1 )\
		3, <> >
	

N_GEN_DEVICES	EQU	($ - GenDevices) / SIZEOF( GenDevice )

	PUBVAR	NumGenDevs, DWORD, N_GEN_DEVICES
	NoEipUpdate	DB	0

	TimeStr		DB	"xx:xx:xx", 0
	Str1	DB	"Check 1"
	Str2	DB	"Check 2"



DATA	ENDS


CODE	SEGMENT	PARA	PUBLIC	USE16	'CODE'
ASSUME	CS:CODE, DS:DATA

;-----------------------------------------------------------------------------
;
; 	Enable A20 address line.
;
;-----------------------------------------------------------------------------
PUBLIC	EnableA20
EnableA20	PROC	near
	mov	al, CMD_A20_Access
	out	KBD_COMMAND, al
	IODelay
	mov	al, CMD_A20_On
	out	KBD_DATA, al
	IODelay
	ret
EnableA20	ENDP


;-----------------------------------------------------------------------------
;
;	Disable A20 address line.
;
;-----------------------------------------------------------------------------
DisableA20	PROC	near
	mov	al, CMD_A20_Access
	out	KBD_COMMAND, al
	IODelay
	mov	al, CMD_A20_Off
	out	KBD_DATA, al
	IODelay
	ret
DisableA20	ENDP


;-----------------------------------------------------------------------------
;
;	I:  DX = PIC base address(20h=master, A0h=slave)
;	    AH = Start INT # for appropriate IRQ.
;
;	(!) AH must be a multiply of 8.
;
;	Initialize PIC. Done for remapping A3-A7 of INT vector.
;
;-----------------------------------------------------------------------------
PUBLIC	InitPIC
InitPIC		PROC	near
	mov	al, CMD_ICW1
	out	dx, al

	inc	dx
	mov	al, ah
	out	dx, al

	mov	al, CMD_ICW3
	cmp	dx, PIC_MASTER_MASK
	je	put_icw3
	mov	al, CMD_SLAVE_ICW3
put_icw3:
	out	dx, al

	mov	al, CMD_ICW4
	out	dx, al
	ret
InitPIC		ENDP


;-----------------------------------------------------------------------------
;
;	Set up video mode (text) and base address (mono/color).
;
;-----------------------------------------------------------------------------
PUBLIC	SetupVideo
SetupVideo	PROC	near
; Detect CRT type.
	call	DetectCrt
	mov	CrtId, al

; Set base CRT controller and ports addresses.
	mov	CrtBase, 3B0h
	mov	VideoTxtBuf, OS_VIDEO_BUF + 10000h
	mov	VideoGfxBuf, OS_VIDEO_BUF + 10000h
	cmp	al, 1
	jna	crt_set
	add	CrtBase, 20h	; Set CRT to 3D0h.
	mov	VideoTxtBuf, OS_VIDEO_BUF + 18000h
	mov	VideoGfxBuf, OS_VIDEO_BUF
crt_set:
; Allocate GDT selectors for text and graphics video buffers.
	ADD_GDT_SEGMENT	VideoTxtBuf, 7FFFh, DATA_ACCESS
	mov	VBufTextSel, ax
	ADD_GDT_SEGMENT	VideoGfxBuf, 0FFFFh, DATA_ACCESS
	mov	VBufGfxSel, ax

; Set mode 3.
	mov	ax, 3
	int	10h

	cmp	CrtId, 5
	jnb	@F
	call	InitErrHandler

@@:
	ret
SetupVideo	ENDP


;-----------------------------------------------------------------------------
;
;	I:
;	O:  AL = 1: mono
;		 2: CGA
;		 3: EGA
;		 4: MCGA
;		 5: VGA/SVGA
;
;	Detects video adapter according to BIOS video modes that it supports.
;
;-----------------------------------------------------------------------------
PUBLIC	DetectCrt
DetectCrt	PROC	near
	sub	ax, ax
	int	10h
	mov	ah, 0Fh
	int	10h
	test	al, al
	jz	col
	mov	al, 1
	ret
col:
	mov	ax, 13h
	int	10h
	mov	ah, 0Fh
	int	10h
	cmp	al, 13h
	jz	mcgavga
	mov	ax, 0Dh
	int	10h
	mov	ah, 0Fh
	int	10h
	cmp	al, 0Dh
	jz	ega
	mov	al, 2
	ret
ega:
	mov	al, 3
	ret
mcgavga:
	mov	ax, 0Dh
	int	10h
	mov	ah, 0Fh
	int	10h
	cmp	al, 0Dh
	mov	al, 4
	jnz	to_ret
	inc	ax
to_ret:
	ret
DetectCrt	ENDP


;-----------------------------------------------------------------------------
;
; Procedure BEEPs on speaker
;
;-----------------------------------------------------------------------------
Beep		PROC
	push	ax
	push	bx
	push	cx

	in	al, KBD_PORT_B
	push	ax
	mov	cx, 100h
Beep0:
	push	cx
	and	al, 11111100b
	out	KBD_PORT_B, al
	mov	cx, 0C0h
	loop	$
	or	al, 00000010b
	out	KBD_PORT_B, al
	mov	cx, 0C0h
	loop	$
	pop	cx
	loop	Beep0

	pop	ax
	out	KBD_PORT_B, al

	pop	cx
	pop	bx
	pop	ax
	ret
Beep		ENDP


;----------------------------------------------------------------------------
;
;	DS:SI -> String (0 - terminated).
;	DL:DH = column: row
;	BL    = color
;
;	R:	PROTMODE.
;
;-----------------------------------------------------------------------------
PUBLIC	PmWriteStr
PmWriteStr	PROC	near USES es ax cx
	call	StrLen
	mov	cx, ax
	mov	al, dh
	mul	Columns
	add	al, dl
	adc	ah, 0
	shl	ax, 1
	mov	di, ax
	mov	es, VBufTextSel
	mov	ah, bl
	cld
write_loop:
	lodsb
	stosw
	loop	write_loop
	ret
PmWriteStr	ENDP


CODE	ENDS


CODE32	SEGMENT	PARA	PUBLIC	USE32	'CODE'
ASSUME	CS:CODE32, DS:FLAT

;-----------------------------------------------------------------------------
;
;	Waits for key press and returns scan code.
;
;	I:
;	O:	AL = scan code.
;		AH = extended key press code.
;
;-----------------------------------------------------------------------------
PUBLIC	GetScanCode
GetScanCode	PROC
	pushfd
	mov	al, 11111101b
	out	PIC_MASTER_MASK, al

	sti
	mov	KeyReady, 0

wait_key:
	cmp	KeyReady, 0
	je	wait_key

	popfd				; Restore IF.

	mov	al, KeyPressed		; Return key pressed
	mov	ah, KeyExtCode		; Return extended code
	ret
GetScanCode	ENDP


;-----------------------------------------------------------------------------
;
;	Waits for key press and returns ASCII code.
;
;	I:
;	O:	AL = ASCII code.
;		AH = scan code.
;
;-----------------------------------------------------------------------------
PUBLIC	GetAsciiCode
GetAsciiCode	PROC	USES ecx edi
	call	GetScanCode
	mov	edi, offset ScanTbl
	mov	ecx, CHAR_TBL_LEN
	cld
		repne	scasb
	mov	ah, al			; store scan code
	jnz	zero_ascii		; If scan code is not in table.

; If shift was held, change table.
	add	edi, offset AsciiTbl - offset ScanTbl - 1
	test	ShiftKeys, Kbd_LShift OR Kbd_RShift
	jz	@F
	add	edi, offset ShiftAsciiTbl - offset AsciiTbl
@@:
	mov	al, [edi]
	jmp	ascii_gotten
zero_ascii:
	sub	al, al
ascii_gotten:

	ret
GetAsciiCode	ENDP


;-----------------------------------------------------------------------------
;
;	Moves cursor on display.
;
;	I:	AL = column, AH = row
;	O:
;
;-----------------------------------------------------------------------------
PUBLIC	GotoXy
GotoXy		PROC	near32	USES eax ecx edx
	mov	CursorX, al
	mov	CursorY, ah

	mov	edx, V_CLR_CRT_ADDR
	mov	al, ah
	mul	Columns
	add	al, CursorX
	adc	ah, 0
	mov	ecx, eax

	mov	al, V_Crt_CURSOR_ADDR_LSB	; CRT cursor position LSB index
	mov	ah, cl
	out	dx, ax

	mov	al, V_Crt_CURSOR_ADDR_MSB	; CRT cursor position MSB index
	mov	ah, ch
	out	dx, ax

	ret
GotoXy		ENDP


;-----------------------------------------------------------------------------
;
;	Print a character at cursor and advance cursor.
;
;	I:	AL = char
;		AH = attribute
;	O:
;
;-----------------------------------------------------------------------------
PUBLIC	TtyChar
TtyChar		PROC	USES	es eax ecx
	mov	ecx, eax
	mov	al, CursorY
	mul	Columns
	add	al, CursorX
	adc	ah, 0
	shl	eax, 1
	and	eax, 0000FFFFh
	mov	es, VBufTextSel
	mov	es:[eax], cx
	mov	al, CursorX
	mov	ah, CursorY
	inc	eax
	call	GotoXy

	ret
TtyChar		ENDP


;-----------------------------------------------------------------------------
;
;	Initializes PIT with a given divisor.
;
;	I: EAX = counter, valid range is 0 - 0FFFFh. 0 means 65536.
;	   BL = channel (0 - 2).
;	O:
;
;-----------------------------------------------------------------------------
PUBLIC	InitPIT
InitPIT		PROC	USES eax ecx edx
	shl	eax, 16		; Keep counter in high bits of eax.
	mov	al, bl
	shl	al, 6		; counter select.

	or	al, 00110110b	; Send LSB, MSB value; select mode 3.
	out	PIT_CONTROL, al

	shr	eax, 16		; Set back counter in AX.
	mov	edx, PIT_CH0_COUNT
	add	dl, bl

	out	dx, al		; Set LSB
	shr	eax, 8
	out	dx, al		; Set MSB

	ret
InitPIT		ENDP


;-----------------------------------------------------------------------------
;
;	Saves video context.
;
;	I: ES:EDI -> memory area to store context.
;
;-----------------------------------------------------------------------------
PUBLIC	SaveVideoContext
SaveVideoContext	PROC	USES eax ebx ecx edx edi
; Check whether the mode is color or mono. Set EBX to base CRT (3x4) address.
	mov	ebx, V_MONO_CRT_ADDR
	mov	edx, V_MISC_IN
	in	al, dx
	mov	(VIDEO_CONTEXT PTR es:[edi]).MiscOutput, al

	and	eax, 1
	shl	eax, 5
	add	ebx, eax

	cld

; Save CRT registers.
	SAVE_BUNCH_REGS	ebx, V_CRT_REGS

; Save sequencer registers.
	SAVE_BUNCH_REGS	V_SEQ_ADDR, V_SEQ_REGS

; Save graphics controller registers.
	SAVE_BUNCH_REGS	V_GFX_ADDR, V_GFX_REGS

; Save attribute controller registers.
	mov	ecx, ebx
	add	ecx, V_CLR_STS1 - V_CLR_CRT_ADDR
	sub	ah, ah

save_attr_regs:
	mov	edx, ecx
	in	al, dx		; Reset address flip-flop.
	mov	edx, V_ATTR_ADDR

	mov	al, ah
	out	dx, al

	inc	edx
	in	al, dx

	stosb
	inc	ah
	cmp	ah, V_ATTR_REGS - 1
	jb	save_attr_regs
	ja	@F
	or	ah, V_Attr_SCR_ENABLE
	jmp	save_attr_regs
@@:

; Save DAC registers.
	mov	edx, V_DAC_PEL_MASK
	in	al, dx
	stosb				; PEL mask reg.

	mov	edx, V_DAC_READ_ADDR
	sub	al, al
	out	dx, al

	mov	edx, V_DAC_DATA
	mov	ecx, V_DAC_REGS - 1
		rep	insb		; DAC RGB data.

	ret
SaveVideoContext	ENDP


;-----------------------------------------------------------------------------
;
;	Saves video memory (all bit planes).
;
;	I: ES:EDX -> task's structure.
;
; (!) Must be in the context of task being saved.
;
;-----------------------------------------------------------------------------
PUBLIC	SaveVideoMemory
SaveVideoMemory		PROC
	pushad

	mov	ebp, edx
; Set all video memory clocks to CPU interface.
	mov	edx, V_SEQ_ADDR
	mov	al, V_Seq_CLOCK_MODE
	out	dx, al
	inc	edx
	in	al, dx
	movzx	ebx, al
	shl	ebx, 16			; Keep clock mode.
	dec	edx
	mov	ah, al
	mov	al, V_Seq_CLOCK_MODE
	or	ah, 20h
	out	dx, ax			; Give all the time to CPU.

; Check memory mapping.
	mov	edx, V_GFX_ADDR
	mov	al, V_Gfx_MISC
	out	dx, al
	inc	edx
	in	al, dx
	test	al, 8			; Text modes?
	jnz	text_modes

; Graphics modes. Check whether current BIOS mode uses bitplanes on the same
; addresses or chains.
	mov	al, fs:[449h]
	cmp	al, 0Dh
	je	plane_modes
	cmp	al, 10h	
	je	plane_modes
	cmp	al, 12h
	je	plane_modes
	cmp	al, 0Eh
	je	plane_modes
	jb	cga_modes

; EGA/VGA chained modes.
	mov	esi, 0A0000h
	mov	eax, 0A0000h SHR 12
	mov	edx, (0A0000h + 10000h) SHR 12
	jmp	@F

cga_modes:
	mov	esi, 0B8000h
	mov	eax, 0B8000h SHR 12
	mov	edx, (0B8000h + 10000h) SHR 12

@@:
	call	copy_mem
	jmp	gfx_exit

plane_modes:
; Set read mode 0.
	mov	edx, V_GFX_ADDR
	mov	al, V_Gfx_MODE
	out	dx, al
	inc	edx
	in	al, dx
	mov	bh, al			; Save graphics ctl. mode register.
	dec	edx
	mov	al, V_Gfx_MODE
	and	ah, 01100000b		; Read and write mode 0, no odd/even
					; mode.
	out	dx, ax

	mov	al, V_Gfx_BIT_PLANE_READ
	out	dx, al
	inc	edx
	in	al, dx
	mov	bl, al			; Save previous bit plane (BL).
	dec	edx

	sub	ah, ah			; AH = bit plane.
	mov	ecx, 0A0000h SHR 12

save_bit_plane:
	push	eax

	mov	edx, V_GFX_ADDR
	mov	al, V_Gfx_BIT_PLANE_READ
	out	dx, ax

	mov	esi, 0A0000h
	mov	eax, ecx
	mov	edx, ecx
	add	edx, 10000h SHR 12
	call	copy_mem
	pop	eax

	inc	ah
	add	ecx, 10000h SHR 12
	cmp	ah, 4
	jb	save_bit_plane

; Restore mode select.
	mov	edx, V_GFX_ADDR
	mov	al, V_Gfx_MODE
	mov	ah, bh
	out	dx, ax

; Restore bit plane select.
	mov	edx, V_GFX_ADDR
	mov	al, V_Gfx_BIT_PLANE_READ
	mov	ah, bl
	out	dx, ax

gfx_exit:
; Restore clock mode.
	shr	ebx, 16
	mov	edx, V_SEQ_ADDR
	mov	al, V_Seq_CLOCK_MODE
	mov	ah, bl
	out	dx, ax

	popad
	ret

text_modes:
	mov	TempMisc, al

; Text modes. Reprogram bit plane select to access plane 2/3.
	mov	edx, V_GFX_ADDR
	mov	al, V_Gfx_BIT_PLANE_READ
	out	dx, al
	inc	edx
	in	al, dx
	mov	bl, al			; Save previous bit plane (BL).
	dec	edx
	mov	al, V_Gfx_BIT_PLANE_READ
	mov	ah, 2			; Set bit plane 2.
	out	dx, ax

; Enable odd bit planes.
	mov	edx, V_SEQ_ADDR
	mov	al, V_Seq_MEM_MODE
	out	dx, al
	inc	edx
	in	al, dx
	dec	edx
	mov	TempMemMode, al
	mov	ah, al
; VGADOC4B has this one reversed. If set, disables odd bitplanes.
; Enable odd/even mode.
	and	ah, NOT 4
	mov	al, V_Seq_MEM_MODE
	out	dx, ax

; Reprogram memory mapping register.
	mov	edx, V_GFX_ADDR
	mov	al, V_Gfx_MISC
	mov	ah, TempMisc
	and	ah, NOT 00001100b	; Map memory to A0000 - BFFFF
	or	ah, 00000010b
	out	dx, ax

; Save character generator tables.
	mov	esi, 0A0000h
	mov	eax, 0A0000h SHR 12
	mov	edx, (0A0000h + 10000h) SHR 12
	call	copy_mem
	mov	esi, 0B0000h
	mov	eax, 0C0000h SHR 12
	mov	edx, (0C0000h + 10000h) SHR 12
	call	copy_mem
; Remap memory back.
	mov	edx, V_GFX_ADDR
	mov	al, V_Gfx_MISC
	mov	ah, TempMisc
	out	dx, ax

; Restore bit plane select (0 & 1).
	mov	edx, V_GFX_ADDR
	mov	al, V_Gfx_BIT_PLANE_READ
	mov	ah, bl
	out	dx, ax

; Restore sequencer's memory mode reg.
	mov	edx, V_SEQ_ADDR
	mov	al, V_Seq_MEM_MODE
	mov	ah, TempMemMode
	out	dx, ax

	test	TempMisc, 4		; CGA compatible modes?
	jz	mono_modes

	mov	esi, 0B8000h		; Save characters and attributes.
	mov	eax, 0B8000h SHR 12
	mov	edx, (0B8000h + 8000h) SHR 12
	call	copy_mem
	jmp	restore_clock

mono_modes:
	mov	esi, 0B0000h		; Save characters and attributes.
	mov	eax, 0B0000h SHR 12
	mov	edx, (0B0000h + 8000h) SHR 12
	call	copy_mem

restore_clock:
; Restore clock mode.
	shr	ebx, 16
	mov	edx, V_SEQ_ADDR
	mov	al, V_Seq_CLOCK_MODE
	mov	ah, bl
	out	dx, ax

	popad
	ret

copy_mem:
; Copy task's memory at A0000h - BFFFFh to virtual (take from task's
; alias mapping).
	push	ecx

	cld
save_page:

	mov	ecx, 400h			; Number of dwords in 1 page.
	mov	edi, (DosTask PTR es:[ebp]).TaskMapping
	mov	edi, es:[edi+eax*4]		; ES:EDI-> dest page
		rep	movs dword ptr es:[edi], es:[esi]

	inc	eax				; Next page
	cmp	eax, edx
	jb	save_page

	pop	ecx
	ret
SaveVideoMemory		ENDP


;-----------------------------------------------------------------------------
;
;	Restores video memory
;
;	I: ES:EDX -> task's structure.
;
; (!) Must be in the context of task being saved.
;
;-----------------------------------------------------------------------------
PUBLIC	RestoreVideoMemory
RestoreVideoMemory	PROC
	pushad

	mov	ebp, edx
; Set all video memory clocks to CPU interface.
	mov	edx, V_SEQ_ADDR
	mov	al, V_Seq_CLOCK_MODE
	out	dx, al
	inc	edx
	in	al, dx
	movzx	ebx, al
	shl	ebx, 16			; Keep clock mode.
	dec	edx
	mov	ah, al
	mov	al, V_Seq_CLOCK_MODE
	or	ah, 20h
	out	dx, ax			; Give all the time to CPU.

; Check memory mapping.
	mov	edx, V_GFX_ADDR
	mov	al, V_Gfx_MISC
	out	dx, al
	inc	edx
	in	al, dx
	test	al, 8			; Text modes?
	jnz	text_modes

; Graphics modes. Check whether current BIOS mode uses bitplanes on the same
; addresses or chains.
	mov	al, fs:[449h]
	cmp	al, 0Dh
	je	plane_modes
	cmp	al, 10h	
	je	plane_modes
	cmp	al, 12h
	je	plane_modes
	cmp	al, 0Eh
	je	plane_modes
	jb	cga_modes

; EGA/VGA chained modes.
	mov	edi, 0A0000h
	mov	eax, 0A0000h SHR 12
	mov	edx, (0A0000h + 10000h) SHR 12
	jmp	@F

cga_modes:
	mov	edi, 0B8000h
	mov	eax, 0B8000h SHR 12
	mov	edx, (0B8000h + 10000h) SHR 12

@@:
	call	restore_mem
	jmp	gfx_exit

plane_modes:
; Set read mode 0.
	mov	edx, V_GFX_ADDR
	mov	al, V_Gfx_MODE
	out	dx, al
	inc	edx
	in	al, dx
	mov	bh, al			; Save graphics ctl. mode register.
	dec	edx
	mov	al, V_Gfx_MODE
	and	ah, 01100000b		; Read and write mode 0, no odd/even
					; mode.
	out	dx, ax

; Reprogram bit plane write select to access bit plane 0.
	mov	al, V_Seq_BIT_PLANE_WRITE
	out	dx, al
	inc	edx
	in	al, dx
	dec	edx
	mov	bl, al			; Save previous bit plane mask.

	mov	ah, 1			; Set bit plane 0.
	mov	ecx, 0A0000h SHR 12
restore_bit_plane:
	push	eax

	mov	edx, V_SEQ_ADDR
	mov	al, V_Seq_BIT_PLANE_WRITE
	out	dx, ax

; Copy video memory.
	mov	edi, 0A0000h
	mov	eax, ecx
	mov	edx, ecx
	add	edx, 10000h SHR 12
	call	restore_mem
	pop	eax

	add	ecx, 10000h SHR 12
	shl	ah, 1
	cmp	ah, 00010000b
	jb	restore_bit_plane

; Restore bit plane write enable.
	mov	edx, V_SEQ_ADDR
	mov	al,  V_Seq_BIT_PLANE_WRITE
	mov	ah, bl
	out	dx, ax

; Restore read/write mode.
	mov	edx, V_GFX_ADDR
	mov	al,  V_Gfx_MODE
	mov	ah, bh
	out	dx, ax

gfx_exit:
; Restore clock mode.
	shr	ebx, 16
	mov	edx, V_SEQ_ADDR
	mov	al, V_Seq_CLOCK_MODE
	mov	ah, bl
	out	dx, ax

	popad
	ret

text_modes:
	mov	TempMisc, al

; Save sequencer's memory mode register.
	mov	edx, V_SEQ_ADDR
	mov	al, V_Seq_MEM_MODE
	out	dx, al
	inc	edx
	in	al, dx
	dec	edx
	mov	TempMemMode, al
	mov	ah, al
; VGADOC4B has this one reversed. If set, disables odd bitplanes.
; Enable odd/even mode.
	and	ah, NOT 4
	mov	al, V_Seq_MEM_MODE
	out	dx, ax

; Reprogram bit plane write select to access bit plane 2.
	mov	al, V_Seq_BIT_PLANE_WRITE
	out	dx, al
	inc	edx
	in	al, dx
	dec	edx
	mov	bl, al			; Save previous bit plane mask.
	mov	al, V_Seq_BIT_PLANE_WRITE
	mov	ah, 4
	out	dx, ax			; Set bit plane 2.

; Set read and write mode 0. (EDX = V_GFX_ADDR).
	mov	al, V_Gfx_MODE
	out	dx, al
	inc	edx
	in	al, dx
	mov	bh, al			; Save previous mode (BH).
	dec	edx
	mov	al, V_Gfx_MODE
	sub	ah, ah			; Read mode 0.
	out	dx, ax			; Set read mode.

; Reprogram memory mapping register.
	mov	edx, V_GFX_ADDR
	mov	al, V_Gfx_MISC
	mov	ah, TempMisc
	and	ah, NOT 00001100b	; Map memory to A0000 - BFFFF
	or	ah, 00000010b
	out	dx, ax

; Restore character generator tables.
	mov	edi, 0A0000h
	mov	eax, 0A0000h SHR 12
	mov	edx, (0A0000h + 10000h) SHR 12
	call	restore_mem
	mov	edi, 0B0000h
	mov	eax, 0C0000h SHR 12
	mov	edx, (0C0000h + 10000h) SHR 12
	call	restore_mem

; Remap memory back to B8000 - BFFFF
	mov	edx, V_GFX_ADDR
	mov	al, V_Gfx_MISC
	mov	ah, TempMisc
	out	dx, ax

; Restore bit plane select (0 & 1).
	mov	edx, V_SEQ_ADDR
	mov	al, V_Seq_BIT_PLANE_WRITE
	mov	ah, bl
	out	dx, ax

; Restore mode register.
	mov	al, bh
	out	dx, ax

; Restore sequencer's memory mode reg.
	mov	edx, V_SEQ_ADDR
	mov	al, V_Seq_MEM_MODE
	mov	ah, TempMemMode
	out	dx, ax

	test	TempMisc, 4		; CGA compatible modes?
	jz	mono_modes

	mov	edi, 0B8000h		; Restore characters and attributes.
	mov	eax, 0B8000h SHR 12
	mov	edx, (0B8000h + 8000h) SHR 12
	call	restore_mem
	jmp	restore_clock

mono_modes:
	mov	edi, 0B0000h		; Restore characters and attributes.
	mov	eax, 0B0000h SHR 12
	mov	edx, (0B0000h + 8000h) SHR 12
	call	restore_mem

restore_clock:
; Restore clock mode.
	shr	ebx, 16
	mov	edx, V_SEQ_ADDR
	mov	al, V_Seq_CLOCK_MODE
	mov	ah, bl
	out	dx, ax

	popad
	ret

restore_mem:
; Copy task's memory at A0000h - BFFFFh from virtual (take from task's
; alias mapping).
	push	ecx

	cld
restore_page:
	mov	ecx, 400h			; Number of dwords in 1 page.
	mov	esi, (DosTask PTR es:[ebp]).TaskMapping
	mov	esi, es:[esi+eax*4]		; ES:ESI-> source page
		rep	movs dword ptr es:[edi], es:[esi]

	inc	eax				; Next page
	cmp	eax, edx
	jb	restore_page

	pop	ecx
	ret
RestoreVideoMemory	ENDP


;-----------------------------------------------------------------------------
;
;	Restores video context.
;
;	I: ES:ESI -> memory area with previously saved context.
;
;-----------------------------------------------------------------------------
PUBLIC	RestoreVideoContext
RestoreVideoContext	PROC	USES eax ebx ecx edx esi
; Restore misc. output register.
	mov	al, (VIDEO_CONTEXT PTR es:[esi]).MiscOutput
	mov	edx, V_MISC_OUT
	out	dx, al

; Check whether the mode is color or mono. Set EBX to base CRT (3x4) address.
	mov	ebx, V_MONO_CRT_ADDR
	mov	edx, V_MISC_IN
	in	al, dx
	and	eax, 1
	shl	eax, 5
	add	ebx, eax

	cld

; Restore CRT registers.

; Enable write to CRT registers 0-7.
	mov	edx, ebx
	mov	al, V_Crt_VERT_RETRACE_END
	out	dx, al
	inc	edx
	in	al, dx
	dec	edx
	and	al, 7Fh
	mov	ah, al
	mov	al, V_Crt_VERT_RETRACE_END
	out	dx, ax

	REST_BUNCH_REGS	ebx, V_CRT_REGS

; Restore sequencer registers.
	REST_BUNCH_REGS	V_SEQ_ADDR, V_SEQ_REGS

; Restore graphics controller registers.
	REST_BUNCH_REGS	V_GFX_ADDR, V_GFX_REGS

; Restore attribute controller registers.
	mov	edx, ebx
	add	edx, V_CLR_STS1 - V_CLR_CRT_ADDR
	in	al, dx		; Reset address flip-flop.
	sub	ah, ah
	mov	edx, V_ATTR_ADDR

restore_attr_regs:
	mov	al, ah
	out	dx, al

	lods	byte ptr es:[esi]
	out	dx, al

	inc	ah
	cmp	ah, V_ATTR_REGS - 1
	jb	restore_attr_regs
	ja	@F
	or	ah, V_Attr_SCR_ENABLE
	jmp	restore_attr_regs
@@:

; Restore DAC registers.
	mov	edx, V_DAC_PEL_MASK
	lods	byte ptr es:[esi]	; PEL mask reg.
	out	dx, al

	mov	edx, V_DAC_WRITE_ADDR
	sub	al, al
	out	dx, al

	mov	edx, V_DAC_DATA
	mov	ecx, V_DAC_REGS - 1
		rep	outs dx, byte ptr es:[esi]	; DAC RGB data.

	ret
RestoreVideoContext	ENDP


;-----------------------------------------------------------------------------
;
;	Traps access to video ports (3B0 - 3DF).
;
;	I: EAX = 0 to allow access
;              = 0FFFFFFFFh to trap access.
;
;-----------------------------------------------------------------------------
PUBLIC	TrapVideoPorts
TrapVideoPorts	PROC	USES ecx edx
	mov	edx, TssBase
	movzx	ecx, (Tss386 PTR fs:[edx]).IoTableBase
	mov	fs:[edx+ecx+3B0h/8], eax	; Trap ports 3B0 - 3CF
	mov	fs:[edx+ecx+3D0h/8], ax		; Trap ports 3D0 - 3DF

	ret
TrapVideoPorts	ENDP


;-----------------------------------------------------------------------------
;
;	Generic I/O instructions trap that saves main chaining on GPF
; handler.
;
;	GPE callback.
;
;-----------------------------------------------------------------------------
PUBLIC	TrapIo
TrapIo		PROC
; If not V86 mode and CPL != 3, return error.
	test	ExcEflags, FL_VM
	jnz	@F
	test	ExcSeg, 3
	jnz	@F
	stc
	ret

@@:
; Check faulting instruction.
	mov	si, ExcSeg
	mov	edi, ExcOffs
	mov	ebx, ExcEflags
	call	PointerToLinear

; Skip prefixes and set defaults.
	call	SkipPrefixes

;
; Here all prefixes are skipped. Check opcode that failed. If opcode is not
; an I/O opcode, return error.
;
	mov	esi, eax

	mov	al, fs:[esi]

	mov	edi, offset IoOpcodes
	mov	ecx, IO_OPCODES
	cld
		repne	scasb
	je	@F

	stc
	ret

@@:
	not	ecx

	add	ecx, IO_OPCODES
	mov	eax, IoOpcodesJmpTbl[ecx*4]
	mov	IoOpcodesIndex, eax

; Now call all I/O emulation functions. The one that handles request will
; return CF = 0.
	call	EmulateVideoIo
	jc	@F
	ret
@@:
	call	EmulateKbdIo
	jc	@F
	ret
@@:
	call	EmulatePITIo
	jc	@F
	ret
@@:
	call	EmulatePICIo
	jc	@F
	ret
@@:
	call	EmulateDMAIo
	jc	@F
	ret
@@:
	call	EmulateFDCIo
	jc	@F
	ret
@@:
	call	EmulateGenDevIo
	jc	@F
	ret
@@:
; Return error (restricted port access).
	ret
TrapIo		ENDP


;-----------------------------------------------------------------------------
;
;	Emulates video I/O instructions that were caused by access to video
; ports by a background application.
;	This is a GPF callback.
;
;-----------------------------------------------------------------------------
PUBLIC	EmulateVideoIo
EmulateVideoIo	PROC	USES eax ebx ecx edx

; If current task is a foreground task, return error.
	mov	eax, CurrentTask
	cmp	eax, ForegroundTask
	jne	@F
	stc
	ret
@@:
; Call generic I/O emulation procedure.
	mov	eax, offset ReadVideoPort
	mov	ecx, offset WriteVideoPort
	call	EmulateIo

	ret
EmulateVideoIo	ENDP


;-----------------------------------------------------------------------------
;
;	Emulates I/O for generic device.
;
;	I: EAX -> procedure to call to emulate reads.
;	   ECX -> procedure to call to emulate writes.
;	O: CF = 0 - OK
;	   CF = 1 - error.
;
;	(!) If read or write port handlers return CF=1, ExcOffs doesn't get
; updated. This may be used to block the task on an I/O instruction.
;
;-----------------------------------------------------------------------------
EmulateIo	PROC	USES eax ebx ecx edx esi edi
LOCAL	pReadPort: dword, 
	pWritePort: dword

	mov	pReadPort, eax
	mov	pWritePort, ecx

;
; Clear the "no update" flag. This flag may be set by the particular I/O
; handler to prevent updating EIP.
;
	mov	NoEipUpdate, 0

	jmp	IoOpcodesIndex

_op_in8_dx::
; IN AL, DX.
	movzx	eax, word ptr ExcEdx
	call	pReadPort
	jc	err_ret
	mov	byte ptr ExcEax, al
	jmp	update_eip

_op_in8_imm::
	inc	esi
	movzx	eax, byte ptr fs:[esi]
	call	pReadPort
	jc	err_ret
	mov	byte ptr ExcEax, al
	jmp	update_eip

_op_in16_dx::
	cmp	OperandSize, 0
	jne	in32_dx
; IN AX, DX.
	movzx	eax, word ptr ExcEdx
do_in16:
	lea	ecx, [eax+1]
	call	pReadPort
	jc	err_ret
	mov	byte ptr ExcEax, al
	mov	eax, ecx
	call	pReadPort
	jc	err_ret
	mov	byte ptr ExcEax[1], al
	jmp	update_eip

in32_dx:
; IN EAX, DX.
	movzx	eax, word ptr ExcEdx
do_in32:
	lea	ecx, [eax+1]
	call	pReadPort
	jc	err_ret
	mov	byte ptr ExcEax, al
	mov	eax, ecx
	inc	ecx
	call	pReadPort
	jc	err_ret
	mov	byte ptr ExcEax[1], al
	mov	eax, ecx
	inc	ecx
	call	pReadPort
	jc	err_ret
	mov	byte ptr ExcEax[2], al
	mov	eax, ecx
	call	pReadPort
	jc	err_ret
	mov	byte ptr ExcEax[3], al
	jmp	update_eip
	
_op_in16_imm::
; IN (e)AX, IMM.
	inc	esi
	movzx	eax, byte ptr fs:[esi]
	cmp	OperandSize, 0
	je	do_in16
	jmp	do_in32
	
_op_insb::
; Check for segment limit violation.
	movzx	eax, word ptr ExcEdi
	cmp	AddressSize, 0
	je	@F

	cmp	ExcEdi, 0FFFFh
	ja	err_ret
	mov	eax, ExcEdi

@@:
;INSB.
	push	eax
	push	esi
	push	edi

	mov	si, ExcSeg
	mov	edi, ExcOffs
	mov	ebx, ExcEflags
	call	PointerToLinear
	mov	ecx, eax

	pop	edi
	pop	esi
	pop	eax

insb_loop:
	movzx	eax, word ptr ExcEdx
	call	pReadPort
	jc	err_ret
	mov	fs:[ecx], al
	cmp	RepPrefix, 0
	jne	rep_insb

	cmp	AddressSize, 0
	jne	@F
	inc	word ptr ExcEdi
	jmp	update_eip
@@:
	inc	ExcEdi
	jmp	update_eip

rep_insb:
	cmp	OperandSize, 0
	jne	@F
	inc	word ptr ExcEdi
	inc	ecx
	dec	word ptr ExcEcx
	jnz	insb_loop
	jmp	update_eip

@@:
	inc	ExcEdi
	cmp	ExcEdi, 0FFFFh
	ja	err_ret
	inc	ecx
	dec	ExcEcx
	jnz	insb_loop
	jmp	update_eip

_op_insw::
	cmp	OperandSize, 0
	jne	do_insd?

; Check for segment limit violation.
	movzx	eax, word ptr ExcEdi
	cmp	AddressSize, 0
	je	@F

	cmp	ExcEdi, 0FFFEh
	ja	err_ret
	mov	eax, ExcEdi
	jmp	do_insw

@@:
	cmp	ax, 0FFFFh
	je	err_ret

do_insw:
; INSW(D).
	push	eax
	push	esi
	push	edi

	mov	si, ExcSeg
	mov	edi, ExcOffs
	mov	ebx, ExcEflags
	call	PointerToLinear
	mov	ecx, eax

	pop	edi
	pop	esi
	pop	eax

insw_loop:
	movzx	eax, word ptr ExcEdx
	call	pReadPort
	jc	err_ret
	mov	fs:[ecx], al
	movzx	eax, word ptr ExcEdx
	inc	eax
	call	pReadPort
	jc	err_ret
	mov	fs:[ecx+1], al

	cmp	RepPrefix, 0
	jne	rep_insw

	cmp	OperandSize, 0
	jne	@F
	add	word ptr ExcEdi, 2
	jmp	update_eip
@@:
	add	ExcEdi, 2
	jmp	update_eip

rep_insw:
	cmp	OperandSize, 0
	jne	@F

	add	ecx, 2
	add	word ptr ExcEdi, 2
	cmp	word ptr ExcEdi, 0FFFEh
	ja	err_ret

	dec	word ptr ExcEcx
	jnz	insw_loop
	jmp	update_eip

@@:
	add	ExcEdi, 2
	cmp	ExcEdi, 0FFFEh
	ja	err_ret

	add	ecx, 2
	dec	ExcEcx
	jnz	insw_loop
	jmp	update_eip

do_insd?:
; Check for segment limit violation.
	movzx	eax, word ptr ExcEdi
	cmp	AddressSize, 0
	je	@F

	cmp	ExcEdi, 0FFFCh
	ja	err_ret
	mov	eax, ExcEdi
	jmp	do_insd

@@:
	cmp	ax, 0FFFCh
	ja	err_ret

do_insd:
	push	eax
	push	esi
	push	edi

	mov	si, ExcSeg
	mov	edi, ExcOffs
	mov	ebx, ExcEflags
	call	PointerToLinear
	mov	ecx, eax

	pop	edi
	pop	esi
	pop	eax

insd_loop:
	movzx	eax, word ptr ExcEdx
	call	pReadPort
	jc	err_ret
	mov	fs:[ecx], al
	movzx	eax, word ptr ExcEdx
	inc	eax
	call	pReadPort
	jc	err_ret
	mov	fs:[ecx+1], al
	movzx	eax, word ptr ExcEdx
	add	eax, 2
	call	pReadPort
	jc	err_ret
	mov	fs:[ecx+2], al
	movzx	eax, word ptr ExcEdx
	add	eax, 3
	call	pReadPort
	jc	err_ret
	mov	fs:[ecx+3], al

	cmp	RepPrefix, 0
	je	rep_insd

	cmp	OperandSize, 0
	jne	@F
	add	word ptr ExcEdi, 4
	jmp	update_eip
@@:
	add	ExcEdi, 4
	jmp	update_eip

rep_insd:
	cmp	OperandSize, 0
	jne	@F
	add	word ptr ExcEdi, 4
	cmp	word ptr ExcEdi, 0FFFCh
	ja	err_ret
	add	ecx, 4
	dec	word ptr ExcEcx
	jnz	insd_loop
	jmp	update_eip

@@:
	add	ExcEdi, 4
	cmp	ExcEdi, 0FFFCh
	ja	err_ret
	add	ecx, 4
	dec	ExcEcx
	jnz	insd_loop
	jmp	update_eip
	
_op_out8_dx::
; OUT DX, AL.
	movzx	eax, word ptr ExcEdx
	mov	cl, byte ptr ExcEax
	call	pWritePort
	jc	err_ret
	jmp	update_eip

_op_out8_imm::
	inc	esi
	movzx	eax, byte ptr fs:[esi]
	mov	cl, byte ptr ExcEax
	call	pWritePort
	jc	err_ret
	jmp	update_eip

_op_out16_dx::
	cmp	OperandSize, 0
	jne	out32_dx
; OUT DX, AX.
	movzx	eax, word ptr ExcEdx
do_out16:
	mov	cl, byte ptr ExcEax
	call	pWritePort
	jc	err_ret
	movzx	eax, word ptr ExcEdx
	inc	eax
	mov	cl, byte ptr ExcEax[1]
	call	pWritePort
	jc	err_ret
	jmp	update_eip

out32_dx:	
; OUT DX, EAX.
	movzx	eax, word ptr ExcEdx
do_out32:
	mov	cl, byte ptr ExcEax
	call	pWritePort
	jc	err_ret
	movzx	eax, word ptr ExcEdx
	inc	eax
	mov	cl, byte ptr ExcEax[1]
	call	pWritePort
	jc	err_ret
	movzx	eax, word ptr ExcEdx
	add	eax, 2
	mov	cl, byte ptr ExcEax[2]
	call	pWritePort
	jc	err_ret
	movzx	eax, word ptr ExcEdx
	add	eax, 3
	mov	cl, byte ptr ExcEax[3]
	call	pWritePort
	jc	err_ret
	jmp	update_eip

_op_out16_imm::
	inc	esi
	movzx	eax, byte ptr fs:[esi]
	cmp	OperandSize, 0
	je	do_out16
	jmp	do_out32

_op_outsb::
; Check for segment limit violation.
	movzx	eax, word ptr ExcEsi
	cmp	AddressSize, 0
	je	@F

	cmp	ExcEsi, 0FFFFh
	ja	err_ret
	mov	eax, ExcEsi
@@:
;OUTSB. Pick segment (according to override).
	movzx	ebx, word ptr ExcDs
	cmp	SegPrefix, 0
	je	@F
	movzx	ebx, word ptr ExcEs
	cmp	SegPrefix, OP_ES_PREFIX
	je	@F
	movzx	ebx, word ptr ExcSeg
	cmp	SegPrefix, OP_CS_PREFIX
	je	@F
	movzx	ebx, word ptr ExcSs
	cmp	SegPrefix, OP_SS_PREFIX
	je	@F
	movzx	ebx, word ptr ExcFs
	cmp	SegPrefix, OP_FS_PREFIX
	je	@F
	movzx	ebx, word ptr ExcGs
@@:
	push	eax
	push	esi
	push	edi

	mov	esi, ebx
	mov	edi, eax
	mov	ebx, ExcEflags
	call	PointerToLinear
	mov	ebx, eax

	pop	edi
	pop	esi
	pop	eax

outsb_loop:
	movzx	eax, word ptr ExcEdx
	mov	cl, fs:[ebx]
	call	pWritePort
	cmp	RepPrefix, 0
	jne	rep_outsb

	cmp	AddressSize, 0
	jne	@F
	inc	word ptr ExcEsi
	jmp	update_eip
@@:
	inc	ExcEsi
	jmp	update_eip

rep_outsb:
	cmp	OperandSize, 0
	jne	@F
	inc	word ptr ExcEsi
	inc	ebx
	dec	word ptr ExcEcx
	jnz	outsb_loop
	jmp	update_eip

@@:
	inc	ExcEsi
	cmp	ExcEsi, 0FFFFh
	ja	err_ret
	inc	ebx
	dec	ExcEcx
	jnz	outsb_loop
	jmp	update_eip

_op_outsw::
	cmp	OperandSize, 0
	jne	do_outsd

; Check for segment limit violation.
	movzx	eax, word ptr ExcEsi
	cmp	AddressSize, 0
	je	@F

	cmp	ExcEsi, 0FFFFh
	jnb	err_ret
	mov	eax, ExcEsi
@@:
; OUTSW. Pick segment (according to override).
	movzx	ebx, word ptr ExcDs
	cmp	SegPrefix, 0
	je	@F
	movzx	ebx, word ptr ExcEs
	cmp	SegPrefix, OP_ES_PREFIX
	je	@F
	movzx	ebx, word ptr ExcSeg
	cmp	SegPrefix, OP_CS_PREFIX
	je	@F
	movzx	ebx, word ptr ExcSs
	cmp	SegPrefix, OP_SS_PREFIX
	je	@F
	movzx	ebx, word ptr ExcFs
	cmp	SegPrefix, OP_FS_PREFIX
	je	@F
	movzx	ebx, word ptr ExcGs
@@:
	push	eax
	push	esi
	push	edi

	mov	esi, ebx
	mov	edi, eax
	mov	ebx, ExcEflags
	call	PointerToLinear
	mov	ebx, eax

	pop	edi
	pop	esi
	pop	eax

outsw_loop:
	movzx	eax, word ptr ExcEdx
	mov	cl, fs:[ebx]
	call	pWritePort
	jc	err_ret
	movzx	eax, word ptr ExcEdx
	inc	eax
	mov	cl, fs:[ebx+1]
	call	pWritePort
	cmp	RepPrefix, 0
	jne	rep_outsw

	cmp	AddressSize, 0
	jne	@F
	add	word ptr ExcEsi, 2
	jmp	update_eip
@@:
	add	ExcEsi, 2
	jmp	update_eip

rep_outsw:
	cmp	OperandSize, 0
	jne	@F
	add	word ptr ExcEsi, 2
	cmp	word ptr ExcEsi, 0FFFFh
	jnb	err_ret
	add	ebx, 2
	dec	word ptr ExcEcx
	jnz	outsw_loop
	jmp	update_eip

@@:
	add	ExcEsi, 2
	cmp	ExcEsi, 0FFFFh
	jnb	err_ret
	add	ebx, 2
	dec	ExcEcx
	jnz	outsw_loop
	jmp	update_eip

do_outsd:
; Check for segment limit violation.
	movzx	eax, word ptr ExcEsi
	cmp	AddressSize, 0
	je	@F

	cmp	ExcEsi, 0FFFCh
	ja	err_ret
	mov	eax, ExcEsi
@@:
; OUTSD. Pick segment (according to override).
	movzx	ebx, word ptr ExcDs
	cmp	SegPrefix, 0
	je	@F
	movzx	ebx, word ptr ExcEs
	cmp	SegPrefix, OP_ES_PREFIX
	je	@F
	movzx	ebx, word ptr ExcSeg
	cmp	SegPrefix, OP_CS_PREFIX
	je	@F
	movzx	ebx, word ptr ExcSs
	cmp	SegPrefix, OP_SS_PREFIX
	je	@F
	movzx	ebx, word ptr ExcFs
	cmp	SegPrefix, OP_FS_PREFIX
	je	@F
	movzx	ebx, word ptr ExcGs
@@:
	push	eax
	push	esi
	push	edi

	mov	esi, ebx
	mov	edi, eax
	mov	ebx, ExcEflags
	call	PointerToLinear
	mov	ebx, eax

	pop	edi
	pop	esi
	pop	eax

outsd_loop:
	movzx	eax, word ptr ExcEdx
	mov	cl, fs:[ebx]
	call	pWritePort
	jc	err_ret
	movzx	eax, word ptr ExcEdx
	inc	eax
	mov	cl, fs:[ebx+1]
	call	pWritePort
	jc	err_ret
	movzx	eax, word ptr ExcEdx
	add	eax, 2
	mov	cl, fs:[ebx+2]
	call	pWritePort
	jc	err_ret
	movzx	eax, word ptr ExcEdx
	add	eax, 3
	mov	cl, fs:[ebx+3]
	call	pWritePort
	jc	err_ret

	cmp	RepPrefix, 0
	jne	rep_outsd

	cmp	AddressSize, 0
	jne	@F
	add	word ptr ExcEsi, 4
	jmp	update_eip
@@:
	add	ExcEsi, 4
	jmp	update_eip

rep_outsd:
	cmp	OperandSize, 0
	jne	@F
	add	word ptr ExcEsi, 4
	cmp	word ptr ExcEsi, 0FFFCh
	ja	err_ret
	add	ebx, 4
	dec	word ptr ExcEcx
	jnz	outsd_loop
	jmp	update_eip

@@:
	add	ExcEsi, 4
	cmp	ExcEsi, 0FFFCh
	ja	err_ret
	add	ebx, 4
	dec	ExcEcx
	jnz	outsd_loop
;	jmp	update_eip

update_eip:
	cmp	NoEipUpdate, 0
	jne	@F

	inc	esi

	push	esi
	push	edi

	mov	si, ExcSeg
	sub	edi, edi
	mov	ebx, ExcEflags
	call	PointerToLinear

	pop	edi
	pop	esi

	sub	esi, eax
	mov	ExcOffs, esi
@@:
	clc
	ret

err_ret:
	stc
	ret

EmulateIo	ENDP


;-----------------------------------------------------------------------------
;
;	Skips prefixes in opcode.
;
;	I: FS:EAX -> faulting opcode (with prefixes).
;	O: FS:EAX -> faulting opcode (without prefixes).
;
;-----------------------------------------------------------------------------
PUBLIC	SkipPrefixes
SkipPrefixes	PROC
; Default 16 bits, no segment override.
	mov	AddressSize, 0
	mov	OperandSize, 0
	mov	SegPrefix, 0
	mov	RepPrefix, 0

skip_prefixes:
	cmp	byte ptr fs:[eax], OP_CS_PREFIX
	jne	@F
	mov	SegPrefix, OP_CS_PREFIX
	inc	eax
	jmp	skip_prefixes
@@:
	cmp	byte ptr fs:[eax], OP_SS_PREFIX
	jne	@F
	mov	SegPrefix, OP_SS_PREFIX
	inc	eax
	jmp	skip_prefixes
@@:
	cmp	byte ptr fs:[eax], OP_DS_PREFIX
	jne	@F
	mov	SegPrefix, OP_DS_PREFIX
	inc	eax
	jmp	skip_prefixes
@@:
	cmp	byte ptr fs:[eax], OP_ES_PREFIX
	jne	@F
	mov	SegPrefix, OP_ES_PREFIX
	inc	eax
	jmp	skip_prefixes
@@:
	cmp	byte ptr fs:[eax], OP_FS_PREFIX
	jne	@F
	mov	SegPrefix, OP_FS_PREFIX
	inc	eax
	jmp	skip_prefixes
@@:
	cmp	byte ptr fs:[eax], OP_GS_PREFIX
	jne	@F
	mov	SegPrefix, OP_GS_PREFIX
	inc	eax
	jmp	skip_prefixes
@@:
	cmp	byte ptr fs:[eax], OP_OPER_PREFIX
	jne	@F
	xor	OperandSize, 1
	inc	eax
	jmp	skip_prefixes
@@:
	cmp	byte ptr fs:[eax], OP_ADDR_PREFIX
	jne	@F
	xor	AddressSize, 1
	inc	eax
	jmp	skip_prefixes
@@:
	cmp	byte ptr fs:[eax], OP_REPNZ_PREFIX
	jne	@F
	mov	RepPrefix, OP_REPNZ_PREFIX
	inc	eax
	jmp	skip_prefixes
@@:
	cmp	byte ptr fs:[eax], OP_REPZ_PREFIX
	jne	@F
	mov	RepPrefix, OP_REPZ_PREFIX
	inc	eax
	jmp	skip_prefixes
@@:
	ret	
SkipPrefixes	ENDP


;-----------------------------------------------------------------------------
;
;	Reads a virtual video port.
;
;	I: EAX = port
;	O: AL = value.
;	   CF = 0	-	OK
;	        1	-	error (port is not a video port).
;
;-----------------------------------------------------------------------------
ReadVideoPort	PROC	USES ecx edx
; Test if video port.
	cmp	eax, FIRST_VIDEO_PORT
	jnb	@F
	stc
	ret
@@:
	cmp	eax, LAST_VIDEO_PORT
	jb	@F
	stc
	ret
@@:
; Set FS:EDX -> current task's video state structure.
	mov	edx, CurrTaskPtr
	mov	edx, (DosTask PTR fs:[edx]).TaskVideoState

; Test if emulated ports (color/mono).
	test	eax, 10h
	jz	non_emulated

	movzx	ecx, (VIDEO_CONTEXT PTR fs:[edx]).MiscOutput
	and	ecx, 1
	shl	ecx, 5
	test	ecx, eax
	jz	emulated
	mov	al, 0FFh
	clc
	ret

; Read emulated port (3D/Bx)
emulated:
	xor	ecx, 20h
	add	eax, ecx

	cmp	eax, V_CLR_CRT_ADDR
	jne	@F
; Read CRT controllrer address register.
	mov	al, (VIDEO_CONTEXT PTR fs:[edx]).CrtIndex
	clc
	ret
@@:
	cmp	eax, V_CLR_CRT_DATA
	jne	sts1?
; Read CRT controllrer data register.
	cmp	(VIDEO_CONTEXT PTR fs:[edx]).CrtIndex, V_CRT_REGS
	jb	@F
	mov	al, 0FFh
	clc
	ret
@@:
	movzx	eax, (VIDEO_CONTEXT PTR fs:[edx]).CrtIndex
	mov	al, fs:[edx][eax+Crt_Regs]
	clc
	ret

sts1?:
	cmp	eax, V_CLR_STS1
	jne	@F
; Status = 0: neither vertical nor horizonatal retrace in background.
; Reset attributes controller flip-flop.
	mov	(VIDEO_CONTEXT PTR fs:[edx]).AttrFlipFlop, 0
	sub	al, al
	mov	al, 8
	clc
	ret
@@:
	mov	al, 0FFh
	clc
	ret

; Read non-emulated port (3Cx).
non_emulated:
	cmp	eax, V_SEQ_ADDR
	jne	@F
; Read sequencer address register.
	mov	al, (VIDEO_CONTEXT PTR fs:[edx]).SeqIndex
	clc
	ret
@@:
	cmp	eax, V_SEQ_DATA
	jne	gfx_regs?
; Read sequencer data register.
	cmp	(VIDEO_CONTEXT PTR fs:[edx]).SeqIndex, V_SEQ_REGS
	jb	@F
	mov	al, 0FFh
	clc
	ret
@@:
	movzx	eax, (VIDEO_CONTEXT PTR fs:[edx]).SeqIndex
	mov	al, fs:[edx][eax+Seq_Regs]
	clc
	ret

gfx_regs?:
	cmp	eax, V_GFX_ADDR
	jne	@F
; Read graphics controller address register.
	mov	al, (VIDEO_CONTEXT PTR fs:[edx]).GfxIndex
	clc
	ret
@@:
	cmp	eax, V_GFX_DATA
	jne	attr_regs?
; Read graphics controller data register.
	cmp	(VIDEO_CONTEXT PTR fs:[edx]).GfxIndex, V_GFX_REGS
	jb	@F
	mov	al, 0FFh
	clc
	ret
@@:
	movzx	eax, (VIDEO_CONTEXT PTR fs:[edx]).GfxIndex
	mov	al, fs:[edx][eax+Gfx_Regs]
	clc
	ret

attr_regs?:
	cmp	eax, V_ATTR_ADDR
	jne	@F
; Read attributes controller address register.
	mov	al, (VIDEO_CONTEXT PTR fs:[edx]).AttrIndex
	clc
	ret
@@:
	cmp	eax, V_ATTR_IN
	jne	pel_regs?
; Read attributes controller data register.
	and	eax, 1Fh
	cmp	(VIDEO_CONTEXT PTR fs:[edx]).AttrIndex, V_ATTR_REGS
	jb	@F
	mov	al, 0FFh
	clc
	ret
@@:
	movzx	eax, (VIDEO_CONTEXT PTR fs:[edx]).AttrIndex
	mov	al, fs:[edx][eax+Attr_Regs]
	clc
	ret

pel_regs?:
	cmp	eax, V_DAC_READ_ADDR
	jne	@F
; Read sequencer address register.
	movzx	eax, (VIDEO_CONTEXT PTR fs:[edx]).PelReadIndex
	mov	cl, 3
	div	cl
	clc
	ret
@@:
	cmp	eax, V_DAC_DATA
	jne	pel_mask?
; Read DAC data register.
	movzx	eax, (VIDEO_CONTEXT PTR fs:[edx]).PelReadIndex
	mov	al, fs:[edx][eax+Pel_Data]
	inc	(VIDEO_CONTEXT PTR fs:[edx]).PelReadIndex
	cmp	(VIDEO_CONTEXT PTR fs:[edx]).PelReadIndex, 100h * 3
	jb	@F
	sub	(VIDEO_CONTEXT PTR fs:[edx]).PelReadIndex, 100h * 3
@@:
	clc
	ret

pel_mask?:
	cmp	eax, V_DAC_PEL_MASK
	jne	@F
	mov	al, (VIDEO_CONTEXT PTR fs:[edx]).PelMask
	clc
	ret
@@:
	cmp	eax, V_MISC_IN
	jne	@F
	mov	al, (VIDEO_CONTEXT PTR fs:[edx]).MiscOutput
	clc
	ret
@@:
	cmp	eax, V_FEAT_CTL_IN
	jne	@F
	mov	al, (VIDEO_CONTEXT PTR fs:[edx]).FeatureCtl
	clc
	ret
@@:
	cmp	eax, V_STS0
	jne	@F
	mov	al, (VIDEO_CONTEXT PTR fs:[edx]).MiscOutput
	and	al, 4
	shl	al, 2
	clc
	ret

@@:
	mov	al, 0FFh
	clc
	ret
ReadVideoPort	ENDP


;-----------------------------------------------------------------------------
;
;	Writes to a virtual video port.
;
;	I: EAX = port
;	   CL = value.
;	O: CF = 0	-	OK
;	        1	-	error (port is not a video port).
;
;-----------------------------------------------------------------------------
WriteVideoPort	PROC	USES eax ebx edx esi
; Test if video port.
	cmp	eax, FIRST_VIDEO_PORT
	jnb	@F
	stc
	ret
@@:
	cmp	eax, LAST_VIDEO_PORT
	jb	@F
	stc
	ret
@@:

; Set FS:EDX -> current task's video state structure.
	mov	edx, CurrTaskPtr
	mov	edx, (DosTask PTR fs:[edx]).TaskVideoState

; Test if emulated ports (color/mono).
	test	eax, 10h
	jz	non_emulated

	movzx	ebx, (VIDEO_CONTEXT PTR fs:[edx]).MiscOutput
	and	ebx, 1
	shl	ebx, 5
	test	ebx, eax
	jz	emulated
	clc
	ret

; Arite emulated port (3D/Bx)
emulated:
	xor	ebx, 20h
	add	eax, ebx

	cmp	eax, V_CLR_CRT_ADDR
	jne	@F
; Write CRT controller address register.
	mov	(VIDEO_CONTEXT PTR fs:[edx]).CrtIndex, cl
	clc
	ret
@@:
	cmp	eax, V_CLR_CRT_DATA
	jne	feat_ctl?
; Write CRT controller data register.
	cmp	(VIDEO_CONTEXT PTR fs:[edx]).CrtIndex, V_CRT_REGS
	jnb	@F
	movzx	ebx, (VIDEO_CONTEXT PTR fs:[edx]).CrtIndex
	mov	fs:[edx][ebx+Crt_Regs], cl
@@:
	clc
	ret

feat_ctl?:
	clc
	ret

non_emulated:
	cmp	eax, V_SEQ_ADDR
	jne	@F
; Write sequencer address register.
	mov	(VIDEO_CONTEXT PTR fs:[edx]).SeqIndex, cl
	clc
	ret
@@:
	cmp	eax, V_SEQ_DATA
	jne	gfx_regs?
; Write sequencer data register.
	cmp	(VIDEO_CONTEXT PTR fs:[edx]).SeqIndex, V_SEQ_REGS
	jnb	@F
	movzx	ebx, (VIDEO_CONTEXT PTR fs:[edx]).SeqIndex
	mov	fs:[edx][ebx+Seq_Regs], cl
@@:
	clc
	ret

gfx_regs?:
	cmp	eax, V_GFX_ADDR
	jne	@F
; Write graphics controller address register.
	mov	(VIDEO_CONTEXT PTR fs:[edx]).GfxIndex, cl
	clc
	ret
@@:
	cmp	eax, V_GFX_DATA
	jne	attr_regs?
; Write graphics controller data register.
	cmp	(VIDEO_CONTEXT PTR fs:[edx]).GfxIndex, V_GFX_REGS
	jnb	@F
	movzx	ebx, (VIDEO_CONTEXT PTR fs:[edx]).GfxIndex
	mov	fs:[edx][ebx+Gfx_Regs], cl
@@:
	clc
	ret

attr_regs?:
	cmp	eax, V_ATTR_ADDR
	jne	dac_regs?
; Write attribute controller register, according to flip-flop.
	test	(VIDEO_CONTEXT PTR fs:[edx]).AttrFlipFlop, 1
	jnz	attr_data
	mov	(VIDEO_CONTEXT PTR fs:[edx]).AttrIndex, cl
	jmp	@F
attr_data:
	movzx	ebx, (VIDEO_CONTEXT PTR fs:[edx]).AttrIndex
	and	ebx, 1Fh
	cmp	ebx, V_ATTR_REGS
	jnb	end_attr_regs
	mov	fs:[edx][ebx+Attr_Regs], cl
@@:
	xor	(VIDEO_CONTEXT PTR fs:[edx]).AttrFlipFlop, 1
end_attr_regs:
	clc
	ret

dac_regs?:
	cmp	eax, V_DAC_WRITE_ADDR
	jne	@F
; Write DAC write address register.
	movzx	ebx, cl
	mov	esi, ebx
	add	ebx, esi
	add	ebx, esi
	mov	(VIDEO_CONTEXT PTR fs:[edx]).PelWriteIndex, bx
	clc
	ret
@@:
	cmp	eax, V_DAC_READ_ADDR
	jne	@F
; Write DAC read address register.
	movzx	ebx, cl
	mov	esi, ebx
	add	ebx, esi
	add	ebx, esi
	mov	(VIDEO_CONTEXT PTR fs:[edx]).PelReadIndex, bx
	clc
	ret
@@:
	cmp	eax, V_DAC_DATA
	jne	pel_mask?
; Write DAC data registers.
	movzx	ebx, (VIDEO_CONTEXT PTR fs:[edx]).PelWriteIndex
	mov	fs:[edx][ebx+Pel_Data], cl
	inc	(VIDEO_CONTEXT PTR fs:[edx]).PelWriteIndex
	cmp	(VIDEO_CONTEXT PTR fs:[edx]).PelWriteIndex, 100h * 3
	jb	@F
	sub	(VIDEO_CONTEXT PTR fs:[edx]).PelWriteIndex, 100h * 3
@@:
	clc
	ret

pel_mask?:
	cmp	eax, V_DAC_PEL_MASK
	jne	@F
	mov	(VIDEO_CONTEXT PTR fs:[edx]).PelMask, cl
	clc
	ret

@@:
	cmp	eax, V_MISC_OUT
	jne	@F
	mov	(VIDEO_CONTEXT PTR fs:[edx]).MiscOutput, cl
	clc
	ret
@@:
	clc
	ret
WriteVideoPort	ENDP


;-----------------------------------------------------------------------------
;
;	Emulates keyboard I/O. Only Input instructions supported. 
;
;	I:
;	O:
;
;-----------------------------------------------------------------------------
PUBLIC	EmulateKbdIo
EmulateKbdIo	PROC	USES eax ebx ecx edx

; Call emulate generic I/O procedure.
	mov	eax, offset ReadKeyboardPort
	mov	ecx, offset WriteKeyboardPort

	call	EmulateIo
	ret
EmulateKbdIo	ENDP


;-----------------------------------------------------------------------------
;
;	Reads a virtual keyboard port.
;
;	I: EAX = port
;	O: AL = value.
;	   CF = 0	-	OK
;	        1	-	error (port is not a video port).
;
;-----------------------------------------------------------------------------
ReadKeyboardPort	PROC	USES ecx
	cmp	eax, KBD_DATA
	je	read_data
	cmp	eax, KBD_STATUS
	je	read_status
	stc
	ret

read_status:
	sub	al, al			; status = no data.
	mov	ecx, KbdQHead
	cmp	ecx, KbdQTail
	je	@F
	inc	eax			; status = data for system.
@@:
	clc
	ret

read_data:
	mov	ecx, KbdQHead		; Read data at queue head.
	cmp	ecx, KbdQTail		; If already read, return previous
					; code.
	jne	read_new

	dec	ecx
	jnl	@F
	add	ecx, KEYBOARD_Q_SIZE
@@:
	mov	al, KeyboardQ[ ecx ]
	clc
	ret

read_new:
	mov	al, KeyboardQ[ ecx ]	; Read code for the first time.
	inc	ecx			; Update queue head.
	cmp	ecx, KEYBOARD_Q_SIZE
	jb	@F
	sub	ecx, ecx
@@:
	mov	KbdQHead, ecx

	clc
	ret
ReadKeyboardPort	ENDP


;-----------------------------------------------------------------------------
;
;	Filter keyboard port writes.
;
;	I: EAX = port
;	   CL = data
;	O: CF = 0 - OK
;	      = 1 - error (wrong port).
;
;-----------------------------------------------------------------------------
WriteKeyboardPort	PROC	USES eax ecx edx
	cmp	eax, KBD_DATA
	je	write_data
	cmp	eax, KBD_STATUS
	jne	@F

	mov	ch, cl
	and	ch, 0F0h
	cmp	ch, 0F0h
	jne	write_data
; Prevent program from booting the computer.
	or	cl, 1
	jmp	write_data
@@:
	stc
	ret

write_data:
	mov	edx, eax
	mov	al, cl
	out	dx, al

	clc
	ret
WriteKeyboardPort	ENDP


;-----------------------------------------------------------------------------
;
;	Emulate PIT I/O. Trapped to support virtual timers with better than
; 18.2 ticks/sec resolution.
;
;-----------------------------------------------------------------------------
EmulatePITIo	PROC

; Call emulate generic I/O procedure.
	mov	eax, offset ReadPITPort
	mov	ecx, offset WritePITPort

	call	EmulateIo
	ret
EmulatePITIo	ENDP


;-----------------------------------------------------------------------------
;
;	Reads a virtual timer port.
;
;	I: EAX = port
;	O: AL = value.
;	   CF = 0	-	OK
;	        1	-	error (wrong port).
;
;-----------------------------------------------------------------------------
ReadPITPort	PROC	USES edx
; Meanwhile reads are supported.
	cmp	eax, PIT_CH0_COUNT
	jb	@F
	cmp	eax, PIT_CONTROL
	ja	@F

; Read.
	mov	edx, eax
	in	al, dx
	clc
	ret

@@:
	stc
	ret
ReadPITPort	ENDP


;-----------------------------------------------------------------------------
;
;	Writes a virtual timer port.
;
;	I: EAX = port
;	   CL = value.
;	O: CF = 0	-	OK
;	        1	-	error (wrong port).
;
;-----------------------------------------------------------------------------
WritePITPort	PROC	USES ebx edx
; Meanwhile reads are supported.
	cmp	eax, PIT_CH0_COUNT
	jb	wrong_port
	cmp	eax, PIT_CONTROL
	ja	wrong_port

; If write to channel 1 count, return with error (restricted).
	cmp	eax, PIT_CH1_COUNT
	jne	@F
	stc
	ret

@@:
; Write to control register?
	cmp	eax, PIT_CONTROL
	jne	ch0_count?

; Is channel 1 selected?
	mov	edx, ecx
	and	edx, 11000000b
	cmp	edx, 01000000b
	jne	@F

; Return with error (restricted).
	stc
	ret
@@:
; Is channel 0 selected?
	test	edx, edx
	jz	select_ch0

do_write:
; Write is allowed (channel 2 select or read back cmd).
	mov	edx, eax
	mov	eax, ecx
	out	dx, al
	clc
	ret

select_ch0:

; Only read/write LSB, MSB is implemented
	mov	edx, ecx
	and	edx, 00110000b
	cmp	edx, 00110000b
	jne	do_write

	mov	edx, ecx
	and	edx, 00001110b

; Only mode 2 is supported.
	cmp	edx, 00000110b
	je	@F

	stc
	ret

@@:

; Mode isn't reset for channel 0 - virtual timer is yet simple. Only mark
; channel 0 selected.
	mov	edx, CurrTaskPtr
	inc	(DosTask PTR fs:[edx]).TaskPITCh0Sel
	clc
	ret

ch0_count?:
	cmp	eax, PIT_CH0_COUNT
	jne	ch2_count

; Set new value for reported ticks for this task.
	mov	edx, CurrTaskPtr

; If select is > 1, then LSB is already written. If it's not 1 (0), then
; init is going wrong (channel not selected). Discard byte.
	cmp	(DosTask PTR fs:[edx]).TaskPITCh0Sel, 1
	ja	set_ch0_count
	jz	save_ch0_count_lsb
	clc
	ret

save_ch0_count_lsb:

; Save LSB in TaskTicksReport field.
	mov	byte ptr (DosTask PTR fs:[edx]).TaskTicksReport, cl
	inc	(DosTask PTR fs:[edx]).TaskPITCh0Sel
	clc
	ret

set_ch0_count:
	movzx	eax, cl
	shl	eax, 8
	mov	ebx, (DosTask PTR fs:[edx]).TaskTicksReport
	and	ebx, 0FFh
	or	ebx, eax

; If value is smaller than one kernel tick, set one kernel tick.
	push	edx
	mov	eax, PIT_FREQUENCY
	sub	edx, edx
	div	TickToSec
	pop	edx

	cmp	ebx, eax
	jnb	@F
	mov	ebx, eax

@@:
	sub	edx, edx
	xchg	eax, ebx
	div	ebx
	mov	edx, CurrTaskPtr
	mov	(DosTask PTR fs:[edx]).TaskTicksReport, eax

; Unselect channel 0.
	mov	(DosTask PTR fs:[edx]).TaskPITCh0Sel, 0
	clc
	ret

ch2_count:
	mov	edx, eax
	mov	eax, ecx
	out	dx, al
	clc
	ret

wrong_port:
	stc
	ret
WritePITPort	ENDP


;-----------------------------------------------------------------------------
;
;	Emulate PIC I/O. This will allow full virtual PIC behaviour in the
; system.
;
;-----------------------------------------------------------------------------
EmulatePICIo	PROC

; Call emulate generic I/O procedure.
	mov	eax, offset ReadPICPort
	mov	ecx, offset WritePICPort
	call	EmulateIo
	ret
EmulatePICIo	ENDP



;-----------------------------------------------------------------------------
;
;	Reads a virtual interrupt controller port.
;
;	I: EAX = port
;	O: AL = value.
;	   CF = 0	-	OK
;	        1	-	error (wrong port).
;
;-----------------------------------------------------------------------------
ReadPICPort	PROC	USES edx
	cmp	eax, PIC_MASTER
	je	read

	cmp	eax, PIC_MASTER_MASK
	jne	@F

	mov	al, byte ptr VirtualImr
	clc
	ret
@@:
	cmp	eax, PIC_SLAVE
	je	read

	cmp	eax, PIC_SLAVE_MASK
	jne	@F
	mov	al, byte ptr VirtualImr[ 1 ]
	clc
	ret
@@:
	stc
	ret

read:
	mov	edx, eax
	in	al, dx
	clc
	ret
ReadPICPort	ENDP


;-----------------------------------------------------------------------------
;
;	Writes a virtual interrupt controller port.
;
;	I: EAX = port
;	   CL = value.
;	O: CF = 0	-	OK
;	        1	-	error (wrong port).
;
;-----------------------------------------------------------------------------
WritePICPort	PROC	USES ebx edx
	cmp	eax, PIC_MASTER
	jne	@F
	cmp	cl, 20h
	jne	write

; Clear the least virtual ISR's bit (first byte).
	movzx	edx, byte ptr VirtualIsr
	dec	edx
	and	byte ptr VirtualIsr, dl
	clc
	ret

@@:
	cmp	eax, PIC_SLAVE
	jne	@F
	cmp	cl, 20h
	jne	write

; Clear the least virtual ISR's bit (second byte).
	movzx	edx, byte ptr VirtualIsr[ 1 ]
	dec	edx
	and	byte ptr VirtualIsr[ 1 ], dl
	clc
	ret

@@:
	cmp	eax, PIC_MASTER_MASK
	jne	@F
	mov	byte ptr VirtualImr, cl
	clc
	ret
@@:
	cmp	eax, PIC_SLAVE_MASK
	jne	@F
	mov	byte ptr VirtualImr[ 1 ], cl
	clc
	ret
@@:
	stc
	ret

write:
	mov	edx, eax
	mov	eax, ecx
	out	dx, al
	clc
	ret
WritePICPort	ENDP


;-----------------------------------------------------------------------------
;
;	Emulate DMA. This will allow DOS programs work with DMA.
;
;-----------------------------------------------------------------------------
EmulateDMAIo	PROC
; Call emulate generic I/O procedure.
	mov	eax, offset ReadDMAPort
	mov	ecx, offset WriteDMAPort
	call	EmulateIo
	ret
EmulateDMAIo	ENDP


;-----------------------------------------------------------------------------
;
;	Reads a DMA port.
;
;	I: EAX = port
;	O: AL = value.
;	   CF = 0	-	OK
;	        1	-	error (wrong port).
;
;-----------------------------------------------------------------------------
ReadDMAPort	PROC	USES edx
	cmp	eax, 20h
	jb	dma_port
	cmp	eax, 80h
	jb	not_dma_port
	cmp	eax, 8Fh
	ja	not_dma_port
dma_port:
	mov	edx, eax
	in	al, dx
	clc
	ret
not_dma_port:
	stc
	ret
ReadDMAPort	ENDP


;-----------------------------------------------------------------------------
;
;	Writes a DMA port.
;
;	I: EAX = port
;	   CL = value.
;	O: CF = 0	-	OK
;	        1	-	error (wrong port).
;
;-----------------------------------------------------------------------------
WriteDMAPort	PROC	USES eax ebx ecx edx esi edi
	cmp	eax, 20h
	jb	dma_port
	cmp	eax, 80h
	jb	not_dma_port
	cmp	eax, 8Fh
	ja	not_dma_port

dma_port:
	cmp	eax, DMA1_MASK
	jne	is_dma1_addr_clear?

; A DMA 1 channel is being programmed.
	test	cl, 00000100b
	jnz	do_write

; Unmask virtual register and start programming. CL holds the channel to program.
	mov	DmaMask, cl
	and	cl, 00000011b

;	mov	al, 1
;	shl	al, cl
;	not	al
;	and	DmaMaskReg, al

	mov	ch, DmaMode
	and	ch, 00001100b

; If mode is write to memory, setup DMA range and do the copy later.
	movzx	edx, cl
	cmp	ch, 00000100b
	jne	read_from_mem

	mov	eax, Dma1BaseAddr[ edx * 4 ]
	mov	ebx, CurrentTask
	mov	DmaIoRange[ ebx * 8 ], eax
	mov	eax, Dma1Count[ edx * 4 ]
	inc	eax
	mov	DmaIoRange[ ebx * 8 ][ 4 ], eax
	mov	RetireDmaFlag, 1
	jmp	program_addr
;	jmp	do_unmask

; If mode is read from memory, copy memory to DMA buffer and go on.
read_from_mem:
	push	es
	push	ecx

	push	fs
	pop	es
	mov	esi, Dma1BaseAddr[ edx * 4 ]
	mov	edi, DmaBufAddr
	add	edi, OS_1ST_MB
	cld
	mov	ecx, Dma1Count[ edx * 4 ]
	inc	ecx
		rep	movs byte ptr es:[edi], es:[esi]

	pop	ecx
	pop	es

program_addr:
; Program the addresses.
	movzx	edx, cl
	mov	eax, DmaBufAddr
	shl	edx, 1		; EDX -> base address for appropriate channel.
	out	dx, al
	IODelay
	xchg	al, ah
	out	dx, al
	IODelay
	shr	eax, 16
	mov	edx, Dma1PageAddress[ edx * 2 ]
	out	dx, al
	IODelay

	movzx	edx, cl
	mov	eax, Dma1Count[ edx * 4 ]
	shl	edx, 1
	inc	edx
	out	dx, al
	IODelay
	xchg	al, ah
	out	dx, al
	IODelay

;	clc
;	ret

do_unmask:
; Unmask the channel.
	mov	al, DmaMask
	out	DMA1_MASK, al
; Clear the internal flipflops.
;	mov	Dma1FlipFlops, 0
	clc
	ret

set_mask1:
	jmp	do_write
;	and	cl, 00000011b
;	mov	al, 1
;	shl	al, cl
;	or	DmaMaskReg, al
;	clc
;	ret
	mov	Dma1FlipFlops, 0
	
is_dma1_addr_clear?:
; If a flip flop is cleared, clear it.
	cmp	eax, DMA1_ADDR_CLEAR
	jne	is_dma1_mode?
	mov	Dma1FlipFlops, 0
	jmp	do_write
;	clc
;	ret

is_dma1_mode?:
	cmp	eax, DMA1_MODE
	jne	is_dma1_addr?
	mov	DmaMode, cl
	jmp	do_write

is_dma1_addr?:
; If an address or count register is programmed.
	cmp	eax, DMA1_CMD
	jnb	is_dma1_page?

	test	eax, 1		; Just bypass count registers
	jnz	get_count

; Write address registers.
	mov	edx, eax
	shr	edx, 1
	bt	Dma1FlipFlops, edx
	jc	@F

	mov	byte ptr Dma1BaseAddr[ edx * 4 ], cl
	bts	Dma1FlipFlops, edx
	clc
	ret
@@:
	mov	byte ptr Dma1BaseAddr[ edx * 4 ][ 1 ], cl
	btc	Dma1FlipFlops, edx
	clc
	ret

get_count:
	push	eax
	push	edx

;	mov	edx, eax
;	mov	al, cl
;	out	dx, al

	pop	edx
	pop	eax

	mov	edx, eax
	shr	edx, 1
	mov	eax, edx
	add	edx, 4
	bt	Dma1FlipFlops, edx
	jc	@F

	mov	byte ptr Dma1Count[ eax * 4 ], cl
	bts	Dma1FlipFlops, edx
	clc
	ret

@@:
	mov	byte ptr Dma1Count[ eax * 4 ][ 1 ], cl
	btc	Dma1FlipFlops, edx
	clc
	ret

is_dma1_page?:
	cmp	eax, DMA_CH0_PAGE
	jne	@F
	mov	byte ptr Dma1BaseAddr[ 2 ], cl
	clc
	ret

@@:
	cmp	eax, DMA_CH1_PAGE
	jne	@F
	mov	byte ptr Dma1BaseAddr[ 4 ][ 2 ], cl
	clc
	ret

@@:
	cmp	eax, DMA_CH2_PAGE
	jne	@F
	mov	byte ptr Dma1BaseAddr[ 8 ][ 2 ], cl
	clc
	ret

@@:
	cmp	eax, DMA_CH3_PAGE
	jne	do_write
	mov	byte ptr Dma1BaseAddr[ 12 ][ 2 ], cl
	clc
	ret

do_write:
	mov	edx, eax
	mov	al, cl
	out	dx, al
	clc
	ret

not_dma_port:
	stc
	ret
WriteDMAPort	ENDP


;-----------------------------------------------------------------------------
;
;	Retires a DMA transfer.
;
;	In:	AL = channel
;
;-----------------------------------------------------------------------------
PUBLIC	RetireDma
RetireDma	PROC	USES	es eax ecx edx esi edi
	cmp	RetireDmaFlag, 0
	jne	@F
	ret

@@:
	mov	RetireDmaFlag, 0
	movzx	eax, al

	mov	ecx, MAX_TASKS
	sub	edx, edx
seek_in_process:
	cmp	DmaIoRange[ edx * 8 ][ 4 ], 0
	jne	in_process
	inc	edx
	dec	ecx
	jnz	seek_in_process
	ret

in_process:
	TASK_PTR	FddSema4Own, ebx
	mov	edx, FddSema4Own
	cmp	edx, CurrentTask
	je	@F

	mov	eax, (DosTask PTR fs:[ebx]).TaskPdb
	mov	cr3, eax

@@:

; Copy data from DMA system buffer to program's buffer.
	mov	esi, DmaBufAddr
	add	esi, OS_1ST_MB
	mov	edi, DmaIoRange[ edx * 8 ]
	mov	ecx, DmaIoRange[ edx * 8 ][ 4 ]
	push	fs
	pop	es

	cld
		rep	movs byte ptr es:[ edi ], es:[ esi ]

	TASK_PTR	CurrentTask, ebx
	mov	edx, FddSema4Own
	cmp	edx, CurrentTask
	je	@F

	mov	eax, (DosTask PTR fs:[ebx]).TaskPdb
	mov	cr3, eax
@@:

; Clear in-process indicator (set range = 0)
	mov	DmaIoRange[ edx * 8 ], 0
	mov	DmaIoRange[ edx * 8 ][ 4 ], 0
;	mov	Dma1BaseAddr[ eax * 4  ], 0
;	mov	Dma1Count[ eax * 4 ], 0

; Unblock task.
;	mov	edx, CurrTaskPtr
;	and	(DosTask PTR fs:[edx]).TaskBlock, NOT DMA_REQUEST
;	jnz	@F
;	and	(DosTask PTR fs:[edx]).TaskState, NOT TASK_BLOCKED
@@:
	ret

RetireDma	ENDP


;-----------------------------------------------------------------------------
;
;	DMA timer handler. If some DMA request is in progress, tests if it's
; completed.
;
;-----------------------------------------------------------------------------
PUBLIC	DmaTimer
DmaTimer	PROC
	mov	ecx, MAX_TASKS
	sub	edx, edx
seek_in_process:
	cmp	DmaIoRange[ edx * 8 ][ 4 ], 0
	jne	in_process
	inc	edx
	dec	ecx
	jnz	seek_in_process
	ret

in_process:
IF 0
	mov	cl, DmaMode
	and	cl, 3
	mov	ah, 1
	shl	ah, cl
	in	al, DMA1_STATUS
	test	al, ah
	jnz	complete
	ret

complete:
ENDIF

; Copy data from DMA system buffer to program's buffer.
	mov	esi, DmaBufAddr
	add	esi, OS_1ST_MB
	mov	edi, DmaIoRange[ edx * 8 ]
	mov	ecx, DmaIoRange[ edx * 8 ][ 4 ]
	push	es
	push	fs
	pop	es

	cld
		rep	movs byte ptr es:[ edi ], es:[ esi ]
	pop	es

; Clear in-process indicator (set range = 0)
	mov	DmaIoRange[ edx * 8 ], 0
	mov	DmaIoRange[ edx * 8 ][ 4 ], 0
	mov	Dma1BaseAddr[ 8 ], 0
	mov	Dma1Count[ 8 ], 0

; Unblock task.
	mov	edx, CurrTaskPtr
	and	(DosTask PTR fs:[edx]).TaskBlock, NOT DMA_REQUEST
	jnz	@F
	and	(DosTask PTR fs:[edx]).TaskState, NOT TASK_BLOCKED
@@:
	ret

DmaTimer	ENDP


;-----------------------------------------------------------------------------
;
;	Emulate DMA. This will allow DOS programs work with DMA.
;
;-----------------------------------------------------------------------------
EmulateFDCIo	PROC
; Call emulate generic I/O procedure.
	mov	eax, offset ReadFDCPort
	mov	ecx, offset WriteFDCPort
	call	EmulateIo
	ret
EmulateFDCIo	ENDP


;-----------------------------------------------------------------------------
;
;	Reads a DMA port.
;
;	I: EAX = port
;	O: AL = value.
;	   CF = 0	-	OK
;	        1	-	error (wrong port).
;
;-----------------------------------------------------------------------------
ReadFDCPort	PROC	USES	edx
	cmp	eax, 3F0h
	jnb	@F
	ret
@@:
	cmp	eax, 3F7h
	jna	@F
	stc
	ret
@@:
	mov	edx, eax
	in	al, dx

	cmp	edx, 3F4h
	jne	@F

	mov	ah, FdcStatus
	and	ah, 80h
	jnz	@F
	mov	FdcStatus, al
	and	al, 80h
	jz	@F

	push	eax
	mov	al, 2
	call	RetireDma
	pop	eax

@@:
	clc
	ret
ReadFDCPort	ENDP


;-----------------------------------------------------------------------------
;
;	Writes a DMA port.
;
;	I: EAX = port
;	   CL = value.
;	O: CF = 0	-	OK
;	        1	-	error (wrong port).
;
;-----------------------------------------------------------------------------
WriteFDCPort	PROC	USES	eax edx
	cmp	eax, 3F0h
	jnb	@F
	ret
@@:
	cmp	eax, 3F7h
	jna	@F
	stc
	ret
@@:
	mov	edx, eax
	mov	al, cl
	out	dx, al
	clc
	ret
WriteFDCPort	ENDP


;-----------------------------------------------------------------------------
;
;	Traps general devices ports. Patches the TSS I/O permission bitmap
; according to this:
;	1) If the current task is owner of a device, the ports are allowed
;	2) Else, ports are trapped.
;
;-----------------------------------------------------------------------------
PUBLIC	TrapGenDevPorts
TrapGenDevPorts	PROC	USES eax ebx ecx edx esi edi
	mov	ecx, NumGenDevs
	mov	edx, offset GenDevices
	mov	esi, TssBase
	movzx	edi, (Tss386 PTR fs:[esi]).IoTableBase

next_device:
; Device available?
	cmp	(GenDevice PTR [edx]).DevSema4.State, 0
	je	trap_ports

; CurrentTask is the device's owner?
	mov	eax, CurrentTask
	cmp	eax, (GenDevice PTR [edx]).DevSema4.Owner
	jne	trap_ports

; Allow access to ports.
	sub	ebx, ebx
@@:
	movzx	eax, (GenDevice PTR [edx]).Ports[ebx*2]
	btc	fs:[esi][edi], eax
	inc	ebx
	cmp	bl, (GenDevice PTR [edx]).NPorts
	jb	@B
	jmp	cont

trap_ports:
	sub	ebx, ebx
@@:
	movzx	eax, (GenDevice PTR [edx]).Ports[ebx*2]
	bts	fs:[esi][edi], eax
	inc	ebx
	cmp	bl, (GenDevice PTR [edx]).NPorts
	jb	@B

cont:
	add	edx, SIZEOF (GenDevice)
	dec	ecx
	jnz	next_device

	ret
TrapGenDevPorts	ENDP


;-----------------------------------------------------------------------------
;
;	Releases general devices ports and allows access to them.
;
;-----------------------------------------------------------------------------
PUBLIC	RelGenDevPorts
RelGenDevPorts	PROC	USES eax ebx ecx edx esi edi
	mov	ecx, NumGenDevs
	mov	edx, offset GenDevices
	mov	esi, TssBase
	movzx	edi, (Tss386 PTR fs:[esi]).IoTableBase

next_device:
	sub	ebx, ebx
@@:
	movzx	eax, (GenDevice PTR [edx]).Ports[ebx*2]
	btc	fs:[esi][edi], eax
	inc	ebx
	cmp	bl, (GenDevice PTR [edx]).NPorts
	jb	@B

	add	edx, SIZEOF (GenDevice)
	dec	ecx
	jnz	next_device

	ret
RelGenDevPorts	ENDP


;-----------------------------------------------------------------------------
;
;	Releases general devices semaphores trapped by the CurrentTask.
; Called when the task is being deleted.
;
;-----------------------------------------------------------------------------
Public	RelGenDevSema4s
RelGenDevSema4s	PROC	USES	gs eax ebx ecx edx esi edi
	mov	ecx, NumGenDevs
	mov	edx, offset GenDevices
	mov	esi, TssBase
	movzx	edi, (Tss386 PTR fs:[esi]).IoTableBase

next_device:
; If a device is avaliable, go ahead.
	cmp	(GenDevice PTR [edx]).DevSema4.State, 0
	je	cont

; Release a semaphore. If a task wasn't device's owner, go ahead.
	mov	eax, CurrentTask
	mov	ebx, (GenDevice PTR [edx]).DevSema4.Owner

	push	eax
	push	ecx
	push	ds
	pop	gs
	lea	ecx, (GenDevice PTR [edx]).DevSema4
	call	Sema4Up
	pop	ecx
	pop	eax

	cmp	eax, ebx
	jne	cont

IF 0
; A task was semaphore's owner.
	sub	ebx, ebx
@@:
	movzx	eax, (GenDevice PTR [edx]).Ports[ebx*2]
	btc	fs:[esi][edi], eax
	inc	ebx
	cmp	bl, (GenDevice PTR [edx]).NPorts
	jb	@B
ENDIF

cont:
	add	edx, SIZEOF (GenDevice)
	dec	ecx
	jnz	next_device

	ret
RelGenDevSema4s	ENDP



;-----------------------------------------------------------------------------
;
;	Emulate access to general device's port.
;
;-----------------------------------------------------------------------------
EmulateGenDevIo	PROC	USES	edx
; Call emulate generic I/O procedure.
	mov	eax, offset ReadGenDevPort
	mov	ecx, offset WriteGenDevPort
	call	EmulateIo
	ret
EmulateGenDevIo	ENDP


;-----------------------------------------------------------------------------
;
;	Frond-end for read access to general device port.
;
;-----------------------------------------------------------------------------
ReadGenDevPort	PROC	USES edx
	sub	edx, edx
	call	AccessGenDevPort
	ret
ReadGenDevPort	ENDP


;-----------------------------------------------------------------------------
;
;	Frond-end for read access to general device port.
;
;-----------------------------------------------------------------------------
WriteGenDevPort	PROC	USES edx
	mov	edx, 1
	call	AccessGenDevPort
	ret
WriteGenDevPort	ENDP


;-----------------------------------------------------------------------------
;
;	Reads/Writes a general device port.
;
;	I: EAX = port
;	   (CL = value).
;	   DL = access (0 = read, 1 = write).
;	O: CF = 0	-	OK
;	        1	-	error (wrong port).
;
;-----------------------------------------------------------------------------
AccessGenDevPort	PROC	USES	gs ebx ecx edx esi edi
LOCAL	Access: dword,
	Port: dword,
	Value: byte

	mov	Access, edx
	mov	Port, eax
	mov	Value, cl

	mov	edx, offset	GenDevices
	mov	ecx, NumGenDevs
next_device:
	sub	ebx, ebx
next_port:
	movzx	esi, (GenDevice PTR [edx]).Ports[ebx*2]
	cmp	eax, esi
	je	found_port
	inc	ebx
	cmp	bl, (GenDevice PTR [edx]).NPorts
	jb	next_port

	add	edx, SIZEOF (GenDevice)
	dec	ecx
	jnz	next_device

; A port being accessed is not found.
	stc
	ret

found_port:
;
; Try to acquire the semaphore. This may acquire a semaphore or put the task
; to sleep and return in a new context.
;
	mov	eax, CurrentTask
	push	ds
	pop	gs
	lea	ecx, (GenDevice PTR [edx]).DevSema4
	call	Sema4Down

; If the semaphore was acquired, allow access to ports.
	test	al, al			; 0 means acquired.
	jz	@F

;
; If a semaphore wasn't acquired, the CurrentTask is blocked on an I/O
; instruction. ExcOffs will not be updated.
;
	mov	NoEipUpdate, 1
	jmp	ok_ret

@@:
; Allow access to ports.
	mov	esi, TssBase
	movzx	edi, (Tss386 PTR fs:[esi]).IoTableBase

	sub	ebx, ebx
@@:
	movzx	eax, (GenDevice PTR [edx]).Ports[ebx*2]
	btc	fs:[esi][edi], eax
	inc	ebx
	cmp	bl, (GenDevice PTR [edx]).NPorts
	jb	@B

; Now emulate the I/O instruction.
	cmp	Access, 0
	jne	do_write

; Read.
	mov	edx, Port
	in	al, dx
	jmp	ok_ret
do_write:
; Write.
	mov	edx, Port
	mov	al, Value
	out	dx, al

ok_ret:
	clc
	ret
AccessGenDevPort	ENDP


CODE32	ENDS

END
