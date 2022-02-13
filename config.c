#include	<stdio.h>
#include	<string.h>

#define	CFG_FILE	"tridos.cfg"

long	CfgDiskCacheSize;
long	CfgTicksPerSec;
extern long	TickToSec;
long	CfgTicksPerSlice;
extern long	SliceTicks;

void	parse_cfg()
{
	FILE	*f;
	char	line[ 256 ];

	f = fopen( CFG_FILE, "rt" );
	if ( !f )
		return;

	while ( !feof( f ) )
	{
		fgets( line, 256, f );

		if ( sscanf( line, "SliceTicks = %ld", &CfgTicksPerSlice ) == 1 )
		{
			SliceTicks = CfgTicksPerSlice;
			continue;
		}

		if ( sscanf( line, "TicksPerSec = %ld", &CfgTicksPerSec ) == 1 )
		{
			TickToSec = CfgTicksPerSec;
			continue;
		}
	}
}
