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

# Strict is always good
use strict;
use CGI qw/param/;
use POSIX qw/floor ceil/;

# our stuff
# use lib '/home/twomi/web/libs';
use lib '/home/customers/tumi/public_html/archives/batmud';
use lib '/home/customers/tumi/tumilib';
use Tumi::Helper;


## Some of the code is in other files
require 'colorfuncs.pl';
require 'colorhash.pl';


## Version number
my $VERSION = "v0.1";
my $mapsize = param('size') || 100;
$mapsize = ($mapsize > 100 ? 100 : ($mapsize < 50 ? 50 : $mapsize));
my $batorg = param('batorg') || "";

my $spacing = "0.2em";
my $opacity1 = "100";
my $opacity2 = "1.0";
my $color = "White";
my $bgcolor = "Black";
my $padding = "0";

if ($batorg) {
	$spacing = "0";
	$opacity1 = "63";
	$opacity2 = "0.63";
	$color = "Black";
	$bgcolor = "White";
	$padding = "2px";
}

## Some magic number definitions
my $map_x = 481;
my $map_y = 481;
my $fontsize = 4;
#my ($image_x, $image_y) = ($map_x * 9, $map_y * 9);
$fontsize = 5 + ceil($fontsize * $mapsize / 100.0)."pt";

## Using those funcs we do the preloading
my @textmap = split/\n/, &readFile('source/batmap.txt');
my @locats = split/\n/, &readFile('source/locations.txt');
my @autolocs = split/\n/, &readFile('source/autogen.txt');
#my @dblocs = split/\n/, &readFile('source/dbgen.txt');
my %locations = &parseLocations(@locats, @autolocs);

# output css
my $output = <<until_end;

/* labels.pl - the css generator for batmap by Tumi (c) 2006 */

body {
	padding: 0;
	margin: 0;
}

.arealabel {
	display: inline-block;
	position: absolute;
	background-color: $bgcolor;
	color: $color;

	filter: alpha(opacity=$opacity1);
	opacity: $opacity2;

	padding: $padding;
	margin: 0;

	font-size: $fontsize;
	font-family: monospace, serif;;
	font-weight: bold;
	letter-spacing: $spacing;
	white-space: nowrap;

	z-index: 25;
}

.arealabel:hover {
	font-size: large;
	z-index: 50;
	opacity: 80;
	filter: alpha(opacity=80);
}


until_end


foreach my $loc (keys %locations) {
  my ($char_y, $char_x) = split/,/, $loc;
  my $name = $locations{$loc};
  my $cssname = lc $name;

  my $abs_x = floor(($char_x-1) * 9 * $mapsize / 100 - 1)."px";
  my $abs_y = floor(($char_y-1) * 9 * $mapsize / 100)."px";
  $cssname =~ s/\?/qmark/g;
  $cssname =~ tr/[a-z0-9]//cd;
  $cssname =~ s/^[0-9]+//;

  $output .= <<until_end;
#$cssname {
	top: $abs_y;
	left: $abs_x;
}

until_end
}


print qq|Content-Type: text/css\nCache-Control: no-cache\n\n|;
print $output;


1;


__END__
