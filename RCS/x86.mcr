head	0.53;
access;
symbols;
locks
	BlackPhantom:0.53
	BlackPhantom:0.7.0.1; strict;
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
next	0.20;

0.20
date	99.04.05.03.17.18;	author BlackPhantom;	state Exp;
branches;
next	0.19;

0.19
date	99.03.30.23.45.44;	author BlackPhantom;	state Exp;
branches;
next	0.18;

0.18
date	99.03.29.18.33.30;	author BlackPhantom;	state Exp;
branches;
next	0.17;

0.17
date	99.03.22.22.40.13;	author BlackPhantom;	state Exp;
branches;
next	0.16;

0.16
date	99.03.18.04.09.05;	author BlackPhantom;	state Exp;
branches;
next	0.15;

0.15
date	99.03.16.02.16.25;	author BlackPhantom;	state Exp;
branches;
next	0.13;

0.13
date	99.03.13.23.36.05;	author BlackPhantom;	state Exp;
branches;
next	0.12;

0.12
date	99.03.12.22.09.18;	author BlackPhantom;	state Exp;
branches;
next	0.11;

0.11
date	99.03.09.04.23.38;	author BlackPhantom;	state Exp;
branches;
next	0.10;

0.10
date	99.03.01.23.10.12;	author BlackPhantom;	state Exp;
branches;
next	0.9;

0.9
date	99.02.25.21.58.28;	author BlackPhantom;	state Exp;
branches;
next	0.8;

0.8
date	99.02.24.02.21.35;	author BlackPhantom;	state Exp;
branches;
next	0.7;

0.7
date	99.02.18.00.09.40;	author BlackPhantom;	state Exp;
branches
	0.7.0.1;
next	0.6;

0.6
date	99.02.17.17.03.04;	author BlackPhantom;	state Exp;
branches;
next	0.5;

0.5
date	99.02.10.14.17.26;	author BlackPhantom;	state Exp;
branches;
next	0.3;

0.3
date	98.06.05.12.51.14;	author BlackPhantom;	state Exp;
branches;
next	0.1;

0.1
date	98.05.16.12.52.44;	author BlackPhantom;	state Exp;
branches;
next	;

0.7.0.1
date	99.02.21.04.02.25;	author BlackPhantom;	state Exp;
branches;
next	;


desc
@Macros file for MULTIX32 project
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
;	Macros file for Tripple-DOS project.
;
;=============================================================================

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
IF	@@Version	LT	611

CPUID		MACRO
	DB	0Fh, 0A2h	; CPUID instruction
ENDM

ENDIF
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
@d3 20
a22 1
;	Macros file for MULTIX32 project.
@


0.43
log
@Bug fixes:
1) Lower word in translation structure on real mode stack was being destroyed - very annoying.
2) Saved exception number was moved to task structure to allow multiple DPMI tasks work.
3 copies of WCC386 worked!
@
text
@@


0.42
log
@1) Added XMS server
2) Memory allocation / deallocation is moved to task creation / deletion
@
text
@@


0.41
log
@Bug fixes:
1) Virtual I/O jump table (very annoying!)
2) IsFileOpen() bug if file name is 0.
@
text
@@


0.20
log
@Task locks on wait for events are added.
@
text
@@


0.19
log
@Trap wait on keyboard (INT 16h / 0, 10h).
Bug fixes in memory allocation.
@
text
@@


0.18
log
@Keyboard virtualized.
File I/O interface for kernel is added.
@
text
@@


0.17
log
@Int 13h locking improvements, bug fixes (NC running)
@
text
@@


0.16
log
@Debug improvements (commands); VGA ports partial virtualizing
@
text
@@


0.15
log
@Debug improvements: hardware breakpoint
@
text
@@


0.13
log
@Proper CPL 0 stack management; foreground task boost on event
@
text
@@


0.12
log
@Bug fixes: 5th task, VGA co40/co80 restore
@
text
@@


0.11
log
@Memory allocation enhance; bug fixes
@
text
@@


0.10
log
@VGA save/restore state fixed; bug fixes
@
text
@@


0.9
log
@VGA state save/resore
@
text
@@


0.8
log
@Synchronization of system services; bug fixes
@
text
@@


0.7
log
@Working preemptive multitasking. Interrupts are reported to ALL tasks. Different tasks cannot work with the same device.
@
text
@@


0.7.0.1
log
@Attempt to synchronize disks with semaphores
@
text
@@


0.6
log
@Working non-preemptive multitasking
@
text
@@


0.5
log
@First V86 emulation version!
@
text
@@


0.3
log
@Port of previous version to 32-bits
@
text
@@


0.1
log
@16/05/98	Initial check-in
@
text
@d7 3
d24 3
@
