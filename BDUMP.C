#include	<stdio.h>

main( int argc, char **argv )
{
	FILE	*f;
	char far	*buf = ( char *) 0x0;

	if ( argc < 3 )
	{
		printf( "Usage: bdump <start_segment> <output_file>\n" );
		return;
	}

	if ( !( f = fopen( argv[ 2 ], "wb" ) ) )
	{
		printf( "Cannot create output file\n" );
		return;
	}

	sscanf( argv[ 1 ], "%x", ( ( char *) &buf ) + 2 );
	printf( "Dumping %04X:%04X\n", *((unsigned*)(&buf) + 1 ), (unsigned) buf );
	fwrite( buf, 1, 0xFFFF, f );
	fclose( f );

}
