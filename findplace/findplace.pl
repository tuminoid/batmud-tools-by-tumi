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

## Always using strict
use strict;
use IO::File;
use POSIX qw/floor/;
use CGI qw/param/;


## Define for map width
my $MAP_WIDTH = 481;

## Paste map to be found here, first line should have only one char
## Also replace the * with the real char
my $req = <<until_end;
          v         
     vvvvvvvvr     
    vvvvvvvvrrr    
   vvvvvvvvvvrrr   
  vvvvvvvvvvvvrrr  
 ^vvvvvvvvvvvvvrrr 
 ^vvvvvvvvvvvvrrrr 
 ^vvvvvvvvvvvvvrrr 
 ^vvvvvvvvvvvvvvrr 
^^vvvvvvvvvvvvvvvrr
 ^vvvvvvvvvvvvvvrr 
 ^vvvvvvvvvvvvvvvr 
 ^vvvvvvvvvvvvvvrr 
 ^vvvvvvvvvvvvvvvr 
  vvvvvvvvvvvvvvr  
   vvvvvvvvvvvvv   
    vvvvvvvvvvv    
     vvvvvvvvv     
         v         

until_end


## Splitting string into array, trimming spaces
my @reqarr = split/\n/, $req;
for (my $i=0;$i<@reqarr; $i++) {
	$reqarr[$i] =~ s/^\s+//g;
	$reqarr[$i] =~ s/\s+$//g;
}


## Calculating size etc from map (note array starts from 0)
my $height   = scalar @reqarr;
my $center_y = floor ($height/2)+1;
my $width    = length $reqarr[$center_y-1];
my $center_x = floor ($width/2)+1;

print STDERR ">>Height: $height Width: $width  CenterX: $center_x CenterY: $center_y<<\n";


## Loading real batmap from file, remember to update once in a while
my @map = readFile("..\\batmap\\source\\batmap.txt");
my @newmap = readFile("..\\batmap\\source\\batmap.txt");


## Going  thru map.. First looking a singlechar match, then processing
## down the map if lines match
my $mapline = 0;
foreach my $line (@map) {
	my $mapline2 = 0;
	my @linesplit = split//, $line;
	for (my $x=0; $x<$MAP_WIDTH; $x++) {
		if ($linesplit[$x] eq $reqarr[0]) {
			my $reqline = 1;
			#print "First line match at X: $x Y: $mapline, mark: '$linesplit[$x]'\n";
			for ($mapline2=$mapline+1; $mapline2<$mapline+$height; $mapline2++) {
				my $start_x = $x - floor(length ($reqarr[$reqline])/2);
				my $len = length $reqarr[$reqline];
				my $stri = substr($map[$mapline2], $start_x, $len);
				#print "Trying at s_x: $start_x y: $mapline2 reqline: $reqline len: $len str: '$stri'\n";
				if ($stri eq $reqarr[$reqline]) {
					#print "Match number ".($mapline2-$mapline+1)." at s_x: $start_x y: $mapline2\n";
					$reqline++;
					next;
				}
				last;
			}

			## Routine didn't exit in for, so here is a match, put a * instead of real char
			if ($mapline2 == $mapline+$height) {
				my $modifline = substr($newmap[$mapline+$center_y-1], $x-$center_x, $width);
				substr($modifline, $center_x, 1) = '*';
				print STDERR "Match on X: ".$x." Y: ".($mapline+$center_y-1)."\n";
				substr($newmap[$mapline+$center_y-1], $x-$center_x, $width) = $modifline;
			}
		}
	}
	$mapline++;
}


## Print out the modified map with * marks
foreach my $line (@newmap) {
	print $line;
}



## read file into array subroutine
sub readFile {
	my @filecontents = ();
	my $filename = shift;

	if($filename) {
		my $file = IO::File->new($filename);
		if($file) {
			@filecontents = <$file>;
			return (@filecontents);
		}
		else {
			die "Error: error while reading from filehandle...\n";
		}
	}
	else {
		die "Error: filename not specified...\n";
	}
}



1;

