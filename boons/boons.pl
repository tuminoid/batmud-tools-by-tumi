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
use CGI qw/param/;
use POSIX qw/ceil/;

# my stuff
# use lib '/home/twomi/web/libs';
use lib '/home/customers/tumi/public_html/archives/batmud';
use lib '/home/customers/tumi/tumilib';
use BatmudTools::Site;
use Tumi::Helper;


my $point_of_site = &readFile('html/pointofsite.html');
my $fixlist = &readFile('html/fixlist.html');
my $buglist = &readFile('html/buglist.html');


my $VERSION = "1.0.1";

# Modifier for boon cost and totalcost variables
my ($modif, $total) = (0, 0);

# If nohtml is defined, no printing tags
my $nohtml = param('nohtml') || 0;

# Max number of boons until we stop
my $boons = param('boons') || 0;
my $showboons = param('boons') || 0;

# Max number of euros until we stop
my $euros = param('euros') || 0;
my $showeuros = param('euros') || 0;

# If we have some taskpoints before donating
my $previous = param('previous') || 0;
my $showprevious = param('previous') || 0;


# If we take half boons instead of full ones
my $half = param('half') || 0;
# We can decide to take some halfs at the start
my $halffirst = param('halffirst') || 0;

# We can decide to take half boons after certain boon
my $halfend = param('halfend') || 0;
my $showhalfend = param('halfend') || 0;


# Max number of tps we might use, from param maxcost or calculated from euros
my $showmaxcost = param('maxcost') || 0;
my $costmodif = ($euros == 0 ?
	$showmaxcost <= (300*1.75) ? 1.75 : ($showmaxcost <= 2250 ? 2.25 : 2.75) :
	$euros <= 300 ? 1.75 : ($euros <= 1000 ? 2.25 : 2.75));
my $maxcost = param('maxcost') || ($euros == 0 ? 10000 : int($euros*$costmodif));
$maxcost += $previous;


my $content = <<until_end;
<h2>Boons/donate calculator by Tumi</h2>
<div class="tool-link"><strong>Version:</strong> $VERSION</div>

$point_of_site
$fixlist
$buglist


<h3 id="boons-insert">Insert parameters</h3>

<form action="boons/boons.pl" method="post">
<div id="boon-form">

<div class="boon-block">
<div class="boons">No. of taskpoints now</div>
<input class="boons" type="text" name="previous" value="$showprevious" size="10" maxlength="10" /><br />
</div>

<div class="boon-block">
<div class="boons">Max boons</div>
<input class="boons" type="text" name="boons" value="$showboons" size="10" maxlength="10" /><br />
</div>

<div class="boon-block">
<div class="boons">Max euros</div>
<input class="boons" type="text" name="euros" value="$showeuros" size="10" maxlength="10" /><br />
</div>

<div class="boon-block">
<div class="boons">Max taskpoints</div>
<input class="boons" type="text" name="maxcost" value="$showmaxcost" size="10" maxlength="10" /><br />
</div>

<div class="boon-block">
<div class="boons">How many fulls you want<br />(half boons after that, 0 = no half boons)</div>
<input class="boons" type="text" name="halfend" value="$showhalfend" size="3" maxlength="3" /><br />
</div>

<br />

<input id="boons-select" type="submit" value="Calculate" />
</div>
</form>


until_end

if ($showmaxcost || $showprevious || $showeuros || $showboons) {
	$content .= "<pre><code>\n";
	$content .= "Printing until max_boons= $boons or max_cost= $maxcost tp\n" unless $euros != 0;
	$content .= "Printing until max_euros= $euros e (max_cost= $maxcost tp)\n" unless $euros == 0;
	$content .= "\n";


	# How many tps we got left
	my $pointsleft = $previous;

	# If we skip some, modif must be saved outside instead of increasing every run
	my $modifcounter = 0;


	my ($failed, $loop) = (0, 0);
	# Lets loop until maxboons (calculated in quarters)
	#for my $loop (0..$boons*4-1) {
	while ($failed < 5 && $loop < 200) {
		# The previous totalcost and number of boons were working with
		my ($prev, $number) = ($total, ($loop+4)/4);

		# Next advancement cost
		my $thiscost = (10 * ($modif+1)) * (2 ** ($loop % 4));

		# Cost in euros to advance this far
		my $cost = ceil (($total+$thiscost-$previous)/$costmodif);

		# Strenght of the boon as string
		my $level = ($loop%4==0 ? "10%" : ($loop%4==1 ? "25%" : ($loop%4==2 ? "50%" : "100%")));

		if (($euros != 0 && $cost > $euros) ||
				($maxcost != 0 && $total > $maxcost) ||
				($boons != 0 && ($loop/4) > $boons)) {

			print STDERR "(cost= $cost, euros= $euros), (total= $total, ",
				"maxcost= $maxcost),  (loop= ", ($loop/4), ", boons= $boons)\n";
			$pointsleft = $maxcost-$prev;
			$failed++;
		}

		$loop++;

		# If it would cost more than we've set limits, go for next round
		# (see if there is any tiny/small etc boons left we might get)
		if ($prev+$thiscost > $maxcost ||
				($half == 1 && $level eq "100%") ||
				($halffirst > 0 && $level eq "100%" && $number < $halffirst+1) ||
				($halfend > 0 && $level eq "100%" && $number > $halfend+1) ) {
			$pointsleft = $maxcost-$prev;
			next;

		# Or we have tps to get it, so modifiercounter get upped as well as totalcost
		} else {
			$modifcounter++;
			$total += $thiscost;
		}

		# Format the information
		my $output =
				"Level: ". sprintf("%4s", $level).
				# "\tModifier: ". sprintf("%2d", $modif+1).
				"\tThis: ". sprintf("%4d tp", $thiscost).
				"\tTotal: ". sprintf("%6d tp", $total).
				"\tCost: ". sprintf("%4d e", $cost < 0 ? 0 : $cost).
				"\n";

		# If level is at 10%, means new boon level started, separate it with line
		$content .= "\n". "-" x int((length $output)*0.52). " Boon ". sprintf("%2d", $number).
				" ". "-" x int((length $output)*0.52). "\n"
			if ($level eq "10%");

		# Print the boon level information
		$content .= $output;

		# If modifiercounter goes to six, increase the cost modifier by one
		$modif++ if ($modifcounter%6 == 0);

		$failed = 0;
	}

	# How many taskpoints we got left after all this juggling
	$content .= "\n\nTaskpoints left: $pointsleft tp\n";
	$content .= "</code></pre>\n";
}


&pageOutput('booncalc', $content);




# Finished
__END__



# 6 FULLIA, 1 PUOLIKAS ja 1 QUARTER ON  _AINA_  PAREMPI KUIN 5 FULL+3HALF!

# Spefific configurations

# LEECH CHANCONJ AOA (70/72 basic, with 100%spellboon 70/88, skillc 117, spellc 70)
# 15bg+24conj+30chan+1nav = 70lvls (31.4m)
# Need 17m for blue channellers, conjus need AoA, Fabs, Mastery + few mils in minortypes
# 32m + 18m + 10m = 60m
# (6f, 1h, 1q) = +Wis, +Int, +Con, +Super, +Spellmax, +Meta; +Moon; +Qlips
#     -> 72wis/int, 52con, 12dex/str + 100% meta + 50% moon
#     -> 270sp, 140hp, 40ep (about 210 int, 160 wis, 1250sp, 135 regen)

# LEECH RUNEBARD (70/72 basic, with 50%spellboon 70/80, skillc 117, spellc 70)
# 15bg+30rune+24bard+1nav = 70lvls (31.4m)
# Need 7m for bards (ware,mastery+blaa), runes need maybe 14-17m (90qc,ana,conc,runics blaa)
# 32m + 7m + 14-17m = 55m
# (6f, 1h, 1q) = +Wis, +Int, +Dex, +Super, +Meta; +Moon; +Spellmax
#     -> 72wis/int/dex, 12con/str + 100% meta/moon + 50% spellmax
#     -> 270sp, 40hp, 84ep (about 180int, 160wis, 200dex, 800sp, 150regen)

# DUCK/ELF RUNEBARD (81/98, skillc 141, spellc 94 | 95/100, skillc 117, spellc 94)
# 15bg+30rune+24bard+1nav = 70lvls (31.4m)
# Need 9m for bards (ware,mastery+blaa), runes need maybe 16-21m (90qc,ana,conc,runics blaa)
# 32m + 9m + 16-21m = 60m
# (6f, 1h, 1q) = +Wis, +Int, +Dex, +Super, +Meta; +Moon; +Qlips
#     -> 72wis/int/dex, 12con/str + 100% meta/moon + 50% Qlips
#     -> 270sp, 40hp, 84ep (about 180int/wis/dex, 850sp, 550hp, 160/150 regen)

# MINOTAUR CRIMSON (83, skillmax+1ss 100, skillcost 105)
# 15bg+35crimson+7ss (1skillmax, 6con = 32con = 10m) = 57 levels = 13m
# Need (11m dodge, 10m parry, 11m con, 10m rest (csense/mano/dsense))
# 13m + 31m + 11m  = 55m
# (6f, 1h, 1q) = +Con, +Dex, +Str, +Super, +R_any, +Skillmax; R_psi; Meta
#     -> 84con, 52str, 72dex, 12int/wis + 100% R_any + 50% R_psi + 25% Meta
#     -> 270hp, max400ep (about 200con, 150str/dex, 1300hp, 400ep, 10%all, 15% psi)




# General guidelines

# Tarma / Nun / Druid / Psi / Conj / Chan / Mage (almost all casters)
# (6f, 1h, 1q) = +Wis, +Int, +Super, +Moon, +Meta, +Qlips; +Con; +Res
#     -> 72wis/int, 32con, 12dex/str + 100% meta/qlips/moon + 25% resist
#     -> 270sp, 93hp, 30ep
# (5f, 3h)     = +Wis, +Int, +Super, +Meta, +Moon; +R_any, +Con, +Qlips
#     -> 72wis/int, 32con, 12dex/str + 100% meta/moon + 50% resist/qlips
#     -> 270sp, 75hp, 34ep


# Monk / Tiger / Templars / Reaver / Spider / ePriest (all mixed guilds)
# (6f, 1h, 1q)  = +Con, +Dex, +Str, +Wis, +R_any, +Super; +Meta; +Moon
#     -> 52con/str, 72wis/dex, 12int + 100% resist, 50% meta, 25% moon
#     -> 156hp, 180sp, 120ep
# (5f, 3h)      = +Con, +Dex, +Wis, +Super, +R_any; +Str, +Meta, +Moon
#     -> 52con, 72wis/dex, 32str, 12int + 100% resist, 50% meta/moon
#     -> 156hp, 180sp, 110ep


# Bard / Runemage (casterish with dex instead of any con)
# (6f, 1h, 1q)  = +Dex, +Wis, +Int, +Meta, +Super, +Moon; +Qlips; +R_any
#     -> 72int/wis/dex + 100% meta/moon, 50% qlips, 25% resist
#     -> 288sp, 72ep
# (5f, 3h)      = +Dex, +Wis, +Int, +Meta, +Super; +Moon, +Qlips, +R_any
#     -> 72int/wis/dex + 100% meta, 50% moon/qlips/resist
#     -> 288sp, 72ep


# Ranger / Crimson / Barbarian / Sabres (any nomad guild)
# (6f, 1h, 1q)  = +Con, +Dex, +Str, +R_any, +Super, +Skillmax; +Meta; +Steady
#     -> 52str/con, 72dex, 16skillmax, 100% resist, 50% meta, %25 steady
#     -> 160hp, 144ep
# (5f, 3h)      = +Con, +Dex, +Str, +R_any, +Skillmax; +Super; +Meta; +Steady
#     -> 46str/con, 66dex, 16skillmax, 100% resist, 50% meta/steady
#     -> 140hp, 132ep




# LIST OF BOONS

# Evil drift
#    Helps your character stay evil.
#
# Fast metabolism
#    Makes your heart work faster.
#
# Good drift
#    Helps your character stay good.
#
# Improved skills
#    Raises the maximum percentile in every skill that you may have.
#
# Improved spells
#    Raises the maximum percentile in every spell that you may have.
#
# Moon improvement
#    Improves the moon state so that spell point costs are biased more towards good
#    moon.
#
# More constitution
#    Raises your natural constitution.
#
# More dexterity
#    Raises your natural dexterity.
#
# More intelligence
#    Raises your natural intelligence.
#
# More strength
#    Raises your natural strength.
#
# More wisdom
#    Raises your natural wisdom.
#
# No drift
#    Helps your character stay neutral.
#
# Quick lips
#    Makes your spells go off faster.
#
# Resist acid damage
#    Resist acid type damage.
#
# Resist any damage
#    Resist any type damage.
#
# Resist asphyxiation damage
#    Resist asphyxiation type damage.
#
# Resist cold damage
#    Resist cold type damage.
#
# Resist electricity damage
#    Resist electricity type damage.
#
# Resist fire damage
#    Resist fire type damage.
#
# Resist magical damage
#    Resist magical type damage.
#
# Resist poison damage
#    Resist poison type damage.
#
# Resist psionic damage
#    Resist psionic type damage.
#
# Semantic augmentation
#    Lessens your chance of fumbling a spell.
#
# Steady hand
#    Improves your chance to hit. Decreases opponent's defensive percentile.
#
# Super characteristics
#    Raises all stats, except charisma and size.
