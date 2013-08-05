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
use warnings;
use diagnostics;

use IO::File;
use CGI qw/param/;
use POSIX qw/ceil/;

use constant USENEW => 0;


# Gives us the header and footer
require '../content/index2.pl';
require '../content/helper.pl';


# Current version number
my $VERSION = "1.0.1a";




#####################################################################
#
# START OF VARIABLE INITIALIZATION, INFORMATION INITIALIZATION
#
#####################################################################




# Fetching the contents
my $pre_content = BatmudIndex::preContent('item700', param('debug'));
my $post_content = BatmudIndex::postContent();
my $point_of_site = readFile('html/pointofsite.html');
my $fixlist = readFile('html/fixlist_hc.html');
my $buglist = readFile('html/buglist_hc.html');


# Racial information contains the race information once it has been loaded up
my %racial_information = ();

# Basecost has contains the skills and spells basecosts once they're loaded up
my %basecosthash = ();

# Totalcost hash contains the totalcosts of skills and spells part of the reinc
# It keeps track of which skills has been calculated etc
my %totalcost = ();

# Arcane talent array contains regexs of skills that are arcane, ie 100 max
my @arcanetalents = ();

# Quest hash
my %questshash = ();




# Background hash contains the available backgrounds and guild within them
my %bghash = (
	"civilized"			=>
		[ "civilized_mages", "civilized_fighters", "runemages", "bards", "sabres",
			"merchants", "alchemists" ],
	"good_religious"	=>
		[ "nuns", "druids", "tarmalens", "monks", "templars" ],
	"evil_religious"	=>
		[ "lords_of_chaos", "priests", "reavers", "spiders", "tigers" ],
	"magical"			=>
		[ "conjurers", "mages", "psionicists", "channellers" ],
	"nomad"				=>
		[ "rangers", "crimsons", "barbarians", "squires", "beastmasters", "cavaliers" ],
	"generic"			=>
		[ "secret_societys", "navigators" ],
);


# Guilld bonuses hash, sorted by the guild/bg. Numbers mean the full guild bonuses
# as level dependant bonuses not avail/too much data. Just divide them by guild
# maxlevel and multiply by the levels in guild to get 'correct' amount.
# Those marked as 'fake' are not based on any real data
my %bonuses = (

	# BACKGROUNDS

	"civilized"
		#=> { "str" => 5, "dex" => 20, "con" => 10, "int" => 18, "wis" => 18 }, # old
		=> { "str" => 5, "dex" => 20, "con" => 10, "int" => 15, "wis" => 20 },  # my guess
	"evil_religious"
		=> { "con" => 20, "int" => 10, "wis" => 30 },
	"good_religious"
		=> { "con" => 20, "int" => 10, "wis" => 30 },
	"magical"
		=> { "int" => 40, "wis" => 20 },
	"nomad"
		=> { "con" => 20, "str" => 20, "dex" => 20 },


	# GUILDS


	"civilized_mages"
		=> { "con" => 15, "int" => 8, "wis" => 15 },
	"civilized_fighters"
		=> { "str" => 10, "dex" => 10, "con" => 10 },
	"runemages"
		=> { "int" => 20, "wis" => 5 }, # fake
	"bards"
		=> { "dex" => 15, "wis" => 20 }, # confirmed 2/2004
	"merchants"
		=> { "str" => 6, "dex" => 6, "con" => 6, "int" => 6, "wis" => 6 },
	"squires"
		=> { "str" => 5, "dex" => 5, "con" => 5 }, # fake
	"beastmasters"
		=> { "str" => 5, "dex" => 10, "con" => 5 }, # fake
	"cavaliers"
		=> { "str" => 10, "dex" => 5, "con" => 5 }, # fake
	"alchemists"
		=> { "con" => 10, "int" => 15, "wis" => 10 }, # confirmed 2/2004


	"nuns"
		=> { "wis" => 13, "int" => 12 },
	"druids"
		=> { "int" => 15, "wis" => 15 },
	"tarmalens"
		=> { "wis" => 30 },
	"monks"
		=> { "dex" => 10, "con" => 20 },
	"templars"
		=> { "str" => 10, "dex" => 5, "con" => 15 },


	"lords_of_chaos"
		=> { "str" => 20, "con" => 10 },
	"priests"
		=> { "int" => 12, "wis" => 25 }, # confirmed 2/2004
	"reavers"
		=> { "str" => 15, "con" => 5, "wis" => 10 }, # fake
	"spiders"
		=> { "str" => 4, "dex" => 4, "con" => 22 }, # confirmed 2/2004
	"tigers"
		=> { "str" => 11, "dex" => 12, "con" => 7 },


	"conjurers"
		=> { "int" => 15, "wis" => 10 },
	"mages"
		=> { "con" => 5, "int" => 30 },
	"psionicists"
		=> { "int" => 25, "wis" => 10 }, # semi-confirmed 2/2004
	"channellers"
		=> { "int" => 26, "con" => 2, "wis" => 2 },


	"rangers"
		=> { "str" => 10, "dex" => 10, "con" => 15 },
	"crimsons"
		=> { "str" => 10, "dex" => 10, "con" => 15 }, # confirmed 2/2004
	"barbarians"
		=> { "str" => 20, "dex" => 10, "con" => 5 }, # confirmed 2/2004


	# RACIAL GUILDS


	"barsoomian"
		=> { "dex" => 5 }, # confirmed 2/2004
	"giant"
		=> { "str" => 2, "con" => 3 }, # confirmed 2/2004
	"human"
		=> { "str" => 1, "dex" => 1, "con" => 1, "int" => 1, "wis" => 1 }, # educated guess 2/2004
	"thrikhren"
		=> { "int" => 4, "wis" => 1 }, # educated guess 2/2004
	"leech"
		=> { "int" => 4, "wis" => 1 }, # confirmed 2/2004
	"drow"
		=> { "dex" => 3, "int" => 2 }, # confirmed 2/2004
	"ogre"
		=> { "str" => 3, "dex" => 2 }, # confirmed 2/2004
);


# The list of races in the game
my @racelist = (
	"barsoomian", "brownie", "catfolk", "centaur", "cromagnon", "cyclops",
	"demon", "draconian", "drow", "duck", "duergar", "dwarf", "elf", "ent",
	"gargoyle", "giant", "gnoll", "gnome", "hobbit", "human", "kobold", "leech",
	"leprechaun", "lich", "lizardman", "merfolk", "minotaur", "moomin", "ogre",
	"orc", "penguin", "satyr", "shadow", "skeleton", "sprite", "thrikhren",
	"tinmen", "titan", "troll", "valar", "vampire", "wolfman", "zombie",
);


# Available rebirth levels and corresponding titles
my %rebirthhash = (
	"0"		=>	"Mortal",
	"1"		=>	"Elder",
	"2"		=>	"Ancient",
	"3"		=>	"Eternal",
);


# How much powers do boons have at 100%
my %boonpowerhash = (
	"str"	=> 40,
	"dex"	=> 60,
	"con"	=> 40,
	"int"	=> 60,
	"wis"	=> 60,
	"super"	=> 12,
	"skill" => 16,
	"spell"	=> 16,
);


# Hash telling where to find the information in raceinfotable
my %infoindexhash = (
	"race"			=> 0,
	"rebirth"		=> 1,
	"skillcost"		=> 2,
	"spellcost"		=> 3,
	"exprate"		=> 4,
	"skillmax"		=> 5,
	"spellmax"		=> 6,
	"str"			=> 7,
	"dex"			=> 8,
	"con"			=> 9,
	"int"			=> 10,
	"wis"			=> 11,
	"siz"			=> 12,
	"fm"			=> 13,
	"infra"			=> 14,
	"gnp"			=> 15,
	"hptick"		=> 16,
	"sptick"		=> 17,
	"eatcorpses"	=> 18,
	"vision"		=> 19,
	"eatfood"		=> 20,
	"seemagic"		=> 21,
	"seeinvisible"	=> 22,
	"escapedeath"	=> 23,
	"waterallergy"	=> 24,
	"clairvoyance"	=> 25,
	"ac"			=> 26,
	"hpratio"		=> 27,
	"special"		=> 28,
);


#####################################################################
#
# END OF VARIABLE INITIALIZATION, INFORMATION INITIALIZATION
#
#####################################################################






#####################################################################
#
# START OF PARAMETER HANDLING, HTML CREATION ETC
#
#####################################################################




# We recreate the files having skills and spells basecosts if
# baseupdate param is defined, otherwise the same old file is loaded
# and used as basecost hash
&findSkillBaseCosts() if (param('baseupdate'));

# In case we might need one
my ($id, $alt_id) = &generateIds(param('id'));


# Loading up the saved params, if there is any, then
# overriding with params from param
my %params = &loadParams("saved/$id.db");
for my $key (param) {
	my @stuff = sort {$b<=>$a} param($key);
	$params{$key} = scalar @stuff == 1 ? param($key) : $stuff[0];
	# print STDERR "key= $key val= $params{$key}\n";
}


# Creating links for This reinc, New reinc and id_string to hold our id
my $quicklink	= qq|<a href="reincsim/hcreincsim.pl?id=$id">Reinc $id</a>|;
my $newreinc	= qq|<a href="reincsim/hcreincsim.pl?id=$alt_id">Create a new reinc</a>|;
my $viewlink	= qq|<a href="reincsim/viewreinc.pl?id=$id">ViewReinc $id (save before clicking!)</a>|;
my $id_string	= qq|<input type="hidden" name="id" value="$id" />\n|;
my $stats_only	= qq|<input type="checkbox" name="only_stats "| . (defined $params{'stats_only'} ? "checked=\"checked\" />\n" : "/>\n");

# Creating a Save & Calculate button for submitting the information to server
my $savereinc	= qq|<input type="submit" name="save" value="Calculate &amp; Save" />|;
my $submit		= qq|<input type="submit" value="Calculate" />|;



# Background, race, and rebirth are the most basic information
my $bg = $params{'bg'} || 'civilized';
my $race = $params{'race'} || 'human';
my $rebirth = $params{'rebirth'} || 0;


# The guilds are next, followed by the guildlevels, which are
# filtered, to meet the right guild maximums (ie glevel1=35 and guild is
# conjurer, which maxes at 25, glevel is filtered to 25)
my $glevel1 = guildMaxLevel($params{'guild1'}, $params{'glevel1'});
my $glevel2 = guildMaxLevel($params{'guild2'}, $params{'glevel2'});
my $glevel3 = guildMaxLevel($params{'guild3'}, $params{'glevel3'});
my $glevel4 = guildMaxLevel($params{'guild4'}, $params{'glevel4'});
my $glevel5 = guildMaxLevel($params{'guild5'}, $params{'glevel5'});


# Constructing a hash about our guilds, to be passed on as a param for
# stat calculator, which calculates our estimated stats
my %guildconfig = (
	$bg		=> 10,
	$params{'guild1'} || "none" => $glevel1,
	$params{'guild2'} || "none" => $glevel2,
	$params{'guild3'} || "none" => $glevel3,
	$params{'guild4'} || "none" => $glevel4,
	$params{'guild5'} || "none" => $glevel5,
);


# Creating the background, race and rebirth select boxes
my $bg_select = &createBgSelect($bg);
my $race_select = &createRaceSelect($race);
my $rebirth_select = &createRebirthSelect($rebirth);


# Need to calculate maxes before populating skills and spells
my $stat_skill = &calculateTalentMax('skill', $race, $params{'boon_skill'}, $params{'ss_skill'});
my $stat_spell = &calculateTalentMax('spell', $race, $params{'boon_spell'}, $params{'ss_spell'});


# Creating guild and guildlevel select boxes for five guilds
my ($g1_select, $gl1_select) = &createGuildSelect($params{'guild1'}, $glevel1, 1);
my ($g2_select, $gl2_select) = &createGuildSelect($params{'guild2'}, $glevel2, 2);
my ($g3_select, $gl3_select) = &createGuildSelect($params{'guild3'}, $glevel3, 3);
my ($g4_select, $gl4_select) = &createGuildSelect($params{'guild4'}, $glevel4, 4);
my ($g5_select, $gl5_select) = &createGuildSelect($params{'guild5'}, $glevel5, 5);


# Creating skills and spells information and select boxes
# 1 as a last parameter means costs are fixed to 0, since theyre free
# as theyre from background
my ($bg_skills,		$bg_skills_cost)	= &createTalents($bg, 10, undef, 'skill', 1);
my ($race_skills,	$race_skills_cost)	= &createTalents($race, 5 - $rebirth, $bg, 'skill');
my ($g1_skills,		$g1_skills_cost)	= &createTalents($params{'guild1'}, $glevel1, $bg, 'skill');
my ($g2_skills,		$g2_skills_cost)	= &createTalents($params{'guild2'}, $glevel2, $bg, 'skill');
my ($g3_skills,		$g3_skills_cost)	= &createTalents($params{'guild3'}, $glevel3, $bg, 'skill');
my ($g4_skills,		$g4_skills_cost)	= &createTalents($params{'guild4'}, $glevel4, $bg, 'skill');
my ($g5_skills,		$g5_skills_cost)	= &createTalents($params{'guild5'}, $glevel5, $bg, 'skill');

my ($bg_spells,		$bg_spells_cost)	= &createTalents($bg, 10, undef, 'spell', 1);
my ($race_spells,	$race_spells_cost)	= &createTalents($race, 5 - $rebirth, $bg, 'spell');
my ($g1_spells,		$g1_spells_cost)	= &createTalents($params{'guild1'}, $glevel1, $bg, 'spell');
my ($g2_spells,		$g2_spells_cost)	= &createTalents($params{'guild2'}, $glevel2, $bg, 'spell');
my ($g3_spells,		$g3_spells_cost)	= &createTalents($params{'guild3'}, $glevel3, $bg, 'spell');
my ($g4_spells,		$g4_spells_cost)	= &createTalents($params{'guild4'}, $glevel4, $bg, 'spell');
my ($g5_spells,		$g5_spells_cost)	= &createTalents($params{'guild5'}, $glevel5, $bg, 'spell');


# Creating area filled with quests
my $quests_select = &createQuests();


# Creating the select boxes about boons, having 5 stages
# (none, tiny, small, medium, full)
my $strboon_select	= &createBoonSelect('str', $params{'boon_str'});
my $dexboon_select	= &createBoonSelect('dex', $params{'boon_dex'});
my $conboon_select	= &createBoonSelect('con', $params{'boon_con'});
my $intboon_select	= &createBoonSelect('int', $params{'boon_int'});
my $wisboon_select	= &createBoonSelect('wis', $params{'boon_wis'});
my $superboon_select= &createBoonSelect('super', $params{'boon_super'});

my $skillboon_select= &createBoonSelect('skill', $params{'boon_skill'});
my $spellboon_select= &createBoonSelect('spell', $params{'boon_spell'});


# Creating the select boxes for society bonuses
my $strss_select = &createSsSelect('str', $params{'ss_str'});
my $dexss_select = &createSsSelect('dex', $params{'ss_dex'});
my $conss_select = &createSsSelect('con', $params{'ss_con'});
my $intss_select = &createSsSelect('int', $params{'ss_int'});
my $wisss_select = &createSsSelect('wis', $params{'ss_wis'});

my $skillss_select = &createSsSelect('skill', $params{'ss_skill'});
my $spellss_select = &createSsSelect('spell', $params{'ss_spell'});


# Calculate eq bonuses
my $streq_select = &createEqSelect('str', $params{'eq_str'});
my $dexeq_select = &createEqSelect('dex', $params{'eq_dex'});
my $coneq_select = &createEqSelect('con', $params{'eq_con'});
my $inteq_select = &createEqSelect('int', $params{'eq_int'});
my $wiseq_select = &createEqSelect('wis', $params{'eq_wis'});


# We count the levels needed, affected by guilds, assumed that
# rebirthers usually take minimum number of levels in raceguilds
my $levels_spent	= 15 - $rebirth + $glevel1 + $glevel2 + $glevel3 + $glevel4 + $glevel5;
my ($exp_on_levels, $exp_saved)	= &countExpSpentOnLevels($levels_spent);


# Calculate train bonuses
my $trainingpoints = 0;
for my $lvl (30..$levels_spent) {$trainingpoints += $lvl;}
my ($strtrain_select, $strtrain_cost) = &createTrainSelect('str', $params{'train_str'});
my ($dextrain_select, $dextrain_cost) = &createTrainSelect('dex', $params{'train_dex'});
my ($contrain_select, $contrain_cost) = &createTrainSelect('con', $params{'train_con'});
my ($inttrain_select, $inttrain_cost) = &createTrainSelect('int', $params{'train_int'});
my ($wistrain_select, $wistrain_cost) = &createTrainSelect('wis', $params{'train_wis'});
my $trainingpoints_spent = $strtrain_cost + $dextrain_cost + $contrain_cost + $inttrain_cost + $wistrain_cost;


# Calculating the final stats, affected by the race, level of boon,
# super characteristics boon, society bonuses, and background and guild
# bonuses. Size natually derives only from the race.
my $stat_str = &calculateStats('str', $race, $params{'train_str'}, $params{'boon_str'}, $params{'boon_super'}, $params{'ss_str'}, $params{'eq_str'}, $bg, \%guildconfig);
my $stat_dex = &calculateStats('dex', $race, $params{'train_dex'}, $params{'boon_dex'}, $params{'boon_super'}, $params{'ss_dex'}, $params{'eq_dex'}, $bg, \%guildconfig);
my $stat_con = &calculateStats('con', $race, $params{'train_con'}, $params{'boon_con'}, $params{'boon_super'}, $params{'ss_con'}, $params{'eq_con'}, $bg, \%guildconfig);
my $stat_int = &calculateStats('int', $race, $params{'train_int'}, $params{'boon_int'}, $params{'boon_super'}, $params{'ss_int'}, $params{'eq_int'}, $bg, \%guildconfig);
my $stat_wis = &calculateStats('wis', $race, $params{'train_wis'}, $params{'boon_wis'}, $params{'boon_super'}, $params{'ss_wis'}, $params{'eq_wis'}, $bg, \%guildconfig);
my $stat_siz = &calculateStats('siz', $race);


# Calculating the total exp spent on reinc, affected by the number of levels,
# skills and spells and society bonuses
my $spent_on_spells = $race_spells_cost + $g1_spells_cost + $g2_spells_cost +
					   $g3_spells_cost + $g4_spells_cost + $g5_spells_cost;
my $spent_on_skills = $race_skills_cost + $g1_skills_cost + $g2_skills_cost +
					  $g3_skills_cost + $g4_skills_cost + $g5_skills_cost;
my $spent_on_ss		= totalToX($params{'ss_str'}, 'Str', 'human', 'skill', 0, 1) +
					  totalToX($params{'ss_dex'}, 'Dex', 'human', 'skill', 0, 1) +
					  totalToX($params{'ss_con'}, 'Con', 'human', 'skill', 0, 1) +
					  totalToX($params{'ss_int'}, 'Int', 'human', 'skill', 0, 1) +
					  totalToX($params{'ss_wis'}, 'Wis', 'human', 'skill', 0, 1);
my $total_spent		= $exp_on_levels + $spent_on_spells + $spent_on_skills + $spent_on_ss;


# And we verbose them by adding a space each third number
$exp_on_levels		= &verboseLargeNumbers($exp_on_levels);
$exp_saved			= &verboseLargeNumbers($exp_saved);
$spent_on_spells	= &verboseLargeNumbers($spent_on_spells);
$spent_on_skills	= &verboseLargeNumbers($spent_on_skills);
$spent_on_ss		= &verboseLargeNumbers($spent_on_ss);
$total_spent		= &verboseLargeNumbers($total_spent);








#####################################################################
#
# END OF PARAMETER HANDLING, HTML CREATION ETC
#
#####################################################################






#####################################################################
#
# START OF PAGE OUTPUT CONSTRUCTION - HTML
#
#####################################################################



# Creating the whole page outout from here on, mostly using the
# information we created above
my $page_output = <<until_end;
<div id="reincsim-main">

<h1 id="reincsim-title">HCReinc simulator by Tumi, $VERSION</h1>

$point_of_site
$fixlist
$buglist

<br />

<form action="reincsim/hcreincsim.pl" method="post">
<table id="reincsim-bgrace">
<tr><td colspan="4"><h3>Background and guild selection</h3></td></tr>
<tr><td colspan="4">&nbsp;</td></tr>
<tr><td>Your quicklink to this reinc:</td><td>$quicklink</td><td colspan="2">$newreinc</td></tr>
<tr><td>View your reinc as text:</td><td colspan="3">$viewlink</td></tr>
<tr><td colspan="4">&nbsp;</td></tr>
<tr><td>Choose your background:</td> <td colspan="3">$bg_select</td></tr>
<tr><td>Choose your race:</td><td colspan="3">$race_select</td></tr>
<tr><td>Choose your rebirth:</td><td colspan="3">$rebirth_select</td></tr>
<tr><td>Choose your primary guild:</td><td>$g1_select</td> <td>at level:</td><td>$gl1_select</td></tr>
<tr><td>Choose your secondary guild:</td><td>$g2_select</td> <td>at level:</td><td>$gl2_select</td></tr>
<tr><td>Choose your tertiary guild:</td><td>$g3_select</td> <td>at level:</td><td>$gl3_select</td></tr>
<tr><td>Choose your quaternary guild:</td><td>$g4_select</td> <td>at level:</td><td>$gl4_select</td></tr>
<tr><td>Choose your quinary guild:</td><td>$g5_select</td> <td>at level:</td><td>$gl5_select</td></tr>
<tr><td colspan="4">&nbsp;</td></tr>
<tr><td colspan="3">Check this box if you wish to do stat calculations only (faster/lighter):</td><td>$stats_only</td></tr>
<tr><td colspan="4">&nbsp;</td></tr>
<tr><td>Levels taken:</td><td colspan="3" class="reincsim-numbers">$levels_spent</td></tr>
<tr><td>Exp spent on levels:</td><td colspan="3" class="reincsim-numbers">$exp_on_levels xp</td></tr>
<tr><td>Exp saved with quests:</td><td colspan="3" class="reincsim-numbers">$exp_saved xp</td></tr>
<tr><td>Exp spent in skills:</td><td colspan="3" class="reincsim-numbers">$spent_on_skills xp</td></tr>
<tr><td>Exp spent in spells:</td><td colspan="3" class="reincsim-numbers">$spent_on_spells xp</td></tr>
<tr><td>Exp spent in SS:</td><td colspan="3" class="reincsim-numbers">$spent_on_ss xp</td></tr>
<tr><td>Total exp spent in reinc:</td><td class="reincsim-numbers" colspan="3">$total_spent xp</td></tr>
<tr><td colspan="4" class="reincsim-submit">$savereinc $submit</td></tr>
</table>
<br />


<table id="reincsim-stats">
<tr><td colspan="6"><h3>Stats and boons selections</h3></td></tr>
<tr id="reincsim-stat-header"><td>Type</td><td>Power</td><td>SS&nbsp;bonus</td><td>Boon&nbsp;level</td><td>EQ&nbsp;bonus</td></tr>
<tr><td>Skillmax:</td><td class="reincsim-numbers">$stat_skill</td><td>$skillss_select</td><td>$skillboon_select</td><td>&nbsp;</td></tr>
<tr><td>Spellmax:</td><td class="reincsim-numbers">$stat_spell</td><td>$spellss_select</td><td>$spellboon_select</td><td>&nbsp;</td></tr>
<tr><td colspan="6">&nbsp;</td></tr>
<tr><td>Strength:</td><td class="reincsim-numbers">$stat_str</td><td>$strss_select</td><td>$strboon_select</td><td>$streq_select</td></tr>
<tr><td>Dexterity:</td><td class="reincsim-numbers">$stat_dex</td><td>$dexss_select</td><td>$dexboon_select</td><td>$dexeq_select</td></tr>
<tr><td>Constitution:</td><td class="reincsim-numbers">$stat_con</td><td>$conss_select</td><td>$conboon_select</td><td>$coneq_select</td></tr>
<tr><td>Intelligence:</td><td class="reincsim-numbers">$stat_int</td><td>$intss_select</td><td>$intboon_select</td><td>$inteq_select</td></tr>
<tr><td>Wisdom:</td><td class="reincsim-numbers">$stat_wis</td><td>$wisss_select</td><td>$wisboon_select</td><td>$wiseq_select</td></tr>
<tr><td>Size:</td><td class="reincsim-numbers">$stat_siz</td><td colspan="3">SuperChar boon: $superboon_select</td></tr>
<tr><td colspan="6" class="reincsim-submit">$savereinc $submit</td></tr>
</table>
<br />

until_end


if (not defined $params{'stats_only'}) {
	$page_output .= <<until_end;
<table id="reincsim-quests">
<tr><td colspan="3"><h3>Level quest selection</h3></td></tr>
<tr><td colspan="3">&nbsp;</td></tr>
<tr><td colspan="2" align="right">Select all quests:</td><td><select name="quests_all"><option value="0">No</option><option value="1">Yes</option></select></td></tr>
<tr><td colspan="3">&nbsp;</td></tr>
$quests_select
<tr><td colspan="3" class="reincsim-submit">$savereinc $submit</td></tr>
</table>
<br />

until_end
}


# If background is selected, race is selected or one of the guilds is selected,
# we should display that guilds skills and spells information
if (not defined $params{'stats_only'} && (defined $params{'guild1'} || defined $params{'guild2'} ||
		defined $params{'guild3'} || defined $params{'guild4'} || defined $params{'guild5'})) {

	# Adding the guilds one by one (note: lines are around 350+ characters long)
	$page_output .= qq|\n<table class="reincsim-guilds">\n|;
	$page_output .= qq|<tr><td colspan="4"><h3>Skills and spells selections</h3></td></tr>\n|;
	$page_output .= qq|</table>\n|;

	$page_output .= qq|<table class="reincsim-guilds\n">\n<tr><td colspan="2" valign="top">$bg_skills</td><td colspan="2" valign="top">$bg_spells</td></tr>\n<tr><td>Cost of skills:</td><td class="reincsim-numbers">$bg_skills_cost xp</td><td>Cost of spells:</td><td class="reincsim-numbers">$bg_spells_cost xp</td></tr>\n</table>\n| if ($bg ne "none");
	$page_output .= qq|<table class="reincsim-guilds\n">\n<tr><td colspan="2" valign="top">$race_skills</td><td colspan="2" valign="top">$race_spells</td></tr>\n<tr><td>Cost of skills:</td><td class="reincsim-numbers">$race_skills_cost xp</td><td>Cost of spells:</td><td class="reincsim-numbers">$race_spells_cost exp</td></tr>\n</table>\n| if ($race ne "none");
	$page_output .= qq|<table class="reincsim-guilds\n">\n<tr><td colspan="2" valign="top">$g1_skills</td><td colspan="2" valign="top">$g1_spells</td></tr>\n<tr><td>Cost of skills:</td><td class="reincsim-numbers">$g1_skills_cost xp</td><td>Cost of spells:</td><td class="reincsim-numbers">$g1_spells_cost xp</td></tr>\n</table>\n| if (defined $params{'guild1'} && not $params{'guild1'} =~ /^(none|secret_societys)?$/i);
	$page_output .= qq|<table class="reincsim-guilds\n">\n<tr><td colspan="2" valign="top">$g2_skills</td><td colspan="2" valign="top">$g2_spells</td></tr>\n<tr><td>Cost of skills:</td><td class="reincsim-numbers">$g2_skills_cost xp</td><td>Cost of spells:</td><td class="reincsim-numbers">$g2_spells_cost xp</td></tr>\n</table>\n| if (defined $params{'guild2'} && not $params{'guild2'} =~ /^(none|secret_societys)?$/i);
	$page_output .= qq|<table class="reincsim-guilds\n">\n<tr><td colspan="2" valign="top">$g3_skills</td><td colspan="2" valign="top">$g3_spells</td></tr>\n<tr><td>Cost of skills:</td><td class="reincsim-numbers">$g3_skills_cost xp</td><td>Cost of spells:</td><td class="reincsim-numbers">$g3_spells_cost xp</td></tr>\n</table>\n| if (defined $params{'guild3'} && not $params{'guild3'} =~ /^(none|secret_societys)?$/i);
	$page_output .= qq|<table class="reincsim-guilds\n">\n<tr><td colspan="2" valign="top">$g4_skills</td><td colspan="2" valign="top">$g4_spells</td></tr>\n<tr><td>Cost of skills:</td><td class="reincsim-numbers">$g4_skills_cost xp</td><td>Cost of spells:</td><td class="reincsim-numbers">$g4_spells_cost xp</td></tr>\n</table>\n| if (defined $params{'guild4'} && not $params{'guild4'} =~ /^(none|secret_societys)?$/i);
	$page_output .= qq|<table class="reincsim-guilds\n">\n<tr><td colspan="2" valign="top">$g5_skills</td><td colspan="2" valign="top">$g5_spells</td></tr>\n<tr><td>Cost of skills:</td><td class="reincsim-numbers">$g5_skills_cost xp</td><td>Cost of spells:</td><td class="reincsim-numbers">$g5_spells_cost xp</td></tr>\n</table>\n| if (defined $params{'guild5'} && not $params{'guild5'} =~ /^(none|secret_societys)?$/i);
	$page_output .= qq|<table class="reincsim-guilds\n">\n<tr><td colspan="4" class="reincsim-submit">$savereinc $submit</td></tr>\n| if ($params{'guild1'} || $params{'guild2'});
	$page_output .= qq|</table>\n|;
}


# Wrapping the ending together
$page_output .= <<until_end;

$id_string
</form>

</div>

until_end



# Only saving if save is true.
# It is saved by the ID number it had, or was created for it at the
# beginning.
if (defined param('save')) {
	saveParams("saved/$id.db", \%params);
}


# Actually printing the page to STDOUT, displaying the page in browser!
BatmudIndex::pageOutput('item725', $page_output, param('debug'));


# End of runnable code
1;


#####################################################################
#
# END OF PAGE OUTPUT CONSTRUCTION - HTML
#
#####################################################################








#####################################################################
#
# START OF SUBFUNCTIONS
#
#####################################################################





#####################################################################
#
# generateIds - Based on the given id, it creates an alternative id
#               to be used in new reinc, or if new reinc, for its
#               id. Id's are 10 digits long and should be unique.
#
# Params      - Original ID number from param (undef if new reinc)
#
# Returns     - ID and alt_id
#
#####################################################################

sub generateIds {
	my $id = shift;
	my $alt_id  = sprintf "%010d", int(rand(2000000000));
	my $alt_id2 = sprintf "%010d", int(rand(2000000000));

	$alt_id  = sprintf "%010d", int(rand(2000000000)) while (-e "saved/$alt_id.html");
	$alt_id2 = sprintf "%010d", int(rand(2000000000)) while (-e "saved/$alt_id2.html");

	return ($id, $alt_id)
		unless not defined $id;
	return ($alt_id, $alt_id2);
}




#####################################################################
#
# countExpSpentOnLevels - Data is read from a file, with no helping
#                         quests completed. Returns the exp spent
#                         to given level.
#
# Params      - Level
#
# Returns     - Exp
#
#####################################################################

sub countExpSpentOnLevels {
	my $level = shift || 0;
	my $fh = new IO::File "data/levels.txt", "r";
	my $exp = 0;
	my $exp_saved = 0;

	&loadQuests()
		if (scalar keys %questshash < 1);

	return 0
		unless $fh;

	while (my $line = <$fh>) {
		my ($lev, $xp) = split/ /, $line;
		last if ($lev > $level);

		my $saved_all = param('quests_all') && defined $questshash{sprintf("%02d", $lev)};
		my $saved_all2 = param('quests_all') && defined $questshash{sprintf("%02d", $lev)} && defined $questshash{sprintf("%02d_2", $lev)};

		if ($saved_all2 || ($params{"lq$lev"} && $params{"lq$lev"."_2"})) {
			$xp = int($xp/3);
			$exp_saved += (2*$xp);
		} elsif ($saved_all || $params{"lq$lev"}) {
			$xp = int($xp/2);
			$exp_saved += $xp;
		}
		$exp += $xp;
	}

	return ($exp, $exp_saved);
}




#####################################################################
#
# createBgSelect - Generates a select box with previously given
#                  background as default choise
#
# Params      - Previously selected background (from param)
#
# Returns     - HTML with select box
#
#####################################################################

sub createBgSelect {
	my $selected = shift;
	my $selection = qq|\n<select name="bg">\n<option value="">---Choose a bg---</option>\n|;

	for my $bgs (sort keys %bghash) {
		my $insert = $selected eq $bgs ? " selected=\"selected\"" : "";
		my $bgs2 = $bgs;
		$bgs2 =~ tr/_/ /;
		$selection .= "<option value=\"$bgs\"$insert>".ucfirst $bgs2."</option>\n";
	}
	$selection .= "</select>\n";

	return $selection;
}




#####################################################################
#
# createRaceSelect - Generates a select box with previously given
#                    race as default choise
#
# Params      - Previously selected race (from param)
#
# Returns     - HTML with select box
#
#####################################################################

sub createRaceSelect {
	my $selected = shift;
	my $selection = qq|\n<select name="race">\n<option value="">---Choose a race---</option>\n|;

	for my $race (sort @racelist) {
		my $insert = $selected eq $race ? " selected=\"selected\"" : "";
		$selection .= "<option value=\"$race\"$insert>".ucfirst $race."</option>\n";
	}
	$selection .= "</select>\n";

	return $selection;
}




#####################################################################
#
# createGuildSelect - Generates two select boxes with previously given
#                     guild and previously selected level as default
#                     choise, tagged as guild number
#
# Params      - Previously selected background, level, guildnumber
#
# Returns     - 2 pieces of HTML with select boxes
#
#####################################################################

sub createGuildSelect {
	my $selected_guild = shift || 'none';
	my $selected_level = shift || 0;
	my $guildno = shift || 1;

	my $selection		= qq|\n<select name="guild$guildno">\n<option value="">---Choose a guild---</option>\n|;
	my $level_selection	= "\n<select name=\"glevel$guildno\">\n";
	my $one_selected = 0;


	# Gathering all guilds into one
	my @guilds = ();
	for my $bg (sort keys %bghash) {
		for my $guild (@{$bghash{$bg}}) {
			push @guilds, $guild;
		}
	}

	for my $guild (sort @guilds) {
		my $guild_orig = $guild;
		my $insert = $selected_guild eq $guild && $one_selected == 0 ? " selected=\"selected\"" : "";
		$one_selected = 1 if (length $insert > 0);
		$guild_orig =~ tr/_/ /;
		$selection .= "<option value=\"$guild\"$insert>".ucfirst $guild_orig."</option>\n";
	}
	$selection .= "</select>\n";

	for my $level (0..35) {
		my $insert = $selected_level == $level ? " selected=\"selected\"" : "";
		$level_selection .= "<option value=\"$level\"$insert>$level</option>\n";
	}
	$level_selection .= "</select>\n";

	return ($selection, $level_selection);
}




#####################################################################
#
# createRebirthSelect - Generates a select box with previously given
#                       rebirth level as default choise
#
# Params      - Previously selected rebirth level (from param)
#
# Returns     - HTML with select box
#
#####################################################################

sub createRebirthSelect {
	my $selected = shift;
	my $selection = "\n<select name=\"rebirth\">\n";

	for my $rebirthlevel (sort keys %rebirthhash) {
		my $insert = $selected eq $rebirthlevel ? " selected=\"selected\"" : "";
		$selection .= "<option value=\"$rebirthlevel\"$insert>$rebirthhash{$rebirthlevel}</option>\n";
	}
	$selection .= "</select>\n";

	return $selection;
}




#####################################################################
#
# createBoonSelect - Creates a select box filled with five levels
#                    of boon powers, modified to suit the boon
#
# Params      - Boon and previous power
#
# Returns     - HTML with select box
#
#####################################################################

sub createBoonSelect {
	my $stat = shift || 'str';
	my $selected = shift || 0;

	my $insert = $selected == 0 ? " selected=\"selected\"" : "";
	my $output = qq|\n<select name="boon_$stat">\n|;

	my $boon_power = $boonpowerhash{$stat} || 0;
	my %multipliers = (
		"0.00" => "None (0 %)",
		"0.10" => "Tiny/Bane (10 %)",
		"0.20" => "Tiny+Bane/2 Banes (20 %)",
		"0.25" => "Small (25 %)",
		"0.35" => "Small+Bane (35 %)",
		"0.50" => "Medium (50 %)",
		"0.60" => "Medium+Bane (60 %)",
		"1.00" => "Full (100 %)",
	);

	for my $multiplier (sort {$a<=>$b} keys %multipliers) {
		my $level = $multipliers{$multiplier};
		my $this_power = int($boon_power * $multiplier);
		my $insert2 = $selected == $this_power ? " selected=\"selected\"" : "";
		$output .= qq|<option value="$this_power"$insert2>$level</option>\n|;
	}
	$output .= qq|</select>\n|;

	return $output;
}




#####################################################################
#
# createSsSelect - Creates a select box filled with 0-60 of bonus
#
# Params      - Stat and previous power
#
# Returns     - HTML with select box
#
#####################################################################

sub createSsSelect {
	my $stat = shift || 'str';
	my $selected = shift || 0;
	my $output = qq|\n<select name="ss_$stat">\n|;

	for my $power (0..60) {
		my $insert = $selected == $power ? " selected=\"selected\"" : "";
		$output .= qq|<option value="$power"$insert>$power</option>\n|;
	}
	$output .= qq|</select>\n|;

	return $output;
}




#####################################################################
#
# createTrainSelect - Creates a select box filled with 0-60 of bonus
#
# Params      - Stat and previous power
#
# Returns     - HTML with select box
#
#####################################################################

sub createTrainSelect {
	my $stat = shift || 'str';
	my $selected = shift || 0;
	my $output = qq|\n<select name="train_$stat">\n|;
	my $traincost = &calculateTrainCost($race, $stat, $selected);

	for my $power (0..60) {
		my $insert = $selected == $power ? " selected=\"selected\"" : "";
		$output .= qq|<option value="$power"$insert>$power</option>\n|;
	}
	$output .= qq|</select>\n|;

	return ($output, $traincost);
}




#####################################################################
#
# createEqSelect - Creates an input box for eq bonuses
#
# Params      - Stat and previous power
#
# Returns     - HTML with select box
#
#####################################################################

sub createEqSelect {
	my $stat = shift || 'str';
	my $selected = shift || 0;
	my $output = qq|<input class="eqstat" type="text" size="4" maxlength="3" name="eq_$stat" value="$selected" />|;

	return $output;
}




#####################################################################
#
# createQuests - Creates three wide table with levels quests
#                and their select boxes
#
# Params      - None
#
# Returns     - HTML with table
#
#####################################################################

sub createQuests {
	my $quests_select = "";

	&loadQuests()
		if (scalar keys %questshash < 1);


	my $cntr = 0;
	for my $level (sort {$a cmp $b} keys %questshash) {
		next unless (defined $questshash{$level});

		$quests_select .= qq|<tr>\n|
			if ($cntr % 3 == 0);

		$level =~ /^0?(\d+)/;
		my $selected = param('quests_all') ? " checked=\"checked\"" :
			((scalar (&param) <= 2 && $params{"lq$level"}) || param("lq$level") ? " checked=\"checked\"" : "");
		$quests_select .= qq|<td><input type="checkbox" name="lq$level"$selected />LQ $1: $questshash{$level}</td>\n|;

		$quests_select .= qq|</tr>\n|
			if (++$cntr % 3 == 0);
	}

	# If count isn't a match, create couple empty cells
	my $empty_cells = $cntr % 3 != 0 ? "<td>&nbsp;</td>" x ($cntr%3) : "";
	my $endtag = $cntr % 3 != 0 ? "</tr>\n" : "";

	return $quests_select.$empty_cells.$endtag;
}




#####################################################################
#
# createTalents - Generates a list of talents of given guild available
#                 at given level, returns them after they're formatted
#
# Params      - Guild, guild level, background, type, bgtalent
#
# Returns     - HTML with skillname, bgbonus+select box, max, expcost
#
#####################################################################

sub createTalents {
	my $guild = shift || 'none';
	my $level = shift || 0;
	my $bg = shift || 'civilized';
	my $type = shift || 'skill';
	my $bgtalents = shift || 0;
	my @array = ();
	my $guildcost = 0;


	# We look for the guild maxes and level advancement requirements
	# to the level were supposed to go. Also searching background for
	# bonuses to the skills/spells.
	my ($maxskills, $maxspells, $min) = lookForGuildMax($guild, $level);
	my ($bg_skills, $bg_spells, $bgmin) = lookForGuildMax($bg, 10);
	my ($maxref, $bgref, $talentmax);

	# Fixing the references according to type
	if ($type eq "skill") {
		$maxref = $maxskills;
		$bgref = $bg_skills;
		$talentmax = $stat_skill;
	} else {
		$maxref = $maxspells;
		$bgref = $bg_spells;
		$talentmax = $stat_spell;
	}

	# Lets loop the skills/spells we found from the guild
	for my $talent (sort keys %$maxref) {
		my $orig_talent = $talent;
		$talent =~ tr/ A-Z/_a-z/;

		# Bg skill/spell bonuses
		my $bgtalent = $bgref->{$orig_talent} || 0;
		my $bgaddon = ($bgtalent > 0 && $bgtalents == 0 ? "$bgtalent+" : "");

		# Beginning the selection, including the bgbonus and deciding the min/max
		my $selection = "\n$bgaddon<select name=\"$type\_$talent\">\n";
		my $talent_arcane = isTalentArcane($talent);
		my $previous_level = $params{$type."_".$talent} || 0;
		my $required = $min->{$orig_talent} || 0;
		my $temp_max = $maxref->{$orig_talent} || 100;
		my $maximum  = $talent_arcane ? $temp_max : ($temp_max < $talentmax ? $temp_max : $talentmax);

		# If maxallguild is defined, skill is trained to maximum.
		# If not, it is preset to previously ordered percentage, or if not present,
		# then requirement, if present. 0 if not.
		my $pre = param($type."s_maxall_$guild") ? $maximum : $previous_level || $required;
		my @loop_range = (grep({$_ != $pre} $required..$maximum), $pre);

		#print STDERR "guild= $guild  prev= $previous_level  arc= $talent_arcane  req= $required ",
		#		"temp= $temp_max  max= $maximum  pre= $pre\n"
		#	if ($talent eq "cast_generic");


		# Inserting every fifth percent into select, and max, min, and current
		for my $perc (sort {$a<=>$b} @loop_range) {
			my $insert = $pre == $perc ? " selected=\"selected\"" : "";
			$selection .= "<option value=\"$perc\"$insert>$perc %</option>\n"
				if ($perc % 5 == 0 || $perc == $pre || $perc == $maximum || $perc == $required);
		}
		$selection .= "</select>\n";
		$selection = $bgtalents ? $temp_max : $selection;

		# If skill does not have a cost at all in costhash,
		# it will be added there after figuring out the cost
		my $cost = totalToX($pre, $orig_talent, $race, $type);
		if (not defined $totalcost{$orig_talent}) {
			$cost = $bgtalents ? 0 : ($maximum < $pre ?
				totalToX($maximum, $orig_talent, $race, $type) :
				totalToX($pre, $orig_talent, $race, $type));
			$guildcost += $cost;
			$totalcost{$orig_talent} = $cost;

		# If it already is in the hash, if lower cost => lower percentage trained before
		# => this cost = totalcost - previous_cost
		} elsif ($totalcost{$orig_talent} < $cost) {
			$cost = $bgtalents ? 0 : $cost;
			$guildcost += $bgtalents ? 0 : $cost - $totalcost{$orig_talent};
			$totalcost{$orig_talent} = $cost;

		# Cost is smaller than the one in hash, no need to train at all in this guild
		} else {
			$cost = 0;
		}

		# Pushing information into array, and arrayref into another array
		my @temp = ($orig_talent, $selection, $bgtalents ? $temp_max : $maximum, $cost);
		push @array, \@temp;
	}

	# Calling formatting for the stuff we just calculated and returning it
	return (formatSkillsSpellsOutput($guild, $type."s", $bgtalents, @array), $guildcost);
}




#####################################################################
#
# formatSkillsSpellsOutput - Formats the given data
#
# Params      - Guild, skill/spell, bgskills, array
#               array = (skillname, select, max, cost)
#
# Returns     - HTML with big div with skills/spell etc
#
#####################################################################

sub formatSkillsSpellsOutput {
	my $guild = ucfirst shift || 'error';
	my $type = ucfirst shift || 'errors';
	my $bgs = shift || 0;
	my @array = @_;
	my $output = "";
	my $type2 = lc $type;
	my $guild2 = lc $guild;

	return $output
		if ($guild eq "Error" || $guild eq 'none' || $type eq "Errors");

	$output .= qq|\n<table class="reincsim-guild">\n|;
	$output .= qq|<tr><td colspan="4"><h3>$guild $type</h3></td></tr>\n|;
	$output .= qq|<tr><td colspan="4">Max all $type in this guild? <select name="$type2\_maxall_$guild2"><option value="0">No</option><option value="1">Yes</option></select></td></tr>\n| unless $bgs;
	$output .= qq|<tr class="reincsim-guild-header"><td>$type</td><td>Choose</td><td>Max</td><td>Expcost</td></tr>\n|;


	for my $spec (@array) {
		my ($talent, $select, $max, $exp) = @$spec;
		$exp = &verboseLargeNumbers($exp);
		$output .= qq|<tr><td>$talent</td><td align="right">$select</td><td>/&nbsp;$max%</td><td class="reincsim-numbers">$exp&nbsp;xp</td></tr>\n|;
	}
	$output .= qq|</table>\n|;

	return $output;
}




#####################################################################
#
# percentX - Calculates what a single percent of some skill/spell
#            might cost, without modifying it with skill/spellcosts
#
# Params      - Target percent, skill/spell basecost
#
# Returns     - How much that percent might cost
#
#####################################################################

sub percentX {
	my $tgt = shift;
	my $skillbase = shift;
	my $talent = shift || 'word of recall';
	my $type = shift || 'skill';
	my $cost_modifier = 1.087 + ($tgt-1)/30000.0;
	my $impro_modif = 1.05;

	my $talent2 = $talent;
	$talent2 =~ tr/A-Z /a-z_/;

	$impro_modif = $tgt > 90 ? 1.25 : 1.05 if (USENEW);
	$skillbase = (isTalentArcane($talent2) ? $skillbase :
		($tgt > ($type eq "skill" ? $stat_skill : $stat_spell) ?
		$skillbase * 2 : $skillbase)) if (USENEW);

	return ($cost_modifier ** ($tgt-1)) * $skillbase * $impro_modif;
}




#####################################################################
#
# firstPercent - Calculates skills basecost from the cost/percent
#                pair
#
# Params      - Percent and how much it costed
#
# Returns     - How much would basecost for that skill be
#
#####################################################################

sub firstPercent {
	my $from = shift || 100;
	my $prev_cost = shift || 10000;
	return 0
		if ($prev_cost =~ m|n/a| || $prev_cost >= 229999);

	$prev_cost /= (1.0935) while ($from-- > 1);

	return int($prev_cost);
}




#####################################################################
#
# totalToX - Calculates how much exp will it cost to train skill/spell
#            from 0 to target, modified by maxcosts and skill/spellcosts
#
# Params      - Percent, skill/spell, race, type, nomaxcost, ssmax
#
# Returns     - How much it costs
#
#####################################################################

sub totalToX {
	my $tgt_percent = shift || 0;
	my $skillspell = shift || 'word of recall';
	my $race = shift || 'human';
	my $type = shift || 'skill';
	my $nomax = shift || 0;
	my $ss_max = shift || 0;
	my $talentcost = &getTalentCost($race, $type) || 100;
	my $basecost = &getBaseCost(lc $skillspell) || 0;

	my $totalcost = 0;

	for my $percent (1..$tgt_percent) {
		$totalcost += int(modifyCost(percentX($percent, $basecost, $skillspell, $type), $talentcost, $nomax, $ss_max));
	}

	return $totalcost;
}




#####################################################################
#
# modifyCost - Modifies the cost by limiting the maximum cost,
#              skill/spellcosts etc
#
# Params      - Cost, race's skill/spellcost, nomax, ssmax
#
# Returns     - Limited/modified cost
#
#####################################################################

sub modifyCost {
	my $cost = shift;
	my $skillcost = shift || 100;
	my $no_max_cost = shift || 0;
	my $ss_limit = shift || 0;
	my $totalcost = int($cost * ($skillcost ne "?" ? $skillcost : 100) / 100);

	$totalcost = $totalcost > 2000000 ? 2000000 : $totalcost
		if ($ss_limit);

	return $totalcost if (USENEW); # No max for cost anymore
	return $totalcost > 229999 ? 229999 : $totalcost;
}




#####################################################################
#
# lookForGuildMax - Looks through lynx -dumped information about
#                   guilds from bat.org, returns three hashrefs,
#                   maxskills, maxspells, and level requirements
#
# Params      - Guild and target level
#
# Returns     - Refs for maxskills, maxspells and requirements
#
#####################################################################

sub lookForGuildMax {
	my $guild = shift || 'foo';
	my $level = shift || 50;
	my ($fix_skills, $fix_spells) = (100, 100);
	my $current_level = 1;

	# If guild not found, quit
	my $fh = new IO::File "data/guilds/$guild.txt", "r";
	return ()
		unless $fh;

	# Init some hashes for our results
	my %maxskills = ();
	my %maxspells = ();
	my %minhash = ();

	# Lets loop through the file
	while (my $line = <$fh>) {
		# If line is FIX num num, those numbers are used to fix the
		# information (tigers/spiders are hidden guilds and do not
		# have webpages (which have correct information)
		($fix_skills, $fix_spells) = ($1, $2)
			if ($line =~ /^FIX (\d+) (\d+)$/);

		# If line reads Level something, we capture it and if the level
		# is higher than our target level, we're done!
		if ($line =~ /^\s+Level (\d+):?/) {
			$current_level = $1;
			last if ($1 > $level);
		}

		# If matches may train to xxx %, do math
		if ($line =~ /^\s+(May train|Gains) skill (\[.*\])?(.*) to (\d+)%/i) {
			$maxskills{$3} = ceil($4*100/$fix_skills); next;
		}

		# If matches may study to xxx %, do math
		if ($line =~ /^\s+(May study|Gains) spell (\[.*\])?(.*) to (\d+)%/i) {
			$maxspells{$3} = ceil($4*100/$fix_spells); next;
		}

		# If matches may train to racial maximum (which is old style), automate as 100%
		if ($line =~ /^\s+May train skill \[.*\](.*) to racial maximum/i) {
			$maxskills{$1} = 100; next;
		}

		# If matches may study to racial maximum (which is old style), automate as 100%
		if ($line =~ /^\s+May study spell \[.*\](.*) to racial maximum/i) {
			$maxspells{$1} = 100; next;
		}

		# If matches requirements string, put into requhash
		if ($line =~ /^\s+Has (trained skill|studied spell) (\[.*\])?(.*) to at least (\d+)%/i) {
			if ($1 eq "studied spell") {
				$minhash{$3} = ceil($4*100/$fix_spells);
			} else {
				$minhash{$3} = ceil($4*100/$fix_skills);
			}
			next;
		}
	}

	# Return references
	return (\%maxskills, \%maxspells, \%minhash);
}




#####################################################################
#
# guildMaxLevel - Looks through guild info file and returns the
#                 max level guild has.
#
# Params      - Guild, given_level and if should return max or min
#
# Returns     - Realmax
#
#####################################################################

sub guildMaxLevel {
	my $guild = shift || 'foo';
	my $given_level = shift || 0;
	my $maxmax = shift || 0;
	my $level = 0;
	my $fh = new IO::File "data/guilds/$guild.txt", "r";

	return 0
		unless $fh;

	while (my $line = <$fh>) {
		$level = $2
			if ($line =~ /^(\s{32,}|\s)Level (\d+):?/);
	}

	return $level
		if ($maxmax);
	return $level < $given_level ? $level : $given_level;
}




#####################################################################
#
# findSkillBaseCosts - Generates basecost files from data in
#                      data/people/. Invoked with param 'baseupdate=1'
#
# Params      - None
#
# Returns     - None
#
#####################################################################

sub findSkillBaseCosts {
	my $fhskills = new IO::File "data/hcskill_basecosts_new.txt", "w";
	my $fhspells = new IO::File "data/hcspell_basecosts_new.txt", "w";

	# If racial information hash is empty, load it up
	&loadRacialInformationIntoHash()
		if (scalar keys %racial_information < 1);

	# If we already have loaded basecosthash, do nothing
	return
		if (scalar keys %basecosthash > 0);


	# Lets find out all the files there is
	my @lines = `ls data/people/`;
	my @files = ();
	my %skillhash = ();
	my %spellhash = ();


	# Wrapping the files into single array
	for my $line (@lines) {
		my @temp = split/\s+/, $line;
		push @files, @temp;
	}

	# Going through the files
	for my $file (sort @files) {
		my $fh = new IO::File "data/people/$file", "r";
		my ($guild, $race) = $file =~ m#([a-z]+)_([a-z]+)\d+\.txt#;
		my $dataref = \%skillhash;
		my $modif = 100;

		# Going through the lines in this file
		while (my $line = <$fh>) {
			# Reading the information in this line (if matches)
			my ($talent, $level, $maxlevel, $cost) =
				$line =~ m#^\| (.*?)\s*\|\s+(\d+) \|\s+(\d+) \|\s+(\d+)#;

			# Which stuff were dealing with
			if ($line =~ /(Skills|Spells) available at level/) {
				my @info = getRaceInfo($race);
				$dataref = $1 eq "Skills" ? \%skillhash : \%spellhash;
				$modif = $1 eq "Skills" ? $info[2] : $info[3];
				$modif = $modif eq "?" ? 100 : $modif;
			}

			# Go forward if line is corrupt or wrong
			next unless ($talent && $maxlevel && $cost);
			$talent = sprintf("%-36s", $talent);

			# If skill isn't trained at all, its basecost is only modified
			# with the racial skillcost it was taken with
			if ($level == 0) {
				$dataref->{$talent} = modifyCost($cost, int(100/$modif*100));

			# Or calculated with firstPercent, then modified and then stored
			} elsif (not defined $dataref->{$talent} || (defined $dataref->{$talent} && $dataref->{$talent} < 1)) {
				$dataref->{$talent} = modifyCost(firstPercent($level, $cost), int(100/$modif*100));
			}
		}
		undef $fh;
	}

	# Printing information into file
	for my $skill (sort keys %skillhash) {
		print $fhskills "$skill $skillhash{$skill}\n";
	}

	for my $spell (sort keys %spellhash) {
		print $fhspells "$spell $spellhash{$spell}\n";
	}
}




#####################################################################
#
# loadRacialInformationIntoHash - Loads racial information into hash
#
# Params      - None
#
# Returns     - None
#
#####################################################################

sub loadRacialInformationIntoHash {
	my $file = new IO::File "../raceinfo/raceinfo.txt", "r";
	die "Filehandle is broken, raceinfo data not found.\n"
		unless ($file);

	my $counter = 0;
	my @lines = <$file>;
	foreach my $line (@lines) {
		next if ($line =~ m/^;/);

		my @raceinfo = split/\s+/, $line;
		$racial_information{lc $raceinfo[0]} = [ @raceinfo ];
	}
}




#####################################################################
#
# loadBaseCostsIntoHash - Loads basecosts into hash
#
# Params      - None
#
# Returns     - None
#
#####################################################################

sub loadBaseCostsIntoHash {
	my $file1 = new IO::File "data/spell_basecosts.txt", "r";
	my $file2 = new IO::File "data/skill_basecosts.txt", "r";
	die "Filehandle is broken, raceinfo data not found.\n"
		unless ($file1 && $file2);

	my @lines1 = <$file1>;
	my @lines2 = <$file2>;
	foreach my $line (@lines1, @lines2) {
		my @costinfo = split/\s{2,}/, $line;
		$basecosthash{lc $costinfo[0]} = $costinfo[1];
	}

	# We'll insert stat costs too
	$basecosthash{"str"} = 67250;
	$basecosthash{"dex"} = 34500;
	$basecosthash{"con"} = 67250;
	$basecosthash{"int"} = 34500;
	$basecosthash{"wis"} = 34500;
}




#####################################################################
#
# getRaceInfo - Returning asked information about race
#
# Params      - Race
#
# Returns     - Race information array
#
#####################################################################

sub getRaceInfo {
	my $race = shift || 'human';

	&loadRacialInformationIntoHash()
		if (scalar keys %racial_information < 1);

	return @{$racial_information{$race}};
}




#####################################################################
#
# getTalentCost - Returns race's skill/spellcost
#
# Params      - Race, type
#
# Returns     - Modifier (100 based, e.g. 141)
#
#####################################################################

sub getTalentCost {
	my $race = shift || 'human';
	my $type = shift || 'skill';

	&loadRacialInformationIntoHash()
		if (scalar keys %racial_information < 1);

	if ($type eq "skill") {
		return @{$racial_information{lc$race}}[2];
	}
	return @{$racial_information{lc$race}}[3];
}




#####################################################################
#
# getBaseCost - Returns skills/spells base cost or 0 if broken
#
# Params      - Skill/Spell
#
# Returns     - Basecost
#
#####################################################################

sub getBaseCost {
	my $talent = shift || 'word of recall';

	&loadBaseCostsIntoHash()
		if (scalar keys %basecosthash < 1);

	return $basecosthash{lc $talent};
}




#####################################################################
#
# calculateStats - Calculating the total stats
#
# Params      - Stat, race, boon, super, ss, bg, guildhash
#
# Returns     - Stat value
#
#####################################################################

sub calculateStats {
	my $stat = shift || 'str';
	my $race = shift || 'human';
	my $trainbonus = shift || 0;
	my $boonbonus = shift || 0;
	my $superboon = shift || 0;
	my $ssbonus = shift || 0;
	my $eqbonus = shift || 0;
	my $bg = shift || 'civilized';
	my $gref = shift;

	my $raceguildbonushash = $bonuses{$race};
	my $raceguildbonus = $raceguildbonushash->{$stat} || 0;

	# Getting racial information
	my @info = &getRaceInfo($race);

	# Size is size, not depending on anything
	return $info[12]
		if ($stat eq "siz");

	# Calculating the stat
	my $total = $info[$infoindexhash{$stat}] + $trainbonus +
		$boonbonus + $superboon + $ssbonus + $raceguildbonus + $eqbonus;

	# Going thought guild levels and giving bonuses from guilds,
	# modified to suit the level/total level ratio of course
	for my $guild (sort keys %$gref) {
		my $bonref = $bonuses{$guild};
		my $gbonus = $bonref->{$stat} || 0;
		my $glevel = $gref->{$guild} || 0;
		my $gmax = guildMaxLevel($guild, $glevel, 1) || 30;

		$total += int($gbonus * $glevel / $gmax);
	}

	return $total;
}




#####################################################################
#
# calculateTrainCost - Calculate cost in training points
#
# Params      - Race, stat, target
#
# Returns     - Cost in training points
#
#####################################################################

sub calculateTrainCost {
	my $race = shift || 'human';
	my $stat = shift || 'con';
	my $number = shift || 0;

	# Getting racial information
	my @info = &getRaceInfo($race);

	return ($number * 12); # BROKEN
}




#####################################################################
#
# calculateTalentMax - Calculate skill/spellmaxes
#
# Params      - Type, race, boon, ss
#
# Returns     - Max
#
#####################################################################

sub calculateTalentMax {
	my $type = shift || 'skill';
	my $race = shift || 'human';
	my $boonbonus = shift || 0;
	my $ssbonus = shift || 0;

	# Getting racial information
	my @info = &getRaceInfo($race);

	return 100
		if ($info[$infoindexhash{$type."max"}] =~ /\?/);

	my $total = $info[$infoindexhash{$type."max"}] + $boonbonus + $ssbonus;

	return $total > 100 ? 100 : $total;
}




#####################################################################
#
# verboseLargeNumbers - Adding space as every third char for readability
#
# Params      - Number
#
# Returns     - Verbosed number
#
#####################################################################

sub verboseLargeNumbers {
	my $number = shift || 0;
	my @elements = split//, $number;
	my @new_string = ();

	my $cntr = 0;
	for my $element (reverse @elements) {
		unshift @new_string, "&nbsp;"
			if ($cntr++ % 3 == 0);
		unshift @new_string, $element;
	}

	return join("", @new_string);
}




#####################################################################
#
# loadParams - Loads parameters from the file and inserts them into
#              a params hash
#
# Params      - Id based filename
#
# Returns     - Hash, containing the file contents
#
#####################################################################

sub loadParams {
	my $file = shift || 'foo.txt';
	my %parhash = ();

	return ()
		unless (-e $file);

	my $handle = new IO::File $file, "r";
	while (my $line = <$handle>) {
		$line =~ tr/\x0D\x0A//d;
		next unless ($line =~ /^(\w+): (\w+)$/);
		$parhash{$1} = $2;
	}

	return %parhash;
}




#####################################################################
#
# saveParams - Saves parameters to the file from the params hash
#
# Params      - Params ref
#
# Returns     - 1
#
#####################################################################

sub saveParams {
	my $file = shift || 'foo.txt';
	my $paramshref = shift;

	return unless $paramshref;

	my $handle = new IO::File $file, "w";
	for my $key (sort keys %$paramshref) {
		next unless (defined $paramshref->{$key});
		print $handle "$key: ", $paramshref->{$key}, "\n";
	}

	1;
}




#####################################################################
#
# isTalentArcane - Check if talent given is arcane
#
# Params      - Talent
#
# Returns     - 1 if arcane, 0 if not
#
#####################################################################

sub isTalentArcane {
	my $talent = shift || 'word_of_recall';

	unless (scalar @arcanetalents > 0) {
		my $handle = new IO::File "data/arcane_skills.txt", "r";
		while (my $line = <$handle>) {
			$line =~ tr/\x0A\x0D//d;
			push @arcanetalents, $line;
		}
	}

	for my $regex (sort @arcanetalents) {
		return 1
			if ($talent =~ m#$regex#i);
	}

	return 0;
}




#####################################################################
#
# loadQuests - Loads quests from file into hash
#
# Params      - None
#
# Returns     - None
#
#####################################################################

sub loadQuests {
	my $handle = new IO::File "data/quests.txt", "r";

	return
		unless ($handle);

	while (my $line = <$handle>) {
		$line =~ tr/\x0A\x0D//d;
		last if ($line =~ /^References/);

		if ($line =~ /^\s+Level (\d+):\s+\[\d+\]([a-zA-Z0-9 \.\'\-]+)\s+\[\d+\]([a-zA-Z0-9 \-\.\']+)\s*/) {
			$questshash{sprintf("%02d", $1)} = $2;
			$questshash{sprintf("%02d_2", $1)} = $3;

		} elsif ($line =~ /^\s+Level (\d+):\s+\[\d+\]([a-zA-Z0-9 \'\.\-]+)\s*/) {
			$questshash{sprintf("%02d", $1)} = $2;
			$questshash{sprintf("%02d", $1)} =~ s/\s+/ /g;
		}
	}

	# Some hidden quests
	$questshash{"12"} = "Mail";
}







#####################################################################
#
# END OF SUBFUNCTIONS
#
#####################################################################







__END__

This is regular text, not showing up anywhere


 - chanconjnav
perl -w reincsim.pl id=0000000001 bg=magical race=duck guild1=channellers guild2=conjurers glevel1=30 glevel2=16 $params{'guild3'}=navigators glevel3=3 skill_quick_chant=75 skill_flow_of_magic=95 skill_mastery_of_draining=75 skill_mastery_of_channelling=75 skill_cast_generic=85 skill_cast_channelling=90 skill_analysis_of_magic_lore=60 skill_damage_criticality=30 skill_mana_control=85 skill_essence_eye=90 skill_cast_teleportation=80 spell_channelball=95 spell_channelbolt=90 spell_channelburn=85 spell_energy_aura=85 spell_feather_weight=60 skill_mastery_of_shielding=44 skill_cast_protection=80 spell_force_absorption=80 skill_ceremony=70 skill_cast_information=75 skill_cast_heal=75 skill_cast_control=75 skill_cast_help=75 skill_cast_magical=75 skill_cast_fire=75 skill_cast_electricity=75 spell_restore=60 spell_neutralize_field=52 spell_invisibility=60 spell_identify=70 spell_heal_self=70 spell_aura_detection=80 spell_relocate=60 spell_summon=60 spell_teleport_without_error=60 spell_teleport_with_error=60 spell_go=60 spell_word_of_recall=75 spell_mobile_cannon=60 spell_dimension_door=60 spell_banish=60 skill_mastery_of_locating=60 skill_location_memory=60 spell_replenish_ally=80 spell_drain_ally=70 spell_drain_enemy=80 spell_drain_room=80 spell_channelspray=80 spell_floating_disc=80 spell_infravision=60 spell_see_invisible=60 spell_see_magic=60 spell_shelter=75 spell_floating=60 spell_water_walking=60 skill_cast_transformation=75 spell_wizard_eye=60 spell_light=60 spell_darkness=60 spell_greater_light=50 spell_greater_darkness=50 spell_create_herb=50 skill_consider=80 boon_int=60 boon_wis=60 boon_super=12 lq50=1 lq55=1 lq60=1 >../foo.html

 - tarmnavss
perl -w reincsim2.pl id=0000000002 bg=good_religious race=elf guild1=tarmalens guild2=navigators $params{'guild3'}=secret_societys glevel1=30 glevel2=3 glevel3=7 boon_wis=60 boon_int=60 boon_super=12 boon_con=20 ss_wis=27 skill_bless=80 skill_cast_generic=85 skill_cast_heal=100 skill_cast_help=80 skill_cast_special=80 skill_cast_teleportation=80 skill_ceremony=75 skill_essence_eye=85 skill_first_aid=70 skill_mana_control=85 skill_mastery_of_assistance=100 skill_mastery_of_medicine=100 skill_quick_chant=100 skill_tempt=50 spell_blessing_of_tarmalen=80 spell_cure_critical_wounds=85 spell_cure_serious_wounds=80 spell_cure_light_wounds=85 spell_cure_player=60 spell_curse_of_tarmalen=60 spell_deaths_door=90 spell_guardian_angel=60 spell_heal_all=60 spell_holy_way=60 spell_lessen_poison=60 spell_life_link=75 spell_light=60 spell_major_heal=90 spell_minor_heal=90 spell_true_heal=90 spell_minor_party_heal=95 spell_major_party_heal=90 spell_true_party_heal=90 spell_new_body=75 spell_raise_dead=90 spell_resurrect=90 spell_satiate_person=75 spell_sex_change=60 spell_see_the_light=60 spell_unstun=90 spell_unpain=90 spell_water_walking=75 spell_word_of_recall=75 spell_summon=80 spell_relocate=60 spell_dimension_door=60 spell_teleport_with_error=60 spell_teleport_without_error=60 spell_banish=60 spell_go=60 spell_mobile_cannon=60 spell_heavy_weight=60 skill_mastery_of_locating=60 skill_location_memory=60 spell_restore=80 spell_natural_renewal=80 spell_remove_scar=90 spell_wizard_eye=60 skill_stargazing=60 >../foo.html

 - spiderpriestnav
perl -w reincsim.pl id=0000000003 bg=evil_religious race=ent guild1=spiders guild2=priests $params{'guild3'}=navigators glevel1=30 glevel2=13 glevel3=3 boon_str=40 boon_con=40 boon_dex=60 boon_super=12 boon_wis=60 skill_alertness=40 skill_attack=75 skill_cast_generic=90 skill_cast_harm=85 skill_cast_demonology=85 skill_cast_heal=60 skill_cast_information=60 skill_cast_poison=75 skill_cast_protection=60 skill_cast_teleportation=60 skill_cast_transformation=60 skill_ceremony=85 skill_combat_sense=60 skill_consider=90 skill_discipline=60 skill_dodge=60 skill_parry=60 skill_essence_eye=90 skill_first_aid=60 skill_hiding=60 skill_knowledge_of_infernal_entities=90 skill_knowledge_of_toxicology=95 skill_mana_control=85 skill_mastery_of_spider_servants=75 skill_negate_offhand_penalty=90 skill_pierce=80 skill_quick_chant=100 skill_short_blades=95 skill_stab=90 skill_stunned_maneuvers=60 skill_tempt=60 skill_throw_weight=50 spell_heavy_weight=60 spell_hunger_of_the_spider=80 spell_infravision=60 spell_poison=60 spell_poison_cloud=60 spell_prayer_to_the_spider_queen=50 spell_remove_poison=75 spell_spider_demon_banishment=92 spell_spider_demon_channelling=80 spell_spider_demon_conjuration=80 spell_spider_demon_control=85 spell_spider_demon_inquiry=75 spell_spider_demon_mass_sacrifice=50 spell_spider_eye=60 spell_spider_gaze=60 spell_spider_gate=60 spell_spider_servant=70 spell_spider_touch=75 spell_spider_walk=60 spell_spider_web=60 spell_spider_wrath=92 spell_toxic_dilution=75 spell_venom_blade=75 skill_baptize=50 skill_cardiac_stimulation=35 skill_cast_magical=60 skill_cast_special=75 skill_conceal_spellcasting=16 skill_dark_meditation=16 skill_desecrate_ground=19 skill_evil_intent=28 spell_aura_of_hate=80 spell_cause_light_wounds=65 spell_cause_critical_wounds=90 spell_cure_light_wounds=85 spell_cure_serious_wounds=80 spell_damn_armament=75 spell_hemorrhage=66 spell_last_rites=60 spell_mellon_collie=75 spell_raise_dead=55 skill_location_memory=60 skill_mastery_of_locating=60 spell_banish=60 spell_dimension_door=60 spell_go=60 spell_mobile_cannon=60 spell_relocate=60 spell_summon=60 spell_teleport_with_error=60 spell_teleport_without_error=60 spell_wizard_eye=60 spell_word_of_recall=60 >../foo.html

 - priestspider
perl -w reincsim.pl id=0000000004 bg=evil_religious race=duck guild1=priests guild2=spiders $params{'guild3'}=navigators glevel1=35 glevel2=15 glevel3=2 boon_wis=60 boon_int=60 boon_super=12 skills_maxall_priests=1 skills_maxall_spiders=1 spells_maxall_priests=1 spells_maxall_spiders=1 skills_maxall_duck=1 spells_maxall_duck=1 skills_maxall_navigators=1 spells_maxall_navigators=1 >../foo.html

 - bard
perl -w reincsim.pl id=0000000005 debug=1 save=1 bg=civilized race=leech guild1=bards guild2=navigators guild3=runemages guild4=secret_societys glevel1=30 glevel2=3 glevel3=2 glevel4=5 boon_int=60 boon_wis=60 boon_dex=60 boon_super=12 boon_spell=16 ss_dex=20 lq02=1 lq04=1 lq05=1 lq07=1 lq08=1 lq08_2=1 lq09=1 lq11=1 lq12=1 lq16=1 lq17=1 lq17_2=1 lq18=1 lq19=1 lq20=1 lq21=1 lq22=1 lq23=1 lq24=1 lq25=1 lq25_2=1 lq27=1 lq28=1 lq29=1 lq31=1 lq35=1 lq38=1 lq40=1 lq41=1 lq49=1 lq50=1 lq51=1 lq52=1 lq55=1 lq60=1 lq65=1 spells_maxall_navigators=1 skills_maxall_navigators=1 skills_maxall_runemages=1 skill_alcohol_tolerance=50 skill_dodge=30 skill_hiking=60 skill_plant_lore=60 skill_quick_chant=1 skill_songcasting=80 skill_songmastery=100 skill_swim=70 spell_achromatic_eyes=50 spell_campfire_tune=88 spell_clandestine_thoughts=50 spell_con_fioco=88 spell_jesters_trivia=70 spell_kings_feast=70 spell_melodical_embracement=70 spell_musicians_alm=30 spell_noituloves_deathlore=80 spell_noituloves_dischord=50 spell_pathfinder=60 spell_soothing_sounds=60 spell_sounds_of_silence=50 spell_strength_in_unity=75 spell_sweet_lullaby=75 spell_venturers_way=75 spell_vigilant_melody=50 spell_war_ensemble=88 skill_mana_control=70 >../foo.html
