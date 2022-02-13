/******************************************************************************
*
*	This source code file is copyright (c) Vadim Drubetsky AKA the 
* Black Phantom. All rights reserved.
*
*	This source code file is a part of the Tripple-DOS project. Your use 
* of this source code must fully comply with the accompanying license file, 
* LICENSE.TXT. You must have this file enclosed with your Tripple-DOS copy in
* order for it to be legal.
*
*	In no event, except for when it is explicitly stated by the applicable 
* law, shall Vadim Drubetsky aka the Black Phantoms be liable for any special,
* incidental, indirect, or consequential damages (including but not limited to
* profit loss, business interruption, loss of business information, or any 
* other pecuniary loss) arising out of the use of or inability to use 
* Tripple-DOS, even if he has been advised of the possibility of such damages.
*
******************************************************************************/

#include	<dos.h>
#include	<stdio.h>

unsigned	DosParams[ 0xB ];

/*
 *											FLUSH.C
 *											-------
 *
 *		Flushes (resets) the specified disk.
 */
main()
{
	unsigned	Err;

	_asm
	{
		mov	ah, 0x62
		int	0x21
		mov	DosParams[ 0xA ], bx
		mov	ax, 0x5D01
		mov	dx, offset DosParams
		int	0x21
		mov	ax, 0
		adc	ax, 0
		mov	Err, ax
	}

	if ( Err )
		printf( "Error!\n" );

	return	0;
}
