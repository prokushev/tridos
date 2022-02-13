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
next	0.50;

0.50
date	2001.02.02.23.44.36;	author BlackPhantom;	state Exp;
branches;
next	0.48;

0.48
date	2000.12.27.05.37.22;	author BlackPhantom;	state Exp;
branches;
next	0.6;

0.6
date	99.02.17.17.03.43;	author BlackPhantom;	state Exp;
branches;
next	;


desc
@Makefile for MULTIX32 project
@


0.53
log
@Last developed version
@
text
@#=============================================================================
#
#	This source code file is copyright (c) Vadim Drubetsky AKA the 
# Black Phantom. All rights reserved.
#
#	This source code file is a part of the Tripple-DOS project. Your use 
# of this source code must fully comply with the accompanying license file, 
# LICENSE.TXT. You must have this file enclosed with your Tripple-DOS copy in
# order for it to be legal.
#
#	In no event, except for when it is explicitly stated by the applicable 
# law, shall Vadim Drubetsky aka the Black Phantom be liable for any special,
# incidental, indirect, or consequential damages (including but not limited to
# profit loss, business interruption, loss of business information, or any 
# other pecuniary loss) arising out of the use of or inability to use 
# Tripple-DOS, even if he has been advised of the possibility of such damages.
#
#=============================================================================

#
#	Makefile for Tripple-DOS - Black Phantom's DOS multitasker.
#

A_OPT	=	/nologo /c /Cx /Cp /DPROVIDE_HIMEM #/DDEBUG_BUILD /DDPMI_COOKIE /DFAKE_WINDOWS /DLOG_DPMI /DMONITOR_DPMI /DLOG_DPMI_STATE
L_OPT	=	/nologo /CPARM:1 /NONULLS /DOSSEG

TC20_DIR =	f:\compile\tc20
MSC80_DIR = 	f:\compile\msvc
CC	=	$(MSC80_DIR)\bin\cl
C_INC	=	$(MSC80_DIR)\include
C_LIB	=	$(MSC80_DIR)\LIB
#CC	=	$(TC20_DIR)\bin\tcc
#C_INC	=	$(TC20_DIR)\include
#C_LIB	=	$(TC20_DIR)\lib
C_OPT	=	-c -I$(C_INC) -AL -NTCODE -NDDATA
#C_OPT	=	-c -I$(C_INC) -mh -zDDATA

debug:	init.obj devices.obj phlib.obj except.obj core.obj phlib32.obj memman.obj taskman.obj debug.obj dpmi.obj xms.obj
	@@echo	linking...
	@@LINK $(L_OPT) init devices phlib except core phlib32 memman taskman debug dpmi xms, tridos;

release:	init.obj devices.obj phlib.obj except.obj core.obj phlib32.obj memman.obj taskman.obj dpmi.obj xms.obj
	@@echo	linking...
	@@LINK $(L_OPT) init devices phlib except core phlib32 memman taskman dpmi xms, tridos;

debug_all:	clean debug

release_all:	clean release

multix32.exe:	init.obj devices.obj phlib.obj except.obj core.obj phlib32.obj memman.obj taskman.obj debug.obj dpmi.obj xms.obj
	@@echo	linking...
	@@LINK $(L_OPT) init devices phlib except core phlib32 memman taskman debug dpmi xms, tridos, m32;

clean:
	del *.exe
	del *.obj

.asm.obj:
	@@ML $(A_OPT) $*.asm

.c.obj:
	@@$(CC) $(C_OPT) $*.c

init.obj:	init.asm init.inc x86.inc phlib.inc devices.inc def.inc makefile
devices.obj:	devices.asm devices.inc x86.inc phlib.inc def.inc makefile
phlib.obj:	phlib.asm phlib.inc makefile
except.obj:	except.asm except.inc x86.inc devices.inc def.inc core.inc taskman.inc makefile
core.obj:	core.asm core.inc x86.inc def.inc makefile
phlib32.obj:	phlib32.asm makefile
memman.obj:	memman.asm x86.inc def.inc makefile
taskman.obj:	taskman.asm taskman.inc x86.inc def.inc makefile
debug.obj:	debug.asm debug.inc devices.inc def.inc core.inc x86.inc dpmi.inc makefile
dpmi.obj:	dpmi.asm dpmi.inc x86.inc taskman.inc makefile
xms.obj:	xms.asm dpmi.inc taskman.inc makefile
@


0.50
log
@Fixed HDD/FDD synchronization problem (trapped opcodes were overwriting each other).
@
text
@d12 1
a12 1
# law, shall Vadim Drubetsky aka the Black Phantoms be liable for any special,
d24 1
a24 1
A_OPT	=	/nologo /c /Cx /Cp /DPROVIDE_HIMEM #/DDEBUG_BUILD /DDPMI_COOKIE /DLOG_DPMI /DMONITOR_DPMI /DFAKE_WINDOWS /DLOG_DPMI_STATE
d27 11
d61 3
d74 1
a74 1
xms.obj:	xms.asm dpmi.inc taskman.inc
@


0.48
log
@Enabled XMS 3.0 interface
@
text
@@


0.6
log
@Working non-preemptive multitasking
@
text
@d1 1
d3 2
a4 1
#	Makefile for MULTIX32.EXE - simple program that enters the 386 PM.
d6 36
d43 3
a45 2
multix32.exe:	init.obj devices.obj phlib.obj except.obj core.obj phlib32.obj memman.obj taskman.obj debug.obj
	LINK /CPARM:1 init devices phlib except core phlib32 memman taskman debug, multix32, m32;
d48 1
a48 1
	ML /c $*.asm
d50 2
a51 2
init.obj:	init.asm init.inc x86.inc phlib.inc devices.inc def.inc x86.mcr makefile
devices.obj:	devices.asm devices.inc x86.inc phlib.inc x86.mcr def.inc makefile
d58 3
a60 1
debug.obj:	debug.asm debug.inc devices.inc def.inc core.inc x86.inc makefile
@
