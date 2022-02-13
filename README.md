# tridos
DOS preemptive multitasker with XMS API support

Mirror from http://phantom.urbis.net.il/bphantom/tridos.html

In short, Triple-DOS is a pre-emptive multitasker for DOS on session
level a-la Windows in Enhanced mode or OS/2. 

Its design focuses on simplicity and small size. Unlike full featured
operating systems, Triple-DOS has nearly no device drivers. It does
only required resources virtualization in order to
multitask. Triple-DOS doesn't provide a proprietary API for DOS
programs - its purpose is to run existent DOS binaries that are not
aware of multitasking.  

This release, version 0.50, is freeware .  The new freeware license
takes over the previous one. Basically the new license gives you the
right to do anything with Triple-DOS except for claiming copyright on
it. The use of the current release of Triple-DOS doesn't require
registration or any other confirmation. Instead, the use itself
constitutes your agreement to the terms and conditions listed in the
license file. You must comply to these terms.  

The current version is very basic. The interface is very simple: you
must start Triple-DOS by executing it in real mode DOS, by typing

tridos 

DOS may be any type or version but it must be compatible with MS-DOS
version 3.0. Triple-DOS will not start if any protected mode software
is running, including EMS memory managers. This version will also not
function correctly with XMS memory managers if some programs have
allocated extended memory prior to starting Triple-DOS. 

Once started, you may start a new DOS session at any time by pressing
Alt-Enter, change to the next session with Alt-Tab, and terminate the
currently active session with Alt-End. You may quit Triple-DOS any
time by pressing Alt-Esc. 

In order to compile Triple-DOS you need MASM 6.x. Probably any version
starting from 6.0 would do; for builds versions 6.1, 6.11d, 6.13 and
6.14 were used. The latest versions of MASM are available from
Microsoft free of charge. You will also need a 16-bit linker as latest
MASM versions don't come with it - it's available also free of charge,
but from a different place. Please refer to Jon Kirwan's "How to get
MASM" page.

In the source ZIP you will find an RCS directory that contains all
previous versions. Use GNU RCS to manage the revisions. All source
files were forcefully checked in, so in order to build a version 'x'
you just need check out all the files of version 'x' that exist.

Triple-DOS has a DPMI 0.9 server. Simple assembly programs work (both
16-bit and 32-bit) but support for large applications in multitasking
environment is tricky. Since the DPMI server was never stable, the
DPMI entry points were always disabled in release versions.

