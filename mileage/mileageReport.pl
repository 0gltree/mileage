#!/usr/bin/perl

chdir( "/home/ottol/mileage" );

chomp( @a = `./mileage` );
for $i ( 0 .. $#a )
{	if ( $i > 3 && $i < $#a )
	{	@e = split( ' ', $a[$i] );
		$diff = int( 1000 * ( $e[11] - $e[13] ) + .5 ) / 1000;
		print "$a[$i]   $diff\n";
	}else
	{	print "$a[$i]\n";
	}
}
