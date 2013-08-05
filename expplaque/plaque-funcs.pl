#!/usr/bin/perl

##############################################################################################
#                                                                                            #
#     BatMUD Tools by Tumi - a supporting site with tools for multiplayer game BatMUD        #
#     Copyright (C) 2002-2007 Tuomo 'Tumi' Tanskanen                                         #
#                                                                                            #
#     This program is free software; you can redistribute it and/or modify it under          #
# the terms of the GNU General Public License as published by the Free Software              #
# Foundation; either version 2 of the License, or (at your option) any later version.        #
#                                                                                            #
#     This program is distributed in the hope that it will be useful, but WITHOUT ANY        #
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A            #
# PARTICULAR PURPOSE. See the GNU General Public License for more details.                   #
#                                                                                            #
#     You should have received a copy of the GNU General Public License along with           #
# this program; if not, write to the Free Software Foundation, Inc., 59 Temple Place,        #
# Suite 330, Boston, MA 02111-1307 USA                                                       #
#                                                                                            #
##############################################################################################

## Strict is always good
use strict;
use IO::File;

# use lib '/home/twomi/web/libs';
use lib '/home/customers/tumi/public_html/archives/batmud';
use lib '/home/customers/tumi/tumilib';
use Tumi::Helper;

my $MAX = 100;


## parsePlaque returns a hash where index is name and value is
## "position;level;exp"
sub parsePlaque {
	my @locarray = @_;
	my %lochash = ();
	my $howmany = 0;

	foreach my $line (@locarray) {
		## 33: Dracandross     100     302 949634 20 hours
		if( $line =~ /\s+(\d{1,4}).{1} (\w+)\s+(\d+)\s+(\d{1,4})\s(\d{6,6})/ ) {
			my ($position, $name, $level, $exp) = ($1, $2, $3, $4*1000000+$5);
			$howmany++;
			$lochash{$name} = "$position;$level;$exp";
		}
	}

	## print STDERR $howmany." players loaded.\n";
	$MAX = $howmany;
	return (%lochash);
}





sub parsePlaques {
	my $oldp = shift;
	my $newp = shift;

	my (%exphash, %perhash, %nameexp, %nameper) = ();
	my $counter;
	my $output = "";
	my (@expoutput, @peroutput) = ();

	foreach my $name (keys %{$oldp}) {
		my @oldstats = split(/;/, $oldp->{$name});
		next if(not defined $newp->{$name});
		my @newstats = split(/;/, $newp->{$name});
		my $expdiff = $newstats[2] - $oldstats[2];
		my $percent = sprintf("%3.2f", $expdiff * 100 / $oldstats[2]);
		$nameexp{$name} = $expdiff;
		$nameper{$name} = $percent;

		if(defined $exphash{"$expdiff"}) {
			$exphash{"$expdiff"} .= ",$name";
		} else {
			$exphash{"$expdiff"} = $name;
		}

		if(defined $perhash{"$percent"}) {
			$perhash{"$percent"} .= ",$name";
		} else {
			$perhash{"$percent"} = $name;
		}
	}

	$counter = 0;
	foreach my $expdiff (reverse sort {$a<=>$b} keys %exphash) {
		my $name = $exphash{$expdiff};

		my @names = split(/,/, $name); # if($name =~ /,/);
		foreach $name (sort {$nameper{$b}<=>$nameper{$a}} @names) {
			$expoutput[$counter] = sprintf("%3d: %12s %9d (%6s",
				++$counter, $name, $nameexp{$name}, $nameper{$name} )."%)";
		}

		last if($counter >= $MAX);
	}

	$counter = 0;
	foreach my $expper (reverse sort {$a<=>$b} keys %perhash) {
		my $name = $perhash{$expper};
		my @names = split(/,/, $name); # if($name =~ /,/);
		foreach $name (sort {$nameexp{$b}<=>$nameexp{$a}} @names) {
			$peroutput[$counter] = sprintf("%3d: %12s %9d (%6s",
				++$counter, $name, $nameexp{$name}, $nameper{$name} )."%)";
		}
		last if($counter >= $MAX);
	}

	$output  = " No:        Name:      Exp:        %: |  No:        Name:      Exp:        %:\n";
	$output .= "--------- Sorted by expgain ----------+------ Sorted by percentage gain -----\n";
	for(my $x=0; $x<$MAX; $x++) {
		$output .= sprintf("%37s | %37s\n", $expoutput[$x+1], $peroutput[$x+1])
			if (defined $expoutput[$x+1] && defined $peroutput[$x+1]);
	}

	return ($output);
}






sub parsePlaquesGained {
	my $year = shift || 2004;
#	my @files = sort `ls sources/source-$year*.txt`;
	my @files = sort &getDir("source", "weekly-$year*.txt");
	my $output = "";
	my (%prevxp, %madexp, %lostxp, %totalxp, %madebyxp, %lostbyxp);

	for my $newfile (@files) {
		$newfile =~ tr/\x0D\x0A//d;
#		print STDERR "Processing: $newfile\n";
		my @plq = split/\n/, &readFile("source/$newfile");
		my %newd = &parsePlaque(@plq);

		foreach my $name (keys %newd) {
			my @stats = split(/;/, $newd{$name});
			my $newexp = $stats[2];
			my $oldexp = defined $prevxp{$name} ? $prevxp{$name} : $newexp;
			my $expgain = $newexp - $oldexp;

			if ($expgain >= 0) {
				$madexp{$name} += $expgain;
			} else {
				$lostxp{$name} += ($expgain < 0 ? -$expgain : $expgain);
			}
			$prevxp{$name} = $newexp;
		}
	}


	for my $name (keys %madexp) {
		my $expmade = $madexp{$name};
		if (defined $madebyxp{$expmade}) {
			$madebyxp{$expmade} .= ",$name";
		} else {
			$madebyxp{$expmade} = $name;
		}
	}

	$output = <<until_end;
CUMULATIVE EXPERIENCE MADE & LOST (AND OUTCOME) of YEAR $year!

  No:          Name:       Exp made:        Exp lost:       Exp total:
------------------- Sorted by exp made  ------------------------------
until_end

	my ($counter, $totallost, $totalmade) = (0, 0, 0);
	for my $exp (sort {$b<=>$a} keys %madebyxp) {
		my @names = split/,/, $madebyxp{$exp};
		for my $name (sort {&sortbyexp($a,$b,$madexp{$a},$lostxp{$a},$madexp{$b},$lostxp{$b})} @names) {
			$output .= sprintf("%4d: %14s %16s %16s %16s\n",
				++$counter, $name, &verbose($madexp{$name}), &verbose($lostxp{$name}),
				&verbose(($madexp{$name} || 0) - ($lostxp{$name} || 0)));
			$totalmade += ($madexp{$name} || 0);
			$totallost += ($lostxp{$name} || 0);
		}
	}
	$output .= <<until_end;

----------------------------------------------------------------------
until_end

	$output .= sprintf("%50s: %19s\n",
		"Total numbers of unique players on plaque", &verbose($counter));
	$output .= sprintf("%50s: %19s\n",
		"Total exp made by all players", &verbose($totalmade));
	$output .= sprintf("%50s: %19s\n",
		"Total exp lost by all players", &verbose($totallost));
	$output .= sprintf("%50s: %19s\n",
		"Total exp increase by all players", &verbose($totalmade - $totallost));



	return ($output);
}


sub sortbyexp {
	my $a = shift;
	my $b = shift;
	my $amade = shift || 0;
	my $alost = shift || 0;
	my $bmade = shift || 0;
	my $blost = shift || 0;

	return ($bmade <=> $amade) if ($amade != $bmade);
	return ($alost <=> $blost) if ($alost != $blost);
	return ($a cmp $b);
}


sub verbose {
	my $number = shift || 0;
	my @elements = split//, $number;
	my @new_string = ();

	my $cntr = 0;
	for my $element (reverse @elements) {
		unshift @new_string, " "
			if ($cntr++ % 3 == 0 && $element ne "-");
		unshift @new_string, $element;
	}

	return join("", @new_string);
}


1;

