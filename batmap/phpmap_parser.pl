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

use strict;
use CGI qw/param/;

# use lib '/home/twomi/web/libs';
use lib '/home/customers/tumi/public_html/archives/batmud';
use lib '/home/customers/tumi/tumilib';
use Tumi::Helper;
require 'colorfuncs.pl';

# setup
my $map_url = 'http://www.bat.org/maps/mapnew.php';
my $wget_bin = 'wget -q';
my $source_file = 'mapnew.php';
my $output_file = 'source/autogen.txt';

# set variables
my ($map_x, $map_y) = (-1, -1);
my ($next_is_area, $counter, $ok_counter) = (0, 0, 0);
my %areas_found = ();
my %names_used = ();

# are we running it manually ?
my $man = param('man') || 0;
my $force = param('force') || $man;
print &findMissingLocations($force) if ($man);


1;


sub findMissingLocations {
	my $force = shift || 0;
	my $reply = "";

	# check latest update
	my $last_mod = (stat($output_file))[9];
	return &readFile($output_file) if (($last_mod + 1*24*60*60) < time());

	# get manual locations info
	my $manual_source = 'source/locations.txt';
	my %manual_areas = &parseLocations(split/\n/, &readFile($manual_source));

	# get data
	my $cmd_output = `$wget_bin $map_url`;
	my @data = split/\n/, &readFile($source_file);


	# do the hard work
	for my $line (@data) {
		# if its marked as area
		if ($next_is_area && $line =~ m#^([a-zA-Z0-9\.\+\/\&'\- ,]+)\.?</DIV>$#) {

			# name goes in only once to handle special case areas
			unless (defined $names_used{$1}) {
				my $location = $1;
				$names_used{$location} = 1;

				# checking if we have manual name for it
				my $manual_loc = &findAreaNearCoord($map_y+1, $map_x+1, %manual_areas);
				if ($manual_loc ne "") {
					$location .= qq| ($manual_loc)|;
					$ok_counter++;
				} else {
					#print STDERR "Couldn't found counterpart for $map_y,$map_x ($location)\n";
					$reply .= "$map_y,$map_x: ?$location\n";
				}
				$areas_found{"$map_y,$map_x"} = $location;
				$counter++;
			}
			$next_is_area = 0;
			next;
		}

		# debug
		if ($next_is_area) {
			#print STDERR "next_is_area still on, line is: '$line'\n";
			$next_is_area = 0;
			next;
		}

		# if its coord line
		if ($line =~ m#<!-- mapX: (\d+), mapY: (\d+) -->#) {
			($map_x, $map_y) = ($1, $2);
			next;
		}

		# if its area name open tag
		if ($line =~ m#^<DIV class="popup" id="p\d+" style=#) {
			$next_is_area = 1;
			next;
		}
	}

	# print stuff
	my $ofh = new IO::File $output_file, "w";
	#for my $coord (sort {&coordSort($a,$b)} keys %areas_found) {
	#	print $ofh "$coord:".(" " x (8-length($coord)))."$areas_found{$coord}\n";
	#}
	print $ofh $reply;

	# remove wget output
	unlink "$source_file";

	#print STDERR "Found $counter areas, $ok_counter counterparts.\n";
	return $reply;
}



sub coordSort {
	my ($a, $b) = @_;
	my ($a_y, $a_x) = split/,/, $a;
	my ($b_y, $b_x) = split/,/, $b;

	return ($a_x <=> $b_x) if ($a_y == $b_y);
	return ($a_y <=> $b_y);
}




__END__

<!-- mapX: 121, mapY: 335 -->
<!--
<DIV class="mappnt" id="pp0" style="position: absolute; left: 121; top:335;margin-top: 0px; margin-right: 0px; visibility:hidden"
  onmouseover="popup('p0',true); return false" onmouseout="popup('p0',false);return false">
<IMG src="b00/b1.gif" width="1" height="1" >
</DIV>
-->
<IMG src="b00/b1.gif" width="1" height="1" class="mappnt" id="pp0" style=
  "position: absolute; left: 121; top:335;margin-top: 0px; margin-right: 0px; visibility:hidden"
  onmouseover="popup('p0',true); return false" onmouseout="popup('p0',false);return false">

<DIV class="popup" id="p0" style="position: absolute; left:122.5; top:335; visibility:hidden">
dahbec</DIV>
