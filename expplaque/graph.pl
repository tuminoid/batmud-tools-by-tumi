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
use CGI qw/param/;
use POSIX qw/floor/;
use GD;

# my stuff
# use lib '/home/twomi/web/libs';
use lib '/home/customers/tumi/public_html/archives/batmud';
use lib '/home/customers/tumi/tumilib';
use Tumi::Helper;
use BatmudTools::Vars;

## Some of the code is in other files
require 'plaque-funcs.pl';


## Version number
my $version = "1.0.2, 3rd Oct 2006";

## Default size is 640, 480
my ($image_x, $image_y) = (640, 480);

## The image param must match 2to4_decim x 2to4_decim format
($image_x, $image_y) = split/x/, param('image')
	if (param('image') && param('image') =~ /^\d{2,4}x\d{2,4}$/);


## Some 'defines'
## Where does the scalelines go
my $HORZLINE_Y      = 40;
my $VERTLINE_X      = 60;

## How much space between scalelines and nearest graph etc
my $EMPTY_SPACE     = 14;

## How many expscalelines will be drawn
my $LINES_ON_GRAPH  = 10;

## How many datescalelines will be drawn
my $WEEKS_ON_GRAPH  = 3;

## Copyright message position
my $TEXT_Y          = 5;
my $TEXT_X          = 10;

## Numbers for start and end exp
my $START_EXP_X     = ($VERTLINE_X + 5);
my $END_EXP_X       = ($image_x - $VERTLINE_X + $EMPTY_SPACE);

## Where the names of graphed people will be drawn
my $NAMES_Y         = 18;

## Where the dates of scales will be drawn
my $WEEKS_Y         = 35;

## Whats the max height and width of the graph part
my $GRAPH_MAX_Y     = ($image_y - $HORZLINE_Y - 4*$EMPTY_SPACE);
my $GRAPH_MAX_X     = ($image_x - $VERTLINE_X - 3*$EMPTY_SPACE - 4*$EMPTY_SPACE); # added 4 for numbers

## First y and x that will be part of graph
my $FIRST_Y         = ($image_y - $HORZLINE_Y - $EMPTY_SPACE);
my $FIRST_X         = ($VERTLINE_X + $EMPTY_SPACE + 2*$EMPTY_SPACE); # added 2 for numbers


## We are printing out png images
print <<until_end;
Content-Type: image/png

until_end

## Directory where source files can be found
my $dir = &getVar('siteroot')."/expplaque/source/";

## Min and Max graph defaults
my ($min, $max) = (100000000, 10000000);


## Getting all the source files into an array
my @allfiles = &getDir($dir, "weekly-*.txt");

## People we should make graph of.. die if invalid
my @ppl = sort split/,/,param('who') || die;

## The number of weeks displayed is defaulted to 20 or if larger than number of files, then that
my $num = (param('num') || 20) > @allfiles ? @allfiles : param('num') || 20;

## Files is the actual set of files we are gonna handle
my @files = (reverse sort &getDir($dir, "weekly-*.txt"))[0..$num-1];
my %data = ();
my $count = 0;



## Reading the data in
for my $file_in (reverse @files) {
	chomp($file_in);
	## Reads the file into array of lines
	my @source = split/\n/, &readFile($dir.$file_in);

	## Makes a hash, indexed by players name, valued with position level and exp
	my %plaque = &parsePlaque(@source);

	##foreach my $k (keys %plaque) {print STDERR "k: $k, v: $plaque{$k}\n"; }

	for (my $who=0; $who<@ppl; $who++) {
		my $plr = ucfirst($ppl[$who]) || next;
		$plr =~ s/^\s+//; $plr =~ s/\s+$//g;
		if (defined $plaque{$plr}) {
			my $expo = (split/;/, $plaque{$plr})[2];
			$max = $expo if ($expo > $max);
			$min = $expo if ($expo < $min);
			if (defined $data{$plr}) { $data{$plr} .= ",".$expo; } else { $data{$plr} = "".$expo; }
		}
		else {
			##print STDERR "$plr wasn't defined\n";
			if (defined $data{$plr}) {$data{$plr} .= ",0"; } else { $data{$plr} = "0"; }
		}
		##print STDERR "data is: ";
		##foreach my $val (values %data) { print STDERR $val, ", "; }
		##print STDERR "\n";
	}
}
$min /= 1.1;
$max *= 1.05;
## End of data preps



## Preparations of image
my $im = new GD::Image($image_x, $image_y);

## Lets define some colors
my $white   = $im->colorAllocate(255, 255, 255);
my $black   = $im->colorAllocate(0, 0, 0);
my $lgrey   = $im->colorAllocate(200, 200, 200);
my $dgrey   = $im->colorAllocate(100, 100, 100);
my $red     = $im->colorAllocate(255, 0, 0);
my $orange    = $im->colorAllocate(230, 150, 40);
my $green   = $im->colorAllocate(40, 200, 80);
my $dblue  = $im->colorAllocate(0, 0, 255);
my $magenta = $im->colorAllocate(255, 0, 255);
my @color = ($red, $dblue, $dgrey, $green, $orange, $magenta);

## White background and black box around the image
$im->rectangle(0, 0, $image_x, $image_y, $white);
$im->rectangle(1, 1, $image_x-1, $image_y-1, $black);

## Vertical scale line
$im->line($VERTLINE_X,
					$image_y - $HORZLINE_Y + $EMPTY_SPACE/2,
					$VERTLINE_X,
					2*$EMPTY_SPACE,
					$dgrey);

## Horizontal scale line
$im->line($VERTLINE_X - $EMPTY_SPACE/2,
					$image_y - $HORZLINE_Y,
					$image_x - $EMPTY_SPACE,
					$image_y - $HORZLINE_Y,
					$dgrey);

## White is transparent; not
$im->transparent($white);
## Image is interlaced..
$im->interlaced('false');


## Copyright
$im->string(gdSmallFont, $TEXT_X, $TEXT_Y,
							"ExpGraph (c) Tumi 2003-2006, http://support.bat.org/expplaque/graph.pl, v$version", $dgrey);




## Dashed scale lines
for (my $z=0; $z<$LINES_ON_GRAPH+1; $z++) {
	my $line_y = floor($GRAPH_MAX_Y/$LINES_ON_GRAPH*$z);
	my $expnum = $min + (($max-$min)/$LINES_ON_GRAPH)*$z;
	if ($z <= $LINES_ON_GRAPH) {
		$im->dashedLine($VERTLINE_X-5,
										$FIRST_Y - $line_y,
										$image_x - $EMPTY_SPACE,
										$FIRST_Y - $line_y,
										$lgrey);
	}

	$im->string(gdSmallFont,
							$VERTLINE_X - 45, # 45 = string width assumption
							$FIRST_Y - $line_y - 5,
							"".(floor($expnum/100000)/10)."M",
							$dgrey);
}


## Names
$count = 0;
foreach my $plr (sort keys %data) {
	my $name_x = $VERTLINE_X + 20 + floor($GRAPH_MAX_X / @ppl * $count);
	$im->string(gdSmallFont, $name_x, $image_y-$NAMES_Y, $plr, $color[$count++]);
}


## Dates
my $drawn = 0;
$count = floor((@files-1)/2);
my @date_x_array = (0, floor($GRAPH_MAX_X/(@files-1)*$count), $GRAPH_MAX_X);
foreach my $date_x (@date_x_array) {

	$files[@files-1] =~ /source\-(\d{4,4})(\d{2,2})(\d{2,2})/
		if ($date_x == 0);
	$files[$count] =~ /source\-(\d{4,4})(\d{2,2})(\d{2,2})/
		if ($date_x == $date_x_array[1]);
	$files[0] =~ /source\-(\d{4,4})(\d{2,2})(\d{2,2})/
		if ($date_x == $GRAPH_MAX_X);
	my ($year, $month, $day) = ($1, $2, $3);

	$im->dashedLine($FIRST_X + $date_x,
									$FIRST_Y + $EMPTY_SPACE,
									$FIRST_X + $date_x,
									2*$EMPTY_SPACE,
									$lgrey);

	$im->string(gdSmallFont,
							$FIRST_X + $date_x - 5 - $drawn*21,   # 5 = -5 from line_x
							$image_y - $WEEKS_Y,
							"".$year."-".$month."-".$day."",
							$lgrey);

	$drawn++;
}



## Graphs
$count = 0;
foreach my $plr (sort keys %data) {
	my @exps = split/,/, $data{$plr};
	my $left_add = $GRAPH_MAX_X / (@exps-1);
	my $prev_y = 0;
	my $plr_color = $color[$count++];
	my $left = 0;
	my ($another_counter, $exp_drawn) = (0, 0);

	print STDERR "min: $min, max: $max\n" if (param('debug'));

	for my $exp (@exps) {
		my $y = floor( ($exp-$min)/($max-$min) * $GRAPH_MAX_Y );
		$another_counter++;

		if ($exp_drawn == 0 || $another_counter == $num) {
			if ($exp > 0) {
				$im->string(gdTinyFont,
										$another_counter == $num ? $END_EXP_X : $START_EXP_X,
										$FIRST_Y - $y - 4,
										"".(floor($exp/100000)/10)."M",
										$plr_color);
				$exp_drawn = 1;
			}
		}

		if ($prev_y > 0 && $y > 0) {
			$im->line($FIRST_X + floor($left - $left_add + 0.5),
								$FIRST_Y - $prev_y,
								$FIRST_X + $left,
								$FIRST_Y - $y,
								$plr_color);

			print STDERR "oldx: $left, oldy: $prev_y, addx: $left_add, newy: $y\n"
				if (param('debug'));
		} else {
			print STDERR "didn't plot: oldx: $left, oldy: $prev_y, addx: $left_add, newy: $y\n"
				if (param('debug'));
		}

		if ($y > 0 || $prev_y > 0) {
			my $this_y = $FIRST_Y - ($y > 0 ? $y : $prev_y);
			my $this_x = $FIRST_X + ($y > 0 ? $left : floor( $left - $left_add + 0.5));

			$im->rectangle($this_x-1, $this_y-1, $this_x+1, $this_y+1, $plr_color);
		}

		$left += $left_add;
		$prev_y = $y;
	}
}

## End of preps



## We need binmode to print out png OK
binmode STDOUT;
print $im->png;





1;
