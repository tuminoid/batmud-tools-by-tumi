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

# my stuff
# use lib '/home/twomi/web/libs';
use lib '/home/customers/tumi/public_html/archives/batmud';
use lib '/home/customers/tumi/tumilib';
use Tumi::Helper;
use BatmudTools::Site;
use Tumi::DB;
use BatmudTools::Vars;


my $SCRIPT = "skillspell.pl";
my $VERSION = "1.0";

my $name = param('name') || "";
$name =~ tr/[a-zA-Z_]//cd;
$name =~ s/_/ /g;
 
my $content = "under construction";


# sql stuff
my $sql_spells = <<until_end;
select * from spell_table order by spellName asc;
until_end

my $sql_skills = <<until_end;
select * from skill_table order by skillName asc;
until_end

my $sql_onespell = <<until_end;
select * from spell_table,spell_data where spell_table.spellName = <name> and spell_table.spellId = spell_data.spellId;
until_end

my $sql_oneskill = <<until_end;
select * from skill_table,skill_data where skill_table.skillName = <name> and skill_table.skillId = skill_data.skillId;
until_end


my @dataorder = ('action_duration', 'spell_category', 'aff_stat', 'spell_type', 'extra_help');



&pageOutput('skillspell', $content);


1;
