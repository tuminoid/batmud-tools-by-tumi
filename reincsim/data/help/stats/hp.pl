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
use CGI qw/param/;

my $con1 = param('c1');
my $con2 = param('c2');
my $con3 = param('c3');
my $hp1 = param('hp1');
my $hp2 = param('hp2');
my $hp3 = param('hp3');

my $r1 = abs($hp1-$hp2)/abs($con1-$con2);
my $r2 = abs($hp2-$hp3)/abs($con2-$con3);
my $r3 = abs($hp1-$hp3)/abs($con1-$con3);

printf "hp/con is %4.2f\n", $r1;
printf "hp/con is %4.2f\n", $r2;
printf "hp/con is %4.2f\n", $r3;
printf "hp/con final is %4.2f\n", ($r1+$r2+$r3)/3;
