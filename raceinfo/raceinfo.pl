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
use CGI qw/param/;
use IO::File;
use POSIX qw/ceil/;

# my stuff
# use lib '/home/twomi/web/libs';
use lib '/home/customers/tumi/public_html/archives/batmud';
use lib '/home/customers/tumi/tumilib';
use Tumi::Helper;
use BatmudTools::Site;
use BatmudTools::Layout;


my $point_of_site = &readFile('html/pointofsite.html');
my $fixlist = &readFile('html/fixlist.html');
my $buglist = &readFile('html/buglist.html');


my $VERSION = "1.1.0";

my %racehash = ();
my %datahash = ();
my @races = ();

my %verbose_stats = (
	"0"		=>	"no limits",
	"3"		=>	"pathetic",
	"6"		=>	"pitiful",
	"9"		=>	"sad",
	"12"	=>	"bad",
	"15"	=>	"tiny",
	"18"	=>	"little",
	"21"	=>	"meager",
	"24"	=>	"feeble",
	"27"	=>	"poor",
	"30"	=>	"paltry",
	"34"	=>	"crude",
	"38"	=>	"weak",
	"42"	=>	"slight",
	"46"	=>	"low",
	"50"	=>	"mediocre",
	"54"	=>	"average",
	"58"	=>	"decent",
	"62"	=>	"adequate",
	"66"	=>	"good",
	"70"	=>	"nice",
	"74"	=>	"great",
	"78"	=>	"excellent",
	"82"	=>	"impressive",
	"86"	=>	"incredible",
	"90"	=>	"superb",
	"94"	=>	"awesome",
	"100"	=>	"dazzling",
	"104"	=>	"magnificent",
	"108"	=>	"unearthly",
	"112"	=>	"divine",
);



my %infoindexhash = (
	"race"			=> 0,
	"rebirth"		=> 1,
	"skillcost"		=> 2,
	"spellcost"		=> 3,
	"exprate"		=> 4,
	"skillmax"		=> 5,
	"spellmax"		=> 6,
	"strength"		=> 7,
	"dexterity"		=> 8,
	"constitution"	=> 9,
	"intelligence"	=> 10,
	"wisdom"		=> 11,
	"size"			=> 12,
);


my @sortorders = (
	"race", "strength", "dexterity", "constitution", "intelligence",
	"wisdom", "size", "exprate", "skillcost", "spellcost", "skillmax", "spellmax",
);


&loadDataIntoHash();


my $rebirth			= &createRebirth(param('rebirth') || 0);
my $strength		= &createStatLimit('str');
my $dexterity		= &createStatLimit('dex');
my $constitution	= &createStatLimit('con');
my $intelligence	= &createStatLimit('int');
my $wisdom			= &createStatLimit('wis');
my $size			= &createStatLimit('siz');
my $sort_by			= &createSortBy(param('sortby'));
my $submitbutton	= qq|<input type="submit" value="List races" />|;

my $show_rebirth	= &showCheckbox('rebirth');
my $show_str		= &showCheckbox('str');
my $show_dex		= &showCheckbox('dex');
my $show_con		= &showCheckbox('con');
my $show_int		= &showCheckbox('int');
my $show_wis		= &showCheckbox('wis');
my $show_siz		= &showCheckbox('siz');
my $show_exprate	= &showCheckbox('exprate');
my $show_skillmax	= &showCheckbox('skillmax');
my $show_spellmax	= &showCheckbox('spellmax');
my $show_skillcost	= &showCheckbox('skillcost');
my $show_spellcost	= &showCheckbox('spellcost');
my $show_fm			= &showCheckbox('fm');
my $show_infra		= &showCheckbox('infra');
my $show_hptick		= &showCheckbox('hptick');
my $show_sptick		= &showCheckbox('sptick');
my $show_eatcorpses	= &showCheckbox('eatcorpses');
my $show_eatfood	= &showCheckbox('eatfood');
my $show_vision		= &showCheckbox('vision');
my $show_seemagic	= &showCheckbox('seemagic');
my $show_seeinvis	= &showCheckbox('seeinvis');
my $show_escapedeath= &showCheckbox('escapedeath');
my $show_allergy	= &showCheckbox('allergy');
my $show_clair		= &showCheckbox('clair');
my $show_ac			= &showCheckbox('ac');
my $show_special	= &showCheckbox('special');
my $show_hpratio	= &showCheckbox('hpratio');



my $content = <<until_end;
<h2>Raceinfo by Tumi</h2>
<div class="tool-link"><strong>Version:</strong> $VERSION</div>

$point_of_site
$fixlist
$buglist


<form action="raceinfo/raceinfo.pl" method="post">
<table id="raceinfo-options">
<tr><td colspan="4" class="raceinfo-header"><h3>Select filters</h3></td></tr>
<tr><td colspan="2" class="raceinfo-attr">Hide rebirth/invite races?</td><td colspan="2" class="raceinfo-val">$rebirth</td></tr>
<tr><td colspan="2" class="raceinfo-attr">Minimum strength</td><td colspan="2" class="raceinfo-val">$strength</td></tr>
<tr><td colspan="2" class="raceinfo-attr">Minimum dexterity</td><td colspan="2" class="raceinfo-val">$dexterity</td></tr>
<tr><td colspan="2" class="raceinfo-attr">Minimum constitution</td><td colspan="2" class="raceinfo-val">$constitution</td></tr>
<tr><td colspan="2" class="raceinfo-attr">Minimum intelligence</td><td colspan="2" class="raceinfo-val">$intelligence</td></tr>
<tr><td colspan="2" class="raceinfo-attr">Minimum wisdom</td><td colspan="2" class="raceinfo-val">$wisdom</td></tr>
<tr><td colspan="2" class="raceinfo-attr">Minimum size</td><td colspan="2" class="raceinfo-val">$size</td></tr>
<tr><td colspan="2" class="raceinfo-attr">Sort races by</td><td colspan="2" class="raceinfo-val">$sort_by</td></tr>

<tr style="border: 0;"><td colspan="4" style="border: 0;">&nbsp;</td></tr>

<tr><td colspan="4" class="raceinfo-header"><h3>Select fields</h3></td></tr>
<tr><td class="align-right">$show_rebirth</td><td class="align-right">$show_str</td><td class="align-right">$show_dex</td><td class="align-right">$show_con</td></tr>
<tr><td class="align-right">$show_int</td><td class="align-right">$show_wis</td><td class="align-right">$show_siz</td><td class="align-right">$show_exprate</td></tr>
<tr><td class="align-right">$show_skillmax</td><td class="align-right">$show_spellmax</td><td class="align-right">$show_skillcost</td><td class="align-right">$show_spellcost</td></tr>
<tr><td class="align-right">$show_fm</td><td class="align-right">$show_infra</td><td class="align-right">$show_hptick</td><td class="align-right">$show_sptick</td></tr>
<tr><td class="align-right">$show_eatcorpses</td><td class="align-right">$show_eatfood</td><td class="align-right">$show_vision</td><td class="align-right">$show_seemagic</td></tr>
<tr><td class="align-right">$show_seeinvis</td><td class="align-right">$show_escapedeath</td><td class="align-right">$show_allergy</td><td class="align-right">$show_clair</td></tr>
<tr><td class="align-right">$show_ac</td><td class="align-right">$show_special</td><td class="align-right">$show_hpratio</td><td>&nbsp;</td></tr>
<tr><td colspan="4" id="raceinfo-submit">$submitbutton</td></tr>
</table>

</form>

until_end



my $bigtable = <<until_end;
<div id="subcontent">
<table id="raceinfo_main">
	<tr class="raceinfo_the_header">
		<td class="raceinfo_header_race"><br />Race</td>
until_end

$bigtable .= qq|\t\t<td class="raceinfo_header"><br />Rebirth</td>\n| if (scalar param() < 2 || param('show_rebirth'));
$bigtable .= qq|\t\t<td class="raceinfo_header"><br />Str</td>\n| if (scalar param() < 2 || param('show_str'));
$bigtable .= qq|\t\t<td class="raceinfo_header"><br />Dex</td>\n| if (scalar param() < 2 || param('show_dex'));
$bigtable .= qq|\t\t<td class="raceinfo_header"><br />Con</td>\n| if (scalar param() < 2 || param('show_con'));
$bigtable .= qq|\t\t<td class="raceinfo_header"><br />Int</td>\n| if (scalar param() < 2 || param('show_int'));
$bigtable .= qq|\t\t<td class="raceinfo_header"><br />Wis</td>\n| if (scalar param() < 2 || param('show_wis'));
$bigtable .= qq|\t\t<td class="raceinfo_header"><br />Size</td>\n| if (scalar param() < 2 || param('show_siz'));
$bigtable .= qq|\t\t<td class="raceinfo_header">Exp<br />rate</td>\n| if (scalar param() < 2 || param('show_exprate'));
$bigtable .= qq|\t\t<td class="raceinfo_header">Skill<br />max</td>\n| if (scalar param() < 2 || param('show_skillmax'));
$bigtable .= qq|\t\t<td class="raceinfo_header">Spell<br />max</td>\n| if (scalar param() < 2 || param('show_spellmax'));
$bigtable .= qq|\t\t<td class="raceinfo_header">Skill<br />cost</td>\n| if (scalar param() < 2 || param('show_skillcost'));
$bigtable .= qq|\t\t<td class="raceinfo_header">Spell<br />cost</td>\n| if (scalar param() < 2 || param('show_spellcost'));

$bigtable .= qq|\t\t<td class="raceinfo_header">Fast<br />meta</td>\n| if (scalar param() < 2 || param('show_fm'));
$bigtable .= qq|\t\t<td class="raceinfo_header">Infra<br />vision</td>\n| if (scalar param() < 2 || param('show_infra'));
$bigtable .= qq|\t\t<td class="raceinfo_header">HP-<br />tick</td>\n| if (scalar param() < 2 || param('show_hptick'));
$bigtable .= qq|\t\t<td class="raceinfo_header">SP-<br />tick</td>\n| if (scalar param() < 2 || param('show_sptick'));
$bigtable .= qq|\t\t<td class="raceinfo_header">Eat<br />corpses</td>\n| if (scalar param() < 2 || param('show_eatcorpses'));
$bigtable .= qq|\t\t<td class="raceinfo_header">Eat<br />food</td>\n| if (scalar param() < 2 || param('show_eatfood'));
$bigtable .= qq|\t\t<td class="raceinfo_header"><br />Vision</td>\n| if (scalar param() < 2 || param('show_vision'));
$bigtable .= qq|\t\t<td class="raceinfo_header">See<br />magic</td>\n| if (scalar param() < 2 || param('show_seemagic'));
$bigtable .= qq|\t\t<td class="raceinfo_header">See<br />invis</td>\n| if (scalar param() < 2 || param('show_seeinvis'));
$bigtable .= qq|\t\t<td class="raceinfo_header">Escape<br />death</td>\n| if (scalar param() < 2 || param('show_escapedeath'));
$bigtable .= qq|\t\t<td class="raceinfo_header">Water<br />allergy</td>\n| if (scalar param() < 2 || param('show_allergy'));
$bigtable .= qq|\t\t<td class="raceinfo_header">Clair<br />voyance</td>\n| if (scalar param() < 2 || param('show_clair'));
$bigtable .= qq|\t\t<td class="raceinfo_header">Armour<br />class</td>\n| if (scalar param() < 2 || param('show_ac'));
$bigtable .= qq|\t\t<td class="raceinfo_header">Hp/Con<br />ratio</td>\n| if (scalar param() < 2 || param('show_hpratio'));
$bigtable .= qq|\t\t<td class="raceinfo_header">Special<br />notes</td>\n| if (scalar param() < 2 || param('show_special'));


$bigtable .= <<until_end;
	</tr>

until_end

my @racesleft = keys %datahash;
@racesleft = filterRebirth(param('rebirth') || 0, @racesleft);
@racesleft = filterStat('strength', param('limit_str') || 0, @racesleft);
@racesleft = filterStat('dexterity', param('limit_dex') || 0, @racesleft);
@racesleft = filterStat('constitution', param('limit_con') || 0, @racesleft);
@racesleft = filterStat('intelligence', param('limit_int') || 0, @racesleft);
@racesleft = filterStat('wisdom', param('limit_wis') || 0, @racesleft);
@racesleft = filterStat('size', param('limit_siz') || 0, @racesleft);


my $color = 0;
my $foo = 0;
foreach my $race (sort sortEm @racesleft) {
	$color = $foo++ % 2 + 1;

	my @raceinfo = @{$datahash{$race}};
	my ($race2, $rebirth, $skillcost, $spellcost, $exprate, $skillmax, $spellmax,
		$str, $dex, $con, $int, $wis, $size, $meta, $infra, $gnp,
		$hptick, $sptick, $eatcorp, $vision, $eatfood, $seemagic,
		$seeinvis, $escape, $allergy, $clair, $ac, $hpratio, $special) = @raceinfo;

	$rebirth = verbose_rebirth($rebirth);
	$hptick = verbose_tick($hptick);
	$sptick = verbose_tick($sptick);
	$vision = verbose_vision($vision);
	$exprate = verbose_exprate($exprate);
	$special =~ s/_/&nbsp;/g if ($special);

	$skillcost = ceil($skillcost*0.85)
		if (not $skillcost =~ /\?/);
	$spellcost = ceil($spellcost*0.85)
		if (not $spellcost =~ /\?/);

	$bigtable .= <<until_end;
	<tr class="raceinfo_info$color">
		<td class="raceinfo_cell_race">$race</td>
until_end

$bigtable .= qq|\t\t<td class="raceinfo_cell">$rebirth</td>\n| if (scalar param() < 2 || param('show_rebirth'));
$bigtable .= qq|\t\t<td class="raceinfo_cell">$str</td>\n| if (scalar param() < 2 || param('show_str'));
$bigtable .= qq|\t\t<td class="raceinfo_cell">$dex</td>\n| if (scalar param() < 2 || param('show_dex'));
$bigtable .= qq|\t\t<td class="raceinfo_cell">$con</td>\n| if (scalar param() < 2 || param('show_con'));
$bigtable .= qq|\t\t<td class="raceinfo_cell">$int</td>\n| if (scalar param() < 2 || param('show_int'));
$bigtable .= qq|\t\t<td class="raceinfo_cell">$wis</td>\n| if (scalar param() < 2 || param('show_wis'));
$bigtable .= qq|\t\t<td class="raceinfo_cell">$size</td>\n| if (scalar param() < 2 || param('show_siz'));
$bigtable .= qq|\t\t<td class="raceinfo_cell">$exprate</td>\n| if (scalar param() < 2 || param('show_exprate'));
$bigtable .= qq|\t\t<td class="raceinfo_cell">$skillmax</td>\n| if (scalar param() < 2 || param('show_skillmax'));
$bigtable .= qq|\t\t<td class="raceinfo_cell">$spellmax</td>\n| if (scalar param() < 2 || param('show_spellmax'));
$bigtable .= qq|\t\t<td class="raceinfo_cell">$skillcost</td>\n| if (scalar param() < 2 || param('show_skillcost'));
$bigtable .= qq|\t\t<td class="raceinfo_cell">$spellcost</td>\n| if (scalar param() < 2 || param('show_spellcost'));

$bigtable .= qq|\t\t<td class="raceinfo_cell">$meta</td>\n| if (scalar param() < 2 || param('show_fm'));
$bigtable .= qq|\t\t<td class="raceinfo_cell">$infra</td>\n| if (scalar param() < 2 || param('show_infra'));
$bigtable .= qq|\t\t<td class="raceinfo_cell">$hptick</td>\n| if (scalar param() < 2 || param('show_hptick'));
$bigtable .= qq|\t\t<td class="raceinfo_cell">$sptick</td>\n| if (scalar param() < 2 || param('show_sptick'));
$bigtable .= qq|\t\t<td class="raceinfo_cell">$eatcorp</td>\n| if (scalar param() < 2 || param('show_eatcorpses'));
$bigtable .= qq|\t\t<td class="raceinfo_cell">$eatfood</td>\n| if (scalar param() < 2 || param('show_eatfood'));
$bigtable .= qq|\t\t<td class="raceinfo_cell">$vision</td>\n| if (scalar param() < 2 || param('show_vision'));
$bigtable .= qq|\t\t<td class="raceinfo_cell">$seemagic</td>\n| if (scalar param() < 2 || param('show_seemagic'));
$bigtable .= qq|\t\t<td class="raceinfo_cell">$seeinvis</td>\n| if (scalar param() < 2 || param('show_seeinvis'));
$bigtable .= qq|\t\t<td class="raceinfo_cell">$escape</td>\n| if (scalar param() < 2 || param('show_escapedeath'));
$bigtable .= qq|\t\t<td class="raceinfo_cell">$allergy</td>\n| if (scalar param() < 2 || param('show_allergy'));
$bigtable .= qq|\t\t<td class="raceinfo_cell">$clair</td>\n| if (scalar param() < 2 || param('show_clair'));
$bigtable .= qq|\t\t<td class="raceinfo_cell">$ac</td>\n| if (scalar param() < 2 || param('show_ac'));
$bigtable .= qq|\t\t<td class="raceinfo_cell">$hpratio</td>\n| if (scalar param() < 2 || param('show_hpratio'));
$bigtable .= qq|\t\t<td class="raceinfo_cell_special">$special</td>\n| if (scalar param() < 2 || param('show_special'));

$bigtable .= <<until_end;
	</tr>

until_end
}


$bigtable .= qq|\t<tr class="raceinfo_the_header">\n|;
$bigtable .= qq|\t\t<td class="raceinfo_header_race"><br />Race</td>\n|;
$bigtable .= qq|\t\t<td class="raceinfo_header"><br />Rebirth</td>\n| if (scalar param() < 2 || param('show_rebirth'));
$bigtable .= qq|\t\t<td class="raceinfo_header"><br />Str</td>\n| if (scalar param() < 2 || param('show_str'));
$bigtable .= qq|\t\t<td class="raceinfo_header"><br />Dex</td>\n| if (scalar param() < 2 || param('show_dex'));
$bigtable .= qq|\t\t<td class="raceinfo_header"><br />Con</td>\n| if (scalar param() < 2 || param('show_con'));
$bigtable .= qq|\t\t<td class="raceinfo_header"><br />Int</td>\n| if (scalar param() < 2 || param('show_int'));
$bigtable .= qq|\t\t<td class="raceinfo_header"><br />Wis</td>\n| if (scalar param() < 2 || param('show_wis'));
$bigtable .= qq|\t\t<td class="raceinfo_header"><br />Size</td>\n| if (scalar param() < 2 || param('show_siz'));
$bigtable .= qq|\t\t<td class="raceinfo_header">Exp<br />rate</td>\n| if (scalar param() < 2 || param('show_exprate'));
$bigtable .= qq|\t\t<td class="raceinfo_header">Skill<br />max</td>\n| if (scalar param() < 2 || param('show_skillmax'));
$bigtable .= qq|\t\t<td class="raceinfo_header">Spell<br />max</td>\n| if (scalar param() < 2 || param('show_spellmax'));
$bigtable .= qq|\t\t<td class="raceinfo_header">Skill<br />cost</td>\n| if (scalar param() < 2 || param('show_skillcost'));
$bigtable .= qq|\t\t<td class="raceinfo_header">Spell<br />cost</td>\n| if (scalar param() < 2 || param('show_spellcost'));

$bigtable .= qq|\t\t<td class="raceinfo_header">Fast<br />meta</td>\n| if (scalar param() < 2 || param('show_fm'));
$bigtable .= qq|\t\t<td class="raceinfo_header">Infra<br />vision</td>\n| if (scalar param() < 2 || param('show_infra'));
$bigtable .= qq|\t\t<td class="raceinfo_header">HP-<br />tick</td>\n| if (scalar param() < 2 || param('show_hptick'));
$bigtable .= qq|\t\t<td class="raceinfo_header">SP-<br />tick</td>\n| if (scalar param() < 2 || param('show_sptick'));
$bigtable .= qq|\t\t<td class="raceinfo_header">Eat<br />corpses</td>\n| if (scalar param() < 2 || param('show_eatcorpses'));
$bigtable .= qq|\t\t<td class="raceinfo_header">Eat<br />food</td>\n| if (scalar param() < 2 || param('show_eatfood'));
$bigtable .= qq|\t\t<td class="raceinfo_header"><br />Vision</td>\n| if (scalar param() < 2 || param('show_vision'));
$bigtable .= qq|\t\t<td class="raceinfo_header">See<br />magic</td>\n| if (scalar param() < 2 || param('show_seemagic'));
$bigtable .= qq|\t\t<td class="raceinfo_header">See<br />invis</td>\n| if (scalar param() < 2 || param('show_seeinvis'));
$bigtable .= qq|\t\t<td class="raceinfo_header">Escape<br />death</td>\n| if (scalar param() < 2 || param('show_escapedeath'));
$bigtable .= qq|\t\t<td class="raceinfo_header">Water<br />allergy</td>\n| if (scalar param() < 2 || param('show_allergy'));
$bigtable .= qq|\t\t<td class="raceinfo_header">Clair<br />voyance</td>\n| if (scalar param() < 2 || param('show_clair'));
$bigtable .= qq|\t\t<td class="raceinfo_header">Armour<br />class</td>\n| if (scalar param() < 2 || param('show_ac'));
$bigtable .= qq|\t\t<td class="raceinfo_header">Hp/Con<br />ratio</td>\n| if (scalar param() < 2 || param('show_hpratio'));
$bigtable .= qq|\t\t<td class="raceinfo_header">Special<br />notes</td>\n| if (scalar param() < 2 || param('show_special'));


$bigtable .= <<until_end;
	</tr>
</table>
</div>

until_end

#&setLayoutItem('subcontent', $bigtable);
&pageOutput('raceinfo', $content.$bigtable);

1;






sub loadDataIntoHash {
	my $file = new IO::File "raceinfo.txt", "r";
	die 'Filehandle is broken, raceinfo data not found.' unless ($file);

	my $counter = 0;
	my @lines = <$file>;
	foreach my $line (@lines) {
		next if (substr($line, 0, 1) eq ";");

		my @raceinfo = split/\s+/, $line;
		$racehash{sprintf("key%02d", $counter++)} = [ @raceinfo ];
		$datahash{shift @raceinfo} = [ @raceinfo ];
	}
}


sub get {
	my $race = shift || 'human';

#	print STDERR "get: $race\n";
	$race = 'human'
		unless (defined $datahash{$race});
	return @{$datahash{$race}};
}



sub verbose_rebirth {
	my $rebirthlevel = shift || 0;

	return "Eternal"		if ($rebirthlevel == 3);
	return "Ancient"		if ($rebirthlevel == 2);
	return "Elder"			if ($rebirthlevel == 1);
	return "Invite"			if ($rebirthlevel == -1);

	return "-";
}


sub verbose_tick {
	my $sta = shift;

	return "Faulty" unless $sta;

	return "Very&nbsp;slow"	if ($sta == 1);
	return "Slow"			if ($sta == 2);
	return "Fast"			if ($sta == 4);
	return "Very&nbsp;fast"	if ($sta == 5);
	return "Average";
}


sub verbose_vision {
	my $vis = shift;

	return "Faulty" unless $vis;

	return "Bad"		if ($vis == 2);
	return "Good"		if ($vis == 4);
	return "Excellent"	if ($vis == 5);
	return "Average";
}



sub verbose_exprate {
	my $expr = shift;

	return "Faulty" unless $expr;

	return $expr if ($expr =~ /\d+/);

	return "Low" if ($expr eq "Sup");
	return "High" if ($expr eq "Inf");

	return "Ave";
}



sub createRebirth {
	my $prev = shift || 0;
	my $output = qq|\n<select name="rebirth">\n|;

	for my $onoff (0..1) {
		my $insert = ($prev == $onoff ? " selected=\"selected\"" : "");
		my $value = ($onoff ? "Yes" : "No");
		$output .= qq|<option value="$onoff"$insert>$value</option>\n|;
	}
	$output .= qq|</select>\n|;

	return $output;
}


sub createStatLimit {
	my $stat = shift || 'str';
	my $prev = param("limit_".$stat) || 0;
	my $output = qq|\n<select name="limit_$stat">\n|;

	for my $val (sort {$a<=>$b} keys %verbose_stats) {
#		$val *= 3;
		my $val2 = ($stat ne "siz" ? ucfirst $verbose_stats{"$val"}." ($val)" : $val);
		my $insert = ($val == $prev ? " selected=\"selected\"" : "");
		$output .= qq|<option value="$val"$insert>$val2</option>\n|;
	}
	$output .= qq|</select>\n|;

	return $output;
}


sub createSortBy {
	my $prev = shift || 'alphabetical';
	my $output = qq|\n<select name="sortby">\n|;

	for my $val (@sortorders) {
		my $insert = ($val eq $prev ? " selected=\"selected\"" : "");
		my $val2 = ucfirst $val;
		$output .= qq|<option value="$val"$insert>$val2</option>\n|;
	}
	$output .= qq|</select>\n|;

	return $output;
}


sub filterRebirth {
	my $filter = shift || 0;
	return @_
		unless $filter;

	my @new = grep {(get($_))[$infoindexhash{'rebirth'}] == 0} @_;
	return @new;
}


sub filterStat {
	my $stat = shift || 'strength';
	my $prev = shift || 0;

	my @new = grep {(get($_))[$infoindexhash{$stat}] >= $prev} @_;
	return @new;
}


sub sortEm {
	my $bywhat = param('sortby') || 'race';
	$bywhat = 'race'
		unless (defined $infoindexhash{$bywhat});
	my $index = $infoindexhash{$bywhat};

	my ($first, $second) = ($a, $b);
	if ($bywhat =~ /cost/) {
		$second = $a;
		$first = $b;
	}


	if ((get($second))[$index] =~ /^(\d+)/) {
		return ( (get($second))[$index] <=> (get($first))[$index] );
	} else {
		return ( (get($first))[$index] cmp (get($second))[$index] );
	}
}


sub showCheckbox {
	my $what = shift;
	my $paramkey = "show_$what";
	my $paramval = param($paramkey) || 0;
	my $onoff = (scalar param() < 2 || $paramval) ? " checked=\"checked\"" : "";
	$what = ucfirst $what;

	return qq|$what: <input type="checkbox" name="$paramkey"$onoff />|;
}



__END__



; pathetic		 3
; pitiful		 6
; sad			 9
; bad			12
; tiny			15
; little		18
; meager		21
; feeble		24
; poor			27
; paltry		30
; crude			33
; weak			36
; slight		39
; low			42
; mediocre 		45
; average		48
; decent 		51
; adequate 		54
; good			57
; nice			60
; great			63
; excellent		66
; impressive	69
; incredible	72
; superb		75
; awesome		78
; dazzling		81
; magnificent	84
; unearthly		87
; divine		90

