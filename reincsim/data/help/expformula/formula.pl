#!/usr/bin/perl -w

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

use strict;
use IO::File;
use CGI qw/param/;

my $file = param('file') || 'dodge2.txt';
&countratio($file);

1;

sub countratio {
	my $file = shift;
	my $fh = new IO::File $file, "r";
	die unless $fh;

	# @Smoking |    1% =      56        |   51% =    6710        |
	# @Smoking |    2% =      58        |   52% =    7223        |

	my ($prev_small, $prev_big) = (0, 0);
	my %ratios = ();
	my %costs = ();

	while (my $line = <$fh>) {
		my ($small1, $smallcost, $big1, $bigcost) = $line =~ /\|\s+(\d+)% = \s+(\d+)\s+\|\s+(\d+)% =\s+(\d+)/;
		next unless ($smallcost && $bigcost);
		$costs{"$small1"} = $smallcost;
		$costs{"$big1"}   = $bigcost;
		$costs{"0"} = int($smallcost*0.96) if ($small1 == 1);
	}

	for my $per (0..99) {
		#my $ratio = ($costs{($per+1).""} - $costs{$per}) * 100.0 / $costs{$per};
		my $ratio = $costs{($per+1).""} * 100.0 / $costs{$per} - 100.0;
		printf "%3d%%: ratio= %8.5f (%7d -> %7d)\n",
			$per+1, 
			#$ratio >= 100 ? 25 : 
			$ratio, $costs{$per}, $costs{($per+1).""};
	}
}


__END__
