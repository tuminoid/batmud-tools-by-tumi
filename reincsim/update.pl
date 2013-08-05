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

# Strict is always good
use strict;

use IO::File;
use CGI qw/param/;

my %racial_information = ();
my (%ratios_skills1, %ratios_skills2, %ratios_spells1, %ratios_spells2, %ratios_arcane);
my @arcane_skills = ();
my @non_arcane_skills = ();
my %arcanehash = ();

`cp data/skill_basecosts.txt data/skill_basecosts.txt.old`;
`cp data/spell_basecosts.txt data/spell_basecosts.txt.old`;

&findSkillBaseCosts();

1;


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
	my $fhskills = new IO::File "data/skill_basecosts.txt", "w";
	my $fhspells = new IO::File "data/spell_basecosts.txt", "w";
	my %basecosthash = ();

	# If racial information hash is empty, load it up
	&loadRacialInformation();


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
			my ($talent, $level, $maxracial, $maxlevel, $cost) =
				$line =~ m#^\| (.*?)\s*\|\s+(\d+) \|\s+(\d+) \|\s+(\d+) \|\s+(\d+)#;

			# Which stuff were dealing with
			if ($line =~ /(Skills|Spells) available at level/) {
				my @info = &getRaceInfo($race);
				$dataref = $1 eq "Skills" ? \%skillhash : \%spellhash;
				$modif = $1 eq "Skills" ? $info[2] : $info[3];
				$modif = $modif eq "?" ? 100 : $modif;
			}

			# Go forward if line is corrupt or wrong
			next unless ($talent && $maxlevel && $cost);
			#print STDERR "guild= $guild, talent= $talent, race= $race, modif= $modif, cost= $cost"
				#if ($talent =~ /claw/i);

			$talent = sprintf("%-36s", $talent);


			# If skill isn't trained at all, its basecost is only modified
			# with the racial skillcost it was taken with
			if ($level == 0) {
				$dataref->{$talent} = &modifyRacialCost($cost, $modif);
				#print STDERR ", new: stored as is" if ($talent =~ /claw/i);

			# Or calculated with firstPercent, then modified and then stored
			} elsif (!(defined $dataref->{$talent}) || $dataref->{$talent} < 1) {
				$dataref->{$talent} = &modifyRacialCost(&firstPercent($level, $cost, $maxracial, $maxlevel, $talent), $modif);
				#print STDERR ", new: $dataref->{$talent}" if ($talent =~ /claw/i);

			# Or value is discarded
			} else {
				#print STDERR ", new: discarded" if ($talent =~ /claw/i);
			}
			#print STDERR "\n" if ($talent =~ /claw/i);

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



sub getRaceInfo {
	my $race = shift || 'human';

	&loadRacialInformation()
		if (scalar keys %racial_information < 1);

	return @{$racial_information{$race}};
}
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

sub getRatio {
	my $tgt = shift || 0;
	my $type = shift || "skill";
	my $basecost = shift || 50;
	my $talent = shift || "consider";

	my ($ratref, $file);

	if ($type eq "skill") {$ratref = \%ratios_skills1; $file="cg";}
	if ($type eq "spell") {$ratref = \%ratios_spells1; $file="dd";}


	return $ratref->{$tgt}
		if (defined $ratref->{$tgt});

	my $fh = new IO::File "data/ratios_$file\.txt", "r";
	return "1.09" unless ($fh && $tgt);

	while (my $line = <$fh>) {
		 # 1%: ratio=  2.105 (    190 ->     194)
		 my ($thisperc, $ratio) = $line =~ /\s*(\d+)%: ratio=\s+([0-9.]+)/;
		 next unless ($thisperc && $ratio);
		 $ratref->{$thisperc} = $ratio;
	}

	# #print STDERR "returning ratio $ratios{$tgt}\n";
	return $ratref->{$tgt} || "1.09";
}


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

sub modifyRacialCost {
	my $cost = shift;
	my $skillcost = shift || 100;

	return int($cost * 100.0 / $skillcost);
}




