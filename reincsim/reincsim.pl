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
use IO::File;
use CGI qw/param/;
use POSIX qw/ceil floor/;

# my stuff
# use lib '/home/twomi/web/libs';
use lib '/home/customers/tumi/public_html/archives/batmud';
use lib '/home/customers/tumi/tumilib';
use Tumi::Helper;
use BatmudTools::Layout;
use BatmudTools::Site;
use BatmudTools::Login;


# Current version number
my $VERSION = "1.9.0.3";
my $SCRIPT = __FILE__;



#####################################################################
#
# START OF VARIABLE INITIALIZATION, INFORMATION INITIALIZATION
#
#####################################################################


# Debug
my $html_debug = "";


# Fetching the contents
my $point_of_site = readFile('html/pointofsite.html');
my $fixlist = readFile('html/fixlist.html');
my $buglist = readFile('html/buglist.html');


# Hiding changes etc if variable set
($point_of_site, $fixlist, $buglist) = ("", "", "") if ((param('hide_changes') || "") eq "yes");

# Guild levels hash
my %guildlevelshash = ();

# Racial information contains the race information once it has been loaded up
my %racial_information = ();

# Basecost has contains the skills and spells basecosts once they're loaded up
my %basecosthash = ();
my %societycosthash = ();
my %abilitieshash = ();

# Totalcost hash contains the totalcosts of skills and spells part of the reinc
# It keeps track of which skills has been calculated etc
my %totalcost = ();
my %totalcostcache = ();


# Arcane talent array contains regexs of skills that are arcane, ie 100 max
# And another array for those that need to be excluded explicitly
my @arcane_skills = ();
my @non_arcane_skills = ();
my %arcanehash = ();


# Quest hash
my %lq_hash = ();
my %aq_hash = ();

# How fast does the cost change
my (%ratios_skills1, %ratios_skills2, %ratios_spells1, %ratios_spells2, %ratios_arcane);

# Special features helping hashes and arrays
my @shelf_costs = ();

# Nun tasks
my %nun_tasks = ();
my %nun_bonuses = ();

# Mage types for special expcosts
my @magetypes = ("acid", "asphyx", "cold", "elec", "fire", "mana", "poison");
my %mage_types = ();

# What special requirements has not been filled
my %miss_level_reqs = ();
my %miss_talent_reqs = ();


# Background hash contains the available backgrounds and guild within them
my %bghash = (
	"civilized"			=>
		[ "civilized_mages", "civilized_fighters", "runemages", "bards", "sabres",
			"merchants", "alchemists", "knights" ],
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
		=> { "str" => 10, "dex" => 10, "con" => 10 }, # confirmed by blayke
	"runemages"
		=> { "int" => 20, "wis" => 5 }, # fake
	"bards"
		=> { "dex" => 15, "wis" => 20 }, # confirmed 2/2004
	"merchants"
		=> { "str" => 6, "dex" => 6, "con" => 6, "int" => 6, "wis" => 6 },
	"alchemists"
		=> { "con" => 10, "int" => 15, "wis" => 10 }, # confirmed 2/2004
	"sabres"
		=> { "con" => 10, "str" => 10, "dex" => 10 }, # confirmed 4/2004
	"knights"
		=> { "con" => 5, "str" => 10, "dex" => 5, "int" => 10 }, # guess

	"squires"
		=> { "str" => 5, "dex" => 5, "con" => 5 }, # fake
	"beastmasters"
		=> { "str" => 5, "dex" => 10, "con" => 5 }, # fake
	"cavaliers"
		=> { "str" => 10, "dex" => 5, "con" => 5 }, # fake

	"rangers"
		=> { "str" => 10, "dex" => 10, "con" => 15 }, # confirmed
	"crimsons"
		=> { "str" => 10, "dex" => 10, "con" => 15 }, # confirmed 2/2004
	"barbarians"
		=> { "str" => 20, "dex" => 10, "con" => 5 }, # confirmed 2/2004


	"nuns"
		=> { "wis" => 13, "int" => 12 }, # confirmed
	"druids"
		=> { "int" => 15, "wis" => 15 }, # confirmed by era
	"tarmalens"
		=> { "wis" => 30 }, # confirmed
	"monks"
		=> { "dex" => 10, "con" => 20 }, # confirmed
	"templars"
		=> { "str" => 10, "dex" => 5, "con" => 22 }, # confirmed 8/2004


	"lords_of_chaos"
		=> { "str" => 20, "con" => 10 },
	"priests"
		=> { "int" => 12, "wis" => 25 }, # confirmed 2/2004
	"reavers"
		=> { "str" => 20, "wis" => 10 }, # confirmed
	"spiders"
		=> { "str" => 4, "dex" => 4, "con" => 22 }, # confirmed 2/2004
	"tigers"
		=> { "str" => 11, "dex" => 12, "con" => 7 }, # confirmed


	"conjurers"
		=> { "int" => 15, "wis" => 10 }, # semi-conf
	"mages"
		=> { "con" => 5, "int" => 30 }, # confirmed
	"psionicists"
		=> { "int" => 25, "wis" => 10 }, # semi-confirmed 2/2004
	"channellers"
		=> { "int" => 26, "con" => 2, "wis" => 2 }, # confirmed


	# GENERICS

	"navigators"
		=> { "int" => 3, "wis" => 2 }, # confirmed 1/2006


	# RACIAL GUILDS


	"barsoomian"
		=> { "dex" => 5 }, # confirmed 2/2004
	"giant"
		=> { "str" => 2, "con" => 3 }, # confirmed 2/2004
	"thrikhren"
		=> { "int" => 3, "wis" => 2 }, # confirmed 3/2004
	"drow"
		=> { "dex" => 3, "int" => 2 }, # confirmed 2/2004
	"ogre"
		=> { "str" => 3, "dex" => 2 }, # confirmed 2/2004
	"ent"
		=> { "con" => 2, "wis" => 2, "int" => 1 }, # confirmed 3/2004
	"duck"
		=> { "int" => 3, "wis" => 1, "dex" => 1 }, # confirmed 3/2004
	"troll"
		=> { "str" => 2, "con" => 3 }, # confirmed 3/2004
	"kobold"
		=> { "dex" => 3, "int" => 1, "wis" => 1 }, # guess 3/2004
	"leech"
		=> { "int" => 1, "wis" => 4 }, # confirmed 3/2004
	"sprite"
		=> { "int" => 3, "wis" => 2 }, # confirmed 3/2004
	"centaur"
		=> { "dex" => 5 }, # confirmed 5/2004
	"catfolk"
		=> { "dex" => 1, "con" => 1, "int" => 3 }, # confirmed 8/2004
	"dwarf"
		=> { "str" => 2, "con" => 3 }, # confirmed 8/2004
	"elf"
		=> { "dex" => 2, "con" => 2, "int" => 1 }, # confirmed 10/2004
	"tinmen"
		=> { "str" => 2, "con" => 3 }, # confirmed 10/2004
	"gnoll"
		=> { "str" => 3, "con" => 2 }, # confirmed 11/2004
	"leprechaun"
		=> { "dex" => 5 }, # confirmed 9/2005
	"valar"
		=> { "con" => 2, "wis" => 1 }, # confirmed 9/2005
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


# Alignment selection
my @alignmentlist = (
	"good", "neutral", "evil",
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
	"dex"	=> 40,
	"con"	=> 40,
	"int"	=> 40,
	"wis"	=> 40,
	"super"	=> 14,
	"skill" => 16,
	"spell"	=> 16,
	"exp"	=> 12,
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


# Training costs (range as race's starting stat and cost for it)
my %training_costs = (
	"103-200"	=> 7,
	"89-102"	=> 8,
	"78-88"		=> 9,
	"69-77"		=> 10,
	"62-68"		=> 11,
	"55-61"		=> 12,
	"47-54"		=> 13,
	"40-46"		=> 14,
	"34-39"		=> 15,
	"28-33"		=> 16,
	"22-27"		=> 17,
	"0-21"		=> 18,
);


# How much bonuses to hp do bg's get, estimates
my %hpbgbonus_hash = (
	"evil_religious"	=> 225,
	"good_religious"	=> 175,
	"magical"			=> 75,
	"nomad"				=> 425,
	"civilized"			=> 225,
	""					=> 0,
);

my %spbgbonus_hash = (
	"evil_religious"		=> 200,
	"evil_religious_int"	=> 1.2,
	"evil_religious_wis"	=> 2.6,

	"good_religious"		=> 250,
	"good_religious_int"	=> 1.2,
	"good_religious_wis"	=> 2.6,

	"magical"				=> 350,
	"magical_int"			=> 2.6,
	"magical_wis"			=> 1.2,

	"nomad"					=> 10,
	"nomad_int"				=> 0.3,
	"nomad_wis"				=> 0.3,

	"civilized"				=> 150,
	"civilized_int"			=> 1.8,
	"civilized_wis"			=> 1.8,
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

my ($user, $login_ok, $sess_ok) = &checkYabb2Session();


# Loading up the saved params, if there is any, then
# overriding with params from param
my %params = (
	"hide_changes"		=> "no",
	"hide_abilities"	=> "no",
	"hide_guilds"		=> "no",
	"hide_gzip"			=> "no",
	"hide_helps"		=> "no",
	"hide_quests"		=> "no",
	"hide_expcosts"		=> "no",
	"sortby"			=> "game",
);


# if copy is defined, we'll copy from another id to this id
&copyreinc(param('id'), param('cp')) if (param('cp'));
&deletereinc(param('id'), param('delete')) if (param('delete') && $login_ok);

# In case we might need one
my $uid = param('uid') || "";
my ($id, $alt_id) = &generateIds(param('id'));
&cleanup($id);



# load up params if were loading from file (ie. have only id param)
if ((scalar &param()) < 3) {
	my $file = "$id.db";

	if ($login_ok && $user && -e "saved/$id.$user") { # logged users reinc
		$file = "$id.$user";
	} elsif ($uid && -e "saved/$id.$uid") { # other users reinc
		$file = "$id.$uid";
	} else { # anonymous reinc
		$file = "$id.db";
	}

	&loadParams("saved/$file", \%params);

# or wrap up param calls to param hash
} else {
	for my $key (param) {
		my @stuff = sort {$b<=>$a} param($key);
		$params{$key} = ((scalar @stuff) == 1) ? param($key) : $stuff[0];
		#print STDERR "load: key: $key  val: $params{$key}\n";
	}
}
&checkMaxall();

# Only saving if save is true.
# It is saved by the ID number it had, or was created for it at the
# beginning.
if (defined param('save')) {
	my $file = "$id.db";
	$file = "$id.$user" if ($login_ok && $user);
	&saveParams("saved/$file", \%params);
}



# Creating links for This reinc, New reinc and id_string to hold our id
my $yourreincs			= &createReincSelect($user);
my $quicklink			= qq|<a href="reincsim/$SCRIPT?id=$id&amp;uid=$user">Reinc $id</a>|;

my $newreinc			= <<until_end;
<!-- qq|<a href="reincsim/$SCRIPT?id=$alt_id">Create a new reinc</a>|; -->
<form action="reincsim/$SCRIPT" method="get">
<input type="hidden" name="id" value="$alt_id" />
<input type="submit" value="Create a new reinc" />
</form>
until_end

my $copyreinc			= <<until_end;
<form action="reincsim/$SCRIPT" method="post">
<input type="hidden" name="id" value="$alt_id" />
<input type="hidden" name="cp" value="$id" />
<input type="submit" value="Copy to a new id" />
</form>
until_end

my $viewlink			= qq|<a href="reincsim/viewreinc.pl?id=$id&amp;uid=$user">Viewreinc $id</a>|;
my $id_string			= qq|<input type="hidden" name="id" value="$id" />\n|;
my $hidechanges_html	= &hideSomethingHtml('changes', param('hide_changes'));
my $hideguilds_html		= &hideSomethingHtml('guilds', $params{'hide_guilds'});
my $hideabilities_html	= &hideSomethingHtml('abilities', $params{'hide_abilities'});
my $hidequests_html		= &hideSomethingHtml('quests', $params{'hide_quests'});
my $hidehelps_html		= &hideSomethingHtml('helps', $params{'hide_helps'});
my $hidegzip_html		= &hideSomethingHtml('gzip', $params{'hide_gzip'});
my $hideexpcost_html	= &hideSomethingHtml('expcosts', $params{'hide_expcosts'});
my $sortby_html			= &sortbyHtml('sortby', $params{'sortby'});

# Creating a Save & Calculate button for submitting the information to server
my $savereinc	= qq|<input type="submit" name="save" value="Save" />|;
my $submit		= qq|<input type="submit" value="Calculate" />|;
my $titleinput	= qq|<input type="text" value="$params{'title'}" name="title" size="40" maxlength="40" />|;


# Background, race, and rebirth are the most basic information
my $bg = $params{'bg'} || 'civilized';
my $race = $params{'race'} || 'human';
my $rebirth = $params{'rebirth'} || 0;
my $alignment = $params{'alignment'} || 'neutral';



# The guilds are next, followed by the guildlevels, which are
# filtered, to meet the right guild maximums (ie glevel1=35 and guild is
# conjurer, which maxes at 25, glevel is filtered to 25)
my $glevel1 = &guildMaxLevel($params{'guild1'}, $params{'glevel1'});
my $glevel2 = &guildMaxLevel($params{'guild2'}, $params{'glevel2'});
my $glevel3 = &guildMaxLevel($params{'guild3'}, $params{'glevel3'});
my $glevel4 = &guildMaxLevel($params{'guild4'}, $params{'glevel4'});
my $glevel5 = &guildMaxLevel($params{'guild5'}, $params{'glevel5'});
my $glevel6 = &guildMaxLevel($params{'guild6'}, $params{'glevel6'});


# Constructing a hash about our guilds, to be passed on as a param for
# stat calculator, which calculates our estimated stats
my %guildconfig = (
	$bg		=> 10,
	$race   => (5 - $rebirth),
	$params{'guild1'} || "none" => $glevel1,
	$params{'guild2'} || "none" => $glevel2,
	$params{'guild3'} || "none" => $glevel3,
	$params{'guild4'} || "none" => $glevel4,
	$params{'guild5'} || "none" => $glevel5,
	$params{'guild6'} || "none" => $glevel6,
);



# Creating the background, race and rebirth select boxes
my $bg_select = &createBgSelect($bg);
my $race_select = &createRaceSelect($race);
my $alignment_select = &createAlignmentSelect($alignment);
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
my ($g6_select, $gl6_select) = &createGuildSelect($params{'guild6'}, $glevel6, 6);


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
my ($g6_skills,		$g6_skills_cost)	= &createTalents($params{'guild6'}, $glevel6, $bg, 'skill');

my ($bg_spells,		$bg_spells_cost)	= &createTalents($bg, 10, undef, 'spell', 1);
my ($race_spells,	$race_spells_cost)	= &createTalents($race, 5 - $rebirth, $bg, 'spell');
my ($g1_spells,		$g1_spells_cost)	= &createTalents($params{'guild1'}, $glevel1, $bg, 'spell');
my ($g2_spells,		$g2_spells_cost)	= &createTalents($params{'guild2'}, $glevel2, $bg, 'spell');
my ($g3_spells,		$g3_spells_cost)	= &createTalents($params{'guild3'}, $glevel3, $bg, 'spell');
my ($g4_spells,		$g4_spells_cost)	= &createTalents($params{'guild4'}, $glevel4, $bg, 'spell');
my ($g5_spells,		$g5_spells_cost)	= &createTalents($params{'guild5'}, $glevel5, $bg, 'spell');
my ($g6_spells,		$g6_spells_cost)	= &createTalents($params{'guild6'}, $glevel6, $bg, 'spell');


# Creating guild specials, like mage types, runemage shelf etc
my ($g1_specials, $g1_special_xp) = &createGuildSpecials($params{'guild1'});
my ($g2_specials, $g2_special_xp) = &createGuildSpecials($params{'guild2'});
my ($g3_specials, $g3_special_xp) = &createGuildSpecials($params{'guild3'});
my ($g4_specials, $g4_special_xp) = &createGuildSpecials($params{'guild4'});
my ($g5_specials, $g5_special_xp) = &createGuildSpecials($params{'guild5'});
my ($g6_specials, $g6_special_xp) = &createGuildSpecials($params{'guild6'});


# Creating area filled with quests
my $lq_select = &createLevelQuests();
my $aq_select = &createAreaQuests();


# Creating the select boxes about boons, having 5 stages
# (none, tiny, small, medium, full)
my $expboon_select	= &createBoonSelect('exp', $params{'boon_exp'});
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
my $levels_spent	= 15 - $rebirth + $glevel1 + $glevel2 + $glevel3 + $glevel4 + $glevel5 + $glevel6;
my ($exp_on_levels, $exp_saved)	= &countExpSpentOnLevels($levels_spent);


# Calculate train bonuses
my $trainingpoints_from_levels = 0;
$trainingpoints_from_levels += 20 for (31..($levels_spent <= 90 ? $levels_spent : 90));
if ($levels_spent > 90) { $trainingpoints_from_levels += 25 for (91..$levels_spent); }
my $trainingpoints_from_quests = &countTrainingPointsFromQuests();
my $trainingpoints = $trainingpoints_from_levels + $trainingpoints_from_quests;

my ($strtrain_select, $strtrain_cost) = &createTrainSelect($race, 'str', $params{'train_str'});
my ($dextrain_select, $dextrain_cost) = &createTrainSelect($race, 'dex', $params{'train_dex'});
my ($contrain_select, $contrain_cost) = &createTrainSelect($race, 'con', $params{'train_con'});
my ($inttrain_select, $inttrain_cost) = &createTrainSelect($race, 'int', $params{'train_int'});
my ($wistrain_select, $wistrain_cost) = &createTrainSelect($race, 'wis', $params{'train_wis'});
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
my $stat_exp = &calculateStats('exp', $race, 0, $params{'boon_exp'});


# Calculating HP/SP/EP for combo
my $total_hp = &calculateHp($race, $bg, $stat_con, $stat_siz);
my $total_sp = &calculateSp($race, $bg, $stat_int, $stat_wis);
my $total_ep = &calculateEp($stat_str, $stat_dex, $stat_con);


# Calculating the total exp spent on reinc, affected by the number of levels,
# skills and spells and society bonuses
my $spent_on_spells = $race_spells_cost + $g1_spells_cost + $g2_spells_cost +
					   $g3_spells_cost + $g4_spells_cost + $g5_spells_cost +
					   $g6_spells_cost;
my $spent_on_skills = $race_skills_cost + $g1_skills_cost + $g2_skills_cost +
					  $g3_skills_cost + $g4_skills_cost + $g5_skills_cost +
					  $g6_skills_cost;
my $spent_on_ss		= &totalToX('', $params{'ss_str'}, 'Str', 'human', 'skill', 0, 1) +
					  &totalToX('', $params{'ss_dex'}, 'Dex', 'human', 'skill', 0, 1) +
					  &totalToX('', $params{'ss_con'}, 'Con', 'human', 'skill', 0, 1) +
					  &totalToX('', $params{'ss_int'}, 'Int', 'human', 'skill', 0, 1) +
					  &totalToX('', $params{'ss_wis'}, 'Wis', 'human', 'skill', 0, 1);
my $spent_on_abilities = &countExpSpentOnAbilities();
my $spent_on_guildspecials = &countExpSpentOnGuildSpecials();
my $total_spent		= $exp_on_levels + $spent_on_spells + $spent_on_skills +
	$spent_on_ss + $spent_on_abilities + $spent_on_guildspecials;
my $guildgoldcost	= &calculateGuildGoldCost();


# And we verbose them by adding a space each third number
$spent_on_abilities	= &verboseLargeNumbers($spent_on_abilities);
$spent_on_guildspecials	= &verboseLargeNumbers($spent_on_guildspecials);
$exp_on_levels		= &verboseLargeNumbers($exp_on_levels);
$exp_saved			= &verboseLargeNumbers($exp_saved);
$spent_on_spells	= &verboseLargeNumbers($spent_on_spells);
$spent_on_skills	= &verboseLargeNumbers($spent_on_skills);
$spent_on_ss		= &verboseLargeNumbers($spent_on_ss);
$total_spent		= &verboseLargeNumbers($total_spent);
$guildgoldcost		= &verboseLargeNumbers($guildgoldcost);


# Pre-filled form values
my $otherboons = $params{"otherboons"} || "";



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

<h2>Reinc simulator by Tumi</h2>
<div class="tool-link"><strong>Version:</strong> $VERSION</div>

$point_of_site
$fixlist
$buglist

<div id="reincsim-main">

<table id="reincsim-bgrace">
<tr><td>Load saved reinc (only registered and logged users):</td><td colspan="3">$yourreincs</td></tr>
<tr><td colspan="4"><h3>Background and guild selection</h3></td></tr>
<tr><td colspan="4">&nbsp;</td></tr>
<tr><td>Your quicklink to this reinc:</td><td>$quicklink</td><td colspan="2">$newreinc</td></tr>
<tr><td>View your reinc as text (save first):</td><td colspan="3">$viewlink</td></tr>
<tr><td>Copy this reinc to another id (save first):</td><td colspan="3">$copyreinc</td></tr>
<tr><td colspan="4"><hr /></td></tr>
<form action="reincsim/$SCRIPT" method="post">
<tr><td>Name of this reinc:</td><td colspan="3">$titleinput</td></tr>
<tr><td>Choose your background:</td> <td colspan="3">$bg_select</td></tr>
<tr><td>Choose your race:</td><td colspan="3">$race_select</td></tr>
<tr><td>Choose your alignment:</td><td colspan="3">$alignment_select</td></tr>
<tr><td>Choose your rebirth:</td><td colspan="3">$rebirth_select</td></tr>
<tr><td>Choose your primary guild:</td><td>$g1_select</td> <td>at level:</td><td>$gl1_select</td></tr>
<tr><td>Choose your secondary guild:</td><td>$g2_select</td> <td>at level:</td><td>$gl2_select</td></tr>
<tr><td>Choose your tertiary guild:</td><td>$g3_select</td> <td>at level:</td><td>$gl3_select</td></tr>
<tr><td>Choose your quaternary guild:</td><td>$g4_select</td> <td>at level:</td><td>$gl4_select</td></tr>
<tr><td>Choose your quinary guild:</td><td>$g5_select</td> <td>at level:</td><td>$gl5_select</td></tr>
<tr><td>Choose your senary guild:</td><td>$g6_select</td> <td>at level:</td><td>$gl6_select</td></tr>
<tr><td colspan="4"><hr /></td></tr>
<tr><td colspan="3">Hide tool desc, fix- &amp; buglists?:</td><td>$hidechanges_html</td></tr>
<tr><td colspan="3">Hide guilds (for calculating stats only):</td><td>$hideguilds_html</td></tr>
<tr><td colspan="3">Hide quests:</td><td>$hidequests_html</td></tr>
<tr><td colspan="3">Hide abilities:</td><td>$hideabilities_html</td></tr>
<tr><td colspan="3">Hide links to bat.org in skills/spells:</td><td>$hidehelps_html</td></tr>
<tr><td colspan="3">Hide expcosts in select boxes:</td><td>$hideexpcost_html</td></tr>
<tr><td colspan="3">Sort skills/spells style:</td><td>$sortby_html</td></tr>
<!-- <tr><td colspan="3">(Debug: Disallow gzip:</td><td>$hidegzip_html)</td></tr> -->
<tr><td colspan="4"><hr /></td></tr>
<tr><td>Levels taken:</td><td colspan="3" class="reincsim-numbers">$levels_spent</td></tr>
<tr><td>Exp spent on levels:</td><td colspan="3" class="reincsim-numbers">$exp_on_levels xp</td></tr>
<tr><td>Exp saved with quests:</td><td colspan="3" class="reincsim-numbers">$exp_saved xp</td></tr>
<tr><td>Exp spent in skills:</td><td colspan="3" class="reincsim-numbers">$spent_on_skills xp</td></tr>
<tr><td>Exp spent in spells:</td><td colspan="3" class="reincsim-numbers">$spent_on_spells xp</td></tr>
<tr><td>Exp spent in SS:</td><td colspan="3" class="reincsim-numbers">$spent_on_ss xp</td></tr>
<tr><td>Exp spent in abilities:</td><td colspan="3" class="reincsim-numbers">$spent_on_abilities xp</td></tr>
<tr><td>Exp spent in guildspecials:</td><td colspan="3" class="reincsim-numbers">$spent_on_guildspecials xp</td></tr>
<tr><td colspan="4"><hr /></td></tr>
<tr><td>Total exp spent in reinc:</td><td class="reincsim-numbers" colspan="3">$total_spent xp</td></tr>
<tr><td>Total gold spent in reinc:</td><td class="reincsim-numbers" colspan="3">$guildgoldcost gp</td></tr>
<tr><td colspan="4" class="reincsim-submit">$savereinc $submit</td></tr>
</table>
<br />


<table id="reincsim-stats">
<tr><td colspan="6"><h3>Stats and boons selections</h3></td></tr>
<tr id="reincsim-stat-header"><td>Type</td><td>Power</td><td>SS&nbsp;bonus</td><td>Boon&nbsp;level</td><td>EQ&nbsp;bonus</td><td>Training</td></tr>
<tr><td>Skillmax:</td><td class="reincsim-numbers">$stat_skill</td><td>$skillss_select</td><td>$skillboon_select</td><td>&nbsp;</td><td>&nbsp;</td></tr>
<tr><td>Spellmax:</td><td class="reincsim-numbers">$stat_spell</td><td>$spellss_select</td><td>$spellboon_select</td><td>&nbsp;</td><td>&nbsp;</td></tr>
<tr><td colspan="6"><hr /></td></tr>
<tr><td>Strength:</td><td class="reincsim-numbers">$stat_str</td><td>$strss_select</td><td>$strboon_select</td><td>$streq_select</td><td>$strtrain_select</td></tr>
<tr><td>Dexterity:</td><td class="reincsim-numbers">$stat_dex</td><td>$dexss_select</td><td>$dexboon_select</td><td>$dexeq_select</td><td>$dextrain_select</td></tr>
<tr><td>Constitution:</td><td class="reincsim-numbers">$stat_con</td><td>$conss_select</td><td>$conboon_select</td><td>$coneq_select</td><td>$contrain_select</td></tr>
<tr><td>Intelligence:</td><td class="reincsim-numbers">$stat_int</td><td>$intss_select</td><td>$intboon_select</td><td>$inteq_select</td><td>$inttrain_select</td></tr>
<tr><td>Wisdom:</td><td class="reincsim-numbers">$stat_wis</td><td>$wisss_select</td><td>$wisboon_select</td><td>$wiseq_select</td><td>$wistrain_select</td></tr>
<tr><td>Size:</td><td class="reincsim-numbers">$stat_siz</td><td colspan="3">SuperChar boon: $superboon_select</td><td class="reincsim-numbers">Tr.Pnts: $trainingpoints_spent / $trainingpoints (Lvls: $trainingpoints_from_levels, Qs: $trainingpoints_from_quests)</td></tr>
<tr><td colspan="6"><hr /></td></tr>
<tr style="color: Red; font-weight: bold;"><td>HP:</td><td class="reincsim-numbers">$total_hp</td><td>SP:</td><td class="reincsim-numbers">$total_sp</td><td>EP:</td><td class="reincsim-numbers">$total_ep</td></tr>
<tr><td>Other boons:</td><td colspan="5"><input type="text" name="otherboons" value="$otherboons" maxlength="255" size="75" /></td></tr>
<tr><td colspan="6" class="reincsim-submit">$savereinc $submit</td></tr>
</table>
<br />

until_end


if ($params{'hide_quests'} eq "no" && $params{'hide_guilds'} eq "no") {
	$page_output .= <<until_end;
<table id="reincsim-quests">
<tr><td colspan="3"><h3>Level quests</h3></td></tr>
<tr><td colspan="3">&nbsp;</td></tr>
<tr><td colspan="2" align="right">Select all quests:</td><td><select name="quests_maxall"><option value="0">No</option><option value="1">Yes</option></select></td></tr>
<tr><td colspan="3">&nbsp;</td></tr>
$lq_select
<tr><td colspan="3"><h3>Area quests</h3></td></tr>
<tr><td colspan="3">&nbsp;</td></tr>
$aq_select
<tr><td colspan="3" class="reincsim-submit">$savereinc $submit</td></tr>
</table>

until_end
}


if ($params{'hide_abilities'} eq "no" && $params{'hide_guilds'} eq "no") {
	my @abilities_selects = &createAbilitySelect();

	$page_output .= <<until_end;
<table id="reincsim-abilities">
<tr><td colspan="4"><h3>Ability selection</h3></td></tr>
<tr><td>Name of the ability:</td><td>Cost:</td><td>Name of the ability:</td><td>Cost:</td></tr>
until_end

	my $cntr = 0;
	for my $full (@abilities_selects) {
		my ($fullname, $select_html) = split/;/, $full;
		$page_output .= qq|<tr>|."\n" if ($cntr%2 == 0);
		$page_output .= qq|<td>$fullname</td><td>$select_html</td>|."\n";
		$page_output .= qq|</tr>|."\n" if ($cntr%2 == 1);
		$cntr++;
	}
	$page_output .= qq|<td>&nbsp;</td></tr>|."\n" if ($cntr%2 == 0);
	$page_output .= <<until_end;

<tr><td colspan="4" class="reincsim-submit">$savereinc $submit</td></tr>
</table>
<br />
until_end
}



# If background is selected, race is selected or one of the guilds is selected,
# we should display that guilds skills and spells information
if ($params{'hide_guilds'} eq "no" && length($params{'guild1'} || "") > 3) {
	my $gspec1 = &guildspecials($params{'guild1'});
	my $gspec2 = &guildspecials($params{'guild2'});
	my $gspec3 = &guildspecials($params{'guild3'});
	my $gspec4 = &guildspecials($params{'guild4'});
	my $gspec5 = &guildspecials($params{'guild5'});
	my $gspec6 = &guildspecials($params{'guild6'});

	# verbosed exp spent on skills
	my $verb_g1_skills_cost = &verboseLargeNumbers($g1_skills_cost);
	my $verb_g2_skills_cost = &verboseLargeNumbers($g2_skills_cost);
	my $verb_g3_skills_cost = &verboseLargeNumbers($g3_skills_cost);
	my $verb_g4_skills_cost = &verboseLargeNumbers($g4_skills_cost);
	my $verb_g5_skills_cost = &verboseLargeNumbers($g5_skills_cost);
	my $verb_g6_skills_cost = &verboseLargeNumbers($g6_skills_cost);

	# verbosed exp spent on spells
	my $verb_g1_spells_cost = &verboseLargeNumbers($g1_spells_cost);
	my $verb_g2_spells_cost = &verboseLargeNumbers($g2_spells_cost);
	my $verb_g3_spells_cost = &verboseLargeNumbers($g3_spells_cost);
	my $verb_g4_spells_cost = &verboseLargeNumbers($g4_spells_cost);
	my $verb_g5_spells_cost = &verboseLargeNumbers($g5_spells_cost);
	my $verb_g6_spells_cost = &verboseLargeNumbers($g6_spells_cost);


	# Adding the guilds one by one (note: lines are around 350+ characters long)
	$page_output .= qq|\n<table class="reincsim-guilds">\n|;
	$page_output .= qq|<tr><td colspan="4"><h3>Skills and spells selections</h3></td></tr>\n|;
	$page_output .= qq|</table>\n|;

	$page_output .= qq|<table class="reincsim-guilds\n">\n<tr><td colspan="2" valign="top">$bg_skills</td><td colspan="2" valign="top">$bg_spells</td></tr>\n<tr><td>Cost of skills:</td><td class="reincsim-numbers">$bg_skills_cost xp</td><td>Cost of spells:</td><td class="reincsim-numbers">$bg_spells_cost xp</td></tr>\n</table>\n| if ($bg ne "none");
	$page_output .= qq|<table class="reincsim-guilds\n">\n<tr><td colspan="2" valign="top">$race_skills</td><td colspan="2" valign="top">$race_spells</td></tr>\n<tr><td>Cost of skills:</td><td class="reincsim-numbers">$race_skills_cost xp</td><td>Cost of spells:</td><td class="reincsim-numbers">$race_spells_cost exp</td></tr>\n</table>\n| if ($race ne "none");
	$page_output .= qq|<table class="reincsim-guilds\n">\n<tr><td colspan="4">$gspec1</td></tr><tr><td colspan="2" valign="top">$g1_skills</td><td colspan="2" valign="top">$g1_spells</td></tr>\n<tr><td>Cost of skills:</td><td class="reincsim-numbers">$verb_g1_skills_cost xp</td><td>Cost of spells:</td><td class="reincsim-numbers">$verb_g1_spells_cost xp</td></tr>\n</table>\n| if (defined $params{'guild1'} && not $params{'guild1'} =~ /^(none|secret_societys)?$/i);
	$page_output .= qq|<table class="reincsim-guilds\n">\n<tr><td colspan="4">$gspec2</td></tr><tr><td colspan="2" valign="top">$g2_skills</td><td colspan="2" valign="top">$g2_spells</td></tr>\n<tr><td>Cost of skills:</td><td class="reincsim-numbers">$verb_g2_skills_cost xp</td><td>Cost of spells:</td><td class="reincsim-numbers">$verb_g2_spells_cost xp</td></tr>\n</table>\n| if (defined $params{'guild2'} && not $params{'guild2'} =~ /^(none|secret_societys)?$/i);
	$page_output .= qq|<table class="reincsim-guilds\n">\n<tr><td colspan="4">$gspec3</td></tr><tr><td colspan="2" valign="top">$g3_skills</td><td colspan="2" valign="top">$g3_spells</td></tr>\n<tr><td>Cost of skills:</td><td class="reincsim-numbers">$verb_g3_skills_cost xp</td><td>Cost of spells:</td><td class="reincsim-numbers">$verb_g3_spells_cost xp</td></tr>\n</table>\n| if (defined $params{'guild3'} && not $params{'guild3'} =~ /^(none|secret_societys)?$/i);
	$page_output .= qq|<table class="reincsim-guilds\n">\n<tr><td colspan="4">$gspec4</td></tr><tr><td colspan="2" valign="top">$g4_skills</td><td colspan="2" valign="top">$g4_spells</td></tr>\n<tr><td>Cost of skills:</td><td class="reincsim-numbers">$verb_g4_skills_cost xp</td><td>Cost of spells:</td><td class="reincsim-numbers">$verb_g4_spells_cost xp</td></tr>\n</table>\n| if (defined $params{'guild4'} && not $params{'guild4'} =~ /^(none|secret_societys)?$/i);
	$page_output .= qq|<table class="reincsim-guilds\n">\n<tr><td colspan="4">$gspec5</td></tr><tr><td colspan="2" valign="top">$g5_skills</td><td colspan="2" valign="top">$g5_spells</td></tr>\n<tr><td>Cost of skills:</td><td class="reincsim-numbers">$verb_g5_skills_cost xp</td><td>Cost of spells:</td><td class="reincsim-numbers">$verb_g5_spells_cost xp</td></tr>\n</table>\n| if (defined $params{'guild5'} && not $params{'guild5'} =~ /^(none|secret_societys)?$/i);
	$page_output .= qq|<table class="reincsim-guilds\n">\n<tr><td colspan="4">$gspec6</td></tr><tr><td colspan="2" valign="top">$g6_skills</td><td colspan="2" valign="top">$g6_spells</td></tr>\n<tr><td>Cost of skills:</td><td class="reincsim-numbers">$verb_g6_skills_cost xp</td><td>Cost of spells:</td><td class="reincsim-numbers">$verb_g6_spells_cost xp</td></tr>\n</table>\n| if (defined $params{'guild6'} && not $params{'guild6'} =~ /^(none|secret_societys)?$/i);

	$page_output .= qq|<table class="reincsim-guilds\n">\n<tr><td colspan="4" class="reincsim-submit">$savereinc $submit</td></tr>\n| if ($params{'guild1'} || $params{'guild2'});
	$page_output .= qq|</table>\n|;
}


# Wrapping the ending together
$page_output .= <<until_end;

$id_string
</form>

</div>

<!-- <p>$html_debug</p> -->

until_end





# Actually printing the page to STDOUT, displaying the page in browser!
&makeTitle();
&pageOutput('reincsim', $page_output);


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

	$alt_id  = sprintf "%010d", int(rand(2000000000)) while (-e "saved/$alt_id.db" || -e "saved/$alt_id.$user");
	$alt_id2 = sprintf "%010d", int(rand(2000000000)) while (-e "saved/$alt_id2.db" || -e "saved/$alt_id2.$user");

	return ($id, $alt_id) if (defined $id && $id =~ /^[0-9]{10}$/);
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

	&loadQuests();

	return 0
		unless $fh;

	while (my $line = <$fh>) {
		my ($lev, $xp) = split/ /, $line;
		last if ($lev > $level);

		my $saved_all = param('quests_maxall') && defined $lq_hash{sprintf("%02d", $lev)};
		my $saved_all2 = param('quests_maxall') && defined $lq_hash{sprintf("%02d", $lev)} && defined $lq_hash{sprintf("%02d_2", $lev)};

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
# countExpSpentOnLevels - Data is read from a file, with no helping
#                         quests completed. Returns the exp spent
#                         to given level.
#
# Params      - Level
#
# Returns     - Exp
#
#####################################################################

sub countTrainingPointsFromQuests {
	my $tps = 0;

	&loadQuests();

	for my $key (keys %lq_hash) {
		my ($q_name, $q_diff, $q_pts) = split/\|/,$lq_hash{$key};
		$tps += $q_pts if (param('quests_maxall') || $params{"lq$key"});
	}

	for my $key (keys %aq_hash) {
		my ($q_diff, $q_pts) = split/\|/,$aq_hash{$key};
		my $param_key = $key;
		$param_key =~ tr/[a-z]//cd;
		$tps += $q_pts if (param('quests_maxall') || $params{"aq_$param_key"});
	}

	return ($tps);
}




#####################################################################
#
# countExpSpentOnAbilities - counts exp spent on abilities
#
# Params      -
#
# Returns     - Exp
#
#####################################################################

sub countExpSpentOnAbilities {
	&loadAbilities();
	my $expspent = 0;

	for my $short (sort keys %abilitieshash) {
		my ($maxcost, $full) = split/;/, $abilitieshash{$short};
		my $percent = defined $params{"ability_$short"} ? $params{"ability_$short"} : 0;
		$expspent += $maxcost * $percent / 100;
	}

	return $expspent;
}




#####################################################################
#
# countExpSpentOnGuildSpecials - counts exp spent on guild specials
#
# Params      -
#
# Returns     - Exp
#
#####################################################################

sub countExpSpentOnGuildSpecials {
	my $exp = 0;

	# Runemage shelf
	&loadShelfCosts();
	my $slots = $params{"guildspecial_runemages_shelf"} || 0;
	$exp += $shelf_costs[$slots];




	return $exp;
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
	my $selection = qq|\n<select name="bg">\n|;

	for my $bgs (sort keys %bghash) {
		next if ($bgs =~ /generic/i);
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
	my $selection = qq|\n<select name="race">\n|;

	for my $race (sort @racelist) {
		my $insert = $selected eq $race ? " selected=\"selected\"" : "";
		$selection .= "<option value=\"$race\"$insert>".ucfirst $race."</option>\n";
	}
	$selection .= "</select>\n";

	return $selection;
}




#####################################################################
#
# createAlignmentSelect - Generates select box with alignemnt
#
# Params      - Previously selected alignment (from param)
#
# Returns     - HTML with select box
#
#####################################################################
sub createAlignmentSelect {
	my $selected = shift;
	my $selection = qq|\n<select name="alignment">\n|;

	for my $align (sort @alignmentlist) {
		my $insert = $selected eq $align ? " selected=\"selected\"" : "";
		$selection .= "<option value=\"$align\"$insert>".ucfirst $align."</option>\n";
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
		my $this_power = $boon_power * $multiplier == 9.6 ? 10 : int($boon_power * $multiplier);
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

	for my $power (0..40) {
			my $ss_cost = "";
		my $insert = ($selected == $power ? " selected=\"selected\"" : "");

		# If we wanna see expcosts around
		if ($params{'hide_expcosts'} eq "no" && ($power > 0)) {
			$ss_cost = &totalToX('', $power, ucfirst $stat, 'human', 'skill', 0, 1);
			$ss_cost = $ss_cost > 0 ? " (".(int($ss_cost / 10000.0) / 100.0)." M)" : "";
		}
		$output .= qq|<option value="$power"$insert>$power$ss_cost</option>\n|;
	}
	$output .= qq|</select>\n|;

	return $output;
}




#####################################################################
#
# createAbilitySelect - Creates a html for all abilities
#
# Params      - None
#
# Returns     - array where data is "full;html" form
#
#####################################################################

sub createAbilitySelect {
	my @selects = ();

	&loadAbilities();
	for my $short (sort {$a cmp $b} keys %abilitieshash) {
		my ($cost, $full) = split/;/, $abilitieshash{$short};
		#$full =~ s/&/&amp;/;
		my $output .= qq|<select name="ability_$short">|."\n";

		for my $percent (0..20) {
			my $realpercent = $percent * 5;
			my $expcost = sprintf("%4.2fM", $percent * $cost / 1000000 / 20);
			my $sel = (defined $params{"ability_$short"} && $params{"ability_$short"} == $realpercent) ?
				" selected=\"selected\"" : "";

			$output .= qq|<option value="$realpercent"$sel>$realpercent % - $expcost</option>|."\n";
		}
		$output .= qq|</select>|."\n";
		push @selects, "".(ucfirst $full).";$output";
	}

	return @selects;
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
	my $race = shift || 'human';
	my $stat = shift || 'str';

	#print STDERR "createTrainSelect: calling trainmax '$race', '$stat'\n";
	my ($racmax, $starts) = &calculateRacialTrainMax($race, $stat);
	my $selected = shift;
	$selected = defined $selected ? $selected : $starts;

	my $output = qq|\n<select name="train_$stat">\n|;
	my $traincost = 0;

	for my $power ($starts..$racmax+60) {
		my $insert = "";
		my $cost = &calculateTrainCost($race, $stat, $starts, $power);
		my $optval = $power - $racmax;
		my $count = $power - $starts;
		if ($selected == $optval) {
			$insert = " selected=\"selected\"";
			$traincost = $cost;
		}
		$output .= qq|<option value="$optval"$insert>$power ($count, $cost pts)</option>\n|;

		# if total is higher than points available, quit printing
		last if (($trainingpoints + 50) < $cost);
	}
	$output .= qq|</select>\n|;
	$output .= qq|<strong>/$racmax</strong>\n|;

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

sub createLevelQuests {
	my $quests_select = "";

	# If quests has not been loaded yet, we will load em
	&loadQuests();

	# quest link
	my $linkt = qq|http://www.bat.org/help/quests.php?str=|;

	# Sorted by level, they're printed out, checked if they were selected
	my $cntr = 0;
	for my $level (sort {$a cmp $b} keys %lq_hash) {
		next unless (defined $lq_hash{$level});

		# make link out if it
		my ($q_name, $q_diff, $q_pts) = split/\|/, $lq_hash{$level};
		my $questtext = &getBatorgLink($q_name, 'quests');

		# Cntr is used to wrap quests in sets of three
		$quests_select .= qq|<tr>\n|
			if ($cntr % 3 == 0);

		$level =~ /^0?(\d+)/;
		my $check = " checked=\"checked\"";
		my $selected = $params{"lq$level"} ? $check : "";
		$selected = param('quests_maxall') ? $check : $selected;

		# make html out of it
		$quests_select .= <<until_end;
<td class="questtd">
    <label>
    <input type="checkbox" name="lq$level"$selected />
    LQ $level: $questtext ($q_diff)
    </label>
</td>
until_end

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
# createQuests - Creates three wide table with levels quests
#                and their select boxes
#
# Params      - None
#
# Returns     - HTML with table
#
#####################################################################

sub createAreaQuests {
	my $quests_select = "";

	# If quests has not been loaded yet, we will load em
	&loadQuests();

	# quest link
	my $linkt = qq|http://www.bat.org/help/quests.php?str=|;

	# Sorted by level, they're printed out, checked if they were selected
	my $cntr = 0;
	for my $q_name (sort {$a cmp $b} keys %aq_hash) {
		next unless (defined $aq_hash{$q_name});

		# make link out if it
		my ($q_diff, $q_pts) = split/\|/, $aq_hash{$q_name};
		my $questtext = &getBatorgLink($q_name, 'quests');

		# tag
		my $tagname = $q_name;
		$tagname =~ tr/[a-z]//cd;

		# Cntr is used to wrap quests in sets of three
		$quests_select .= qq|<tr>\n|
			if ($cntr % 3 == 0);

		my $check = " checked=\"checked\"";
		my $selected = $params{"aq_$tagname"} ? $check : "";
		$selected = param('quests_maxall') ? $check : $selected;

		# make html out of it
		$quests_select .= <<until_end;
<td class="questtd">
    <label>
    <input type="checkbox" name="aq_$tagname"$selected />
    AQ: $questtext ($q_diff)
    </label>
</td>
until_end

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
	#my ($maxskills, $maxspells, $min, $skillreq, $spellreq, $levelreq) = &lookForGuildMax($guild, $level);
	#my ($bg_skills, $bg_spells, $bgmin, $skr, $spr, $lvr) = &lookForGuildMax($bg, 10);
	my ($maxskills, $maxspells, $min) = &lookForGuildMax($guild, $level);
	my ($bg_skills, $bg_spells, $bgmin) = &lookForGuildMax($bg, 10);
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
	for my $talent (sort sorttalents keys %$maxref) {
		my $orig_talent = $talent;
		$talent =~ tr/ A-Z/_a-z/;

		# Bg skill/spell bonuses
		my $bgtalent = $bgref->{$orig_talent} || 0;
		my $bgaddon = ($bgtalent > 0 && $bgtalents == 0 ? "$bgtalent+" : "");

		# Beginning the selection, including the bgbonus and deciding the min/max
		my $selection = "\n$bgaddon<select name=\"$type\_$talent\">\n";
		my $talent_arcane = ($type eq "skill" ? &isTalentArcane($talent) : 0);
		my $previous_level = $params{$type."_".$talent} || 0;          # How much previuous calc had
		my $required = $min->{$orig_talent} || 0;                      # How much is required by guild
		my $temp_max = $maxref->{$orig_talent} || 0;                 # How much is guildmax !!!
		my $maximum = $temp_max < 100 ? $temp_max : 100;               # ??? Pretty useless I'd say, didn't dare to remove
		my $cheapmax = $talentmax < $maximum ? $talentmax : $maximum;  # Which is cheaper, guildmax or racialmax

		# If maxallguild is defined, skill is trained to maximum.
		# If not, it is preset to previously ordered percentage, or if not present,
		# then requirement, if present. 0 if not.
		my $maxall = param($type."s_maxall_$guild") || 0;

		# New version
		my $pre = ($previous_level < $required ? $required : $previous_level || $required); # Either prev or guildreg
		$pre = ($maxall == 1 ? ($cheapmax < $pre ? $pre : $cheapmax) : $pre); # Maxing to racemax
		$pre = ($maxall == 2 ? ($maximum < $pre ? $pre : $maximum) : $pre);   # Maxing to guildmax?
		$pre = ($maxall > 2 ? ($maxall < $pre ? $pre : $maxall) : $pre );     # Maxing to certain%
		$pre = ($pre > $maximum ? $maximum : $pre);                           # If pre is higher than max

		# Old version
		#my $pre = ($maxall > 2 ? $maxall :
		#	($maxall == 2 ? $maximum :
		#		($maxall == 1 ?
		#			($cheapmax < $previous_level ? $previous_level : $cheapmax) :
		#			$previous_level || $required)));

		my @loop_range = grep {$_ % 5 == 0} $required..$maximum;
		@loop_range = &removeDuplicates(@loop_range, $pre, $maximum, $required,
			$talentmax <= $maximum ? $talentmax : 0);


		# Inserting every fifth percent into select, and max, min, talentmax and current
		for my $perc (sort {$a<=>$b} @loop_range) {
			my $insert = ($pre == $perc) ? " selected=\"selected\"" : "";
			$selection .= qq|<option value="$perc"$insert>$perc %|;
			if (($params{'hide_expcosts'} eq 'no') && ($perc > 0)) {
				my $expcost = &totalToX($guild, $perc, $orig_talent, $race, $type);
				$expcost = sprintf "%.1f", int($expcost / 10000) / 100.0;
				$selection .= qq| ($expcost M)|;
			}
			$selection .= qq|</option>\n|;
		}
		$selection .= "</select>\n";
		$selection = $bgtalents ? $temp_max : $selection;

		# If skill does not have a cost at all in costhash,
		# it will be added there after figuring out the cost
		my $cost = &totalToX($guild, $pre, $orig_talent, $race, $type);
		if (not defined $totalcost{$orig_talent}) {
			$cost = $bgtalents ? 0 : ($maximum < $pre ?
				&totalToX($guild, $maximum, $orig_talent, $race, $type) :
				&totalToX($guild, $pre, $orig_talent, $race, $type));
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
	return (formatTalentsOutput($guild, $type."s", $bgtalents, @array), $guildcost);
}




#####################################################################
#
# formatTalentsOutput - Formats the given data
#
# Params      - Guild, skill/spell, bgskills, array
#               array = (skillname, select, max, cost)
#
# Returns     - HTML with big div with skills/spell etc
#
#####################################################################

sub formatTalentsOutput {
	my $guild = ucfirst shift || 'error';
	my $type = ucfirst shift || 'errors';
	my $bgs = shift || 0;
	my @array = @_;
	my $output = "";
	my ($type2, $guild2) = (lc $type, lc $guild);
	my $verb = $type2 eq "skills" ? "Train" : "Study";

	my $span_width = $params{'hide_expcosts'} eq "no" ? 3 : 4;
	my ($cost_hide_open, $cost_hide_close) = $params{'hide_expcosts'} eq "yes" ? ("", "") : ("<!--","-->");

	my %maxallhash = (
		"0"		=> "-",
		"1"		=> "Racialmax",
		"2"		=> "Guildmax",
		"10"	=> "10%",
		"20"	=> "20%",
		"30"	=> "30%",
		"40"	=> "40%",
		"50"	=> "50%",
		"60"	=> "60%",
		"70"	=> "70%",
		"80"	=> "80%",
		"90"	=> "90%",
	);


	return $output
		if ($guild eq "Error" || $guild eq 'none' || $type eq "Errors");


	# Creating train/study all to xx select
	my $maxall_html = qq|<select name="$type2\_maxall_$guild2">\n|;
	for my $maxto (sort {$a<=>$b} keys %maxallhash) {
		$maxall_html .= qq|<option value="$maxto">$maxallhash{$maxto}</option>\n|;
	}
	$maxall_html .= qq|</select>\n|;


	$output .= qq|\n<table class="reincsim-guild">\n|;
	$output .= qq|<tr><td colspan="$span_width"><h3>$guild $type</h3></td></tr>\n|;
	$output .= qq|<tr><td colspan="$span_width">$verb all $type2 in this guild to $maxall_html?</td></tr>\n| unless $bgs;
	$output .= qq|<tr class="reincsim-guild-header"><td>$type</td><td>Choose</td><td>Max</td>$cost_hide_open<td>Expcost</td>$cost_hide_close</tr>\n|;


	for my $spec (@array) {
		my ($talent, $select, $max, $exp) = @$spec;
		my $talentlink = &getBatorgLink($talent, $type2);
		$exp = &verboseLargeNumbers($exp);
		$output .= qq|<tr><td>$talentlink</td><td align="right">$select</td><td>/&nbsp;$max%</td>$cost_hide_open<td class="reincsim-numbers">$exp&nbsp;xp</td>$cost_hide_close</tr>\n|;
	}
	$output .= qq|</table>\n|;

	return $output;
}




#####################################################################
#
# createGuildSpecials - Creates html for guild specials, like mage
#                       types, runemage shelf etc
#
# Params      - guild, any params as hash
#
# Returns     - "" if no specials, otherwise html & extracost
#
#####################################################################

sub createGuildSpecials {
	my $guild = shift;
	my %special_params = ( @_ );

	my $special = "";
	my $special_xpcost = 0;

	return ""
		unless ($guild);


	# Mage type costs
	if ($guild eq "Mages") {
		my @magetypes = (
			$params{'special_mages_type1'},
			$params{'special_mages_type2'},
			$params{'special_mages_type3'},
			$params{'special_mages_type4'},
			$params{'special_mages_type5'},
			$params{'special_mages_type6'},
			$params{'special_mages_type7'},
		);
		my $cost_factor = 0.2;
		my $this_type = &specialMageFindType($special_params{"talent"});
		my $exponent = 0;
		$exponent++ while ($magetypes[$exponent] ne lc$this_type);

		$special_xpcost = $special_params{"talent_cost"} *
			(1 + $cost_factor*$exponent);
	}


	# Runemages shelf
	if ($guild eq "Runemages") {
		my $previous = $params{'special_runemages_shelf'};
		my @shelf_range = 1..50;

		$special .= qq|Choose your shelf level: |;
		$special .= qq|<select name="special_runemages_shelf">\n|;

		for my $shelflevel (@shelf_range) {
			my $xp_cost = &specialShelfCost($shelflevel);
			my $prev_select = "";
			if ($shelflevel == $previous) {
				$prev_select = " selected=\"selected\"";
				$special_xpcost = $xp_cost;
			}
			$special .= qq|<option value="$shelflevel"$prev_select>$shelflevel slots - $xp_cost xp</option>\n|;
		}
		$special .= qq|</select>\n\n|;
	}

	return ($special, $special_xpcost);
}




#####################################################################
#
# hideSomethingHtml - makes a select box with yes no choises with
#                     given name
#
# Params      - Selection name, previous choise, invert
#
# Returns     - Nice select clause
#
#####################################################################

sub hideSomethingHtml {
	my $name = shift;
	my $prev_choise = shift || 'no';
	my $invertchoise = shift || 0;
	my ($sel_yes, $sel_no) = $prev_choise eq "yes" ? (" selected=\"selected\"", "") : ("", " selected=\"selected\"");

	if ($invertchoise) {
		my $temp = $sel_yes;
		$sel_yes = $sel_no;
		$sel_no = $sel_yes;
	}

	my $html = <<until_end;
<select name="hide_$name">
<option value="no"$sel_no>No</option>
<option value="yes"$sel_yes>Yes</option>
</select>
until_end

	return $html;
}




#####################################################################
#
# sortbyHtml - makes a select box with game/alpha choises
#
# Params      - Selection name, previous choise
#
# Returns     - Nice select clause
#
#####################################################################

sub sortbyHtml {
	my $name = shift;
	my $prevchoise = shift || 'alpha';
	my ($sel_game, $sel_alpha) = $prevchoise eq 'game' ? (" selected=\"selected\"", "") : ("", " selected=\"selected\"");

	my $html = <<until_end;
<select name="sortby">
<option value="game"$sel_game>Cost</option>
<option value="alpha"$sel_alpha>Alpha</option>
</select>
until_end

	return $html;
}



#####################################################################
#
# getBatorgLink - returns link to bat.org's skill/spell help page
#
# Params      - Skill/spell and type
#
# Returns     - Link or talent name if links disabled
#
#####################################################################

sub getBatorgLink {
	my $talent = shift;
	my $type = shift || "skill";
	return "" unless ($talent);
	return $talent if ($params{'hide_helps'} eq "yes");
	$talent = ucfirst $talent;

	my $talent2 = $talent;
	$talent2 =~ s/^\s+|\s+$//g;
	$talent2 =~ tr/A-Z /a-z_/;
	$talent2 =~ tr/_/\+/ if ($type eq 'quests');
	my $baseaddr = qq|http://www.bat.org/help/$type.php?str=$talent2|;
	my $link = qq|<a href="$baseaddr" target="_blank">$talent</a>|;

	return $link;
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
	my ($maxrac, $max, $talent) = @_;

	#&modifyRacialCost(&firstPercent($level, $cost, $maxracial, $maxlevel, $talent), $modif);
	#print STDERR "\n ----- First percent for: $talent\n";

	if ($prev_cost =~ m|n/a| || $from >= $max) {
		#print STDERR "talent '$talent', prev '$prev_cost', maxrac '$maxrac', max '$max', aborting\n";
		return 0;
	}

	while ($from >= 1) {
		my $ratio = &getRatio($from--);
		$prev_cost /= ($ratio / 100.0 + 1);

		#print STDERR "$from % : $prev_cost\n" if (defined $talent && $talent =~ /claw/i);
	}

	return int($prev_cost);
}


#####################################################################
#
# get50th - "Calculates" cost of 51%st percent, which seems to be
#           close to 100+cost/10 times to cost of first percent.
#
# Params  - Basecost, must been modified with racial beforehand
#
# Returns - Cost of 51st percent cost
#
#####################################################################

sub get50th {
	my $cost = shift || 0;
	return ($cost*(100+$cost/10));
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
	my $guild = shift || '';
	my $tgt_percent = shift || 0;
	my $skillspell = shift || 'word of recall';
	my $race = shift || 'human';
	my $type = shift || 'skill';
	my $nomax = shift || 0;
	my $ss_max = shift || 0;
	my $talentcost = &getTalentCost($race, $type) || 100;
	my $basecost = &getBaseCost(lc $skillspell) || 0;

	if ($skillspell =~ /^(str|dex|con|int|wis)$/i) {
		return &getSocietyCost(0, $tgt_percent);
	}

	# If it was previously cached, use that cache info
	return int($totalcostcache{(lc $skillspell).",$tgt_percent"})
		if (defined $totalcostcache{(lc $skillspell).",$tgt_percent"});

	my $talent2 = $skillspell; $talent2 =~ tr/A-Z /a-z_/;
	my $maxtalent = $type eq "spell" ? $stat_spell : (&isTalentArcane($talent2) ? 100 : $stat_skill);
	my $totalcost = 0;


	# Magetypesupport
	my $typenro = &isMageTypeTalent($talent2);
	if ($typenro > 0 && $guild eq "mages") {
		$basecost *= (1.0 + 0.2*$typenro);
	}

    # Basecost modified by talentcost (0.85 to adjust human, and 3% cutoff)
    my $prev_cost = 1.0 * $basecost * $talentcost / 100;
    for my $percent (1..$tgt_percent) {
		my $ratio = &getRatio($percent, $type, $basecost, $talent2);
	 	my $talratio = (($talentcost-100)**2)/400;
	 	$ratio += 4 if ($percent > $maxtalent);
	 	$ratio += $talratio if ($percent > $maxtalent && $basecost > 120);
	 	$ratio += ($percent == ($maxtalent+1) ? 118 : 0);
	 	$ratio += $type eq "spell" ? 0.125 : -0.225;
	 	my $thiscost = $prev_cost * ($ratio/100.0 + 1);

		$totalcost += int($thiscost);
		$prev_cost = $thiscost;

		# Add info to cache
		if (($percent % 5) == 0) {
			$totalcostcache{(lc $skillspell).",$percent"} = $totalcost;
		}
	}

	return int($totalcost);
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

#sub modifyCost {
#	my $cost = shift;
#	my $skillcost = shift || 100;
#	my $no_max_cost = shift || 0;
#	my $ss_limit = shift || 0;
#	my $totalcost = int($cost);
#
#	$totalcost = ($totalcost > 2000000 ? 2000000 : $totalcost) if ($ss_limit);
#
#	return $totalcost;
#}




#####################################################################
#
# modifyRacialCost - Modifies the cost by racial costfactor
#
# Params      - Cost, race's skill/spellcost
#
# Returns     - Modified cost
#
#####################################################################

sub modifyRacialCost {
	my $cost = shift;
	my $skillcost = shift || 100;

	return int($cost * 100.0 / $skillcost);
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
	my $ignore_nun_stuff = shift || 0;

	my ($fix_skills, $fix_spells) = (100, 100);
	my $current_level = 1;

	# If guild not found, quit
	my $fh = new IO::File "data/guilds/$guild.txt", "r";
	return () unless $fh;

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
			$minhash{$3} = $4;
			next;
		}
	}

	# nun limits
	if ($guild =~ /^nun/i && !$ignore_nun_stuff) {
		&loadNunTasks();
		my ($max_sk, $max_sp, $max_min) = &lookForGuildMax('nuns', 35, 1);

		# go thru tasks and reduce the trainable amount
		for my $task (sort keys %nun_tasks) {
			my $lctask = lc$task;
			$lctask =~ tr/[a-z]//cd;

			unless ($params{"nuntask_$lctask"}) {
				my @bonuses = split/;/, $nun_tasks{$task};
				for my $bon (@bonuses) {
					my ($tgt, $amt) = split/:/, $bon;
					$max_sk->{$tgt} -= $amt if (defined $max_sk->{$tgt});
					$max_sp->{$tgt} -= $amt if (defined $max_sp->{$tgt});
				}
			}
		}

		# taking the one in account thats proper
		for my $sk (keys %maxskills) {
			$maxskills{$sk} = &min($maxskills{$sk}, max(0, $max_sk->{$sk}));
		}
		for my $sp (keys %maxspells) {
			$maxspells{$sp} = &min($maxspells{$sp}, max(0, $max_sp->{$sp}));
		}
	}

	# Return references
	return (\%maxskills, \%maxspells, \%minhash);
}




#     Must pass 1 out of the following:
#       * Has studied spell [75]Light to at least 40%
#       * Has studied spell [76]Darkness to at least 40%
#              Has trained skill [77]Cast generic to at least 30%
#              May study spell [78]Chill touch to 15%


#     May train skill [831]Combat damage analysis to 90%, special
#   requirements:
#       * Has trained skill [832]Consider to at least 40%
#             May train skill [833]Enhance criticals to 65%

sub beta_lookForGuildMax {
	my $guild = shift || 'foo';
	my $level = shift || 50;
	my ($fix_skills, $fix_spells) = (100, 100);
	my $current_level = 1;

	$html_debug .= qq|lookForGuildMax(): ($guild, $level)<br />\n|;

	# If guild not found, quit
	my $fh = new IO::File "data/guilds/$guild.txt", "r";
	return () unless $fh;

	$html_debug .= qq|lookForGuildMax(): file for '$guild' was found<br />\n|;

	# Init some hashes for our results
	my %maxskills = ();
	my %maxspells = ();
	my %minhash = ();
	my %skillreq = ();
	my %spellreq = ();
	my %levelreq = ();

	# statesaving
	my $mustpass = 0;
	my ($musttrain, $muststudy) = ("", "");

	# Lets loop through the file
	while (my $line = <$fh>) {
		#print STDERR $line if ($guild =~ /reaver|tarmalen/i);

		# If line is FIX num num, those numbers are used to fix the
		# information (tigers/spiders are hidden guilds and do not
		# have webpages (which have correct information)
		($fix_skills, $fix_spells) = ($1, $2)
			if ($line =~ /^FIX (\d+) (\d+)$/);

		# print STDERR "matching level\n";
		# If line reads Level something, we capture it and if the level
		# is higher than our target level, we're done!
		if ($line =~ /^\s+Level (\d+):?/) {
			$current_level = $1;
			last if ($1 > $level);
		}

		# If its level requirement, one of many choises
		# print STDERR "matching level req thingie\n";
		if ($line =~ /^\s+Must pass (\d+) out of the following:/) {
			$mustpass = $1;
			next;
		}

		# level requirement
		#print STDERR "matching level req thingie 2\n";
		if ($mustpass > 0 && $line =~ /^\s+\* Has (train|studi)ed (skill|spell) \[\d+\](.*?) to at least (\d+)%/) {
			my $key="$guild,$current_level,$mustpass";
			$levelreq{$key} .= defined $levelreq{$key} ? ",$2_$3_$4" : "$2_$3_$4";
			#print STDERR "saving levelreq: guild= $guild, level= $current_level, mustpass= $mustpass = $2_$3_$4\n";
			$mustpass++;
		}
		$mustpass--;

		# training requirement
		#print STDERR "matching train req\n";
		if (defined $musttrain && length ($musttrain) > 0 &&
			$line =~ /^\s+\* Has trained skill \[\d+\](.*?) to at least (\d+)%/) {
			$skillreq{"$musttrain,$maxskills{$musttrain},$1"} = $2;
			#$skillreq{"$guild,$musttrain,$maxskills{$musttrain}"} = "$1_$2";
			#print STDERR "saving trainreq: guild= $guild, musttrain= $musttrain, max= $maxskills{$musttrain} = $1_$2\n";
			#print STDERR "*** Must train $1 to $2 to be able to train $musttrain to $maxskills{$musttrain}\n";
			next;
		}

		# training requirement
		#print STDERR "matching study req\n";
		if (defined $muststudy && length ($muststudy) > 0 &&
			$line =~ /^\s+\* Has studied spell \[\d+\](.*?) to at least (\d+)%/) {
			$spellreq{"$muststudy,$maxspells{$muststudy},$1"} = $2;
			#$spellreq{"$guild,$muststudy,$maxspells{$muststudy}"} = "$1_$2";
			#print STDERR "saving studyreq: guild= $guild, muststudy= $muststudy, max= $maxspells{$muststudy} = $1_$2\n";
			#print STDERR "*** Must study $1 to $2 to be able to study $muststudy to $maxspells{$muststudy}\n";
			next;
		}

		# If matches may train to xxx %, do math
		# May train skill [26]Discipline to 20%
		if ($line =~ /^\s+(May train|Gains) skill \[\d+\]?(.*) to (\d+|racial maximum)\%?(, special)?/i) {
			my $thistrain = ($3 eq "racial maximum" ? 100 : $3);
			$maxskills{$2} = ceil($thistrain*100/$fix_skills);
			$maxskills{$2} = 100 if ($3 eq "racial maximum");
			$musttrain = "$2" if (defined $4 && $4 eq ", special");
			#print STDERR "can train $2 to $3\n";
			#print STDERR "saving musttrain: $2\n" if (defined $4 && $4 eq ", special");
			next;
		}

		# If matches may study to xxx %, do math
		if ($line =~ /^\s+(May study|Gains) spell \[\d+\]?(.*) to (\d+|racial maximum)\%?(, special)?/i) {
			my $thistrain = ($3 eq "racial maximum" ? 100 : $3);
			$maxspells{$2} = ceil($thistrain*100/$fix_spells);
			$maxspells{$2} = 100 if ($3 eq "racial maximum");
			$muststudy = "$2" if (defined $4 && $4 eq ", special");
			#print STDERR "saving muststudy: $2\n" if (defined $4 && $4 eq ", special");
			next;
		}

		# If matches may train to racial maximum (which is old style), automate as 100%
		if ($line =~ /^\s+May train skill \[.*\](.*) to racial/i) {
			$maxskills{$1} = 100; next;
		}

		# If matches may study to racial maximum (which is old style), automate as 100%
		if ($line =~ /^\s+May study spell \[.*\](.*) to racial/i) {
			$maxspells{$1} = 100; next;
		}

		# If matches requirements string, put into requhash
		if ($line =~ /^\s+Has (trained skill|studied spell) (\[.*\])?(.*) to at least (\d+)%/i) {
			$minhash{$3} = $4;
			next;
		}
	}

	#print STDERR "skills:\n";
	#foreach my $tmp (sort keys %maxskills) {
	#	print STDERR "skill: $tmp: $maxskills{$tmp}\n";
	#}

	#print STDERR "spells:\n";
	#foreach my $tmp (sort keys %maxspells) {
	#	print STDERR "spell: $tmp: $maxspells{$tmp}\n";
	#}

	# Lets see what we gathered
	#foreach my $tmp (sort keys %skillreq) {
	#	my ($skill, $skill_max, $req) = split/,/,$tmp;
	#	my $req_min = $skillreq{$tmp};
	#	print STDERR "To train $skill:$skill_max\%, you need $req:$req_min\%\n";
	#}

	#foreach my $tmp (sort keys %spellreq) {
	#	my ($spell, $spell_max, $req) = split/,/,$tmp;
	#	my $req_min = $spellreq{$tmp};
	#	print STDERR "To study $spell:$spell_max\%, you need $req:$req_min\%\n";
	#}

	# $levelreq{"$guild,$current_level,$mustpass"} = "$2_$3_$4";
	#foreach my $tmp (sort keys %levelreq) {
	#	my ($guild, $level, $mustpass) = split/,/,$tmp;
	#	my @choises = split/,/,$levelreq{$tmp};
	#	print STDERR "To advance level $level, you need $mustpass of:\n";
	#	for my $tmp2 (sort @choises) {
	#		my ($tmp3, $req, $req_min) = split/_/,$tmp2;
	#		print STDERR "  $req:$req_min\%\n";
	#	}
	#}

	# Return references
	return (\%maxskills, \%maxspells, \%minhash );#, \%skillreq, \%spellreq, \%levelreq);
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
	my $hlevel = $guildlevelshash{$guild};

	return $hlevel if ($maxmax && defined $hlevel);
	return ($hlevel < $given_level ? $hlevel : $given_level) if (defined $hlevel);

	my $fh = new IO::File "data/guilds/$guild.txt", "r";
	return 0 unless $fh;

	while (my $line = <$fh>) {
		$level = $2	if ($line =~ /^(\s{32,}|\s)Level (\d+):?/);
	}

	$guildlevelshash{$guild} = $level;

	return $level if ($maxmax);
	return $level < $given_level ? $level : $given_level;
}




#####################################################################
#
# loadRacialInformation - Loads racial information into hash
#
# Params      - None
#
# Returns     - None
#
#####################################################################

sub loadRacialInformation {
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
# loadBaseCosts - Loads basecosts into hash
#
# Params      - None
#
# Returns     - None
#
#####################################################################

sub loadBaseCosts {
	return if ((keys %basecosthash) > 1);

	my $file1 = new IO::File "data/spell_basecosts.txt", "r";
	my $file2 = new IO::File "data/skill_basecosts.txt", "r";
	die "Filehandle is broken, raceinfo data not found.\n"
		unless ($file1 && $file2);

	my @lines1 = <$file1>;
	my @lines2 = <$file2>;
	foreach my $line (@lines1, @lines2) {
		chomp $line;
		my @costinfo = split/\s{2,}/, $line;
		$basecosthash{lc $costinfo[0]} = $costinfo[1];
	}

	# We'll insert stat costs too
	$basecosthash{"str"} = 33625;
	$basecosthash{"dex"} = 33625;
	$basecosthash{"con"} = 33625;
	$basecosthash{"int"} = 33625;
	$basecosthash{"wis"} = 33625;
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

	&loadRacialInformation()
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

	&loadRacialInformation()
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
	&loadBaseCosts();

	return $basecosthash{lc $talent};
}




#####################################################################
#
# getSocietyCost - Returns cost for training stat to something
#
# Params      - from, to
#
# Returns     - expcost
#
#####################################################################

sub getSocietyCost {
	my $from = shift || 0;
	my $to = shift || 0;

	if ($from > $to) {
		my $temp = $from;
		$from = $to;
		$to = $temp;
	}
	return 0 if ($from == $to || $to == 0);

	&loadSocietyCosts();
	my $cost1 = $societycosthash{"$from"} || 0;
	my $cost2 = $societycosthash{"$to"} || 0;

	return ($cost2 - $cost1);
}


sub getAbilityCost {
	my $ability = shift;
	my $percent = shift || 0;
	return 0 unless ($ability && $percent > 0);

	&loadAbilities();

	my ($total, $fullname) = split/;/, $abilitieshash{$ability};
	return ($total * $percent / 100);
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
	return $info[$infoindexhash{'siz'}]
		if ($stat eq "siz");

	# exprate only dependant on exp boon
	return ($info[$infoindexhash{'exprate'}] + $boonbonus)
		if ($stat eq "exp");

	# Calculating the stat
	my $total = (&calculateRacialTrainMax($race, $stat))[0] + $trainbonus +
		$boonbonus + $superboon + $ssbonus + $raceguildbonus + $eqbonus;

	# Going thought guild levels and giving bonuses from guilds,
	# modified to suit the level/total level ratio of course
	for my $guild (sort keys %$gref) {
		my $bonref = $bonuses{$guild};
		my $gbonus = $bonref->{$stat} || 0;
		$gbonus = int($gbonus * 0.9)
			if ($guild eq $bg);
		my $glevel = $gref->{$guild} || 0;
		my $gmax = guildMaxLevel($guild, $glevel, 1) || 30;

		$total += int($gbonus * $glevel / $gmax);
	}

	return $total;
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
			if ($cntr++ % 3 == 0 && (scalar @elements) >= $cntr);
		unshift @new_string, $element;
	}

	my $new_str = join("", @new_string);
	$new_str =~ s/&nbsp;$//g;

	return $new_str;
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
	my $hashref = shift;
#	my %parhash = ();

	return () unless (-e $file);

	my $handle = new IO::File $file, "r";
	while (my $line = <$handle>) {
		chomp $line;
		next unless ($line =~ /^(\w+):\s(.+)$/);
		$hashref->{$1} = $2;
	}

#	return %parhash;
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

		# couple things cannot be saved, or they'll fuck up things on reload
		next if ($key =~ /maxall/);
		next if ($key eq "cp");

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

	&loadArcaneSkills();
	return $arcanehash{$talent} if (defined $arcanehash{$talent});

	# return 0 for those couple specials
	for my $regex (@non_arcane_skills) {
		if ($talent =~ m#$regex#i) {
		$arcanehash{$talent} = 0;
		#$html_debug .= qq|isTalentArcane(): '$talent' found in non-arcane list<br />\n|;
		return 0;
		}
	}

	# return 1 for the rest of matching
	for my $regex (@arcane_skills) {
		if ($talent =~ m#$regex#i) {
			$arcanehash{$talent} = 1;
			#$html_debug .= qq|isTalentArcane(): '$talent' found in arcane list<br />\n|;
			return 1;
		}
	}

	# the rest aren't arcane
	$arcanehash{$talent} = 0;
	return 0;
}




#####################################################################
#
# isMageTalent - Checks if spell/skills is one of mage type talents
#
# Params      - Talent
#
# Returns     - No. of type (if mages), 0 if not
#
#####################################################################

sub isMageTypeTalent {
	my $talent = shift || "foo";
	$talent =~ tr/A-Z /a-z_/;

	#my $cnt = 0;
	#for (1..6) { $cnt++ if (&getParam{"guild$_"} eq "mages"); }
	#return 0 if ($cnt == 0);

	&loadMageTypes();

	if (defined $mage_types{$talent}) {
		my @typearray = (
			$params{'guildspecial_mages_type0'} || 'acid',
			$params{'guildspecial_mages_type1'} || 'asphyx',
			$params{'guildspecial_mages_type2'} || 'cold',
			$params{'guildspecial_mages_type3'} || 'elec',
			$params{'guildspecial_mages_type4'} || 'fire',
			$params{'guildspecial_mages_type5'} || 'mana',
			$params{'guildspecial_mages_type6'} || 'poison',
		);
		my $type = $mage_types{$talent};

		my $typenro = 0;
		for my $type2 (@typearray) {
			if (lc$type eq lc$type2) {
				#print STDERR "Talent '$talent' is of type '$type' and its number '$typenro'!\n";
				return $typenro;
			}
			$typenro++;
		}

		#print STDERR "Talent '$talent' was in magetypes, yet no typenumber found!\n";
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
	return if ((keys %lq_hash) > 10);

	my $handle = new IO::File "data/quests.txt", "r";
	return unless ($handle);

	while (my $line = <$handle>) {
		$line =~ tr/\x0A\x0D//d;

		# lq:  2 : quest room                   / easy (1)
		if ($line =~ /^\s*lq:\s+(\d+) : (.*?)\s* \/ ([a-zA-Z ]+) \((\d+)\)$/) {
			my $key = sprintf("%02d", $1);
			if (defined $lq_hash{$key}) { $key .= "_2"; }
			$lq_hash{$key} = join("|", (ucfirst $2, $3, $4*2));
		}

		# aq : 1 : a day at the circus          / easy (1)
		if ($line =~ /^\s*aq:\s+(\d+) : (.*?)\s* \/ ([a-zA-Z ]+) \((\d+)\)$/) {
			$aq_hash{"$2"} = join("|", ($3, $4*2));
		}

	}
}



#####################################################################
#
# loadSocietyCosts - Loads costs to train stats in societys
#
# Params      - None
#
# Returns     - None
#
#####################################################################

sub loadSocietyCosts {
	return if ((keys %societycosthash) >= 40);

	my $fh = new IO::File "data/society_statcosts.txt", "r";
	while (my $line = <$fh>) {
		chomp $line;
		next if (length($line) < 20);

		my ($exp, $to) =
			$line =~ /^It would cost (\d+) exp to train your \w{3,3} bonus from \d+ to (\d+)\./;
		next unless (defined $exp && defined $to);
		$societycosthash{"$to"} = $exp;
	}
}



#####################################################################
#
# loadArcaneSkills - Loads list of skills that are and are not
#                    arcane
#
# Params      - None
#
# Returns     - None
#
#####################################################################

sub loadArcaneSkills {
	return if ((scalar @arcane_skills) > 1);

	# load arcane skills
	my $fh = new IO::File "data/arcane_skills.txt", "r";
	while (my $line = <$fh>) {
		$line =~ tr/\x0A\x0D//d;
		next if (length($line) < 5);
		push @arcane_skills, $line;
		#$html_debug .= qq|loadArcaneSkills(): arcane '$line' found<br />\n|;
	}
	undef $fh;

	# load non arcane skills
	$fh = new IO::File "data/nonarcane_skills.txt", "r";
	while (my $line = <$fh>) {
		$line =~ tr/\x0A\x0D//d;
		next if (length($line) < 5);
		push @non_arcane_skills, $line;
		#$html_debug .= qq|loadArcaneSkills(): nonarcane '$line' found<br />\n|;
	}
	undef $fh;
}




#####################################################################
#
# loadAbilities - Loads abilities into hash
#
# Params      - None
#
# Returns     - None
#
#####################################################################

sub loadAbilities {
	return if ((keys %abilitieshash) > 10);

	my $fh = new IO::File "data/abilities.txt", "r";
	my @content = <$fh>;
	for my $line (@content) {
		next unless (length($line) > 10 && $line =~ /^\|\s*[a-z]/);
		chomp $line;

		my ($ability, $total, $total_100, $shortname) = $line =~ /^\|\s*([a-z \-\&]+) \|.*?\|\s*(\d+)\.(\d+)M \|.*?\| (\w+)$/;
		$abilitieshash{$shortname} = (($total*100+$total_100) * 10000).";$ability";
	}
}



#####################################################################
#
# getRatio - Loads ratios for exp-expense and return the costs
#
# Params      - None
#
# Returns     - None
#
#####################################################################

sub getRatio {
	my $tgt = shift || 0;
	my $type = shift || "skill";
	my $basecost = shift || 50;
	my $talent = shift || "consider";

	my ($ratref, $file);

	if ($type eq "skill" && $basecost <  90) {$ratref = \%ratios_skills1; $file="skills1";}
	if ($type eq "skill" && $basecost >= 90) {$ratref = \%ratios_skills2; $file="skills2";}
	if ($type eq "spell" && $basecost <  75) {$ratref = \%ratios_spells1; $file="spells1";}
	if ($type eq "spell" && $basecost >= 75) {$ratref = \%ratios_spells2; $file="spells2";}
	#if ($type eq "skill") {$ratref = \%ratios_skills1; $file="cg";}
	#if ($type eq "spell") {$ratref = \%ratios_spells1; $file="dd";}


	return $ratref->{$tgt}
		if (defined $ratref->{$tgt});

	my $fh = new IO::File "data/ratios_$file\.txt", "r";
	return "1.08" unless ($fh && $tgt);

	while (my $line = <$fh>) {
		 # 1%: ratio=  2.105 (    190 ->     194)
		 my ($thisperc, $ratio) = $line =~ /\s*(\d+)%: ratio=\s+([0-9.]+)/;
		 next unless ($thisperc && $ratio);
		 $ratref->{$thisperc} = $ratio;
	}

	# #print STDERR "returning ratio $ratios{$tgt}\n";
	return $ratref->{$tgt} || "1.08";
}




#####################################################################
#
# getParam - Returns content if params hash if key is defined
#
# Params      - Id, numeric 0 for 0, "" for 1
#
# Returns     - Stuff in params hash
#
#####################################################################

#sub getParam {
#	my $id = shift;
#	my $numeric = shift || 0;
#	return undef unless (defined $id);
#
#	unless (defined $params{$id}) {
#		return 0 if ($numeric);
#		return "";
#	}
#
#	return $params{$id};
#}




#####################################################################
#
# removeDuplicates - Simply removes duplicates from array
#
# Params      - None
#
# Returns     - None
#
#####################################################################

sub removeDuplicates {
	my %hashy = ();
	$hashy{$_} = 1 for (@_);
	return sort keys %hashy;
}



sub specialMageFindType {
	my $talent = shift;
	return "" unless ($talent);

	&loadMageTypes()
		unless (scalar keys %mage_types);

	$talent =~ tr/A-Z /a-z_/;
	for my $skillspell (keys %mage_types) {
		return $mage_types{$skillspell} if ($skillspell eq $talent);
	}

	return "";
}


sub loadMageTypes {
	return if ((keys %mage_types) > 3);

	#print STDERR "Loading magetypes, currently ".(scalar keys %mage_types)." keys in hash.\n";

	my $fh = new IO::File "data/extras/special_mages_types.txt", "r";
	return unless ($fh);

	while (my $line = <$fh>) {
		chomp $line;
		next unless ($line =~ /^([a-z_]+)=([a-z]+)/);
		$mage_types{$1} = $2;
	}

	return;
}


#,------------------------------------------------------------------.
#| Name: Convent's life                                             |
#| Rating: Ridiculously easy                                        |
#| Time to Complete: 5d                                             |
#| Extra equipment: No                                              |
#|------------------------------------------------------------------|
#| Bonuses                                                          |
#|    Cure serious wounds                                        13 |
#|    Stat wis                                                    2 |
#|    Cure light wounds                                          28 |
#|------------------------------------------------------------------|
#| Description                                                      |
#|   You must prove to the guild elders that you have               |
#|   familiarized nun's life by doing various things. After         |
#|   starting the task you have to visit following places:          |
#|   Abbess' office, Convent's shop, Healing room, Garden           |
#|   statue, Convent's library. You have to participate in one      |
#|   hour of prayer and turn atleast three(3) undeads. You have     |
#|   five days to fulfill these requirements.                       |
#|------------------------------------------------------------------|
#| Help                                                             |
#|   No special help available.                                     |
#`------------------------------------------------------------------'

sub loadNunTasks {
	return if ((keys %nun_tasks) > 3);

	#print STDERR "Loading nun quests\n";
	my @lines = split/\n/, &readFile('data/extras/nun_tasks.html');
	my $task = "";
	my @bonuses = ();
	my $reading_bonuses = 0;

	for my $line (@lines) {
		#print STDERR "Processing '$line'\n";

		# bonuses
		if ($reading_bonuses) {
			# putting them in array
			if ($line =~ m{^\|\s{4}([A-Z][a-z ]+)\s+(\d+) \|} && $1 && $2) {
				my ($tgt, $amt) = ($1, $2);
				$tgt =~ s/^\s+|\s+$//g;
				push @bonuses, "$tgt:$amt";

				$nun_bonuses{$tgt} = defined $nun_bonuses{$tgt} ?
					$nun_bonuses{$tgt}+$amt : $amt;
				#print STDERR "Found bonus '$tgt:$amt'\n";
				next;
			}

			# putting them in hash if end of reading
			if ($line =~ m#^\|\-{60,}\|#) {
				$nun_tasks{$task} = join(";", @bonuses);
				#print STDERR "Task '$task' complete with bonuses $nun_tasks{$task}\n";

				$task = "";
				$reading_bonuses = 0;
				@bonuses = ();
				next;
			}
		}

		# task name
		if ($line =~ m{^\| Name: (.*?)\s+\|}) {
			$task = $1;
			$task =~ s/^\s+|\s+$//g;
			#print STDERR "Found task '$task'\n";
			next;
		}

		# open of bonus
		if ($line =~ m{^\| Bonuses(\s+)\|} && $task ne "") {
			$reading_bonuses = 1;
			#print STDERR "Reading bonuses for '$task'\n";
			next;
		}
	}
}



#####################################################################
#
# specialShelfCost - Calculates the exp for level X shelf
#
# Params      - Slots in shelf
#
# Returns     - Xp cost of that many slots
#
#####################################################################

sub specialShelfCost {
	my $shelflevel = shift || 1;

	&loadShelfCosts()
		unless (scalar @shelf_costs);

	my $xp_cost = 0;
	for my $cost (sort {$b<=>$a} @shelf_costs) {
		$xp_cost += $cost;
	}

	return $xp_cost;
}





#####################################################################
#
# loadShelfCosts - Load shelf costs from file
#
# Params      - None
#
# Returns     - None
#
#####################################################################

sub loadShelfCosts {
	return if (@shelf_costs > 10);

	my $fh = new IO::File "data/extras/special_runemages_shelf.txt", "r";
	return unless ($fh);
	push @shelf_costs, 0;

	while (my $line = <$fh>) {
		chomp $line;

# |    500000 ....................   10 |
		if ($line =~ m/^\|\s*(\d+)\s\.{20}\s*(\d+)\s+\|$/) {
			push @shelf_costs, $1;
		}
	}

	return;
}




#####################################################################
#
# calculateRacialTrainMax - Calculates the racial'max' and starting
#                           number for stat
#
# Params      - Race, stat
#
# Returns     - Racemax, startvalue
#
#####################################################################

sub calculateRacialTrainMax {
	my $race = shift;
	my $stat = shift;
	return (0,0) unless ($stat && $race);

	my @raceinfo = &getRaceInfo($race);
	my $racmax = int($raceinfo[$infoindexhash{$stat}]);
	my $starts = int($racmax * 0.65);

	return ($racmax, $starts);
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
	my $race = shift;
	my $stat = shift;
	my $min_train = shift;
	my $max_train = shift;
	my $cost = 0;

	return 0 unless ($min_train && $race && $stat);
	#print STDERR "createTrainSelect: calling trainmax '$race', '$stat'\n";
	my ($racmax, $starts) = &calculateRacialTrainMax($race, $stat);
	my $basecost = 0;

	my ($min, $max) = ($min_train, $min_train);

	if ($max_train) {
		($min, $max) = ($min_train < $max_train ?
			($min_train,$max_train) : ($max_train,$min_train));
	}

	#print STDERR "calculateTrainCost: min '$min', max '$max', race '$race', stat '$stat', max '$racmax'\n";

	for my $range (keys %training_costs) {
		my ($rmin, $rmax) = split/\-/, $range;
		#print STDERR "trCost: range '$range', min '$min', max '$max', rminmax '$rmin/$rmax'\n";
		$basecost = $training_costs{$range}
			if ($racmax >= $rmin && $racmax <= $rmax);
	}


	#print STDERR "calculateTrainCost: basecost '$basecost'\n";

	my ($previous, $temp_cost) = (0, 0);
	my $this_cost = $basecost;
	for my $this ($min+1..$max) {
		$previous = $this_cost;
		$temp_cost = 1;

		# Racmax-2 has huge raise
		if ($this == $racmax-2) {
			$this_cost *= 1.35;
		}

		# 11th+ cost 15% more than previous
		if ($this >= $racmax+11) {
			my $varcost = ($this-($racmax+11)) * (0.07 / 15);
			$this_cost *= (1.0785+ ($varcost>0.07 ? 0.07 : $varcost));
			 #1.1485; old constant
			#print STDERR "calculateTrainCost: racmax+11 +15%\n";

		# 10 points after racmax are cheaper
		} elsif ($this >= $racmax && $this <= $racmax+10) {
			$this_cost *= (1.045+ ($this-$racmax)/200.0);
			#print STDERR "calculateTrainCost: cheaper 10: '$this_cost'%\n";

		# Below racemax values
		} else {
			$this_cost *= 1.0068+ $this/19000;
			#print STDERR "calculateTrainCost: else +1.25%\n";
		}

		$cost += int($this_cost*$temp_cost);
		#$previous = $this_cost;
	}

	#printf STDERR "calculateTrainCost: race '$race', stat '$stat', $starts/$racmax, $min -> $max, totalcost '$cost', last '%d', ratio '%5.3f%%'\n",
	#	$this_cost*$temp_cost, $previous > 0 ? ($this_cost*$temp_cost/$previous-1)*100 : 0.0;
	return int($cost * 1.05);
}




#####################################################################
#
# calculateGuildGoldCost - Calculates a guild gold cost
#
# Params      - Nothing :(
#
# Returns     - Cost in gold
#
#####################################################################

sub calculateGuildGoldCost {
	my $totalcost = 0;
	my $xth_level = 0;
	my $level_maxcost = 50000;

	for my $gld (1..6) {
		next unless (defined $params{"guild$gld"} && defined $params{"glevel$gld"});
		my $maxlevel = &guildMaxLevel($params{"guild$gld"}, $params{"glevel$gld"});

		if ($params{"glevel$gld"}>0 && not ($params{"guild$gld"} =~ m/^(none|secret|error)/i)) {
			#print STDERR "totalcost before guild $gld: $totalcost\n";
			for my $this_level (1..$maxlevel) {
				$xth_level++;
				if ($this_level == 1) {
					#print STDERR "level $this_level: free\n";
					next;
				}

				my $this_cost = ($xth_level * $xth_level) * 10;
				#print STDERR "level $this_level: $this_cost\n";
				$totalcost += ($this_cost > $level_maxcost ? $level_maxcost : $this_cost);
			}
			#print STDERR "totalcost after guild $gld: $totalcost\n";
		}
	}

	return $totalcost;
}




sub _diminishConBonus {
	my $stat = shift || 0;

	my $divider = 150.0;
	my $offset = 125;

	return 1 if (($stat - $offset) < 0);
	return 0.2 if ($stat >= ($divider+$offset));

	return (($divider+$offset-$stat)/($divider+max($stat-$offset*4/3, 0)));
}

sub calculateHp {
	my $race = shift;
	my $bg = shift;
	my $con = shift;
	my $size = shift;

	my @raceinfot = &getRaceInfo($race);
	my $hpcon = $raceinfot[$infoindexhash{"hpratio"}];
	$hpcon = 3.0 if ($hpcon eq "-");
	my $bon = $hpbgbonus_hash{$bg};


	# GUILD SPECIALS AFFECTING HP
	my $guild_hp = 0;
	$guild_hp += ($params{"guildspecial_bards_hp"} || 0);
	$guild_hp += ($params{"guildspecial_spiders_hp"} || 0);


	# hp
	my $hpmax = $bon;
	for my $num (1..$con) {
		my $ratio = &_diminishConBonus($num);
		$ratio = (1+$ratio)/2 if ($bg eq "nomad");
		$hpmax += $ratio * $hpcon;
	}
	$hpmax += $size*2.1;
	return int($hpmax + $guild_hp);
}


sub _diminishCasterBonus {
	my $stat = shift || 0;

	my $divider = 200.0;
	my $offset = 225;

	return 1 if (($stat - $offset) < 0);
	return 0.1 if ($stat >= ($divider+$offset));

	return (($divider+$offset-$stat)/($divider+max($stat-$offset*4/3, 0)));
}

sub calculateSp {
	my ($race, $bg, $int, $wis) = @_;
	my %bonuses = (
		   "301" => 60,
		   "351" => 80,
		   "401" => 100
		   );

	my %racial = (
		  "vampire" => 0.07,
		  "thrikhren" => 0.03,
		  "duck" => 0.02,
		  "lich" => -0.03,
		  "elf" => -0.04,
		  "tinmen" => -0.04,
		  "wolfman" => -0.10,
		  "kobold" => -0.12,
		  );

	# base bonus and int/wis multipliers
	my $bg_bonus = $spbgbonus_hash{$bg};
	my $int_bon = $spbgbonus_hash{$bg."_int"};
	my $wis_bon = $spbgbonus_hash{$bg."_wis"};
	my $spmax = $bg_bonus;

	# int
	for my $num (1..$int) {
		$spmax += &_diminishCasterBonus($num) * $int_bon;
		$spmax += $bonuses{$num} if (defined $bonuses{$num});
	}

	# wisdom
	for my $num (1..$wis) {
		$spmax += &_diminishCasterBonus($num) * $wis_bon;
		$spmax += $bonuses{$num} if (defined $bonuses{$num});
	}

	# racial multipliers
	if (defined $racial{$race}) {
		$spmax *= (1+$racial{$race});
	}



	# guild specials giving spmax
	my $guild_sp = 0;
	$guild_sp += ($params{"guildspecial_bards_sp"} || 0)
	if (&memberOfGuild("bards"));
	$guild_sp += ($params{"guildspecial_spiders_sp"} || 0)
	if (&memberOfGuild("spiders"));
	$guild_sp += ($params{"guildspecial_channellers_aura"} || 0) *
	($params{"skill_mastery_of_channelling"} || 0)
	if (&memberOfGuild("channellers"));


	return int($spmax + $guild_sp);
}



sub calculateEp {
	my ($str, $dex, $con) = @_;

	my $ep = 140 + $str/2 + $dex + $con/2;


	# GUILD SPECIALS AFFECTING EP
	my $guild_ep = 0;
	$guild_ep += ($params{"guildspecial_bards_ep"} || 0)
		if (&memberOfGuild("bards"));
	$guild_ep += ($params{"guildspecial_spiders_ep"} || 0)
		if (&memberOfGuild("spiders"));




	return (int($ep > 400 ? (400+($ep-400)/8) : $ep) + $guild_ep);
}



sub guildspecials {
	my $guild = shift || "";
	return "" unless (length($guild) > 3);

	my $guildspecial = "";


	# Nun guild special - tasks
	if ($guild =~ /^nun/i) {
		&loadNunTasks();
		$guildspecial = &guildspecialNuns();
	}



	# Bard guild special - instrument
	if ($guild =~ /^bard/i) {
		my $instru = $params{"guildspecial_bards_instru"} || "";
		my ($hp, $sp, $ep) = &guildspecialBards($params{"guildspecial_bards_hp"},
			$params{"guildspecial_bards_sp"}, $params{"guildspecial_bards_ep"});
		$guildspecial = <<until_end;
<table border="0" width="100%">
<tr>
<td><i>(Guild special)</i></td>
<td>Instrument: <input type="text" name="guildspecial_bards_instru" value="$instru" size="20" maxlength="50" /></td>
<td>Hp: $hp</td>
<td>Sp: $sp</td>
<td>Ep: $ep</td>
</tr>
</table>
until_end
	}



	# Spider guild special - demon
	if ($guild =~ /^spider/i) {
		my ($hp, $sp, $ep) = &guildspecialSpiders($params{"guildspecial_spiders_hp"},
			$params{"guildspecial_spiders_sp"}, $params{"guildspecial_spiders_ep"});
		$guildspecial = <<until_end;
<table border="0" width="100%">
<tr>
<td><i>(Guild special)</i></td>
<td>Demon bonuses:</td>
<td>Hp: $hp</td>
<td>Sp: $sp</td>
<td>Ep: $ep</td>
</tr>
</table>
until_end
	}



	# Channeller guild special - aura
	if ($guild =~ /^channeller/i) {
		my $auralevel = $params{'guildspecial_channellers_aura'} || 0;
		my $spaddon = $auralevel * ($params{'skill_mastery_of_channelling'} || 0);
		my $aura_html = &guildspecialChannellers($auralevel);

		$guildspecial = <<until_end;
<table border="0" width="100%">
<tr>
<td><i>(Guild special)</i></td>
<td>Aura level:</td><td>$aura_html</td>
<td><i>($spaddon spmax)</i></td>
</tr>
</table>
until_end
	}



	# Runemages guild special - shelf
	if ($guild =~ /^runemage/i) {
		my $slots = $params{"guildspecial_runemages_shelf"} || 0;
		my $shelf_html = &guildspecialRunemages($slots);
		my $expcost = $shelf_costs[$slots];

		$guildspecial = <<until_end;
<table border="0" width="100%">
<tr>
<td><i>(Guild special)</i></td>
<td>Shelf slots:</td><td>$shelf_html</td>
<td><i>(expcost: $expcost)</i></td>
</tr>
</table>
until_end
	}



	# Mages guild special - types
	if ($guild =~ /^mage/i) {
		my @typearray = (
			$params{'guildspecial_mages_type0'} || 'acid',
			$params{'guildspecial_mages_type1'} || 'asphyx',
			$params{'guildspecial_mages_type2'} || 'cold',
			$params{'guildspecial_mages_type3'} || 'elec',
			$params{'guildspecial_mages_type4'} || 'fire',
			$params{'guildspecial_mages_type5'} || 'mana',
			$params{'guildspecial_mages_type6'} || 'poison',
		);

		my @type_html = &guildspecialMages(@typearray);

		$guildspecial = <<until_end;
<table border="0" width="100%">
<tr>
<td><i>(Guild special)</i></td>
<td>Types:</td>
<td>1st: $type_html[0]</td>
<td>2nd: $type_html[1]</td>
<td>3rd: $type_html[2]</td>
<td>4th: $type_html[3]</td>
<td>5th: $type_html[4]</td>
<td>6th: $type_html[5]</td>
<td>7th: $type_html[6]</td>
</tr>
</table>
until_end
	}



	return $guildspecial;
}



sub guildspecialBards {
	my $prevhp = shift || 0;
	my $prevsp = shift || 0;
	my $prevep = shift || 0;

	my $hp_select = qq|<select name="guildspecial_bards_hp">\n|;
	for my $hp (0..20) {
		my $thishp = $hp*5;
		my $sel = ($prevhp == $thishp ? " selected=\"selected\"" : "");
		$hp_select .= qq|<option value="$thishp"$sel>$thishp</option>\n|;
	}
	$hp_select .= qq|</select>|."\n\n";


	my $sp_select = qq|<select name="guildspecial_bards_sp">|."\n";
	for my $sp (0..20) {
		my $thissp = $sp*5;
		my $sel = ($prevsp == $thissp ? " selected=\"selected\"" : "");
		$sp_select .= qq|<option value="$thissp"$sel>$thissp</option>\n|;
	}
	$sp_select .= qq|</select>|."\n\n";


	my $ep_select = qq|<select name="guildspecial_bards_ep">|."\n";
	for my $ep (0..20) {
		my $thisep = $ep*5;
		my $sel = ($prevep == $thisep ? " selected=\"selected\"" : "");
		$ep_select .= qq|<option value="$thisep"$sel>$thisep</option>\n|;
	}
	$ep_select .= qq|</select>\n|;

	return ($hp_select, $sp_select, $ep_select);
}


sub guildspecialChannellers {
	my $prevaura = shift || 0;
	my %auradesc = (
		"0"	=> "no aura",
		"1"	=> "yellow aura",
		"2"	=> "red aura",
		"3"	=> "blue aura",
	);
	my %aurareq = (
		"0"	=> "0",
		"1"	=> "20",
		"2"	=> "50",
		"3"	=> "95",
	);


	my $html = qq|<select name="guildspecial_channellers_aura">\n>|;

	for my $level (0..3) {
		my $sel = ($prevaura == $level ? " selected=\"selected\"" : "");
		my $fomnow = $params{"skill_flow_of_magic"} || 0;
		my $pass = ($aurareq{$level} > $fomnow ? " - ($fomnow\% FoM too low, need $aurareq{$level}\%)" : "");
		$html .= qq|<option value="$level"$sel>$level - $auradesc{$level}$pass</option>\n|;
	}
	$html .= qq|</select>\n|;

	return $html;
}


sub guildspecialRunemages {
	my $prevslots = shift || 0;
	&loadShelfCosts();

	my $html = qq|<select name="guildspecial_runemages_shelf">\n|;

	for my $slots (1..50) {
		my $sel = ($slots == $prevslots ? " selected=\"selected\"" : "");
		my $cost = $shelf_costs[$slots] || 0;

		$html .= qq|<option value="$slots"$sel>$slots - $cost xp</option>\n|;
	}
	$html .= qq|</select>\n|;

	return $html;
}


sub guildspecialMages {
	my @typeorder = @_;
	my @type_html = ();
	my @used_types = ();
	my @types_left = ('acid', 'asphyx', 'cold', 'elec', 'fire', 'mana', 'poison');

	my $counter = 0;
	for my $type (@typeorder) {
		my $html = qq|<select name="guildspecial_mages_type$counter">\n|;

		for my $type2 (sort @magetypes) {
			my $disptype = ucfirst $type2;
			my $sel = (lc$type eq lc$type2 ? " selected=\"selected\"" : "");
			$html .= qq|<option value="$type2"$sel>$type2</option>\n|;
		}
		$html .= qq|</select>\n|;

		$counter++;
		push @type_html, $html;
	}

	return @type_html;
}


sub guildspecialSpiders {
	my $prevhp = shift || 0;
	my $prevsp = shift || 0;
	my $prevep = shift || 0;

	my $hp_select = qq|<input type="text" name="guildspecial_spiders_hp" value="$prevhp" size="4" maxlength="4" />\n|;
	my $sp_select = qq|<input type="text" name="guildspecial_spiders_sp" value="$prevsp" size="4" maxlength="4" />\n|;
	my $ep_select = qq|<input type="text" name="guildspecial_spiders_ep" value="$prevep" size="4" maxlength="4" />\n|;

	return ($hp_select, $sp_select, $ep_select);
}




sub guildspecialNuns {
	my $link_to_html = qq|http://www.tomcrawford.info/fun/batmud/nun_tasks.htm|;

	my $html = <<until_end;
<h3>Nun tasks</h3>
<p>Find nun task info and bonuses from <a href="$link_to_html">Moss's nun info</a>.</p>

<table style="width: 100%;">
<tr><td colspan="4" align="right">
All tasks marked as completed:
<select name="maxall_nuntasks">
<option value="0">No</option>
<option value="1">Yes</option>
<option value="2">Clear</option>
</select>
</td></tr>
<tr><td>Task:</td><td>Completed:</td><td>Task:</td><td>Completed:</td></tr>
until_end

	my $cntr = 0;
	for my $task (sort keys %nun_tasks) {
		$html .= qq|<tr>| if ($cntr % 2 == 0);
		$html .= &guildspecialNunsTaskHtml($task);
		$html .= qq|</tr>| if ($cntr % 2 == 1);
		$cntr++;
	}
	$html .= qq|<td colspan="2">&nbsp;</td>| if ($cntr % 2 == 0);
	$html .= qq|</table>\n|;

	return $html;
}



sub guildspecialNunsTaskHtml {
	my $name = shift || "broken";
	my $lcname = lc $name;
	$lcname =~ tr/[a-z]//cd;
	my $prev = $params{"nuntask_$lcname"} || 0;

	my $yes_ok = ($prev == 1 ? qq| selected="selected"| : "");
	my $no_ok = ($prev == 0 ? qq| selected="selected"| : "");

	my $html = <<until_end;
<td>$name</td>
<td>
<select name="nuntask_$lcname">
<option value="0"$no_ok>No</option>
<option value="1"$yes_ok>Yes</option>
</select>
</td>
until_end

	return $html;
}




sub makeTitle {
	my $t_l = $levels_spent || "";
	my $t_r = ucfirst $params{'race'} || "";
	my $t_g1 = ucfirst $params{'guild1'} || "";
	my $t_g2 = ucfirst $params{'guild2'} || "";

	$t_g1 =~ s/.$//;
	$t_g2 =~ s/.$//;

	&setLayoutItem('title', "Level $t_l $t_r $t_g1$t_g2") if ($t_g1);
}



sub checkMaxall {
	my @maxall_list = (
		'nuntasks', #'quests'
	);

	for my $maxall_what (@maxall_list)  {
		my $checked = (defined $params{"maxall_$maxall_what"} && $params{"maxall_$maxall_what"} > 0) ? 1 : 0;
		next unless ($checked);

		# nun task maxall
		if ($maxall_what eq 'nuntasks') {
			&loadNunTasks();

			# if we clear them
			my $val = 1;
			$val = 0 if ($params{"maxall_$maxall_what"} == 2);

			for my $task (keys %nun_tasks) {
				my $lctask = lc $task;
				$lctask =~ tr/[a-z]//cd;
				$params{"nuntask_$lctask"} = $val;
			}
		}
	}


}


sub createReincSelect($) {
	my $user = shift;
	my $optlist = "";

	$optlist = &listUserReincs($user) if ($user && $login_ok);
	my $dis = ($login_ok && $user ? "" : ' disabled="disabled"');

	my $output = <<until_end;
<form action="reincsim/$SCRIPT" method="get">
<select name="id"$dis>
<option value="">-- Choose reinc to load --</option>
$optlist
</select>
<input type="submit" value="Load"$dis />
<input type="submit" value="Delete" name="delete"$dis />
</form>

until_end

	return $output;
}


sub listUserReincs($) {
	my $user = shift;
	my @reincs = &getDir('saved', "*.$user");
	my $output = "";

	for my $file (sort @reincs) {
		my %temp = ();
		&loadParams("saved/$file", \%temp);
		my $rid = $temp{'id'};

		my $r1 = ucfirst ($temp{'race'});
		my $g1 = ucfirst ($temp{'guild1'} ? $temp{'guild1'} : "");
		my $g2 = ucfirst ($temp{'guild2'} ? $temp{'guild2'} : "");

		$g1 =~ s/s$//;
		$g2 =~ s/s$//;

		my $title = $temp{'title'} ? $temp{'title'}." - " : "";
		$output .= qq|<option value="$rid">$title$r1 $g1$g2</option>\n|;
	}

	return $output;
}







# copies reinc from one to another
sub copyreinc {
	my $to_id = shift || return;
	my $from_id = shift || return;

	# taunt them
	$to_id =~ tr/[0-9]//cd;
	$from_id =~ tr/[0-9]//cd;

	return if (not (-e "saved/$from_id.db"));
	return if (-e "saved/$to_id.db");

	`cp saved/$from_id.db saved/$to_id.db`;
}


# copies reinc from one to another
sub deletereinc {
	my $which_id = shift || return;
	$which_id =~ tr/[0-9]//cd;

	unlink <saved/$which_id.*>;
}


# Given guildname, returns 1 or 0 if player has levels in the guild
sub memberOfGuild {
	my $guild = shift || return 0;

	for my $gnum (1..6) {
		return 1 if ( (defined $params{"guild$gnum"}) &&
					  ($params{"guild$gnum"} eq $guild) &&
					  ($params{"glevel$gnum"} > 0) );
	}

	return 0;
}


sub memberarray {
	my $item = shift || return -1;
	my @array = @_ || return -1;
	my $cntr = 0;

	for my $this (@array) {
		return $cntr if ($this eq $item);
		$cntr++;
	}

	return -1;
}

sub remfromarray {
	my $item = shift || return;
	my @array = @_ || return;
	my @retarr = ();

	for my $arritem (@array) {
		push @retarr, $arritem if ($item ne $arritem);
	}

	return @retarr;
}



sub cleanup {
	return;
}

sub cleanup_real {
	my $thisid = shift || "0000000000";
	return unless ($thisid =~ /^\d+$/);

	my $range = substr($thisid, 0, 2);
	my @files = `ls -l saved/$range????????.db`;
	map {chomp; s/^.{56,56}//g} @files;

	for my $file (@files) {
		my $maxtime = 365*24*60*60;
		my $lastedit = ((stat($file))[9]) || time();
		next if ($file eq "$thisid.db");
		`rm $file` if (($lastedit + $maxtime) < time());
	}
}






sub sorttalents {
	my $type = $params{'sortby'} || 'alpha';
	&loadBaseCosts();

	if ($type eq "game") {
		my $a_cost = $basecosthash{lc $a} || 0;
		my $b_cost = $basecosthash{lc $b} || 0;
		return ($a_cost <=> $b_cost) unless ($a_cost == $b_cost);
	}

	return ((lc$a) cmp (lc$b));
}



sub min {
	my ($a, $b) = @_;
	return $a unless defined $b;
	return $b unless defined $a;

	return $a if ($a < $b);
	return $b;
}


sub max {
	my ($a, $b) = @_;
	return $a unless defined $b;
	return $b unless defined $a;

	return $a if ($a > $b);
	return $b;
}



#####################################################################
#
# END OF SUBFUNCTIONS
#
#####################################################################







__END__

