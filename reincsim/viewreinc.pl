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
use POSIX qw/ceil/;


# my stuff
# use lib '/home/twomi/web/libs';
use lib '/home/customers/tumi/public_html/archives/batmud';
use lib '/home/customers/tumi/tumilib';
use Tumi::Helper;
use BatmudTools::Site;


# Current version number
my $VERSION = "1.2.1";



my $top_template = <<until_end;



                                      ,-----------.
                                      |Percentiles|
,-------------------------------------+-----------+
| <g> - <type>, level <l> | Cur | Max |
|=====================================|=====|=====|
until_end

my $middle_template = <<until_end;
| <talent> | <c> | <m> |
until_end

my $bottom_template = <<until_end;
`-------------------------------------------------'

until_end




my $id = param('id') || '';
my $uid = param('uid') || "db";
my $content = <<until_end;
<h2 id="welcome">Show reinc summary, $VERSION</h2>

<p>Note: to use train/study commands, <b>FIRST</b> advance to the planned level,
and only after then paste those.. The commands do not understand anything about
requirements or prequisites.</p>

until_end





unless (-e "saved/$id.$uid") {
	$content .= <<until_end;
<form action="reincsim/viewreinc.pl" method="get">
Reinc number: <input type="text" size="15" maxlength="20" name="id" value="$id" />
<input type="submit" value="View reinc" />
</form>
until_end

} else {
	my %params = &loadParams("saved/$id.db");
	$content .= "<pre><code>\n";

	my @guilds = ($params{'guild1'}, $params{'guild2'}, $params{'guild3'}, $params{'guild4'}, $params{'guild5'});
	my @glevels = ($params{'glevel1'}, $params{'glevel2'}, $params{'glevel3'}, $params{'glevel4'}, $params{'glevel5'});

	for my $ind (0..4) {
		my $g = $guilds[$ind];
		my $gl = $glevels[$ind];

		next
			unless (defined $gl && $gl > 0 && defined $g && not $g =~ /^(none|secret)/i);

		my ($sk, $sp, $min) = &lookForGuildMax($g, $gl);


		# Skills
		my $temp1 = $top_template;
		$temp1 =~ s/<g>/sprintf"%16s",ucfirst $g/e;
		$temp1 =~ s/<type>/Skills/;
		$temp1 =~ s/<l>/sprintf"%2s",$gl/e;
		$content .= $temp1;

		my @train_cmds = ();
		for my $skill (sort keys %{$sk}) {
			my $skill2 = $skill;
			$skill2 =~ tr/A-Z /a-z_/;
			my $skperc = $params{"skill_$skill2"} || 0;
			my $temp2 = $middle_template;

			$temp2 =~ s/<talent>/sprintf"%-35s",$skill/e;
			$temp2 =~ s/<c>/sprintf"%3s",$skperc/e;
			$temp2 =~ s/<m>/sprintf"%3s",$sk->{$skill}/e;

			$content .= $temp2;

			my $amt = ($skperc > $sk->{$skill} ? $sk->{$skill} : $skperc);
			$skill =~ tr/ /_/;
			my $train = qq|train $skill to:$amt|;
			push(@train_cmds, lc$train) if ($amt > 0);
		}
		$content .= $bottom_template;
		$content .= "$_\n" for (@train_cmds);



		# Spells
		$temp1 = $top_template;
		$temp1 =~ s/<g>/sprintf"%16s",ucfirst $g/e;
		$temp1 =~ s/<type>/Spells/;
		$temp1 =~ s/<l>/sprintf"%2s",$gl/e;
		$content .= $temp1;

		my @study_cmds = ();
		for my $spell (sort keys %{$sp}) {
			my $spell2 = $spell;
			$spell2 =~ tr/A-Z /a-z_/;
			my $spperc = $params{"spell_$spell2"} || 0;
			my $temp2 = $middle_template;

			$temp2 =~ s/<talent>/sprintf"%-35s",$spell/e;
			$temp2 =~ s/<c>/sprintf"%3s",$spperc/e;
			$temp2 =~ s/<m>/sprintf"%3s",$sp->{$spell}/e;

			$content .= $temp2;

			my $amt = ($spperc > $sp->{$spell} ? $sp->{$spell} : $spperc);
			$spell =~ tr/ /_/;
			my $study = qq|study $spell to:$amt|;
			push(@study_cmds, lc$study) if ($amt > 0);
		}
		$content .= $bottom_template;
		$content .= "$_\n" for (@study_cmds);
	}



	$content .= "</code></pre>\n";
}

&pageOutput('reincview', $content);

1;




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

__END__

