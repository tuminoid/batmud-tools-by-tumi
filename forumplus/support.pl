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
use IO::File;
use POSIX qw/strftime/;

# my stuff
# use lib '/home/twomi/web/libs';
use lib '/home/customers/tumi/public_html/archives/batmud';
use lib '/home/customers/tumi/tumilib';
use Tumi::Helper;
use BatmudTools::Site;
use BatmudTools::Vars;
use BatmudTools::Login;

my ($party_open, $party_success, $party_fail, $party_cancelled) = (0,0,0,0);
my %partylead_cache = ();
my %partyeq_cache = ();
my %partymember_cache = ();
my %partymember30_cache = ();


# gamename => loginname
my %usermapping = (
	"society"	=> "society",
	"twomi"		=> "admin",
	"calmar"	=> "Calmar",
	"cilwand"	=> "Cilwand",
#	"cutter"	=> "cutter",
#	"deras"		=> "deras",
	"descad"	=> "Descad",
#	"ealoren"	=> "ealoren",
#	"eronk"		=> "eronk",
	"farliss"	=> "Farliss",
#	"farthon"	=> "farthon",
	"flora"		=> "Flora",
	"gaurhoth"	=> "Gaurhoth",
	"grediah"	=> "Grediah",
	"grimpold"	=> "Grimpold",
	"heretic"	=> "Heretic",
#	"juo"		=> "juo",
	"kawasa"	=> "Kawasa",
#	"keat"		=> "keat",
	"kyynel"	=> "Kyynel",
	"lightscape"=> "Lightscape",
#	"mandrake"	=> "mandrake",
#	"miger"		=> "miger",
#	"milk"		=> "milk",
#	"murrough"	=> "murrough",
	"nufan"		=> "Nufan",
	"orthanc"	=> "Orthanc",
	"rankku"	=> "Rankku",
	"turmio"	=> "Turmio",
	"zenick"	=> "Zenick",
#	"gorph"		=> "gorph",
	"walciz"	=> "Walciz",
#	"runko"		=> "runko",
	"zithromax"	=> "Zithromax",
	"brog"		=> "Brog",
	"era"		=> "Era",
	"mendar"	=> "Mendar",
#	"peelo"		=> "peelo",
	"capula"	=> "Parru",
	"foxbat"	=> "Foxbat",
);




my %guilds = (
	"-1" => "--Select a guild--",
	"00" => "Civilized mages",
	"01" => "Civilized fighters",
	"02" => "Runemages",
	"03" => "Bards",
	"04" => "Sabres",
	"05" => "Merchants",
	"06" => "Alchemists",
	"07" => "Knights",
	"08" => "Nuns",
	"09" => "Druids",
	"10" => "Tarmalens",
	"11" => "Monks",
	"12" => "Templars",
	"13" => "Lords of Chaos",
	"14" => "Priests",
	"15" => "Reavers",
	"16" => "Spiders",
	"17" => "Tigers",
	"18" => "Conjurers",
	"19" => "Mages",
	"20" => "Psionicists",
	"21" => "Channellers",
	"22" => "Rangers",
	"23" => "Crimsons",
	"24" => "Barbarians",
	"25" => "Squires",
	"26" => "Beastmasters",
	"27" => "Cavaliers",
	"28" => "SS",
	"29" => "Navigators",
);


my %gshort = (
	"--Select a guild--"	=> "",
	"Civilized mages"		=> "CivMage",
	"Civilized fighters"	=> "CivFig",
	"Runemages"				=> "Rune",
	"Bards"					=> "Bard",
	"Sabres"				=> "Sabre",
	"Merchants"				=> "Merch",
	"Alchemists"			=> "Alch",
	"Knights"				=> "Knight",
	"Nuns"					=> "Nun",
	"Druids"				=> "Druid",
	"Tarmalens"				=> "Tarm",
	"Monks"					=> "Monk",
	"Templars"				=> "Templa",
	"Lords of Chaos"		=> "LoC",
	"Priests"				=> "Priest",
	"Reavers"				=> "Reaver",
	"Spiders"				=> "Spider",
	"Tigers"				=> "Tiger",
	"Conjurers"				=> "Conju",
	"Mages"					=> "Mage",
	"Psionicists"			=> "Psi",
	"Channellers"			=> "Channu",
	"Rangers"				=> "Ranger",
	"Crimsons"				=> "Crimso",
	"Barbarians"			=> "Barb",
	"Squires"				=> "Squire",
	"Beastmasters"			=> "Beast",
	"Cavaliers"				=> "Cava",
	"SS"					=> "SS",
	"Navigators"			=> "Nav",
);

my @racelist = (
	"barsoomian", "brownie", "catfolk", "centaur", "cromagnon", "cyclops",
	"demon", "draconian", "drow", "duck", "duergar", "dwarf", "elf", "ent",
	"gargoyle", "giant", "gnoll", "gnome", "hobbit", "human", "kobold", "leech",
	"leprechaun", "lich", "lizardman", "merfolk", "minotaur", "moomin", "ogre",
	"orc", "penguin", "satyr", "shadow", "skeleton", "sprite", "thrikhren",
	"tinmen", "titan", "troll", "valar", "vampire", "wolfman", "zombie",
);


my @possibleTypes = (
	"1st row - HaboTank", "1st row - BardTank", "1st row - TarmTank",
		"1st row - NomadTank", "1st row - Any tank", "1st row - Non-nomad tank",
		"1st row - Tarm- or Nomadtank",
	"TarmaDruid", "TarmaNun", "NunDruid", "Any tarma", "Any nun",
	"ConjuMage", "MageChannu", "Any conju", "Any mage",
	"ConjuChannu", "PsiChannu", "Any channu",
	"Any priest", "Blaster, non-channu", "Blaster, non-psi",
		"Blaster, area", "Any blaster",
	"Psichan or priest", "Conjumage or priest",
	"BardSomething", "RuneBard", "Any bard",
	"Anyone", "Outsider, diced", "Outsider, paid",
	"CLOSED",
);


# Directory listings
my @_users = ();
my @_items = ();
my @_auctions = ();
my @_bids = ();
my @_parties = ();
my @_logs = ();


# Some mappings
my %_displaynames = ();
my %_validmembers = ();
my %_validofficers = ();

my %_userdata = ();
my %_itemdata = ();
my %_partydata = ();
my %_debtdata = ();
my %_auctiondata = ();
my %_biddata = ();
my %_pointdata = ();
my %_usermapping = ();


1;



my %menus = (
	"00 Log in"				=> "forumplus/index.pl?pageid=00&amp;action=login",
	"01 Start"				=> "forumplus/index.pl?pageid=01",
	"05 Rules"				=> "forumplus/index.pl?pageid=05",
#	"07 PartyRSS"			=> 'forumplus/rss.pl?user=%s',
	"08 Log out"			=> "forumplus/index.pl?pageid=99&amp;action=logout",
	"09 Tools"				=> "-",
	"10 Profile"			=> "forumplus/index.pl?pageid=10",
# 11 - view log
	#"20 Links"				=> "forumplus/index.pl?pageid=20",
	"21 Debts"				=> "forumplus/index.pl?pageid=22",
	"22 Transfers"			=> "forumplus/index.pl?pageid=24",
	"24 Actions&nbsp;log"	=> "forumplus/index.pl?pageid=21",
	"26 Points&nbsp;log"	=> "forumplus/index.pl?pageid=23",
	"29 Lists"				=> "-",
	"30 Members"			=> "forumplus/index.pl?pageid=30",
	"40 Parties"			=> "forumplus/index.pl?pageid=40",
# 41 - view single party
# 42 - join/leave party
# 43 - createparty
	"50 Auctions"			=> "forumplus/index.pl?pageid=50",
	"51 Items"				=> "forumplus/index.pl?pageid=51",
# 52 - single item eq
# 53 - auction single item
	 "55 Search"                    => "forumplus/index.pl?pageid=55",

# officer only
	"60 Officers"			=> "-",
	"61 Add&nbsp;item"		=> "forumplus/index.pl?pageid=61",
	"62 Add&nbsp;auction"	=> "forumplus/index.pl?pageid=62",
# 63 - close auction
	"64 Handouts"			=> "forumplus/index.pl?pageid=64",

# admin only
	"70 Admin"				=> "-",
	"71 Points"			=> "forumplus/index.pl?pageid=70",
	"72 Det.points"			=> "forumplus/index.pl?pageid=65",
	"73 Users"				=> "forumplus/index.pl?pageid=72",

);



#
# Creates menu
#
sub createMenu {
	my $user = shift;

	my $menucode = <<until_end;
<tr class="menutitle" style="font-size: 1.2em;"><td colspan="2">Forum+</td></tr>
until_end


	for my $item (sort keys %menus) {
		my @text = $item =~ /^\d+ (.*)/;
		my $link = $menus{$item};

		next unless ($user);
		next if ($user && $item =~ /^00/);
		next if ($item =~ /^6/ && !&isValidOfficer($user));
		next if ($item =~ /^7/ && $user ne "admin");
		next unless (&isProfiledMember($user) || $item =~ /^(10|08|05) /);

		$link =~ s/\%s/$user/g;
		if ($link eq "-") {
			$menucode .= qq|<tr><td colspan="2">&nbsp;</td></tr>\n|;
			$menucode .= qq|<tr class="menutitle"><td colspan="2">$text[0]</td></tr>\n|;
		} else {
			$menucode .= qq|<tr class="menuitem"><td colspan="2"><a href="$link">$text[0]</a></td></tr>\n|;
		}
	}

	if (&isProfiledMember($user)) {
		my %udata = &getData($user, "data/users");
		#my ($bids, $debts, $maxdebt, $points, $incoming) = (0,0,0,0,0);
		my $logged = &getDisplayName($user);
		my $bids = &countWinningBids($user);
		my ($debts, $maxdebt) = &countDebts($user, 1);
		my $points = &getPoints($user);
		my $incoming = &getIncomingPoints($user);
		my ($whosin, $number) = &currentlyLogged(1);

		$menucode .= <<until_end;
	<tr><td colspan="2">&nbsp;</td></tr>
	<tr class="menutitle"><td colspan="2">Info</td></tr>
	<tr class="userinfo"><td><b>Login</b></td><td>$logged</td></tr>
	<tr class="userinfo"><td><b>Points</b></td><td>$points</td></tr>
	<tr class="userinfo"><td><b>Incoming</b></td><td>$incoming</td></tr>
	<tr class="userinfo"><td><b>Bids</b></td><td>$bids</td></tr>
	<tr class="userinfo"><td><b>Debts</b></td><td>$debts</td></tr>

	<tr><td colspan="2">&nbsp;</td></tr>
	<tr class="menutitle"><td colspan="2">Online&nbsp;($number)</td></tr>
	<tr class="userinfo"><td colspan="2">$whosin</td></tr>

until_end
	}

	return $menucode;
}




#
# Read logfile
#
sub getLogs {
	my $user = shift;
	return () unless ($user && -e "data/logs/$user.dat");

	my $fh = new IO::File "data/logs/$user.dat", "r";
	my @logs = <$fh>;

	return @logs;
}




#
# Creates option field
#
sub createGuildSelection {
	my $selected_id = shift || "-1";
	my $options = "";

	for my $gid (sort {$guilds{$a} cmp $guilds{$b}} keys %guilds) {
		my $gname = $guilds{$gid};
		my $sel = $gid eq "$selected_id" ? " selected" : "";
		$options .= "<option value=\"$gid\"$sel>$gname</option>\n";
	}

	return $options;
}



sub createRaceSelection {
	my $prev = shift;

	my $options = "<option value=\"\">--Select--</option>\n";

	for my $race (sort @racelist) {
		my $disp = ucfirst $race;
		my $sel = $prev eq $race ? " selected" : "";
		$options .= "<option value=\"$race\"$sel>$disp</option>\n";
	}

	return $options;
}





#
# Creates option list filled with players
#
sub createPlayerSelection {
	my $prev = shift || "";
	my $onlyactive = shift || 0;

	my @members = &listFiles("data/users");
	my $options = "<option value=\"\">--Select--</option>\n";

	for my $user (sort {(lc &getDisplayName($a)) cmp (lc &getDisplayName($b))} @members) {
		next if ($onlyactive && !&isValidMember($user));
		my $disp = &getDisplayName($user);
		my $sel = $prev eq $user ? " selected" : "";
		$options .= "<option value=\"$user\"$sel>$disp</option>\n";
	}

	return $options;
}



#
# Create level selection
#
sub createLevelSelection {
	my $prev = shift || 0;
	my $html = "";

	for my $level (50..100) {
		my $sel = $level == $prev ? " selected" : "";
		$html .= "<option value=\"$level\"$sel>$level</option>\n";
	}

	return $html;
}



#
# create options list for html select for items
#
sub createItemSelection {
	my $prev = shift;
	my $reverse = shift || 0;
	my @items = &listFiles("data/items");
	my $html = "";

	for my $itemid (sort {&itemsort($a,$b,$reverse)} @items) {
		my %idata = &getData($itemid, "data/items");
		my $short = $idata{'name'};
		my $bonuses = &itemBonusString($itemid);
		my $sel = $prev eq $itemid ? " selected" : "";

		$html .= "<option value=\"$itemid\"$sel>$short - $bonuses</option>\n";
	}

	return $html;
}




#
# creates party status selection
#
sub createStatusSelection {
	my $prev = shift || 'Open';
	my @possibilities = ( 'Open', 'Full', 'Over', 'Failed', 'Cancelled' );

	my $html = "<select name=\"status\">\n";
	for my $st (@possibilities) {
		my $sel = (lc$st) eq (lc$prev) ? " selected" : "";
		$html .= "<option value=\"".(lc$st)."\"$sel>$st</option>\n";
	}
	$html .= "</select>\n";

	return $html;
}



#
# Creates member type selection for party create
#
sub createMemberSelection {
	my $ppos = shift || '11';
	my $prev = shift || 'Anyone';

	my @users = grep {&isValidMember($_)} &listFiles("data/users");
	my @members = sort {advancedsort($a,$b,"sortstring")}
		map {$_ = &getDisplayName($_)} @users;

	my $html = "<select name=\"wanted$ppos\">\n";
	for my $type ((sort @possibleTypes), @members) {
		my $sel = $type eq $prev ? " selected" : "";
		$html .= "<option value=\"$type\"$sel>$type</option>\n";
	}
	$html .= "</select>\n";

	return $html;
}



#
# createdate selection
#
sub createDateSelection {
	my $timestamp = shift || 0;
	my $html = "";

	my @wdays = ("Sunnuntai", "Maanantai", "Tiistai", "Keskiviikko", "Torstai", "Perjantai", "Lauantai");

	for my $date (-7..45) {
		my @tt = localtime(time());
		my $today0 = time()-$tt[0]-$tt[1]*60-$tt[2]*60*60;
		my $timetobe = $today0+$date*24*60*60;
		my @timearray = localtime($timetobe);
		my $humandate = "$timearray[3].".($timearray[4]+1).".".($timearray[5]+1900)." (".$wdays[$timearray[6]].")";

		my $sel = $timestamp == $timetobe ? " selected" : "";
		$html .= "<option value=\"$timetobe\"$sel>$humandate</option>\n";
	}

	return $html;
}



#
# returns a single line for party
#
sub getPartyLine {
	my $user = shift;
	my $pid = shift;
	return "" unless (-e "data/parties/$pid.dat");

	my %pdata = &getData($pid, "data/parties");
	#my $startdate = (scalar localtime($pdata{'starting'}));
	my $startdate = &datefmt($pdata{'starting'});
	my $starttime = &verboseDate($pdata{'starting'});
	#my $ok_members = scalar (&listPartyMembers($pid));
	#my $maxmembers = &partySlots($pid);
	my $creator = &getDisplayName($pdata{'creator'});
	my $color = "White";
	my $member = &isPartyMember($user, $pid) ? "<br />(member)" : "";
	my $membermapping = &describeParty($user, $pid);
	my $pname = $pdata{'name'} || "(untitled)";

	$color = "winbid" if ($pdata{'status'} eq "full");
	$color = "completed" if ($pdata{'status'} eq "over");
	$color = "losebid" if ($pdata{'status'} eq "open");
	$color = "noauction" if ($pdata{'status'} eq "cancelled");


	my $html = <<until_end;
<tr><td><a href="forumplus/index.pl?pageid=41&amp;action=view&amp;id=$pid">$pname</a></td>
<td>$creator</td><td>$startdate</td><td>$starttime</td>
<td class="cntr">$membermapping</td>
<!-- <td class="$color"><b>$pdata{'status'}</b> $member</td> -->
</tr>
until_end

	return $html;
}


sub getAuctionLine {
	my $user = shift;
	my $aid = shift;
	my $pagetgt = shift;

	my %aucdata = &getData($aid, "data/auctions");
	return "aid $aid invalid" unless (%aucdata && (keys %aucdata) > 0);

	# Auction data
	my ($itemid, $added, $status, $itemnames, $itemhelpers) =
		($aucdata{'itemid'}, scalar localtime($aucdata{'opened'}),
		$aucdata{'status'},	$aucdata{'names'}, $aucdata{'helpers'});

	# Item the auction is about
	my %itemdata = &getData($itemid, "data/items");
	my ($itemname, $bonuses) = ($itemdata{'name'}, &itemBonusString($itemid));

	my ($highbid, $highuser) = &getHighestBid($aid);
	$highuser = &getDisplayName($highuser);
	my ($usermsg, $color) = &getUserAuctionStatus($user, $aid, $pagetgt);
	my $closing = &verboseDate(&getAuctionClosing($aid));

	my $officeredit = &isValidOfficer($user) ? qq|/<a href="forumplus/index.pl?pageid=53&amp;action=edit&amp;id=$aid">edit</a>| : "";



	my $output = <<until_end;
<tr><td><a href="forumplus/index.pl?pageid=52&amp;action=view&amp;id=$itemid">$itemname</a></td>
<td>$bonuses</td><td>$closing</td><td class="$color">$usermsg</td>
<td class="cntr">
	<a href="forumplus/index.pl?pageid=53&amp;action=view&amp;id=$aid">view</a>$officeredit
</td>
</tr>
until_end

	return $output;
}




sub memberClass {
	my $user = shift;
	return "" unless (&isProfiledMember($user));

	my $combo = &getGuildCombo($user);

	return "Tank, Bard" if ($combo =~ /Bard/ && $combo =~ /Sabre|Knight|Cavalier/);
	return "MageConju" if ($combo =~ /Mage/ && $combo =~ /Conju/);
	return "TarmDruid" if ($combo =~ /TarmDruid/);
	return "TarmNun" if ($combo =~ /TarmNun/);
	return "Tank, Tarm" if ($combo =~ /Tarm/ && $combo =~ /Templa/);
	return "Tank, Habo" if ($combo =~ /ReaverPriest/);
	return "Priest" if ($combo =~ /Priest/);
	return "Tank, Nomad" if ($combo =~ /Crimso/ || $combo =~ /Ranger/ || $combo =~ /Barb/);
	return "Expreinc?";
}




#
# describes member
#
sub describeMember {
	my $user = shift;
	return $user unless (&isProfiledMember($user));

	my %udata = &getData($user, "data/users");
	my $display = &getDisplayName($user);
	my $level = $udata{'level'};
	my $race = ucfirst $udata{'race'};
	my $gstring = &shortenGuild(&verboseGuild($udata{'guild1'}, $udata{'guild2'}, $udata{'guild3'}));
	my ($hp, $sp) = ($udata{'hpmax'}, $udata{'spmax'});
	my $desc = length($udata{'desc'})>0 ? qq|<tr><td colspan="2">$udata{'desc'}</td></tr>\n| : "";

	my $html = <<until_end;
<table class="describemember">
<tr><td><b>$display</b></td><td>$level - $race</td></tr>
<tr><td><b>$gstring</b></td><td>$hp/$sp</td></tr>
$desc
</table>
until_end

	return $html;
}





#
# is this a member of forum+
#
sub getDisplayName {
	my $user = shift || "";
	my $addition =  &isValidOfficer($user) ? "©" : "";
	my %info = &getYabb2Userinfo($user);

	return "..$user" if ((keys %info) < 10);
	return $info{'realname'}.$addition;
}




#
# gets members guildcombo in short
#
sub getGuildCombo {
	my $user = shift;
	return "" unless (&isProfiledMember($user));

	my %udata = &getData($user, "data/users");
	return &shortenGuild(&verboseGuild($udata{'guild1'}, $udata{'guild2'}, $udata{'guild3'}));
}




#
# gives login name casesensitive
#
sub getLoginName {
	my $lcname = shift;
	return &getGameName($lcname);
}



#
# is this a member of forum+
#
sub isValidMember {
	my $user = shift;
	return (&checkYabb2ForumAccess($user))[2];
}



#
# does member have a profile
#
sub isProfiledMember {
	my $user = shift;
	return (&isValidMember($user) && -e "data/users/$user.dat");
}



#
# is member also an officer
#
sub isValidOfficer {
	my $user = shift || "";
	return (&checkYabb2ForumAccess($user))[1];
}






#
# gives members in party
#
sub listPartyMembers {
	my $pid = shift;
	return () unless ($pid && -e "data/parties/$pid.dat");

	my %pdata = &getData($pid, "data/parties");
	my @members = ();
	for my $key (keys %pdata) {
		push @members, "outsider" if ($key =~ /^wanted\d{2}/ && $pdata{$key} =~ /outsider/i);
		next unless ($key =~ /^member/);
		my ($pos) = ($key =~ /^member(\d{2})/);
		my $member = $pdata{$key} || "";
		push @members, $member;
	}

	return @members;
}


#
# is user party member
#
sub isPartyMember {
	my $user = shift;
	my $pid = shift;
	my %pdata = &getData($pid, "data/parties");

	return (scalar (grep {(($user eq $pdata{$_}) && ($_=~/^member/));} keys %pdata) > 0);
}



#
# what slot user the member in party
#
sub partyMemberSlot {
	my $user = shift;
	my $pid = shift;
	return "" unless (&isValidMember($user) && $pid);
	return "" unless (&isPartyMember($user, $pid));

	my %pdata = &getData($pid, "data/parties");

	for my $memberslot (sort keys %pdata) {
		return $1 if ($memberslot =~ /^member(\d{2})/ && $pdata{$memberslot} eq $user);
	}

	return "";
}


sub partySlots {
	my $pid = shift;
	my %pdata = &getData($pid, "data/parties");
	my $members = 0;

	for my $slot (grep {/wanted(\d{2})/} keys %pdata) {
		$members += 1 unless ($pdata{$slot} =~ /CLOSED/);
	}

	return $members;
}



sub describeParty {
	my $user = shift;
	my $pid = shift;
	my %pdata = &getData($pid, "data/parties");

	my $ok_members = scalar (&listPartyMembers($pid));
	my $maxmembers = &partySlots($pid);
	my $member = &isPartyMember($user, $pid) ? "(member)" : "&nbsp;";
	my %cdata = &getData($pid, "data/comments/party");
	my $commentcount = scalar (keys %cdata);

	my %pf = ();
	for my $key (keys %pdata) {
		next unless ($key =~ /^wanted/);

		my $value = $pdata{$key};
		my $spot = substr($key, 6, 2);
		my $taken = "free";

		if ($value eq "CLOSED") {
			$taken = "closed";
		} elsif ($value =~ /^outsider/i) {
			$taken = "outsider";
		} elsif ($pdata{"member$spot"} eq $user) {
			$taken = "you";
		} elsif (length($pdata{"member$spot"}) > 2) {
			$taken = "taken";
		}

		$pf{"$spot"} = $taken;
	}

	my @tiles = ();
	for my $spot (sort keys %pf) {
		my $status = $pf{$spot};
		my $code = "";

		if ($status eq "outsider") {
			push @tiles, "o";
		} elsif ($status eq "taken") {
			push @tiles, "t";
		} elsif ($status eq "free") {
			push @tiles, "f";
		} elsif ($status eq "you") {
			push @tiles, "u";
		} elsif ($status eq "closed") {
			push @tiles, "c";
		}
	}
	my $mmap_url = qq|forumplus/membermap.pl?size=medium&amp;pos=|.join(",",@tiles);

	my $output = <<until_end;
<table>
<tr>
<td><img src="$mmap_url" alt="membermap" width="42" height="42" title="Membermap of $pdata{'name'}" /></td>
<td style="width: 100%;">
$ok_members&nbsp;/&nbsp;$maxmembers<br />
<b>$pdata{'status'}</b> $member<br />
$commentcount comments<br />
</td>
</tr>
</table>
until_end

	return $output;
}




#
# returns a hash with usernames as index and partycount as value
#
# pid: status,state,starting,comments,leader,members
#
sub _findPartyMembershipsWithLimit {
    my $timelimit = shift || time();

    my %res = ();
    my %pcache = &getData("parties.cache", "data");
    for my $pid (keys %pcache) {
	my ($status, $state, $starting, $comments, $leader, $members) = split/,/,$pcache{$pid};
	next unless ($status);	# only closed ones
	next if ((time() - $starting) > $timelimit); # if limit has been passed

	my @memlist = split/;/, $members;
	for my $mem (@memlist) {
	    my $prev = $res{$mem};
	    $res{$mem} = $prev ? $prev+1 : 1;
	}
    }

    return %res;
}

sub _findPartyMemberships {
    return %partymember_cache
	if ((keys %partymember_cache) > 0);
    %partymember_cache = &findPartyMembershipsWithLimit();
    return %partymember_cache;
}

sub _findPartyMembershipsLast30 {
    return %partymember30_cache
	if ((keys %partymember30_cache) > 0);
    %partymember30_cache = &findPartyMembershipsWithLimit(30*24*60*60);
    return %partymember30_cache;
}




sub findPartyMemberships {
	return %partymember_cache
		if ((keys %partymember_cache) > 0);

	my @parties = &listFiles("data/parties");
	for my $pid (@parties) {
		my %pdata = &getData($pid, "data/parties");
		next unless ($pdata{'status'} =~ /over|failed/);

		for my $key (sort keys %pdata) {
			next unless ($key =~ /^member/);
			my $prev = $partymember_cache{$pdata{$key}};
			$partymember_cache{$pdata{$key}} = $prev ? $prev+1 : 1;
		}
	}

	return %partymember_cache;
}


sub findPartyMembershipsLast30 {
	return %partymember30_cache
	if ((keys %partymember30_cache) > 0);

	my @parties = &listFiles("data/parties");
	for my $pid (@parties) {
		my %pdata = &getData($pid, "data/parties");
		next unless ($pdata{'status'} =~ /over|failed/);
		next if ($pdata{'starting'} > time());
		next if (time() > (30*24*60*60 + $pdata{'starting'}));

		for my $key (sort keys %pdata) {
			next unless ($key =~ /^member/);
			my $prev = $partymember30_cache{$pdata{$key}};
			$partymember30_cache{$pdata{$key}} = $prev ? $prev+1 : 1;
		}
	}

	return %partymember30_cache;
}


#
# counts how many parties the user has led
#
sub countPartyLeads {
	my $user = shift;
	return unless (defined $user);

	return ($partylead_cache{$user} || 0)
		if ((keys %partylead_cache) > 0);

	my @parties = &listFiles("data/parties");
	my $count = 0;

	for my $pid (@parties) {
		my %pdata = &getData($pid, "data/parties");
		next unless ($pdata{'status'} =~ /over/);
		my $plead = $pdata{'creator'};
		$partylead_cache{$plead} = defined $partylead_cache{$plead} ?
			$partylead_cache{$plead}+1 : 1;
		$count++;
	}

	return $partylead_cache{$user} || 0;
}


sub countLeadEq {
	my @auctions = &listFiles("data/auctions");

	return %partyeq_cache
		if ((keys %partyeq_cache) > 0);

	for my $aid (@auctions) {
		my %adata = &getData($aid, "data/auctions");
		next unless ($adata{'status'} eq "closed");
		my ($hibid, $hiuser, $hitime) = &getHighestBid($aid);
		$partyeq_cache{$adata{'leader'}} += $hibid;
	}

	return %partyeq_cache;
}


sub countParties {
	my $party_total = $party_open+$party_success+$party_fail+$party_cancelled;

	return ($party_total, $party_open, $party_success, $party_fail, $party_cancelled)
		if ($party_total > 0);


	for my $pid (&listFiles("data/parties")) {
		my %pdata = &getData($pid, "data/parties");
		$party_open += 1 if ($pdata{'status'} =~ /open/i);
		$party_success += 1 if ($pdata{'status'} =~ /over/i);
		$party_fail += 1 if ($pdata{'status'} =~ /fail/i);
		$party_cancelled += 1 if ($pdata{'status'} =~ /cancel/i);
	}

	$party_total = $party_open+$party_success+$party_fail+$party_cancelled;
	return ($party_total, $party_open, $party_success, $party_fail, $party_cancelled)
	if ($party_total > 0);
}




#
# ----------------------- HELPER FUNCS ---------------------------
#


#
# Compares items by shortdesc, then bonuses
#
sub itemsort {
	my ($a, $b, $reverse) = @_;
	my %a_data = &getData($reverse==0 ? $a : $b, "data/items");
	my %b_data = &getData($reverse==0 ? $b : $a, "data/items");

	my $name_cmp = (lc$a_data{'name'}) cmp (lc$b_data{'name'});
	return ($a_data{'bonuses'} cmp $b_data{'bonuses'}) unless ($name_cmp);

	return ($name_cmp);
}



#
# reads directory
#
sub listFiles {
	my $dir = shift;
	return () unless (-e $dir);
#	my $base = &getVar('forumdata');

	# if we have stuff preloaded
	return @_users if ($dir =~ /users/ && @_users > 0);
	return @_bids if ($dir =~ /bids/ && @_bids > 0);
	return @_auctions if ($dir =~ /auctions/ && @_auctions > 0);
	return @_parties if ($dir =~ /parties/ && @_parties > 0);
	return @_items if ($dir =~ /items/ && @_items > 0);
	return @_logs if ($dir =~ /logs/ && @_logs > 0);

# -rw-r--r--  1 twomi twomi  84 May 29 12:45
	#my @filelist = ();
#	foreach my $line (`ls -l $dir`) {
	#foreach my $line (<$dir>) { #`ls -l $dir`) {
	#	$line =~ tr/\x0D\x0A//d;
	#	$line =~ /([a-zA-Z]+)\.dat$/;
	#	push @filelist, $1;
	#	print STDERR "Found '$dir': $1\n";
	#}
	#@filelist = grep {s/^.{43}(\w+)\.dat$/$1/;} @filelist;
	#@filelist = grep {} @filelist;
	#return @filelist;

	my @files = &getDir($dir, "*.dat");
	#print STDERR "debb: got ".(scalar @files)." files from '$dir'\n";
	#print STDERR "debb: ".join(", ", @files)."\n";
	foreach my $file (@files) {
		$file =~ s/\.dat//;
	}

	return @files;
}



#
# gets data from file
#
sub getData {
	my $id = shift;
	my $dir = shift;
	my $force = shift || 0;
	return () unless ($id && $dir && -e "$dir/$id.dat");

	my @lines = &getLines($id, $dir, $force);

	my %results = ();
	for my $line (@lines) {
		next if (length ($line) < 5);
		my ($opt, $val) = $line =~ /^(.*?): (.*)$/;
		$results{$opt} = $val;
	}

	return %results;
}



#
# reads lines from file
#
sub getLines {
	my $id = shift;
	my $dir = shift;
	my $force = shift || 0;

	# Checking if stuff already loaded
	if ($dir =~ /items/ && defined $_itemdata{$id} && !$force) {
		return (split/\|\|\|/, $_itemdata{$id});

	} elsif ($dir =~ /parties/ && defined $_partydata{$id} && !$force) {
		return (split/\|\|\|/, $_partydata{$id});

	} elsif ($dir =~ /users/ && defined $_userdata{$id} && !$force) {
		return (split/\|\|\|/, $_userdata{$id});

	} elsif ($dir =~ /debts/ && defined $_debtdata{$id} && !$force) {
		return (split/\|\|\|/, $_debtdata{$id});

	} elsif ($dir =~ /auctions/ && defined $_auctiondata{$id} && !$force) {
		return (split/\|\|\|/, $_auctiondata{$id});

	} elsif ($dir =~ /points/ && defined $_pointdata{$id} && !$force) {
		return (split/\|\|\|/, $_pointdata{$id});

	} elsif ($dir =~ /bids/ && defined $_biddata{$id} && !$force) {
		return (split/\|\|\|/, $_biddata{$id});
	}

	# wasn't hashed
	my $fh = new IO::File "$dir/$id.dat", "r";
	my @lines = <$fh>;
	map {tr/\x0D\x0A//d} @lines;

	my $truncline = join("|||", @lines);
	$_itemdata{$id} = $truncline if ($dir =~ /items/);
	$_partydata{$id} = $truncline if ($dir =~ /parties/);
	$_userdata{$id} = $truncline if ($dir =~ /users/);
	$_debtdata{$id} = $truncline if ($dir =~ /debts/);
	$_auctiondata{$id} = $truncline if ($dir =~ /auctions/);
	$_pointdata{$id} = $truncline if ($dir =~ /points/);
	$_biddata{$id} = $truncline if ($dir =~ /bids/);

	return @lines;
}




#
# Updates data in file from hash
#
sub writeData {
	my ($id, $dir, %hash) = @_;
	return "Bad id, bad dir or no data" unless ($id && $dir && %hash && -e $dir);

	my $fh = new IO::File "$dir/$id.dat", "w";
	for my $key (sort keys %hash) {
		my $val = $hash{$key};
		print $fh "$key: $val\n" unless ($key =~ /_/ || $key =~ /^(action|pageid)/);
	}

	return "Successfully updated $id.";
}



#
# Write to log
#
sub writeUserLog {
	my $user = shift;
	my $msg = shift || "--error--";
	return unless ($user && &isValidMember($user));

	my $fh = new IO::File "data/logs/$user.dat", "a";
	print $fh (scalar localtime()).": $msg\n";

	return;
}


sub addPointsLog {
	my $user=shift;
	my $pts=shift ||0;
	my $msg=shift ||"";
	return if ($user eq "society");

	my %pdata=&getData($user, "data/points", 1);
	$pts=($pts > 0 ? "+$pts" : $pts);
	$pdata{"$pts;$msg"} = time();
	&writeData($user, "data/points", %pdata);

	return;
}


sub addTransferLog {
	my $user = shift;
	my $pts = shift ||0;
	my $msg = shift || "";
	my $admincheck = shift || 0;
	my $adminfrom = shift;
	my $adminto = shift;
	return if ($user eq "society" && !$admincheck);

	if ($admincheck) {
		my %pdata_from = &getData($adminfrom, "data/transfers", 1);
		my $from_pts = "-$pts";
		$pdata_from{time()} = "$from_pts;societyfix;$adminto;".time().";$msg";
		&writeData($adminfrom, "data/transfers", %pdata_from) if ($adminfrom ne "society");

		my %pdata_to = &getData($adminto, "data/transfers", 1);
		my $to_pts = "+$pts";
		$pdata_to{time()} = "$to_pts;societyfix;$adminfrom;".time().";$msg";
		&writeData($adminto, "data/transfers", %pdata_to) if ($adminto ne "society");

	} else {
		my %pdata = &getData($user, "data/transfers", 1);
		$pts = ($pts > 0 ? "+$pts" : $pts);
		$pdata{time()} = "$pts;$msg";
		&writeData($user, "data/transfers", %pdata);
	}

	return;
}


#
# Gives verbal name for guild
#
sub verboseGuild {
	my @gids = @_;
	my @these_guilds = ();

	for my $gid (@gids) {
		push @these_guilds, ($guilds{sprintf("%02d",$gid)} || "Unknown");
	}

	return @these_guilds;
}

sub shortenGuild {
	my @guilds = @_;
	my $shorts = "";

	for my $guild (@guilds) {
		$shorts .= ($gshort{$guild} || "");
	}

	return $shorts;
}



#
# advancedsort for players
#
sub advancedsort {
	my ($a, $b, $type) = @_;
	my %a_info = &getData($a, "data/users");
	my %b_info = &getData($b, "data/users");

	if ($type eq "sortstring") {
		return ( (lc $a) cmp (lc $b) );

	} elsif ($type eq "sortname") {
		return ( (lc &getDisplayName($a)) cmp (lc &getDisplayName($b)));

	} elsif ($type eq "sortcombo") {
		(&memberClass($a) cmp &memberClass($b)) == 0 ?
			return ( (lc &getGuildCombo($a)) cmp (lc &getGuildCombo($b))) :
			return (&memberClass($a) cmp &memberClass($b));

	} elsif ($type eq "sortlevel") {
		return ( (lc &getDisplayName($a)) cmp (lc &getDisplayName($b))) if ($b_info{'level'} == $a_info{'level'});
		return ( $b_info{'level'} <=> $a_info{'level'} );

	} elsif ($type eq "sortrace") {
		return ( (lc &getDisplayName($a)) cmp (lc &getDisplayName($b))) if ($b_info{'race'} eq $a_info{'race'});
		return ( $a_info{'race'} cmp $b_info{'race'} );

	} elsif ($type eq "sorthpmax") {
		return ( $b_info{'hpmax'} <=> $a_info{'hpmax'} );

	} elsif ($type eq "sortspmax") {
		return ( $b_info{'spmax'} <=> $a_info{'spmax'} );

	} elsif ($type eq "sortpool") {
		return ( &getPoints($b) <=> &getPoints($a) );

	} elsif ($type eq "sortdebt") {
		return ( &countDebts($b) <=> &countDebts($a) );

	} elsif ($type eq "sortcount") {
		my %pcounts = &findPartyMemberships();
		%pcounts = &findPartyMembershipsLast30() if ($pcounts{$b} == $pcounts{$a});
		return ( $pcounts{$b} <=> $pcounts{$a} );

	} elsif ($type eq "sortcount30") {
		my %pcounts = &findPartyMembershipsLast30();
		%pcounts = &findPartyMemberships() if ($pcounts{$b} == $pcounts{$a});
		return ( $pcounts{$b} <=> $pcounts{$a} );

	} elsif ($type eq "sortleads") {
		my ($aleads, $bleads) = (&countPartyLeads($a), &countPartyLeads($b));
		if ($aleads == $bleads) {
			my %leads = &countLeadEq();
			return ( $leads{$b} <=> $leads{$a} );
		}
		return ( $bleads <=> $aleads );

	} elsif ($type eq "sortworth") {
		my %leads = &countLeadEq();
		return ( $leads{$b} <=> $leads{$a} );

	} elsif ($type eq "sortlogin") {
		my $alast = &getLastLogin(&getVar('loginpath'), $a, "forumplus/");
		my $blast = &getLastLogin(&getVar('loginpath'), $b, "forumplus/");
		return ( $blast <=> $alast );
	}

	return (lc$a cmp lc$b);
}



#
# sort by starting time
#
sub sortdate {
	my ($a, $b) = @_;

	my %a_data = &getData($a, "data/parties");
	my %b_data = &getData($b, "data/parties");

	return ($a_data{'starting'} <=> $b_data{'starting'});
}




#
#
# Verboses time
sub verboseDate {
	my $timesecs = shift || 0;
	my $fullverbose = shift || 0;
	my ($minutes, $hours, $days);
	my $thistime = $fullverbose ? $timesecs : ($timesecs - time());

	$days = int ($thistime/(60*60*24));
	$thistime -= $days*60*60*24;
	$hours = int($thistime/(60*60));
	$thistime -= $hours*60*60;
	$minutes = int ($thistime/60);
	$thistime -= $minutes*60;


	my $daystr = $days != 0 ? $days."d&nbsp;" : "";
	my $hourstr = $hours != 0 ? $hours."h&nbsp;" : "";

	return sprintf("%s%s%dm", $daystr, $hourstr, $minutes) if ($fullverbose);
	return sprintf("%s%s", $daystr, $hourstr) if ($days > 2);
	return sprintf("%s%s%dm", $daystr, $hourstr, $minutes) if ($timesecs > time());
	return sprintf("%dd ago", $days < 0 ? -$days : $days);
}



sub getGameName {
	my $user = shift;

	return $_usermapping{$user} if (defined $_usermapping{$user});

	for my $key (keys %usermapping) {
		my $val = $usermapping{$key};
		$_usermapping{$key} = $val;
		$_usermapping{$val} = $key;
	}

	return (defined $_usermapping{$user} ? $_usermapping{$user} : $user);
}


#
# Dummy func
#
sub dummy {
	return "";
}


sub removeDuplicates {
	my %hashy = ();
	$hashy{$_} = 1 for (@_);
	return sort keys %hashy;
}


sub login {
	return "<p><b>Please log in</b></p>\n".&checkLogin(860);
}


sub logoff {
	return "<p>Thanks for visiting! <a href=\"forumplus/\">Log in again</a></p>\n";
}

sub currentlyLogged {
	my $number = shift || 0;
	my $path = &getVar('siteroot')."/content/logins/forumplus/";
	my @filelist = `ls -1 $path`;
	@filelist = grep {s/\.log//;} @filelist;
	@filelist = grep {tr/\x0D\x0A//d;} @filelist;

	my @online = ();
	foreach my $file (@filelist) {
		push @online, &getDisplayName($file)
			if ((time() - (stat "$path$file.log")[9]) < 15*60);
	}
	my $str = join(", ", sort {(lc$a)cmp(lc$b)} @online);

	return ($str, scalar @online) if ($number);
	return $str;
}



sub getLoginFromGameName {
	my $ingame = shift;

	return ($usermapping{$ingame} || $ingame);
}


sub datefmt {
    my $epochtime = shift || 0;
    return strftime("%a %d.%m.%Y %H:%M", localtime($epochtime));
}




__END__

