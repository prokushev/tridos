#=============================================================================
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
LINK	=	f:\compile\msvc\bin\link.exe
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
	@echo	linking...
	@$(LINK) $(L_OPT) init devices phlib except core phlib32 memman taskman debug dpmi xms, tridos;

release:	init.obj devices.obj phlib.obj except.obj core.obj phlib32.obj memman.obj taskman.obj dpmi.obj xms.obj
	@echo	linking...
	@$(LINK) $(L_OPT) init devices phlib except core phlib32 memman taskman dpmi xms, tridos;

debug_all:	clean debug

release_all:	clean release

multix32.exe:	init.obj devices.obj phlib.obj except.obj core.obj phlib32.obj memman.obj taskman.obj debug.obj dpmi.obj xms.obj
	@echo	linking...
	@LINK $(L_OPT) init devices phlib except core phlib32 memman taskman debug dpmi xms, tridos, m32;

clean:
	del *.exe
	del *.obj

.asm.obj:
	@ML $(A_OPT) $*.asm

.c.obj:
	@$(CC) $(C_OPT) $*.c

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
