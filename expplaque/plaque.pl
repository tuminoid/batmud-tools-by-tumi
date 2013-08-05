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
use IO::File;

# my stuff
# use lib '/home/twomi/web/libs';
use lib '/home/customers/tumi/public_html/archives/batmud';
use lib '/home/customers/tumi/tumilib';
use BatmudTools::Vars;
use Tumi::Helper;
use BatmudTools::Site;

## Some of the code is in other files
require 'plaque-funcs.pl';


if (param('cumulative')) {
	my $year = param('cumulative') || 2004;
	my $content = "<pre>";
	$content .= &parsePlaquesGained($year);
	&pageOutput('expplaque', $content."</pre>");
	exit;
}



## Version number
my $version = "1.0.0";
my $siteroot = &getVar('siteroot');

my $oldie = param('old') || '20021216';
my $newie = param('new') || '20021222';
my $type = param('type') || 'source'; 

if ($oldie > $newie) {
  my $temp = $oldie;
  $oldie = $newie;
  $newie = $temp;
}

my $dir = "$siteroot/expplaque/" . 
  ($type eq "source" ? "sources" : "source");


my $file_in  = "$dir/$type-$oldie.txt";
my $file_in2 = "$dir/$type-$newie.txt";

if (!(-e $file_in && -e $file_in2)) {
	print STDERR "Error while processing.. f1=$file_in f2=$file_in2\n";
	&pageOutput('expplaque', "Error in dates");
	exit;
}

## Using those funcs we do the preloading
my @oldSource = split/\n/, &readFile($file_in);
my @newSource = split/\n/, &readFile($file_in2);
my %oldPlaque = &parsePlaque(@oldSource);
my %newPlaque = &parsePlaque(@newSource);
my $output = "<pre><code>\n".&parsePlaques(\%oldPlaque, \%newPlaque)."</code></pre>\n";

my $content = "<h2>Top Expmakers $oldie - $newie</h2>\n".$output;


&pageOutput('expplaque', $content);


1;
