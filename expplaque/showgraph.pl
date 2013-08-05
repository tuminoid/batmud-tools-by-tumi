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

# my stuff
# use lib '/home/twomi/web/libs';
use lib '/home/customers/tumi/public_html/archives/batmud';
use lib '/home/customers/tumi/tumilib';
use Tumi::Helper;
use BatmudTools::Site;



my @dudes = split/,|%20/, param('who') || ('twomi');

for my $dude (sort @dudes) {
	$dude = ucfirst $dude;
}
my $people = join(", ", @dudes);


my $query = "";
my $width = 640;
my $height = 480;
for my $key (param) {
	$query .= "$key=".param($key)."&";
	($width, $height) = split/x/, param($key)
		if ($key eq "image");

}
$query =~ s/&$//;
$query =~ s/&/&amp;/g;

my $content = <<until_end;
<h2>$people</h2>
<img src="expplaque/graph.pl?$query" width="$width" height="$height" alt="Expgraph $width x $height" />
until_end


&pageOutput('expgraph', $content);



1;

__END__
