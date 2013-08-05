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

my %racial_training = (
	"barsoomian"	=> "77,63,52,42,101",
	"brownie"		=> "39,37,90,79,82",
	"catfolk"		=> "68,77,62,65,96",
	"centaur"		=> "102,92,47,72,55",
	"cromagnon"		=> "89,79,42,42,67",
	"cyclops"		=> "110,112,27,27,55",
	"demon"			=> "74,87,70,60,66",
	"draconian"		=> "100,94,42,42,57",
	"drow"			=> "62,62,77,102,87",
	"duck"			=> "57,50,98,84,75",
	"duergar"		=> "92,87,53,64,72",
	"dwarf"			=> "86,84,57,63,68",
	"elf"			=> "63,60,86,92,77",
	"ent"			=> "65,92,57,112,17",
	"gargoyle"		=> "106,88,32,32,64",
	"giant"			=> "105,112,27,27,55",
	"gnoll"			=> "69,77,59,67,70",
	"gnome"			=> "54,52,66,82,72",
	"hobbit"		=> "79,57,80,67,102",
	"human"			=> "71,71,71,71,71",
	"kobold"		=> "56,57,70,57,64",
	"leech"			=> "47,48,82,62,107",
	"leprechaun"	=> "44,42,98,94,98",
	"lich"			=> "65,65,65,65,65",
	"lizardman"		=> "93,85,32,32,82",
	"merfolk"		=> "69,60,86,86,55",
	"minotaur"		=> "101,92,42,42,67",
	"moomin"		=> "65,60,87,87,77",
	"ogre"			=> "104,97,47,47,54",
	"orc"			=> "95,87,42,52,79",
	"penguin"		=> "68,47,77,87,27",
	"satyr"			=> "75,57,79,82,87",
	"shadow"		=> "68,50,82,82,68",
	"skeleton"		=> "77,77,57,57,77",
	"sprite"		=> "42,40,77,72,112",
	"thrikhren"		=> "42,42,112,72,40",
	"tinmen"		=> "81,76,82,34,54",
	"titan"			=> "102,102,42,45,62",
	"troll"			=> "101,97,42,47,57",
	"valar"			=> "74,92,72,92,82",
	"vampire"		=> "65,57,88,87,77",
	"wolfman"		=> "89,76,60,60,72",
	"zombie"		=> "112,54,52,97,32",
);


for my $race (sort keys %racial_training) {
	my ($con, $str, $int, $wis, $dex) = split/,/, $racial_training{$race};
	printf "%3d %3d %3d %3d %3d\n", $str, $dex, $con, $int, $wis;
}

1;
