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
use IO::File;
use GD;

# use lib '/home/twomi/web/libs';
use lib '/home/customers/tumi/public_html/archives/batmud';
use lib '/home/customers/tumi/tumilib';
use BatmudTools::Site;
use BatmudTools::Vars;

my %sizes = (
	'small' 	=> "24,24",
	'medium'	=> "42,42",
	'large'		=> "60,60",
	'xlarge'	=> "90,90",
);


## Version number
my $VERSION = "0.1";
my $size = param('size') || "small";
my ($image_x, $image_y) = split/,/, $sizes{$size};
my @tiles = split/,/,param('pos');

my $logdir = &getVar('logpath');
my $fh = new IO::File "$logdir/forummap.log", "a+";
print $fh "X" if ($fh);
undef $fh;

## We are printing out png images
	print <<until_end;
Content-Type: image/png

until_end





## Preparations of image
my $im = new GD::Image($image_x, $image_y);
$im->interlaced('false');

## Lets define some colors
my $white   = $im->colorAllocate(255, 255, 255);
my $black   = $im->colorAllocate(0, 0, 0);

my %cmap = (
	'c' => "235,235,235",	# closed
	'u' => "160,210,245",	# you
	'f' => "255,0,0",		# free
	't' => "50,240,50",		# taken
	'o' => "235,235,0",		# outsider
);
$im->fill(1, 1, $white);

$cmap{'c'}	= $im->colorAllocate(split/,/,$cmap{'c'});
$cmap{'u'}	= $im->colorAllocate(split/,/,$cmap{'u'});
$cmap{'f'}	= $im->colorAllocate(split/,/,$cmap{'f'});
$cmap{'t'}	= $im->colorAllocate(split/,/,$cmap{'t'});
$cmap{'o'}	= $im->colorAllocate(split/,/,$cmap{'o'});


my $cntr = 0;
for my $tile (@tiles) {
	my $x = ($cntr % 3) * int($image_x / 3);
	my $y = int($cntr / 3) * int($image_y / 3);
	my $w = int($image_x / 3);
	my $h = int($image_y / 3);
	my $c = $cmap{$tile} || $white;

	print STDERR "Printing tile $tile to $x,$y  sized $w,$h, color $c\n";
	$im->rectangle($x, $y, $x+$w, $y+$h, $black);
	$im->fill( int($x+$w/2), int($y+$h/2), $c);

	$cntr++;
}

## black box around the image
$im->rectangle(0, 0, $image_x-1, $image_y-1, $black);


## We need binmode to print out png OK
binmode STDOUT;
print $im->png;





1;
