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
use POSIX qw/floor/;

my $HUMAN_SKILLCOST = 234814;
my $HUMAN_SPELLCOST = 785446;


while(<>) {
	/(\w+)\s+(\d+)\s+(\d+)/;
	my $race = $1;
	my $skillcost_mod = floor($2/$HUMAN_SKILLCOST * 100.0);
	my $spellcost_mod = floor($3/$HUMAN_SPELLCOST * 100.0);

	printf "%-14s %3d %3d\n", $race, $skillcost_mod, $spellcost_mod;
}
