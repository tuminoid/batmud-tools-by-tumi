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
use IO::File;
use CGI qw/param/;

# my stuff
# use lib '/home/twomi/web/libs';
use lib '/home/customers/tumi/public_html/archives/batmud';
use lib '/home/customers/tumi/tumilib';
use Tumi::Helper;
use BatmudTools::Site;



####################### PRE-DEFINITIONS ######################

# some basic stuff
my $VERSION = '0.4-beta1';
my $pointofsite = &readFile('html/pointofsite.html');

# html is the page where everything is appended
my $html = "";
my $society = param('society') || "";

# if msg is to be displayed
my $msg = param('msg') || "";

# data & ssdata are files where stuff is loaded
my $DATA = "bonuses.txt";
my $SSDATA = "ss/$society.txt";

# and theyre loaded here
my %datahash = &loadStats($DATA);
my %sshash = &loadStats($SSDATA);

# some data for us
my @avail_stats = ("str", "dex", "con", "int", "wis", "skillmax", "spellmax", "dodge", "parry");
my %stats = (
	'str' => 0,
	'dex' => 0,
	'con' => 0,
	'int' => 0,
	'wis' => 0,
	'skillmax' => 0,
	'spellmax' => 0,
	'dodge' => 0,
	'parry' => 0,
);
my $MAX_IMP = 29;
my $MAX_STAT = 40;

# header for all outputs
my $header = <<until_end;
<h2>SS Counter by Tumi</h2>
<div class="tool-link"><strong>Version:</strong> $VERSION</div>

$pointofsite

until_end



########################## CODE ITSELF #############################

#Name: Erimaankielenpuhumista
#Command: swe+
#Guild masters: Demerzel, Desos, Gotrek, Spid, Doughnut and Ruffneck
#Maximum level: 16

# submitting defined, thus there is info coming, lets parse it
if (param('submitting')) {
	my $txt = param('guildinfo') || "";
	my @lines = split/\n/, $txt;

	my ($name, $command, $gms, $maxlvl) = ("", "", "Unknown", 0);
	my $this_lvl = 0;
	my %bon = ();
	my @level_bon = ();

	# parse data line by line
	for my $line (@lines) {

		# found a command, lets store it
		if ($line =~ /^Command: ([a-z]+)/) {
			$command = lc$1; next;
		}

		# found a name, lets store it
		if ($line =~ /^Name: ([A-Za-z _]+)/) {
			$name = $1; next;
		}

		# found guild masters, lets store it
		if ($line =~ /^Guild masters: ([A-Za-z ,]+)/) {
			$gms = $1; next;
		}

		# found maxlevel, lets store it
		if ($line =~ /^Maximum level: (\d+)/) {
			$maxlvl = $1; next;
		}

		# found a level.. if level is already defined, its a new level and old info is stored
		if ($line =~ /^ Level (\d+):/) {
			 my $new_level = $1;
			 if ($this_lvl) {
				$bon{"$this_lvl"} = join(",", @level_bon);
				@level_bon = ();
			 }
			 $this_lvl = $new_level;
			 next;
		}

		# found statmax for some stat, store it
		if ($this_lvl && $line =~ /Statmax of ([a-z]+)/) {
			push @level_bon, $1;
			next;
		}

		# found skill/spellmax of all, store it
		if ($this_lvl && $line =~ /(Skillmax|Spellmax) of all/) {
			push @level_bon, (lc $1);
			next;
		}

		# found skill/spellmax of someskill, store it
		if ($this_lvl && $line =~ /(Skillmax|Spellmax) of ([a-z ]+)/) {
			push @level_bon, (lc $2);
			next;
		}
	}

	# last level is left open, close it
	if ((scalar @level_bon) > 0 && $this_lvl) {
		$bon{"$this_lvl"} = join(",", @level_bon);
	}


	# we found a name, thus suspecting a success
	if ($name) {
		# save parsed data to ss dir
		my $fh = new IO::File "ss/$command.txt", "w";
		print $fh "name: $name\ngms: $gms\nmaxlvl: $maxlvl\n";
		for my $lev (sort {$a<=>$b} keys %bon) {
			print $fh "$lev: $bon{$lev}\n";
		}
		undef $fh;

		# save raw data to raw dir
		$fh = new IO::File "ss/raw/$command.txt", "w";
		print $fh $txt;
		undef $fh;

		# show message and define society variable
		$msg = "Society $name ($command\+) info imported successfully. ".
			"Found $maxlvl levels. Guildmasters are: $gms.";
		$society = $command;
		%sshash = &loadStats("ss/$society.txt");

	# we failed to find a name for ss, so we fail
	} else {
		$msg = "Failed miserably while importing data. Make sure you include whole output of the command.";
		$society = "";
	}
}



# if we have society selected, move to actual calculating
if ($society ne "") {
	my $soc_name = $sshash{'name'} || $society;
	my $soc_gms = $sshash{'gms'} || "Unknown";
	my $soc_lvl = $sshash{'maxlvl'} || "Unknown";

	$html .= <<until_end;
<form action="sscounter/ss.pl" method="post">
<input type="hidden" name="society" value="$society" />
<table id="sscounter">
<tr><td colspan="3">Using society template: <strong>$society+</strong> (<a href="sscounter/ss.pl">change</a>)</td></tr>
<tr><td colspan="3"><strong>Society name:</strong> $soc_name</td></tr>
<tr><td colspan="3"><strong>Guildmasters:</strong> $soc_gms</td></tr>
<tr id="header"><td>Level:</td><td>Stat:</td><td>Cumulative:</td></tr>
until_end

	my @train_cmds = ();
	for my $level (1..20) {
		my %temp = &countSSLevel($level);
		next unless (length($sshash{"$level"}) > 2);

		for my $key (keys %stats) {
			$stats{$key} += $temp{$key};
		}
		$html .= &createSSLevel($level, param("level$level") || "", \%stats, \%sshash);
		my $train_cmd = &createTrainCmd(param("level$level"));
		push @train_cmds, $train_cmd;# if ($train_cmd ne "");
	}

	$html .= <<until_end;
<tr><td colspan="3" id="submit">
<input type="submit" name="submittype" value="Calculate" />
<input type="submit" name="submittype" value="Calculate w/ train commands" />
</td></tr>

</table>
</form>
until_end

	# if train cmd is enabled
	if (param('submittype') =~ /train/) {
		$html .= qq|<pre class="msg">\n|;
		$html .= join("\n", @train_cmds);
		$html .= qq|</pre>\n|;
	}


# if not, then list the societys
} else {
	my $socbox = &createSocietyBox($society);

	$html .= <<until_end;
<form action="sscounter/ss.pl" method="get">
<p>Choose a society template to work with:
$socbox
<input type="submit" value="Choose" />
</p>
</form>
until_end
}



# param add is defined, overwrite the previous html as we wanna just print out
# a form to submit new data
if (param('add')) {
	$html = <<until_end;
<h3>Add a new society template</h3>

<p class="msg">Paste the whole '&lt;society&gt;+ info' output to the textbox and submit, and thats it!</p>

<form action="sscounter/ss.pl" method="post">
<input type="hidden" name="submitting" value="1" />
<textarea name="guildinfo" rows="25" cols="60" wrap="virtual"></textarea><br />
<input type="submit" value="Add SS template" />
</form>
until_end
}





# output the html in thru template
my $dispmsg = $msg ? qq|<p class="msg">$msg</p>| : "";
&pageOutput('sscounter', $header.$dispmsg.$html);


# end if runnable code
1;






######################## SUBROUTINES #########################


# list files in ss dir, and make a select box out of them
sub createSocietyBox {
	my $prev = shift;

	my $html = qq|<select name="society">\n|;
	my @files = &getDir('ss', '*.txt');

	for my $guild (sort {$a cmp $b} @files) {
		$guild =~ s/\.txt//;
		my $sel = $guild eq $prev ? ' selected="selected"' : '';
		my $verbose = (ucfirst $guild)."+";
		$html .= qq|<option value="$guild"$sel>$verbose</option>\n|;
	}
	$html .= qq|</select>\n|;

	return $html;
}



# parse level param into hash for counting the stats
sub countSSLevel {
	my ($level) = @_;
	my %temp = (
		 'str' => 0,
		 'dex' => 0,
		 'con' => 0,
		 'int' => 0,
		 'wis' => 0,
		 'skillmax' => 0,
		 'spellmax' => 0,
		 'dodge' => 0,
		 'parry' => 0,
		 );

	my $key = param("level$level");
	my ($stat, $num) = $key =~ /([a-z]+)(\d+)/;
	$temp{$stat} = $num;

	return (%temp);
}



# create whole row of one ss levle
sub createSSLevel {
	my ($level, $choise, $stats, $ss) = @_;
	my $sbox = &createSSLevelChoise($level, $choise, %{$ss});
	my $bonuses = &getBonuses(%{$stats});
	$bonuses = "&nbsp;" unless (param("level$level"));

	my $html = <<until_end;
<tr class="data">
<td>$level</td>
<td class="middle">$sbox</td>
<td>$bonuses</td>
</tr>
until_end

	return $html;
}



#  create choicebox including all choises in level
sub createSSLevelChoise {
	my ($level, $choise, %ss) = @_;

	# max_num is what bonus level has for skillspellmax, and stat_num for stats
	my $max_num = $datahash{"maxes$level"} || 0;
	my $stat_num = $datahash{"stats$level"} || 0;

	my $html = "";
	my @level_stats = ();

	for my $stat (@avail_stats) {
		next unless ($ss{"$level"} =~ /$stat/);

		my $num = $stat =~ /max/ ? $max_num : $stat_num;
		my $verbose = (ucfirst $stat).": $num";
		push @level_stats, (ucfirst $stat);
		my $selected = $choise =~ /$stat/ ? ' selected="selected"' : '';
		$html .= qq|<option value="$stat$num"$selected>$verbose</option>\n|;
	}

	my $statlist = join(" ", sort {length($a) <=> length($b)} @level_stats);
	$html = <<until_end;
<select name="level$level">
<option value="">($statlist)</option>
$html
</select>
until_end

	return $html;
}



# makes train command
sub createTrainCmd {
	my $for_stat = shift || "";
	my ($what) = $for_stat =~ /([a-z]+)/;
	my %hash = (
		"str"		=> "advance statmax str",
		"dex"		=> "advance statmax dex",
		"con"		=> "advance statmax con",
		"int"		=> "advance statmax int",
		"wis"		=> "advance statmax wis",
		"spellmax"	=> "advance spellmax all",
		"skillmax"	=> "advance skillmax all",
		"dodge"		=> "advance skillmax dodge",
		"parry"		=> "advance skillmax parry",
		""			=> "",
	);

	return $hash{$what} || "";
}



# verbose stats into txt
sub getBonuses {
	my (%stats) = @_;
	my (@these_stats) = ();

	for my $stat (@avail_stats) {
		my $verbose = ucfirst $stat;
		my $fullhtml = &colorizeStat($stats{$stat}, 1);
		push @these_stats, qq|$verbose: $fullhtml| if ($stats{$stat} > 0);
	}

	return join(", ", @these_stats);
}




# get color for stat
sub colorizeStat {
	my $num = shift || 0;
	my $fullhtml = shift || 0;
	my $color = "inherit";
	my $weight = "normal";

	# pick a color
	($color, $weight) = ("#dd0", "bold") if ($num > $MAX_IMP);
	($color, $weight) = ("#d00", "bold") if ($num > $MAX_STAT);

	# if fullhtml is on, output is full html span
	return qq|<span style="color: $color; font-weight: $weight;">$num</span>| if ($fullhtml);

	# otherwise just return color
	return $color;
}



# load "key: val" paired data into hash
sub loadStats {
	my $file = shift;
	return () unless (-e $file);

	my @lines = split/\n/, &readFile($file);
	my %temp = ();

	for my $line (@lines) {
		my ($key, $val) = split/: /, $line;
		$temp{$key} = $val;
	}

	return (%temp);
}

__END__

