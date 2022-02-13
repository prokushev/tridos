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
;				DEVICES.INC
;				-----------
;	Basic devices programming include file for Tripple-DOS.
;
;	For MASM v6.1x.
;
;=============================================================================

IFNDEF	DEVICES_INC
 DEVICES_INC	EQU	1

	INCLUDE	TASKMAN.INC

;
;	General macros.
;
IODelay		MACRO
; Delay after in/out instructions.
	push	ecx
	mov	ecx, 8000h
	loop	$
	pop	ecx
ENDM


;-----------------------------------------------------------------------------
; BIOS data area.
;-----------------------------------------------------------------------------
BIOS_CRT_BASE	EQU	463h		; Base port for CRT addr. (3B0/3D0).
BIOS_BOOT_ADDR	EQU	467h		; Far ptr to BOOT address.

;-----------------------------------------------------------------------------
; Video.
;-----------------------------------------------------------------------------
MONO_BUF	EQU	0B0000h
CLR_TXT_BUF	EQU	0B8000h
CLR_GFX_BUF	EQU	0A0000h

; CRT controller ports and registers.
V_CLR_CRT_ADDR	EQU	3D4h
V_CLR_CRT_DATA	EQU	3D5h
V_MONO_CRT_ADDR	EQU	3B4h
V_MONO_CRT_DATA	EQU	3B5h

	V_Crt_HOR_TOTAL		EQU	0
	V_Crt_HOR_DISP		EQU	1
	V_Crt_HOR_BLANK_ST	EQU	2
	V_Crt_HOR_BLANK_END	EQU	3
	V_Crt_HOR_RETRACE_ST	EQU	4
	V_Crt_HOR_RETRACE_END	EQU	5
	V_Crt_VERT_TOTAL	EQU	6
	V_Crt_OVERFLOW		EQU	7
	V_Crt_PRESET_ROW_SCAN	EQU	8
	V_Crt_MAX_SCAN_LINE	EQU	9
	V_Crt_CURSOR_ST		EQU	0Ah
	V_Crt_CURSOR_END	EQU	0Bh	V_Crt_ST_ADDR_MSB	EQU	0Ch
	V_Crt_ST_ADDR_LSB	EQU	0Dh
	V_Crt_CURSOR_ADDR_MSB	EQU	0Eh
	V_Crt_CURSOR_ADDR_LSB	EQU	0Fh
	V_Crt_VERT_RETRACE_ST	EQU	10h
	V_Crt_VERT_RETRACE_END	EQU	11h
	V_Crt_VERT_END		EQU	12h
	V_Crt_OFFSET		EQU	13h
	V_Crt_UNDERLINE		EQU	14h
	V_Crt_VERT_BLANK_ST	EQU	15h
	V_Crt_VERT_BLANK_END	EQU	16h
	V_Crt_MODE_CTL		EQU	17h
	V_Crt_LINE_CMP		EQU	18h

V_CRT_REGS	=	19h

; Sequencer ports and registers.
V_SEQ_ADDR	EQU	3C4h
V_SEQ_DATA	EQU	3C5h

	V_Seq_RESET		EQU	0
	V_Seq_CLOCK_MODE	EQU	1
	V_Seq_BIT_PLANE_WRITE	EQU	2
	V_Seq_CHAR_GEN_SELECT	EQU	3
	V_Seq_MEM_MODE		EQU	4

V_SEQ_REGS	=	5

; Graphics controller ports and registers.
V_GFX_ADDR	EQU	3CEh
V_GFX_DATA	EQU	3CFh

	V_Gfx_SET_RESET		EQU	0
	V_Gfx_SET_RESET_ENABLE	EQU	1
	V_Gfx_COLOR_CMP		EQU	2
	V_Gfx_DATA_ROTATE	EQU	3
	V_Gfx_BIT_PLANE_READ	EQU	4
	V_Gfx_MODE		EQU	5
	V_Gfx_MISC		EQU	6
	V_Gfx_COLOR_DONT_CARE	EQU	7
	V_Gfx_BIT_MASK		EQU	8

V_GFX_REGS	=	9

; Attribute controller ports and registers.
; Accesses must be separated by >= 250 ns.
V_ATTR_ADDR	EQU	3C0h
V_ATTR_OUT	EQU	3C0h
V_ATTR_IN	EQU	3C1h

V_ATTR_PALETTE_REGS	=	10h

	V_Attr_MODE_CTL		EQU	10h
	V_Attr_BORDER_COLOR	EQU	11h
	V_Attr_CLR_PLANE_ENABLE	EQU	12h
	V_Attr_HOR_PANNING	EQU	13h
	V_Attr_CLR_SELECT	EQU	14h

	V_Attr_SCR_ENABLE	EQU	20h

V_ATTR_REGS	=	V_ATTR_PALETTE_REGS + 5

; DAC ports and registers.
V_DAC_PEL_MASK		EQU	3C6h
V_DAC_STATE_IN		EQU	3C7h
V_DAC_READ_ADDR		EQU	3C7h
V_DAC_WRITE_ADDR	EQU	3C8h
V_DAC_DATA		EQU	3C9h

V_DAC_REGS	=	100h * 3 + 1


V_CLR_FEAT_CTL	EQU	3DAh
V_CLR_STS1	EQU	3DAh
V_MONO_FEAT_CTL	EQU	3BAh
V_MONO_STS1	EQU	3BAh

V_MISC_OUT	EQU	3C2h
V_MISC_IN	EQU	3CCh
V_FEAT_CTL_IN	EQU	3CAh

V_STS0		EQU	3C2h

V_VGA_ENABLE	EQU	3C3h

FIRST_VIDEO_PORT	EQU	3B0h
LAST_VIDEO_PORT		EQU	3DFh


VIDEO_CONTEXT	STRUC
	Crt_Regs	=	$
ORG	$ + V_CRT_REGS
	Seq_Regs	=	$
ORG	$ + V_SEQ_REGS
	Gfx_Regs	=	$
ORG	$ + V_GFX_REGS
	Attr_Regs	=	$
ORG	$ + V_ATTR_REGS
	PelMask		DB	?
	Pel_Data	=	$
ORG	$ + V_DAC_REGS - 1

	MiscOutput	DB	?
	CrtIndex	DB	?
	SeqIndex	DB	?
	GfxIndex	DB	?
	AttrIndex	DB	?
	AttrFlipFlop	DB	?
	PelReadIndex	DW	?
	PelWriteIndex	DW	?
	FeatureCtl	DB	?
VIDEO_CONTEXT	ENDS

; Save video "bunch" registers (address = [base], data = [base+1]).
SAVE_BUNCH_REGS	MACRO	BaseAddr:REQ, EndReg:REQ
LOCAL	save_loop

	mov	edx, BaseAddr
	sub	ah, ah
save_loop:
	mov	al, ah
	out	dx, al
	inc	edx
	in	al, dx
	stosb
	inc	ah
	dec	edx
	cmp	ah, EndReg
	jb	save_loop
ENDM


; Restore video "bunch" registers (address = [base], data = [base+1]).
REST_BUNCH_REGS	MACRO	BaseAddr:REQ, EndReg:REQ
LOCAL	rest_loop
	mov	ch, EndReg
	mov	edx, BaseAddr
	sub	al, al
rest_loop:
	mov	ah, es:[esi]
	inc	esi
	out	dx, ax

	inc	eax
	cmp	al, EndReg
	jb	rest_loop
ENDM


VIDEO_MONO	EQU	1
VIDEO_CGA	EQU	2
VIDEO_EGA	EQU	3
VIDEO_MCGA	EQU	4
VIDEO_VGA	EQU	5

;-----------------------------------------------------------------------------
; CMOS.
;-----------------------------------------------------------------------------
; CMOS ports.
CMOS_ADDR	EQU	70h
CMOS_DATA	EQU	71h

; CMOS addresses
	Cmos_BOOT_STATE	EQU	0Fh	; CMOS boot state reg.
	Cmos_MASK_NMI	EQU	80h	; Value to mask NMI with port 70h
	Cmos_RTC_HOURS	EQU	04h	; CMOS hours
	Cmos_RTC_MIN	EQU	02h	; CMOS minutes
	Cmos_RTC_SEC	EQU	0	; CMOS seconds
	Cmos_XMEM_SIZE0	EQU	30h	; Extended memory size LSB
	Cmos_XMEM_SIZE1	EQU	31h	; Extended memory size MSB

; CMOS CPU reset options
	CMD_AltCtrlDel	EQU	00h
	CMD_ChkMemSize	EQU	01h
	CMD_TestMem	EQU	02h
	CMD_CrcMem	EQU	03h
	CMD_Reboot	EQU	04h
	CMD_PicAndJmp	EQU	05h
	CMD_CpuPmTest	EQU	06h
	CMD_LowToXmsMov	EQU	09h
	CMD_ImmedJmp	EQU	0Ah


;-----------------------------------------------------------------------------
; Keyboard.
;-----------------------------------------------------------------------------
; Keyboard ports.
KBD_DATA	EQU	60h
KBD_PORT_B	EQU	61h
KBD_STATUS	EQU	64h
KBD_COMMAND	EQU	64h

; Keyboard status keys
	Kbd_LShift	EQU	0001h
	Kbd_RShift	EQU	0002h
	Kbd_LCtrl	EQU	0004h
	Kbd_RCtrl	EQU	0008h
	Kbd_LAlt	EQU	0010h
	Kbd_RAlt	EQU	0020h
	Kbd_CapsLock	EQU	0040h
	Kbd_NumLock	EQU	0080h

	Key_LShift	EQU	002Ah
	Key_RShift	EQU	0036h
	Key_LCtrl	EQU	001Dh
	Key_RCtrl	EQU	0E01Dh
	Key_LAlt	EQU	38h
	Key_RAlt	EQU	0E038h
	Key_CapsLock	EQU	003Ah
	Key_NumLock	EQU	0045h

	KEY_Released	EQU	0F0h	; Break code prefix.

; Keyboard status byte (status port, 64h - rd)
	STS_Data_Ready	EQU	01h	; 8042 wants to send data.
	STS_Input_Data	EQU	02h	; Data waits for 8042 in input reg.
	STS_Sys		EQU	04h	; System flag
	STS_Input_Cmd	EQU	08h	; Data in input reg. is a command.
	STS_Kbd_Enabled	EQU	10h	; Keyboard enabled.
	STS_Tx_TimeOut	EQU	20h	; Transmit timeout
	STS_Rx_TimeOut	EQU	40h	; Receive timeout
	STS_Even_Parity	EQU	80h	; Should be 0

; Keyboard controller commands (command port, 64h - wr)
	CMD_ShutDown	EQU	0FEh	; (~Pulse) output port. Bit 0 of
					; output port conn. to CPU reset line
	CMD_A20_Access	EQU	0D1h	; Write output port command.

; Keyboard controller commands (output port)
	CMD_Kbd_Data	EQU	80h
	CMD_Kbd_Clock	EQU	40h
	CMD_Empty_Input	EQU	20h
	CMD_Output_Full	EQU	10h
	CMD_A20		EQU	02h
	CMD_Rst_Off	EQU	01h
	CMD_Undef	EQU	0Ch
	CMD_A20_On	EQU	CMD_Undef OR CMD_Rst_Off OR CMD_A20 OR CMD_Output_Full OR CMD_Kbd_Clock OR CMD_Kbd_Data
	CMD_A20_Off	EQU	CMD_A20_On AND (NOT CMD_A20)

	KEYBOARD_Q_SIZE	EQU	30

;-----------------------------------------------------------------------------
; PIC.
;-----------------------------------------------------------------------------
; PIC ports.
PIC_MASTER	EQU	20h
PIC_MASTER_MASK	EQU	21h
PIC_SLAVE	EQU	0A0h
PIC_SLAVE_MASK	EQU	0A1h

; PIC init commands (Initialization Command Words).
	CMD_ICW1	EQU	11h	; ICW4 needed, cascading 8259h,
					; 8-byte vectors, edge-triggered mode
	CMD_ICW2	EQU	0	; bits 3-7 = A3-A7 int vector.
	CMD_ICW3	EQU	04h	; IRQ 2 has slave, rest - no slave.
	CMD_SLAVE_ICW3	EQU	02h	; Bits 0-2 = master's cascade vector.
	CMD_ICW4	EQU	01h	; Normal EOI, no buffering,
					; sequential mode.
; PIC Operation control words. (reg. select for next read)
	CMD_EOI		EQU	20h	; OCW 2: non-specific EOI, upon IRQ 0
	CMD_Read_IRR	EQU	09h	; Read IRR on next read.
	CMD_Read_ISR	EQU	08h	; Read ISR on next read.

;-----------------------------------------------------------------------------
; PIT.
;-----------------------------------------------------------------------------
PIT_CH0_COUNT	EQU	40h
PIT_CH1_COUNT	EQU	41h
PIT_CH2_COUNT	EQU	42h
PIT_CONTROL	EQU	43h


PIT_FREQUENCY	EQU	1193180		; PIT count rate
PIT_TICK_TO_SEC	EQU	1000		; Ticks per second (must not be >18).

;-----------------------------------------------------------------------------
; DMA
;-----------------------------------------------------------------------------
DMA_CH0_BASE	EQU	0
DMA_CH0_CURR	EQU	0
DMA_CH0_COUNT	EQU	1
DMA_CH1_BASE	EQU	2
DMA_CH1_CURR	EQU	2
DMA_CH1_COUNT	EQU	3
DMA_CH2_BASE	EQU	4
DMA_CH2_CURR	EQU	4
DMA_CH2_COUNT	EQU	5
DMA_CH3_BASE	EQU	6
DMA_CH3_CURR	EQU	6
DMA_CH3_COUNT	EQU	7
DMA_CH4_BASE	EQU	0C0h
DMA_CH4_COUNT	EQU	0C2h
DMA_CH5_BASE	EQU	0C4h
DMA_CH5_COUNT	EQU	0C6h
DMA_CH6_BASE	EQU	0C8h
DMA_CH6_COUNT	EQU	0CAh
DMA_CH7_BASE	EQU	0CCh
DMA_CH7_COUNT	EQU	0CEh

DMA_CH0_PAGE	EQU	87h
DMA_CH1_PAGE	EQU	83h
DMA_CH2_PAGE	EQU	81h
DMA_CH3_PAGE	EQU	82h
DMA_CH5_PAGE	EQU	8Bh
DMA_CH6_PAGE	EQU	89h
DMA_CH7_PAGE	EQU	8Ah

DMA1_CMD	EQU	8
DMA2_CMD	EQU	0D0h
DMA1_STATUS	EQU	8
DMA2_STATUS	EQU	0D0h
DMA1_WRITE_REQ	EQU	9
DMA2_WRITE_REQ	EQU	0D2h
DMA1_MASK	EQU	0Ah
DMA2_MASK	EQU	0D4h
DMA1_MODE	EQU	0Bh
DMA2_MODE	EQU	0D6h
DMA1_ADDR_CLEAR	EQU	0Ch
DMA2_ADDR_CLEAR	EQU	0D8h
DMA1_MASTER_CLEAR	EQU	0Dh
DMA2_MASTER_CLEAR	EQU	0DAh
DMA1_MASK_CLEAR	EQU	0Eh
DMA2_MASK_CLEAR	EQU	0DCh
DMA1_MASK_WRITE	EQU	0Fh
DMA2_MASK_WRITE	EQU	0DEh

MAX_PORTS	EQU	32

GenDevice	STRUCT
	NPorts		DB	?
	Ports		DW	?
REPEAT	MAX_PORTS - 1
			DW	?
ENDM
	Irq		DB	?
	DevSema4	Sema4	<>
GenDevice	ENDS

ENDIF	; DEVICES_INC
