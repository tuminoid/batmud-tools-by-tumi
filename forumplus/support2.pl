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

# my stuff
# use lib '/home/twomi/web/libs';
use lib '/home/customers/tumi/public_html/archives/batmud';
use lib '/home/customers/tumi/tumilib';
use Tumi::Helper;
use BatmudTools::Site;
use BatmudTools::Vars;
use BatmudTools::Login;

my $skillfile = "../reincsim/data/skill_basecosts.txt";
my $spellfile = "../reincsim/data/spell_basecosts.txt";


my %_pointshash = ();
my %_totaldebts = ();
my %_totalmaxdebts = ();

my %auctionclosing_cache = ();



my @slots = (
	"amulet", "arm", "arms", "belt", "bracelet", "bracelets", "cloak", "finger",
		"foot", "feet", "hand", "hands", "head", "held", "leg", "legs",
		"neck", "tail", "torso",
	"o-yoroi", "multislot",
	"inventory",
	"axe", "bludgeon", "longsword", "shortsword", "polearm", "shield",
);

my @additional_bonuses = (
	"spr", "hpr", "hpmax", "spmax", "epmax", "avoid",
	"str", "dex", "con", "int", "wis", "cha",
	"pr", "acidres", "coldres", "fireres", "psires",
		"aspres", "poisres", "elecres", "manares",
	"physdam", "aciddam", "colddam", "firedam", "psidam",
		"aspdam", "poisdam", "elecdam", "manadam",
	"avoid death", "fastmeta", "dam",
	"genprot", "cutprot", "stabprot", "bashprot",
	"light", "darkness",
	"hit", "evil wield", "good wield",
);


my %shortenbonus = (
	"Theory of electrical engineering"	=> "elecmastery",
	"Mastery of arctic powers" 			=> "coldmastery",
	"Knowledge of toxicology"			=> "poismastery",
	"Knowledge of magic lore"			=> "manamastery",
	"Knowledge of asphyxiation"			=> "asphmastery",
	"Theory of mental power"			=> "psimastery",
	"Theory of pyromania"				=> "firemastery",
	"Theory of corrosion"				=> "acidmastery",

	"Mastery of medicine"	=> "mom",
	"Mastery of shielding"	=> "mos",

	"Martial arts"			=> "ma",
	"Combat sense"			=> "cs",
	"Quick chant"			=> "qc",
	"Stunned maneuvers"		=> "stunmano",
	"Enhance criticals"		=> "ecrits",
	"Dodge"					=> "dodge",
	"Parry"					=> "parry",
	"Damage criticality"	=> "dcrit",
	"Harm body"				=> "habo",
	"Aneurysm"				=> "ane",
	"Power of faith"		=> "pof",
	"Dispel evil"			=> "de",
	"Long blades"			=> "lblades",
	"Short blades"			=> "sblades",
);


1;





sub createSlotNumberSelection {
	my $prev = shift || 1;
	my $html = "";

	for my $slotno (1..10) {
		my $sel = $slotno == $prev ? " selected" : "";
		$html .= "<option value\"$slotno\"$sel>$slotno</option>\n";
	}

	return $html;
}


sub createMultipleSlotSelections {
	my $number = shift || 1;
	my @prevslots = @_;
	my $html = "";

	for my $slotno (1..$number) {
		$html .= "<select name=\"slot$slotno\">\n";
		$html .= &createSlotSelection($prevslots[$slotno-1]);
		$html .= "</select>\n\n";
	}

	return $html;
}


sub createSlotSelection {
	my $prev = shift || '';
	my $html = "";

	for my $slot (@slots) {
		my $sel = (lc $slot) eq (lc $prev) ? " selected" : "";
		$html .= "<option value=\"$slot\"$sel>$slot</option>\n";
	}

	return $html;
}



sub listSkillsSpells {
	my $type = shift || 'skill';
	my $file = $type eq 'skill' ? $skillfile : $spellfile;
	my $fh = new IO::File $file, "r";
	my @items = ();

	while (my $line=<$fh>) {
		$line =~ tr/\x0D\x0A//d;
		my ($skill, $costs) = split/\s{2,}/, $line;
		push @items, $skill;
	}

	return @items;
}


sub createAuctionStatusSelection {
	my $prev = shift;
	my @states = ( "Open", "Closed" );

	my $html = "";
	for my $state (@states) {
		my $lcstate = lc$state;
		my $sel = $prev eq $lcstate ? " selected" : "";

		$html .= qq|<option value="$lcstate"$sel>$state</option>|."\n";
	}

	return $html;
}




sub createBonusSelection {
	my $prev = shift || '';
	my @spells = &listSkillsSpells('spell');
	my @skills = &listSkillsSpells('skill');
	my @bonus = @additional_bonuses;
	map {$_ = "Bonus $_";} @bonus;
	map {$_ = "Spell $_";} @spells;
	map {$_ = "Skill $_";} @skills;

	my $html = "<option value=\"\">--Add bonus--</option>\n";

	for my $juttu (sort (@spells, @skills, @bonus)) {
		my $sel = $juttu eq $prev ? " selected" : "";
		$html .= "<option value=\"$juttu\"$sel>$juttu</option>\n";
	}

	return $html;
}





sub itemBonusString {
	my $id = shift;
	return "" unless (-e "data/items/$id.dat");

	my %idata = &getData($id, "data/items");
	my $bonuses = "";
	my ($b1, $b2, $b3, $b4, $b5) = grep {s/^\w+ //g} ($idata{'bonus1'},
		$idata{'bonus2'}, $idata{'bonus3'}, $idata{'bonus4'}, $idata{'bonus5'});


	$bonuses .= $idata{'bonus1power'}."$b1" if ($b1);
	$bonuses .= ", ".$idata{'bonus2power'}."$b2" if ($b2);
	$bonuses .= ", ".$idata{'bonus3power'}."$b3" if ($b3);
	$bonuses .= ", ".$idata{'bonus4power'}."$b4" if ($b4);
	$bonuses .= ", ".$idata{'bonus5power'}."$b5" if ($b5);

	for my $from (sort keys %shortenbonus) {
		my $to = $shortenbonus{$from};
		$bonuses =~ s/$from/$to/g;
	}

	if (length($idata{'special'}) > 3) {
		if (length($bonuses) < 3) {
			$bonuses = "Special: ".substr($idata{'special'}, 0, 18);
			$bonuses .= ".." if (length($idata{'special'}) > 18);
		} else {
			$bonuses .= " +special";
		}
	}

	return $bonuses;
}




sub getHighestBid {
	my $aid = shift;
	my $force_reload = shift || 0;
	return (0, "buggy") unless (-e "data/bids/$aid.dat");

	my %bids = &getData($aid, "data/bids", $force_reload);
	my ($highbid, $highuser, $hightime) = (-1, "society", 0);

	for my $key (sort keys %bids) {
		my $biddata = $bids{$key};
		$key =~ s/^bid//;
		my ($databid, $datatime) = split/;/, $biddata;

		if ($databid > $highbid) {
			($highbid, $hightime) = ($databid, $datatime);
			$highuser = $key;
		}
	}

	return ($highbid, $highuser, $hightime);
}



sub getUserBid {
	my $user = shift;
	my $aid = shift;
	return -1 unless (-e "data/bids/$aid.dat");

	my %bids = &getData($aid, "data/bids");
	my $bid = 0;

	for my $key (sort keys %bids) {
		my ($tempbid, $time) = split/;/, $bids{$key};
		$bid = $tempbid if ($key =~ /^bid$user/ && $tempbid > $bid);
	}

	return $bid;
}


sub addBid {
	my $user = shift;
	my $id = shift;
	my $bid = shift || 0;
	my $time = time();

	return "No such auction" unless (-e "data/auctions/$id.dat");
	my ($highbid, $highuser, $hightime) = &getHighestBid($id);
	my %adata = &getData($id, "data/auctions");

	return "Your bid is lower than highest current." if ($highbid >= $bid);
	return "Minimum raise is 25 points." if (($highbid + 25) > $bid);
	return "Auction has already closed." if (&getAuctionClosing($id) < $time || $adata{'status'} ne "open");
	return "You already have the highest bid." if ($highuser eq $user);

	my $fh = new IO::File "data/bids/$id.dat", "a+";
	print $fh "bid$user: $bid;$time\n";

	return "Your bid of $bid points is recorded.";
}



sub getUserAuctionStatus {
	my $user = shift;
	my $aid = shift;
	my $pagetgt = shift || 53;

	return ("No such auction", "noauction") unless (-e "data/auctions/$aid.dat");

	my %adata = &getData($aid, "data/auctions", 1);
	my @names = split/,/, $adata{'names'};
	my @helps = split/,/, $adata{'helpers'};
	my @all = (@names, @helps);

	map {$_ = &getLoginName($_)} @all;

	my ($highbid, $highuser, $hightime) = &getHighestBid($aid);
	my $highdisp = &getDisplayName($highuser);
	my $userbid = &getUserBid($user, $aid);

	my $bidcat = (int($highbid / 200) > 4 ? 4 : int($highbid / 200)) + 1;
	my ($plus1, $plus2, $plus3) = ($bidcat*20, $bidcat*50, $bidcat*200);
	my $bidsmall = $highbid+$bidcat*20;
	my $bidmed = $highbid+$bidcat*50;
	my $bidbig = $highbid+$bidcat*200;

	return ("Auction closed<br />($highdisp: $highbid)", "unablebid") if ($adata{'status'} eq "closed");
	return ("Unable to bid<br />($highdisp: $highbid)", "unablebid") unless (scalar grep {$_ eq $user} @all);

	my $bidmore = <<until_end;
<form action="forumplus/index.pl" method="get" name="bidform_$aid">
<input type="hidden" name="action" value="bid" />
<input type="hidden" name="id" value="$aid" />
<input type="hidden" name="pageid" value="$pagetgt" />
<select name="bidselect" onChange="document.bidform_$aid.bid.value=document.bidform_$aid.bidselect.options[selectedIndex].value;" style="font-size: 0.8em;">
<option value="0">-</option>
until_end

        for my $addbid (25, 50, 100, 250, 500, 1000, 2500, 5000) {
	    my $newbid = $highbid+$addbid;
	    $bidmore .= qq|<option value="$newbid">+$addbid</option>\n|;
	}

	$bidmore .= <<until_end;
</select>
<input type="text" value="" name="bid" size="4" maxlength="6" style="font-size: 0.8em;" />
<input type="submit" value="Bid" style="font-size: 0.8em;" />
</form>
until_end

	return ("Winning: $highbid", "winbid") if ($highuser eq $user);
	return ("$highdisp: $highbid<br />$bidmore", "losebid") if ($highbid > 0 && $userbid < $highbid);
	return ("No bids<br />$bidmore", "nobid");
}


sub getAuctionNames {
	my $aid = shift;
	my $helperstoo = shift || 0;

	my @names = split/,\s?/, &getAuctionUsers($aid, $helperstoo);
	map {$_ = &getDisplayName($_)} @names;
	return join(", ", @names);
}



sub getAuctionUsers {
	my $aid = shift;
	my $helperstoo = shift || 0;

	return () unless (-e "data/auctions/$aid.dat");

	my %adata = &getData($aid, "data/auctions");
	my @names = split/,/, $adata{'names'};
	my @helps = split/,/, $adata{'helpers'};

	map {$_ = &getLoginName($_)} @names;
	map {$_ = &getLoginName($_)} @helps;

	return join(", ", @helps) if ($helperstoo == 2);
	return join(", ", (@names, @helps)) if ($helperstoo == 1);
	return join(", ", @names);
}



sub getAuctionClosing {
	my $aid = shift;
	my $force_reload = shift || 0;
	return 0 unless (-e "data/bids/$aid.dat");

	return ($auctionclosing_cache{$aid})
		if (defined $auctionclosing_cache{$aid});

	#my %adata = &getData($aid, "data/auctions");
	my ($bid, $user, $time) = &getHighestBid($aid, $force_reload);
	my $lastbid = $time+36*60*60;
	my $opened = $aid+72*60*60;

	my $closing = ($lastbid > $opened ? $lastbid : $opened);
	$auctionclosing_cache{$aid} = $closing;

	return $closing;
}



sub countWinningBids {
	my $user = shift;
	return 0 unless (&isProfiledMember($user));

	my $bids = 0;
	for my $aid (&indexList("auctions", 1)) {
		my %adata = &getData($aid, "data/auctions");
		my ($highbid, $highuser, $hightime) = &getHighestBid($aid);
		$bids += $highbid if ($highuser eq $user);
	}

	return $bids;
}





sub transferPoints {
	my $fromuser = shift;
	my $touser = shift;
	my $points = shift;
	my $msg = shift || "";


	my %senderdata = ();
	my %receiverdata = ();
	my $maxpoints = 1000000;
	my ($validfrom, $validto) = (2, 2);
	my $content = "";


	# Checking everything is OK
	if ($fromuser ne "society") {
		$validfrom = (&isProfiledMember($fromuser) ? 1 : 0);
		%senderdata = &getData($fromuser, "data/users", 1);
		$maxpoints = &getPoints($fromuser);
	}

	if ($touser ne "society") {
		$validto = (&isProfiledMember($touser) ? 1 : 0);
		%receiverdata = &getData($touser, "data/users", 1);
	}


	# Actual xferring
	if ($validto && $validfrom && $points <= $maxpoints) {
		my $time = time();
		&addTransferLog($touser, $points, "transferfrom;$fromuser;$time;$msg");
		&addTransferLog($fromuser, -$points, "transferto;$touser;$time;$msg");

		$content .= "<p>Transferred '$points' to '$touser' successfully with message '$msg'.\n";
		$content .= "You have ".($maxpoints-$points)." left.\n" if ($fromuser ne "society");
		$content .= "<p>\n";

		&writeUserLog($fromuser, "Sent '$points' points to '$touser' with message '$msg'.") unless ($fromuser eq "society");
		&writeUserLog($touser, "'$fromuser' transferred you '$points' points with message '$msg'.") unless ($touser eq "society");

	} else {
		$content .= "<p>Not enough points for transfer (you have only '$maxpoints') or invalid target '$touser'.</p>\n";
	}

	return $content;
}



sub addDebt {
	my $user = shift;

	#my $iid = shift;
	my $aid = shift; # DEBTTUNE

	my $debt = shift;
	my $time = time();

	my %ddata = ();
	%ddata = &getData($user, "data/debts", 1) if (-e "data/debts/$user.dat");

	# DEBT TUNE
	my %adata = &getData($user, "data/auctions", 1);
	my $iid = $adata{'itemid'};

	my %idata = &getData($iid, "data/items");
	#$ddata{$iid} = "$debt;$debt;$time;debted";
	$ddata{$aid} = "$debt;$debt;$time;debted";

	&writeUserLog($user, "Won auction on $idata{'name'}, $debt pt added to your debts.");
	&writeData($user, "data/debts", %ddata);
}





sub payDebt {
	my $user = shift;
	my $iid = shift;
	my $amount = shift || 'partial';
	return "You don't have any debts." unless (-e "data/debts/$user.dat");

	my %ddata = &getData($user, "data/debts", 1);
	my %idata = &getData($iid, "data/items");
	my %udata = &getData($user, "data/users", 1);

	my ($debt, $maxdebt, $prevtime, $status) = split/;/, $ddata{$iid};
	my $payback = $amount eq "all" ? $debt :
		(int($maxdebt/3+0.99) > 1000 ? 1000 : int($maxdebt/3+0.99));
	$payback = $debt if ($debt - $payback < 0);

	# If some error
	return "Debt already paid in full" if ($debt < 1);
	return "You trying to cheat or something?" if ($payback < 0);
	return "Not enough points to pay $amount debt of $idata{'name'}" if ($payback > &getPoints($user));


	# Updating debts
	my $max_overtime = 20*24*60*60;
	$prevtime += 30*24*60*60;
	$prevtime = $prevtime > (time()+$max_overtime) ? time()+$max_overtime : $prevtime;
	&addPointsLog($user, -$payback, "payback;$iid;$prevtime");
	$debt -= $payback;
	$status = "paid" if ($debt < 1);
	$ddata{$iid} = "$debt;$maxdebt;$prevtime;$status";
	&writeData($user, "data/debts", %ddata);
	&writeData($user, "data/users", %udata);

	my $msg = "Paid '$payback' points of debt for '$idata{'name'}'";
	$msg .= ", '$debt' points of debt left, " if ($debt > 0);
	$msg .= ", next payment (at latest): ".(scalar localtime(time()+30*24*60*60)) if ($debt > 0);

	&writeUserLog($user, $msg);
	return $msg;
}


sub getPoints {
	my $user = shift;
#	my %points = &getData("points", "data", 1);
#	return ($points{$user} || 0);
	return &getPointsFromFile($user);
}


sub getPointsFromFile {
	my $user = shift;

	my $points = 0;
	my %points = &getData($user, "data/points", 1);

	for my $key (keys %points){
		my ($pts, $reason, $msg, $timer) = split/;/, $key;
		$pts =~ s/\+//g;
		$points += int($pts);
	}

	$points += &countXferPoints($user);

	return $points;
}


sub getIncomingPoints {
	my $user = shift;
	return 0 unless (&isProfiledMember($user));

	my $incoming = 0;
	for my $aid (&indexList("auctions", 1)) {
		my %adata = &getData($aid, "data/auctions");
		my ($highbid, $highuser, $hightime) = &getHighestBid($aid);
		my $names = join(", ", &getAuctionUsers($aid, 1));
		$incoming += int($highbid * &getAuctionShare($user, $aid))
			if ($names =~ /$user/);
	}

	return $incoming;
}


sub countDebts {
	my $user = shift;
	my $givetotal = shift || 0;
	return (0, 0) if (not (-e "data/debts/$user.dat") && $givetotal);
	return 0 unless (-e "data/debts/$user.dat");

	return ($_totaldebts{$user}, $_totalmaxdebts{$user}) if (defined $_totaldebts{$user} && defined $_totalmaxdebts{user} && $givetotal);
	return ($_totaldebts{$user}) if (defined $_totaldebts{$user});

	my %ddata = &getData($user, "data/debts");
	my $totaldebt = 0;
	my $totalmaxdebt = 0;

	for my $itemdebt (sort keys %ddata) {
		my ($debt, $maxdebt, $prevtime, $status) = split/;/, $ddata{$itemdebt};
		$totaldebt += $debt;
		$totalmaxdebt += $maxdebt;
	}

	$_totaldebts{$user} = $totaldebt;
	$_totalmaxdebts{$user} = $totalmaxdebt;

	return ($totaldebt, $totalmaxdebt) if ($givetotal);
	return $totaldebt;
}


sub clearPoints {
	#for my $member (&listFiles("data/users")) {
	#	my %udata = &getData($member, "data/users");
	#	$udata{'poolpoints'} = 0;
	#	&writeData($member, "data/users", %udata);
	#}

	#return "All points reseted";
	return "Feature disabled.";
}


sub clearDebts {
	#my @debts = &listFiles("data/debts");
	#for my $debt (@debts) {
	#	`rm data/debts/$debt.dat`;
	#}

	#return "All debts reseted";
	return "Feature disabled.";
}


sub countAuctionPoints {
	my $user = shift;
	my $gethash = shift || 0;
	my $points = 0;
	my %pointhash = ();

	for my $aid (&listFiles("data/auctions")) {
		my %adata = &getData($aid, "data/auctions");
		next unless ($adata{'status'} eq "closed");
		my $aucshare = &getAuctionShare($user, $aid);
		my ($hibid, $hiuser, $hitime) = &getHighestBid($aid);
		my $thispt = int($aucshare * $hibid);

		$points += $thispt;
		$pointhash{"$aid"} = "$hibid;$aucshare;$thispt";
	}

	return ($points, %pointhash) if ($gethash);
	return $points;
}



sub recountPoints {
	my $user = shift;
	return "unauthorized" unless ($user eq "admin");
	return "disabled";
	my $time = time();

	for my $member (&listFiles("data/users")) {
		my $fh = new IO::File "data/points/$member.dat", "w";
		my ($pts, %pointhash) = &countAuctionPoints($member, 1);
		my %ddata = &getData($member, "data/debts");

		for my $aid (sort keys %pointhash){
			my ($hibid, $share, $sharept) = split/;/, $pointhash{$aid};
			my %adata = &getData($aid, "data/auctions");
			next if ($sharept < 1 || $adata{'status'} eq "open");
			#print $fh "+$sharept;share;$aid: $time\n";
			print $fh "+$sharept;share;$aid: ".&getAuctionClosing($aid)."\n";
		}

		for my $iid (sort keys %ddata) {
			my ($debtleft, $maxdebt, $prev, $status) = split/;/,$ddata{$iid};
			my $payback = $maxdebt-$debtleft;
			#print $fh "-$payback;payback;$iid: $time\n" if($payback > 0);
			print $fh "-$payback;payback;$iid: $time\n" if($payback > 0);
		}
	}

	return "Points recounted";
}


sub getAuctionShare {
	my $user = shift;
	my $aid = shift;

	my %adata = &getData($aid, "data/auctions");
	my @aname = split/,/, $adata{'names'};
	my @ahelp = split/,/, $adata{'helpers'};
	my $members = scalar @aname + scalar @ahelp;
	my $points = 0;
	my $gname = &getGameName($user);
	my %ismember = ();
	for my $usr (@aname, @ahelp) {
		$ismember{&getLoginName($usr)} = 1;
	}

	return 0 unless ($ismember{$user});

	if (lc$user eq lc$adata{'leader'}) {
		return ((1 / $members) * (1 + 1/$members));
	} else {
		return ((1 / $members) * (1 - 1/($members*($members-1))));
	}
}



sub countXferPoints {
	my $user = shift;
	my $pointcheck = shift || 0;
	return (0, 0) if (not (-e "data/transfers/$user.dat") && $pointcheck > 0);
	return 0 unless (-e "data/transfers/$user.dat");

	my ($points, $fixpoints) = (0, 0);
	my %tdata = &getData($user, "data/transfers");
	for my $timekey (sort keys %tdata) {
		my ($pts, $type, $from, $time, $msg) = split/;/, $tdata{$timekey};
		$fixpoints += $pts if ($type eq "societyfix" && $pointcheck > 0);
		$points += $pts;
	}

	return ($points, $fixpoints) if ($pointcheck > 0);
	return $points;
}






sub getAddCommentHtml {
	my $pid = shift || return "";
	my $area = shift || return "";

	my $output .= <<until_end;
<h2>Post comment:</h2>
<form method="post" action="forumplus/addcomment.pl">
<textarea name="comment" rows="5" cols="80"></textarea><br />
<input type="hidden" name="id" value="$pid" />
<input type="hidden" name="type" value="party" />
<input type="submit" value="Post comment" align="right" />
</form>

until_end

	return $output;
}



sub getCommentsHtml {
	my $id = shift || return "";
	my $type = shift || return "";

	my %cdata = &getData($id, "data/comments/$type");
	return "" if ((keys %cdata) < 1);
	my $html_output = qq|<h2>Comments (ugly, beta):</h2><table width="100\%" border="1">\n|;

	for my $posttime (sort keys %cdata) {
		my ($poster, $comment) = split/~~/, $cdata{$posttime};
		my $dposter = &getDisplayName($poster);
		my $date = localtime($posttime);

		$html_output .= qq|<tr><td width="30\%"><b>$dposter</b><br />$date</td>|;
		$html_output .= qq|<td width="70\%">$comment</td></tr>\n|;
	}

	$html_output .= qq|</table>\n|;

	return $html_output;
}



sub getMemberLine {
	my $user = shift || "";
	my $uid = shift || $user;

	my %userdata = &getData($uid, "data/users");
	next unless (%userdata && (keys %userdata) > 0);

	my %partyhash = &findPartyMemberships();
	my %party30hash = &findPartyMembershipsLast30();
	my %leadeqworth = &countLeadEq();

	my ($race, $hpmax, $spmax, $level, $desc) =
		(ucfirst $userdata{'race'}, $userdata{'hpmax'}, $userdata{'spmax'},
		$userdata{'level'},	$userdata{'desc'});
	my ($partycount, $partycount30) = ($partyhash{$uid} || 0, $party30hash{$uid} || 0);

	my $prof_link = qq|forumplus/index.pl?pageid=10&amp;action=view&amp;id=|;
	my $display = &getDisplayName($uid);
	my $display_html = (($user eq "admin") || &isProfiledMember($uid)) ?
		qq|<a href="$prof_link$uid">$display</a>| : qq|<strong>$display</strong>|;

	my $gstring = &getGuildCombo($uid);
	my ($debts, $maxdebt) = &countDebts($uid, 1);
	my $poolpoints = &getPoints($uid);
	my $leads = &countPartyLeads($uid);
	my $leadworth = $leadeqworth{$uid} || 0;

	my $lastlogindate = &getLastLogin(&getVar('loginpath'), $uid, "forumplus/");
	if (not &isValidMember($uid)) {
		$lastlogindate = "inactive";
	} elsif ($lastlogindate == -1) {
		$lastlogindate = "unknown";
	} else {
		$lastlogindate = &verboseDate(time() - $lastlogindate, 1);
	}

	my $output .= <<until_end;
<tr>
	<td>$display_html</td><td>$level</td><td>$race</td><td>$gstring</td>
	<td>$poolpoints</td><td>$debts</td>
	<td>$partycount&nbsp;($partycount30)</td>
	<td>$leadworth&nbsp;($leads)</td>
	<td>$lastlogindate</td>
</tr>
until_end

	return $output;
}


__END__

