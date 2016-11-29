#!/usr/bin/perl

#########################################################################
#    mileage.pl 9-1-2016 OGL3                                           #
#      add a new data point at bottom of mileage_withDate.txt file.     #
#      make sure there are no blank lines!!!                            #
#      run this program.                                                #
#########################################################################

@fw = ( 6, 5, 5, 8 );							# field widths for formatted output for printed table
@tw = ( 5, 5, 3, 8 );							# field widths for formatted output for mileage.last file
$d = "+--------+-------+-------+----------+----------+----------+";
$h = "| Gas    | Miles | Delta | DMPG     | TMPG     | AtMPG    |";
chdir "/home/ottol/mileage/";						# change to working directory
chomp( $DT=`date +%Y%m%d` );

#                                              DO UPFRONT SANITY CHECKS.
chomp(@fl = `wc -l mileage*.txt |grep -iv total`);			# expect 2 lines
if ( $#fl != 1 )							# verify last subscript 0 & 1 are 2
{	print "Not 2 files!\n";						# announce problem
	exit( 0 );							# abort
}
@f1 = split( ' ', $fl[0] );	@f2 = split( ' ', $fl[1] );		# seperate line count from filename for both files
if ( $f1[0] eq $f2[0] )							# new data ?
{	print "seems like nothing to do.\n";				# no
#	chomp( $oF=`ls -lt /home/ottol/mileage/dataBU_*.tgz |head -1 |awk '{print \$9}'` );
#	`mpack -a $oF -s "dataBU_${DT}" ogltree\@gmail.com` if [ "$oF" != "" ];
	exit( 0 );							# just leave
}else									# have new data
{	$z = abs( $f1[0] - $f2[0] );					# number of new data lines
}

#                                         GET DATA & INITIAL CONDITIONS
$m[0] = 2939;								# first odometer reading (to get distance traveled)
chomp( @a = `cat mileage_withDate.txt` );				# read data, strip LF
chomp( $w = `cat mileage.last` );					# read last saved info so we don't have to recompute everything.
@last = split( ' ', $w );						# 0=$dt[$i] 1=$g[$i] 2=$m[$i] 3=$tg 4=$stmpg 5=$nst
$nst      = $last[5];		$stmpg    = $last[4];
$tg       = $last[3];		$m[$nst]  = $last[2];
$g[$nst]  = $last[1];		$dt[$nst] = $last[0];

print "$d\n";								# output table divider line
print "$h\n";								# print column headers
print "$d\n";								# output table divider line
$start = $#a +1 -$z;

for $i ( $start .. $#a )						# loop to process data  (if wc -l = 23 then $#a = 22)
{	( $g[$i], $m[$i], $dt[$i] ) = split( ' ', $a[$i] );		# split into Gas, Miles and Date
	if ( $i > 0 )
	{	$dm = $m[$i] - $m[$i-1];				# delta miles
		$mpg[$i] = $dm / $g[$i];				# delta mpg
		$tg += $g[$i];						# total gas used
		$tmpg = ( $m[$i] - $m[0] ) / $tg;			# total mpg
		$stmpg += $tmpg;					# sum of total MPG
		$nst++;							# number of tmpg in sumation
		$atmpg = $stmpg / $nst;					# average of tmpg
		printf( "| %$fw[0].3f | %$fw[1]d | %$fw[2]d | %$fw[3].5f | %$fw[3].5f | %$fw[3].5f |\n", $g[$i], $m[$i], $dm, $mpg[$i], $tmpg, $atmpg );
		if ( $i == $#a )
		{
			`mysql -uottol -pe^?0aI/% mileage 2>/dev/null <<EOT
			insert into fillup set gas=$g[$i],miles=$m[$i],date=$dt[$i],deltaM=$dm,deltaMPG=$mpg[$i],totalMPG=$tmpg,averageTmpg=$atmpg;
EOT
`;									# update database
			$outs = sprintf( "$g[$i] $m[$i]\n" );
			`/bin/echo -n "$outs" >>mileage.txt`;		# add to backup text file to avoid running same data again.
			$outs = sprintf( "%$tw[0].3f %$tw[1]d %$tw[2]d %$tw[3].5f %$tw[3].5f %$tw[3].5f\n", $g[$i], $m[$i], $dm, $mpg[$i], $tmpg, $atmpg );
			`/bin/echo -n "$outs" >>mileage.out`;		# add to output file for graphing via python script

			chomp( $b = `cat mileage.out |awk '{print \$4}' |grep -v DMPG |/usr/bin/sort -n` );
			@a = split( ' ', $b );
			$n = int( $#a / 2 );
			$o = $#a % 2;					# 0=odd, 1-even
			if ( $o == 1 )
			{	$hw = $n + 1;
				$med = int(( $a[$n] + $a[$hw] ) * 500 + .5 ) / 1000;
			}else
			{	$med = $a[$n];
			}
			`echo $med > med.out`;

			`rm -f mvs.out`;
			$mv = 0;
			$nl = `wc -l mileage.out |awk '{print \$1}'`;
			for $i ( 2 .. $nl )
			{	chomp( $b = `head -$i mileage.out |awk '{print \$4}' |grep -v DMPG |/usr/bin/sort -n` );
				@a = split( ' ', $b );
				$oe = $#a % 2;							# 0 => even, 1 => odd
				$omv = $mv;
				$mp = int( $#a / 2 );
				$hp = ( $#a > 0 ) ? $mp + 1 : $mp;
				$mv = ( $oe == 1 ) ? int(( $a[$mp] + $a[$hp] ) * 500 + .5 ) / 1000 : $a[$mp];
			#	print "i=$i  oe=$oe   mp=$mp a[mp]=$a[$mp]    hp=$hp a[hp]=$a[$hp]   mv=$mv\n";
				`echo $mv >> mvs.out`;
			}
			`cat med.out >>mvs.out`;

			`./mileage.py`;					# run python script to generate graph
			$outs = sprintf( "$dt[$i] $g[$i] $m[$i] $tg $stmpg $nst" );
			`/bin/echo -n "$outs" >mileage.last`;		# save info to avoid having to compute every data point.
			`sudo ./dspmv`;
			`../mysql_Scripts/dump`;
			chomp( $newD=`ls -lt ~/mysql_Scripts/BUs |head -2 |tail -1 |awk '{print \$9}'` );
			`cp *.[plot][lyaux]*                  ~/mysql_Scripts/BUs/$newD/`;
			`cp ~/mysql_Scripts/dump              ~/mysql_Scripts/BUs/$newD/`;
			`cp ~/mysql_Scripts/showDatabases.sql ~/mysql_Scripts/BUs/$newD/`;
			`sudo cp /usr/local/bin/newD          /home/ottol/mysql_Scripts/BUs/$newD/`;
			`sync;sleep 1`;
			`cd ~/mysql_Scripts/BUs; tar cf - $newD |gzip -c - > ~/mileage/dataBU_${DT}.tgz`;
			`mpack -a /home/ottol/mileage/dataBU_${DT}.tgz -s "dataBU_${DT}" ogltree\@gmail.com`;
		}
	}else
	{	printf( "| %$fw[0].3f | %$fw[1]d |       |          |          |          |\n", $g[$i], $m[$i] );
	}
}
print "$d\n";

chomp( $UL = `tail -1 mileage.out |awk '{print \$5}'` );
chomp( $LL = `tail -1 mileage.out |awk '{print \$6}'` );
print "UL=$UL   LL=$LL\n";
chomp( @pts = `./deltaMPG` );
$T = $M = $B = 0;
for $i ( @pts )
{	if ( $i < $LL )
	{	$B++;
	}else
	{	if ( $i > $UL )
		{	$T++;
		}else
		{	$M++;
		}
	}
}
print "$T Above,   $M between,   $B Below\n";
open( $fh, ">", "counts.out" );
printf( $fh "<pre><strong style=\"color:green;\">$T Above,      </strong><strong style=\"color:black;\">$M between,      </strong><strong style=\"color:red;\">$B Below</strong></pre>" );
close $fh;

# +----------+--------+--------------------------------------------------------------------+
# | Database | Tables | Columns                                                            |
# |          |        +-------------+--------------+------+-----+---------+----------------+
# |          |        | Field       | Type         | Null | Key | Default | Extra          |
# +----------+--------+-------------+--------------+------+-----+---------+----------------+
# | mileage  | fillup | gas         | float(4,3)   | NO   |     | NULL    |                |
# |          |        | miles       | int(6)       | NO   | PRI | NULL    |                |
# |          |        | date        | int(8)       | YES  |     | NULL    |                |
# |          |        | deltaM      | int(6)       | YES  |     | NULL    |                |
# |          |        | deltaMPG    | float(12,10) | YES  |     | NULL    |                |
# |          |        | totalMPG    | float(12,10) | YES  |     | NULL    |                |
# |          |        | averageTmpg | float(12,10) | YES  |     | NULL    |                |
# +----------+--------+-------------+--------------+------+-----+---------+----------------+
