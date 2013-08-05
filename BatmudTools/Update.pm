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

package BatmudTools::Update;
use strict;
use IO::File;
#use Net::Telnet;
use HTML::Entities;
use vars qw($VERSION @ISA @EXPORT);
use vars qw/$telnet $not_finished/;

# own stuff
# use lib '/home/twomi/web/libs';
use lib '/home/customers/tumi/public_html/archives/batmudtools';
use lib '/home/customers/tumi/tumilib/lib';
use Tumi::Helper;
use Tumi::DB;
use BatmudTools::Vars;

$VERSION = '0.1';
require Exporter;
use DynaLoader();
@ISA = qw(Exporter DynaLoader);
@EXPORT = qw(updateAll);





1;



sub updateAll() {
	my $siteroot = &getVar('siteroot');
	my ($day, $month, $year, $wday) = (localtime)[3..6];
	my $postfix = sprintf("%04d%02d%02d.txt", $year+1900, $month+1, $day);
	my %files = ();


	# monthly expplaque
	my $exproot = "$siteroot/expplaque";
	if ($day == 1) {
		my $prefix = "source/monthly-";
		my $file = "$exproot/$prefix$postfix";

		unless (-e $file && (stat($file))[7] > 5000) {
			$files{$file} = &getVar('exp_uses_db') ? &_updateExpplaqueDB() : &_updateExpplaque();
		}
	}


	# monthly expplaque
	if ($wday == 1) {
		my $prefix = "source/weekly-";
		my $file = "$exproot/$prefix$postfix";

		unless (-e $file && (stat($file))[7] > 5000) {
			$files{$file} = &getVar('exp_uses_db') ? &_updateExpplaqueDB() : &_updateExpplaque();
		}
	}


	# weekly exploreplaque
	my $exploreroot = "$siteroot/explore";
	if ($wday == 1) {
		my $prefix = "source/weekly-";
		my $file = "$exploreroot/$prefix$postfix";

		unless (-e $file && (stat($file))[7] > 5000) {
			$files{$file} = &_updateExploreDB();
		}
	}


	# monthly exploreplaque
	if ($day == 1) {
		my $prefix = "source/monthly-";
		my $file = "$exploreroot/$prefix$postfix";

		unless (-e $file && (stat($file))[7] > 5000) {
			$files{$file} = &_updateExploreDB();
		}
	}


	# weekly questplaque
	my $questroot = "$siteroot/quests";
	if ($wday == 1) {
		my $prefix = "source/weekly-";
		my $file = "$questroot/$prefix$postfix";

		unless (-e $file && (stat($file))[7] > 5000) {
			$files{$file} = &_updateQuestDB();
		}
	}


	# monthly questplaque
	if ($day == 1) {
		my $prefix = "source/monthly-";
		my $file = "$questroot/$prefix$postfix";

		unless (-e $file && (stat($file))[7] > 5000) {
			$files{$file} = &_updateQuestDB();
		}
	}

	# write data to files
	foreach my $file (keys %files) {
		print STDERR "Writing: $file\n";
		my $fh = new IO::File $file, "w";
		print $fh $files{$file};
		undef $fh;
		print STDERR "File len: ".((stat($file))[7])."\n";
	}


	1;
}



sub _updateExploreDB() {
	my $output = "";
	my $sql = <<until_end;
SELECT player,lvl,rooms
FROM bat.exploreplaque
ORDER BY rooms DESC,player ASC
LIMIT 1000;
until_end

	&dbSetup('bat@www-i', &getVar('mysql_user'), &getVar('mysql_pass'));
	my $sth = &dbGet('bat@www-i', $sql);
	return "" unless ($sth);

	while (my $row = $sth->fetchrow_hashref()) {
		$output .= sprintf("%s,%s,%s\n", $row->{'player'}, $row->{'lvl'}, $row->{'rooms'});
	}

	return $output;
}



sub _updateQuestDB() {
	my $output = "";
	my $sql = <<until_end;
SELECT player,lvl,numquests
FROM bat.questplaque
ORDER BY numquests DESC,player ASC
LIMIT 1000;
until_end

	&dbSetup('bat@www-i', &getVar('mysql_user'), &getVar('mysql_pass'));
	my $sth = &dbGet('bat@www-i', $sql);
	return "" unless ($sth);

	while (my $row = $sth->fetchrow_hashref()) {
		$output .= sprintf("%s,%s,%s\n", $row->{'player'}, $row->{'lvl'}, $row->{'numquests'});
	}

	return $output;
}



sub _updateExpplaqueDB() {
	my $sql = <<until_end;
SELECT player,lvl,totexp,hideexp
FROM bat.expplaque
ORDER BY totexp DESC,player ASC;
until_end

	&dbSetup('bat@www-i', &getVar('mysql_user'), &getVar('mysql_pass'));
	my $sth = &dbGet('bat@www-i', $sql);
	return "" unless ($sth);
	my $pos = 0;
	my $output = "Top 1000 signed players on BatMUD\n";

	while (my $row = $sth->fetchrow_hashref()) {
		$pos++;
		if (!$row->{'hideexp'} && $row->{'totexp'} > 3000000) {
			my $mills = int($row->{'totexp'} / 1000000) > 0 ? int($row->{'totexp'} / 1000000) : "";
			my $rest = $row->{'totexp'} % 1000000;

#  12: Dogi            100     469 763371  1 day 17 hours
			my $addon = sprintf("%4d: %-16s  %3d    %4s %06d\n",
				$pos++, $row->{'player'}, $row->{'lvl'}, $mills, $rest);
			$output .= $addon;
			#print STDERR "Added: $addon";
		}
	}

	return $output;
}




sub _updateExpplaque() {
	return "";
}

__END__

sub _updateExpplaqueOrig() {
	my $output = "";
	$not_finished = 1;
	my $siteroot = &getVar('siteroot');

	$telnet = new Net::Telnet(
		Timeout 				=> 5,
		Host					=> 'batmud.bat.org',
		Port					=> 23,
		Output_log				=> "$siteroot/expplaque/logs/out.log",
		Input_log				=> "$siteroot/expplaque/logs/in.log",
		Output_record_separator	=> "\n",
		Input_record_separator	=> "\n",
	);

	return ""
		unless $telnet;

	$telnet->waitfor(String => 'Please enter your choice or name');
	$telnet->print("2");
	$telnet->waitfor(String => 'Press enter to continue');
	$telnet->print("");
	sleep 3;
	$telnet->print("3 e;s;u");
	$telnet->print("look at long list");

	while ($not_finished) {
		sleep 1;
		my ($prematch, $match) = $telnet->waitfor(
			String => 'More',
			Errmode => \&damnit,
			Timeout => 3,
		);

		if ($not_finished && $match =~ /^More/) {
			$prematch =~ s#^(\s*\(\d+%\) \[qpbns\?\])##gi;
			$output .= $prematch;
			$telnet->print("");

		} else {
			$telnet->print("");
			last;
		}
	}

	return $output;
}


sub damnit {
	$telnet->print("say Updated the exp-plaque, come see at http://support.bat.org/expplaque/ !");
	$telnet->print("wave");
	$telnet->print("quit");
	$not_finished = 0;
}




__END__

