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
use CGI qw/param/;
use POSIX qw/mktime/;
use HTML::Entities;

# my stuff
# use lib '/home/twomi/web/libs';
use lib '/home/customers/tumi/public_html/archives/batmud';
use lib '/home/customers/tumi/tumilib';
use Tumi::Helper;
use BatmudTools::Site;
use BatmudTools::Vars;
use Tumi::HiresTime;
use BatmudTools::Layout;
use BatmudTools::Login;

my $VERSION = '1.8.21';

my $time0 = &getHiresTime();

require 'support.pl';
require 'support2.pl';
require 'support3.pl';


my %subs = (
	"00"	=> \&login,
	"01"	=> \&entryPage,
	"05"	=> \&printRules,
	"10"	=> \&editProfile,
	"20"	=> \&memberTools,
	"21"	=> \&actionLogs,
	"22"	=> \&pointHandling,
	"23"	=> \&bankRecords,
	"24"	=> \&transferPointsHtml,
	"29"	=> \&paybackDebts,
	"30"	=> \&memberList,
	"40"	=> \&listPartySchedules,
	"41"	=> \&viewParty,
	"42"	=> \&joinParty,
	"43"	=> \&createParty,
	"50"	=> \&auctionsList,
	"51"	=> \&eqList,
	"52"	=> \&viewItem,
	"53"	=> \&viewAuction,
	"55"    => \&searchLists,
	"60"	=> \&officerClub,
	"61"	=> \&addItem,
	"62"	=> \&addAuction,
#	"63"	=> \&closeAuction,
	"64"	=> \&handoutItem,
	"65"	=> \&viewPoints,
#	"68"	=> \&recountPoints,
#	"69"	=> \&clearStuff,
	"70"	=> \&adminPoints,
	"72"	=> \&adminUsers,
	"99"	=> \&logoff,
	"def"	=> \&dummy,
);


my $content = "";
my $pageid = param('pageid') || "01";
my $action = param('action') || "";
my $user;


if ($action eq "logout") {
	$content .= &logOut();
} else {
	($content, $user) = &checkLogin('forumplus');
	unless ($user) {
		$content = "<h2>Welcome to the Forum+!</h2>\n".$content;
		&pageOutput('forumplus', $content);
		exit;
	}
}


my $time1 = &getHiresTime();
# Doing the page action
&backup();
&checkAuctions();
&checkIndexes();
&checkBidding($user);

*coderef = ${subs{"$pageid"}} || ${subs{'def'}};
my $time2 = &getHiresTime();
my $pagecontent = &coderef($user);
my $time3 = &getHiresTime();
my $menucontent = &createMenu($user);
my $time4 = &getHiresTime();
my $msg = param('msg') || "";
$msg = qq|<p style="color: Red;">$msg</p>\n| if ($msg);
my $timer_menu = "";
my $version_menu = "";

if (&isValidMember($user)) {
	my $t_pre = sprintf("%.3f", ($time1-$time0)/1000000.0);
	my $t_ch = sprintf("%.3f", ($time2-$time1)/1000000.0);
	my $t_co = sprintf("%.3f", ($time3-$time2)/1000000.0);
	my $t_me = sprintf("%.3f", ($time4-$time3)/1000000.0);
	my $t_tot = sprintf("%.3f", ($time4-$time0)/1000000.0);

	$timer_menu = <<until_end;
<tr><td colspan="2">&nbsp;</td></tr>
<tr class="menutitle"><td colspan="2">Timer</td></tr>
<tr class="userinfo"><td><b>Page</b></td><td>$t_tot</td></tr>
<tr class="userinfo"><td><b>Preload</b></td><td>$t_pre</td></tr>
<tr class="userinfo"><td><b>Integrity</b></td><td>$t_ch</td></tr>
<tr class="userinfo"><td><b>Menu</b></td><td>$t_me</td></tr>
<tr class="userinfo"><td><b>Content</b></td><td>$t_co</td></tr>
until_end

	$version_menu = <<until_end;
<tr><td colspan="2">&nbsp;</td></tr>
<tr class="menutitle"><td colspan="2">Version</td></tr>
<tr class="userinfo"><td><b>Version</b></td><td>$VERSION</td></tr>
until_end


}

my $precontent = <<until_end;
<table id="invis">
<tr>
<td class="noborders">
<table class="plusmenu">
$menucontent $timer_menu $version_menu
</table>
</td>
<td class="noborders" id="forumcontent">
$content
$msg
$pagecontent
</td></tr>
</table>

until_end


my $create_on_load = ($pageid == 43) ? ' onLoad="document.partyform.name.focus();"' : "";
&setLayoutItem('body_on_load', $create_on_load);
&pageOutput('forumplus', $precontent);


1;



#
# entrypage
#
sub entryPage {
	my $user = shift;
	return "No access" unless (&isValidMember($user));

	# new member
	#unless (-e "data/users/$user.dat") {
	#	my $redir_url = qq|http://2-mi.com/batmud/forumplus/index.pl?pageid=10|;
	#	&printHeaderRedirect($redir_url."&msg=Please%20fill%20in%20profile%20first.");
	#}


	my $displayname = &getDisplayName($user);
	my $html = <<until_end;
<h2>Welcome back to Forum+, $displayname!</h2>

<h3>Your incoming parties:</h3>
<table>
<tr class="header"><td>Party name:</td><td>Creator:</td>
<td>Start date:</td><td>Time left:</td><td>Membermap:</td></tr>
until_end

	my $myparties = 0;
	for my $pid (sort {sortdate($a,$b)} &indexList("parties", 1)) {
		my %pdata = &getData($pid, "data/parties");

		if (&isPartyMember($user, $pid)) {
			$myparties++;
			$html .= &getPartyLine($user, $pid);
		}
	}

	$html .= <<until_end;
<tr class="footer"><td colspan=6>Number of parties: $myparties</td></tr>
</table>


<h3>Open auctions you have bids on:</h3>
<table>
<tr class="header"><td>Item:</td><td>Bonuses:</td>
<td>Closing:</td><td>Bidding&nbsp;status:</td><td>Details:</td></tr>
until_end

	my $myauctions = 0;
	for my $aid (sort {&getAuctionClosing($a) <=> &getAuctionClosing($b)} &indexList("auctions", 1)) {
		if (&getUserBid($user, $aid) > 0) {
			$myauctions++;
			$html .= &getAuctionLine($user, $aid, "01");
		}
	}

	$html .= <<until_end;
<tr class="footer"><td colspan=5>Number of auctions: $myauctions</td></tr>
</table>

<h3>Your unpaid debts:</h3>
<table>
<tr class="header"><td>Item:</td><td>Next&nbsp;payment:</td>
<td>Debt:</td><td>Price:</td><td>Pay Partial:</td><td>Pay Full:</td></tr>

until_end

	my @opendebt = ();
	my %ddata = &getData($user, "data/debts", 1);
	for my $did (keys %ddata) {
	    push @opendebt, $did
			if ($ddata{$did}=~/debted/);
	}
	my $mydebts = scalar @opendebt;

	for my $did (@opendebt) {
		my ($debtleft, $debtmax, $lastpayment, $status) = split/;/,$ddata{$did};
		my %idata = &getData($did, "data/items");
		my $nextpayment = &verboseDate($lastpayment+30*24*60*60);
		my $partialpayment = int($debtmax/3) < 1000 ? int($debtmax/3) : 1000;

		my $partiallink = $debtleft >= 300 ?
			qq|<a href="forumplus/index.pl?pageid=29&amp;action=payback&amp;id=$did&amp;amount=partial">$partialpayment&nbsp;pts</a>| : "";
		my $fulllink = qq|<a href="forumplus/index.pl?pageid=29&amp;action=payback&amp;id=$did&amp;amount=all">$debtleft pts</a>|;

		$html .= <<until_end;
<tr><td><a href="forumplus/index.pl?pageid=52&amp;action=view&amp;id=$did">$idata{'name'}</a></td><td>$nextpayment</td><td>$debtleft</td><td>$debtmax</td>
<td>$partiallink</td><td>$fulllink</td></tr>

until_end
	}

	$html .= <<until_end;
<tr class="footer"><td colspan="6">Number of debts: $mydebts</td></tr>
</table>

until_end


	return $html;
}





#
# Profile
#
sub editProfile {
	my $user = shift;
	my $action = param('action') || 'edit';
	my $uid = param('id') || $user;

	return "No access" unless (&isValidMember($user));
	#return "No profile" unless (&isProfiledMember($user) || $user ne "admin");
	#return "No profile, really" unless (-e "data/users/$uid.dat");

	$action = (($uid eq $user) || ($user eq "admin")) ? $action : "view";
	my $verb = $uid eq $user ? "Your" : ucfirst($uid)."'s";

	my %userdata = &getData($uid, "data/users");
	my $profile = "";

	my ($race, $guild1, $guild2, $guild3, $hpmax, $spmax, $level, $desc) =
		(ucfirst $userdata{'race'}, $userdata{'guild1'}, $userdata{'guild2'}, $userdata{'guild3'},
		$userdata{'hpmax'}, $userdata{'spmax'}, $userdata{'level'}, $userdata{'desc'});

	# Htmlzing it all
	my $login_html = (($action eq "edit") || ($user eq $uid)) ? qq|<tr><td>Login:</td><td>$uid</td></tr>| : "";
	my $display = &getDisplayName($uid);
	my $ingame = &getGameName($uid);
	my $password_html = <<until_end;
<tr><td>Password:</td><td><a href="http://2-mi.com/services/yabb2/YaBB.pl?action=profileCheck;username=$user">Change password</a>
(<a href="http://2-mi.com/services/yabb2/YaBB.pl?action=login">login</a> first)</td></tr>
until_end

	my $html_race = $action eq "edit" ? qq|<select name="race">|.&createRaceSelection($userdata{'race'})."</select>" : $race;
	my $html_g1 = $action eq "edit" ? qq|<select name="guild1">|.&createGuildSelection($guild1)."</select>" : (&verboseGuild($guild1))[0];
	my $html_g2 = $action eq "edit" ? qq|<select name="guild2">|.&createGuildSelection($guild2)."</select>" : (&verboseGuild($guild2))[0];
	my $html_g3 = $action eq "edit" ? qq|<select name="guild3">|.&createGuildSelection($guild3)."</select>" : (&verboseGuild($guild3))[0];
	my $html_level = $action eq "edit" ? qq|<select name="level">|.&createLevelSelection($level)."</select>" : $level;

	my $hp_html = $action eq "edit" ? qq|<input type="text" name="hpmax" value="$hpmax" size="4" maxlength="4" />| : $hpmax;
	my $sp_html = $action eq "edit" ? qq|<input type="text" name="spmax" value="$spmax" size="4" maxlength="4" />| : $spmax;
	my $desc_html = $action eq "edit" ? qq|<input type="text" name="desc" value="$desc" size=60 maxlength=200 />| : $desc;
	my $subm_html = $action eq "edit" ? qq|<tr class="footer"><td colspan=2 align=right><input type="submit" value="Change profile" /></td></tr>| : "";

	$password_html = "" if ($user ne $uid);

	$profile = <<until_end;
<h2>$verb profile</h2>

<form method="post" action="forumplus/modifyprofile.pl">
<table class="vertical">
$login_html
<tr><td>Displayed:</td><td>$display</td></tr>
<tr><td>Ingame:</td><td>$ingame</td></tr>
$password_html
<tr><td>Race:</td><td>$html_race</td></tr>
<tr><td>Primary guild:</td><td>$html_g1</td></tr>
<tr><td>Secondary guild:</td><td>$html_g2</td></tr>
<tr><td>Tertiary guild:</td><td>$html_g3</td></tr>

<tr><td>Hpmax&nbsp;(battleset&nbsp;on):</td><td>$hp_html</td></tr>
<tr><td>Spmax&nbsp;(battleset&nbsp;on):</td><td>$sp_html</td></tr>
<tr><td>Level:</td><td>$html_level</td></tr>
<tr><td>Description:</td><td>$desc_html</td></tr>

$subm_html
</table>
</form>

until_end


	return $profile;
}




#
# fiddle with points
#
sub pointHandling {
	my $user = shift;
	return "No such user" unless (&isValidMember($user));

	my %userdata = &getData($user, "data/users");
	return "Please update profile" unless (%userdata && (keys %userdata) > 0);

	my $options = &createPlayerSelection();
	my $maxpoints = &getPoints($user);
	my $total_bids = 0;
	my $total_debts = 0;

	my $html = <<until_end;
<h2>Your items and debts</h2>

<table>
<tr class="header"><td>Item:</td><td>Next payment (latest):</td>
<td>Price:</td><td>Debt left:</td><td>Pay 33%:</td><td>Pay all:</td><td>Status:</td></tr>

until_end

	my %ddata = ();
	%ddata = &getData($user, "data/debts") if (-e "data/debts/$user.dat");
	my $countdebts = 0;

	# DEBTTUNE
	for my $iid (sort keys %ddata) {
		my ($debt, $maxdebt, $prevtime, $status) = split/;/, $ddata{$iid};
		$status =~ s/([a-z])/uc($1)/e;
		$status =~ tr/_/ /;
		#my %adata = &getData($aid, "data/auctions");
		#my $iid = $adata{'itemid'};

		$total_bids += $maxdebt;
		$total_debts += $debt;

		my %idata = &getData($iid, "data/items");
		my $paymentdate = &verboseDate($prevtime+30*24*60*60);
		$paymentdate = "-" if ($status =~ /delivered|paid/i);
		my $partialpayment = int($maxdebt/3) < 1000 ? int($maxdebt/3) : 1000;
		$countdebts++;

		my $linkpartial = $debt >= 300 ?
			qq|<a href="forumplus/index.pl?pageid=29&amp;action=payback&amp;id=$iid&amp;amount=partial">Pay $partialpayment pts</a>| : "";
		my $linkfull = $debt > 0 ?
			qq|<a href="forumplus/index.pl?pageid=29&amp;action=payback&amp;id=$iid&amp;amount=all">Pay all $debt pts</a>| : "";


		$html .= <<until_end;
<tr><td><a href="forumplus/index.pl?pageid=52&amp;action=view&amp;id=$iid">$idata{'name'}</a></td>
<td>$paymentdate</td><td>$maxdebt</td><td>$debt</td>
<td>$linkpartial</td>
<td>$linkfull</td>
<td class="cntr">$status</td>
</tr>
until_end

	}

	$html .= <<until_end;
<tr class="footer"><td colspan="2">Total bids / open debts:</td>
<td>$total_bids</td><td>$total_debts</td>
<td colspan="2">Number of debts:</td><td>$countdebts</td></tr>
</table>
until_end

	return $html;
}


sub transferPointsHtml {
	my $user = shift;
	return "No such user" unless (&isValidMember($user));

	my %userdata = &getData($user, "data/users");
	return "Please update profile" unless (%userdata && (keys %userdata) > 0);

	my $options = &createPlayerSelection("", 1);
	my $maxpoints = &getPoints($user);

	my $html = <<until_end;
<h2>Transfer points</h2>

<form method="post" action="forumplus/xferpoints.pl">
<table class="vertical">
<tr><td>Transfer (max $maxpoints):</td><td><input type="text" size="10" maxlength="10" name="xferpoints" value="0" /> pts</td></tr>
<tr><td>To:</td><td><select name="xferto">$options</select></td></tr>
<tr><td>Message:</td><td><input type="text" name="msg" size="30" maxlength="100" value="" /></td></tr>
<tr class="footer"><td colspan="2"><input type="submit" value="Transfer points" /></td></tr>
</table>
</form>

until_end

	return $html;
}




#
# Action log
#
sub bankRecords {
	my $user = shift;
	return "No \"bank records\" for you." unless ((stat "data/points/$user.dat")[7]>0);

	my $html = <<until_end;
<h2>Bank records</h2>
<!--
<p>
Go back to <a href="forumplus/index.pl?pageid=20">Member Tools</a> or
<a href="forumplus/index.pl?pageid=22">Point fiddling</a>.
</p>
-->
<table>
<tr class="header"><td>Time:</td><td>Action:</td><td>Amount:</td><td>Details:</td></tr>

until_end

	my %pdata = &getData($user, "data/points");
	for my $key (sort {$pdata{$a} <=> $pdata{$b}} keys %pdata) {
		my ($pts, $action, $actionid) = split/;/, $key;
		my $date = scalar localtime($pdata{$key});
		my $detail = "";

		if ($action eq "share") {
			my %d = &getData($actionid,"data/auctions");
			my %di = &getData($d{'itemid'},"data/items");
			$detail = <<until_end;
<a href="forumplus/index.pl?pageid=53&amp;action=view&amp;id=$actionid">Auction</a>
of <a href="forumplus/index.pl?pageid=52&amp;action=view&amp;id=$d{'itemid'}">$di{'name'}</a>
until_end

		}

		if ($action eq "payback") {
			my %d=&getData($actionid,"data/items");
			$detail =qq|Payback of <a href="forumplus/index.pl?pageid=52&amp;action=view&amp;id=$actionid">$d{'name'}</a>|;
		}


		$html .= <<until_end;
<tr><td>$date</td><td>$action</td><td>$pts</td><td>$detail</td></tr>
until_end

	}

	my $points = &getPoints($user);
	$html .= <<until_end;
<tr class="footer"><td colspan=4>Total points (including transfers below): $points</td></tr>
</table>


<h3>Point transfers</h3>
<table>
<tr class="header"><td>Time:</td><td>Action:</td><td>Amount:</td><td>Message:</td></tr>

until_end

	my %tdata = &getData($user, "data/transfers");
	for my $timekey (sort keys %tdata) {
		my ($pts, $action, $from, $time, $detail) = split/;/, $tdata{$timekey};
		my $date = scalar localtime($timekey);

		if ($action =~ /transfer(from|to)/) {
			$action = "Transfer $1 $from";
		}

		if ($action =~ /societyfix/) {
			$action = "Society point fix";
		}

		$html .= <<until_end;
<tr><td>$date</td><td>$action</td><td>$pts</td><td>$detail</td></tr>
until_end
	}

	my $xferpoints = &countXferPoints($user);
	$html .= <<until_end;
<tr class="footer"><td colspan=4>Transfers totals: $xferpoints</td></tr>
</table>

until_end

	return $html;
}


#
# Action log
#
sub actionLogs {
		my $user = shift;
		return "No logs for unknown user." unless ($user);

		my $html = "<h2>Logs for $user</h2>\n".
				"<!--<p><a href=\"forumplus/index.pl?pageid=20\">Go back to tools</a></p>-->\n";
		$html .= qq|<div style="font-size: 0.7em; margin: 1em;">|;

		my @logs = &getLogs($user);
		for my $logline (reverse @logs) {
				$html .= $logline."<br />";
		}

		$html .= "</div></p>\n";

		return $html;
}





#
# Memberlist
#
sub memberList {
	my $user = shift;
	my @members = &listFiles("data/users");
	return "No access" unless (&isValidMember($user));

	my $show_inactives = param('inactives') || 0;
	my %partyhash = &findPartyMemberships();
	my %party30hash = &findPartyMembershipsLast30();
	my ($allparty, $openparty, $successparty, $failparty, $cancelparty) = &countParties();

	my $membercount = 0;
	my %leadeqworth = &countLeadEq();
	my $sorttype = param('action') || 'sortname';

	my ($stat_lvl, $stat_leads, $stat_worth, $stat_parties) = (0, 0, 0, 0);
	my ($stat_pts, $stat_debt, $stat_members) = (0, 0, scalar @members);
	my ($g_tank, $g_conju, $g_tarma, $g_priest, $g_blaster, $g_nun) = (0, 0, 0, 0, 0, 0);

	my $extraparam = $show_inactives ? "&amp;inactives=1" : "";

	my $output = <<until_end;
<h2>Memberlist:</h2>

<p>
<a href="forumplus/index.pl?pageid=30">Hide</a> inactives,
<a href="forumplus/index.pl?pageid=30&amp;inactives=1">show</a> inactives.
</p>

<table id="memberlist">
<tr class="header">
<td><a href="forumplus/index.pl?pageid=30&amp;action=sortname$extraparam">Name</a></td>
<td><a href="forumplus/index.pl?pageid=30&amp;action=sortlevel$extraparam">Lvl</a></td>
<td><a href="forumplus/index.pl?pageid=30&amp;action=sortrace$extraparam">Race</a></td>
<td><a href="forumplus/index.pl?pageid=30&amp;action=sortcombo$extraparam">Combo</a></td>
<td><a href="forumplus/index.pl?pageid=30&amp;action=sortpool$extraparam">Points</a></td>
<td><a href="forumplus/index.pl?pageid=30&amp;action=sortdebt$extraparam">Debts</a></td>
<td>
	<a href="forumplus/index.pl?pageid=30&amp;action=sortcount$extraparam">Parties</a>/
	<a href="forumplus/index.pl?pageid=30&amp;action=sortcount30$extraparam">Last30</a>
</td>
<td>
	<a href="forumplus/index.pl?pageid=30&amp;action=sortworth$extraparam">Lead\$\$\$</a>/
	<a href="forumplus/index.pl?pageid=30&amp;action=sortleads$extraparam">parties</a>
</td>
<td><a href="forumplus/index.pl?pageid=30&amp;action=sortlogin$extraparam">Last&nbsp;login</a></td>
</tr>

until_end

	my $cntr = 0;
	my $class = "";
	for my $member (sort {advancedsort($a,$b,$sorttype)} @members) {
		my $html = "";

		# class
		if ($sorttype eq "sortcombo" && $class ne &memberClass($member)) {
			$class = &memberClass($member);
			$html = qq|<tr class="footer"><td colspan="9">$class</td></tr>\n|;
			$cntr--;
		}
		$html .= &getMemberLine($user, $member);

		# statistics
		if (&isProfiledMember($member)) {
			my $gstring = &getGuildCombo($member);
			$g_tank += 1 if ($gstring =~ /loc|tiger|barb|ranger|reaver|crimso|sabre|knight|templa|monk/i);
			$g_tarma += 1 if ($gstring =~ /tarm/i);
			$g_conju += 1 if ($gstring =~ /conju/i);
			$g_priest += 1 if ($gstring =~ /priest/i);
			$g_blaster += 1 if ($gstring =~ /psi|channu|mage/i);
			$g_nun += 1 if ($gstring =~ /nun/i);
			$membercount++;

		# dim inactives
		} else {
			$html =~ s/<tr>/<tr style="color: #aaaaaa;">/;
		}

		# coloring background
		$cntr++ if (&isProfiledMember($member) || $show_inactives);
		my $color = ($cntr % 2) ? "#ffffff" : "#eeeeee";
		$html =~ s/<tr>/<tr style="background-color: $color;">/;
		$html =~ s/<tr style="/<tr style="background-color: $color; /;

		my %userdata = &getData($member, "data/users");
		next unless (%userdata && (keys %userdata) > 0);

		my ($race, $hpmax, $spmax, $level, $desc) =
			(ucfirst $userdata{'race'}, $userdata{'hpmax'}, $userdata{'spmax'},
			$userdata{'level'},	$userdata{'desc'});
		my ($partycount, $partycount30) = ($partyhash{$member} || 0, $party30hash{$member} || 0);

		my ($debts, $maxdebt) = &countDebts($member, 1);
		my $poolpoints = &getPoints($member);
		my $leads = &countPartyLeads($member);
		my $leadworth = $leadeqworth{$member} || 0;

		$stat_leads += $leads;
		$stat_worth += $leadworth;
		$stat_pts += $poolpoints;
		$stat_debt += $debts;

		# regged people on these only
		if (&isProfiledMember($member)) {
			$stat_lvl += $level;
			$stat_parties += $partycount;
		}

		$output .= $html if (&isProfiledMember($member) || $show_inactives);
	}

	my $avg_level = int ($stat_lvl * 10 / $membercount) / 10;
	my $avg_parties = int ($stat_parties * 10 / $stat_members) / 10;

	$output .= <<until_end;
<tr class="footer">
	<td>Avg. level:</td>
	<td>$avg_level</td>
	<td colspan="2">Total pts&amp;debts, parties, eq worth:</td>
	<td>$stat_pts</td>
	<td>$stat_debt</td>
	<td>$avg_parties / $successparty</td>
	<td>$stat_worth</td>
	<td>&nbsp;</td>
</tr>

<tr class="footer">
	<td>Tanks: $g_tank</td>
	<td colspan="2">Tarmas: $g_tarma</td>
	<td>Nuns: $g_nun</td>
	<td colspan="2">Blasters: $g_blaster</td>
	<td colspan="2">Priests: $g_priest</td>
	<td>Conjus: $g_conju</td>
</tr>

<tr class="footer">
	<td colspan="2">© = officer</td>
	<td colspan="7">Total number of active members: $membercount</td>
</tr>

</table>

until_end

	return $output;
}




#
# Auctions
#
sub auctionsList {
	return "No access" unless (&isValidMember($user));
	my $type = ucfirst (param('type') || 'open');
	my $action = param('action') || 'list';
	my $id = param('id');

	my $atype = ($type =~ /closed/i) ? 0 : 1;
	my @auctions = &indexList("auctions", $atype);

	my $output = <<until_end;
<h2>Auctions</h2>

<p>
View
<a href="forumplus/index.pl?pageid=50&amp;type=open">open auctions</a>
or
<a href="forumplus/index.pl?pageid=50&amp;type=closed">closed auctions</a>.
</p>


<div style="border: 1px solid Black; font-size: 0.8em; background-color: #dddddd; margin-bottom: 2em; margin-left: auto; margin-right: auto; width: 75%; text-align: center; padding: 0.3em;">
Some quotes from the <a href="http://2-mi.com/batmud/forumplus/index.pl?pageid=05">rules.</a><br />
1) Remember that nominal value of one (1) point is 1k (1000) gp.<br/>
2) Only members who have name on eq or are accredited helpers (raisers etc), may bid.
</div>


<h3>$type auctions</h3>
<table>
<tr class="header"><td>Item:</td><td>Bonuses:</td>
<td>Closing:</td><td>Bidding&nbsp;status:</td><td>Details:</td></tr>
until_end

	my ($aucopen, $atotal, $myshare) = (0, 0, 0);
	for my $aid (sort {&getAuctionClosing($type=~/closed/i?$b:$a) <=> &getAuctionClosing($type=~/closed/i?$a:$b)} @auctions) {
		next if ((($aid + 3*86400) < time()) && ($type eq "open")); # quick filter real olds

		my %adata = &getData($aid, "data/auctions");
		next unless ($adata{'status'} eq lc $type);

		my $line = &getAuctionLine($user, $aid, 50);
		my $color = (++$aucopen % 2) ? "#ffffff" : "#eeeeee";
		$line =~ s/<tr>/<tr style="background-color: $color;">/;
		$output .= $line;

		my ($hibid, $hiuser, $hitime) = &getHighestBid($aid);
		$atotal += $hibid;
		my $names = join(", ", &getAuctionUsers($aid, 1));
		$myshare += $hibid if ($names =~ /$user/);
	}


	$output .= <<until_end;
<tr class="footer">
	<td>$type auctions: $aucopen</td>
	<td>&nbsp;</td>
	<td>Self:$myshare</td>
	<td>Total:$atotal</td>
	<td>&nbsp;</td>
</tr>
</table>

until_end


	return $output;
}




#
# Add EQ
#
sub addItem {
	my $user = shift;
	my $action = param('action') || 'edit';
	my $id = param('id') || time();
	return "Unauthorized access." unless (&isValidOfficer($user));

	my %idata = ();

	if ($action eq 'create') {
		%idata = ('id' => $id);
	} else {
		%idata = &getData($id, "data/items");
	}


	my $slotselect = &createSlotSelection($idata{'slots'});
	my ($bonus1select, $bonus2select, $bonus3select, $bonus4select, $bonus5select) = (
		&createBonusSelection($idata{'bonus1'}), &createBonusSelection($idata{'bonus2'}),
		&createBonusSelection($idata{'bonus3'}), &createBonusSelection($idata{'bonus4'}),
		&createBonusSelection($idata{'bonus5'})
	);

	my $html = <<until_end;
<h2>Add item</h2>

<form method="post" action="forumplus/additem.pl">
<input type="hidden" name="id" value="$id" />
<table class="vertical">
<tr><td>Name:</td><td><input type="text" size="50" maxlength="100" name="name" value="$idata{'name'}" /></td></tr>
<tr><td>Slots:</td><td><select name="slots">$slotselect</select></td></tr>
<tr><td>Short desc:</td><td><input type="text" size="50" maxlength="100" name="shortdesc" value="$idata{'shortdesc'}" /></td></tr>
<tr><td>Long desc:</td><td><textarea name="longdesc" rows="5" cols="60">$idata{'longdesc'}</textarea></td></tr>
<tr><td>Specials:</td><td><textarea name="special" rows="5" cols="60">$idata{'specials'}</textarea></td></tr>
<tr><td>Weight (kg):</td><td><input type="text" name="weight" value="$idata{'weight'}" size=4 maxlength=10 /></td></tr>
<tr><td colspan=2>(Note: each item with different bonuses should be created as separate item... also names are separate field on auctions)</td></tr>
<tr><td>Bonus1:</td><td><input type="text" name="bonus1power" value="$idata{'bonus1power'}" size=5 maxlength=10 /><select name="bonus1">$bonus1select</select></td></tr>
<tr><td>Bonus2:</td><td><input type="text" name="bonus2power" value="$idata{'bonus2power'}" size=5 maxlength=10 /><select name="bonus2">$bonus2select</select></td></tr>
<tr><td>Bonus3:</td><td><input type="text" name="bonus3power" value="$idata{'bonus3power'}" size=5 maxlength=10 /><select name="bonus3">$bonus3select</select></td></tr>
<tr><td>Bonus4:</td><td><input type="text" name="bonus4power" value="$idata{'bonus4power'}" size=5 maxlength=10 /><select name="bonus4">$bonus4select</select></td></tr>
<tr><td>Bonus5:</td><td><input type="text" name="bonus5power" value="$idata{'bonus5power'}" size=5 maxlength=10 /><select name="bonus5">$bonus5select</select></td></tr>
<tr><td colspan=2 align=right><input type="submit" value="Add item to DB" /></td></tr>
</table>
</form>

until_end

	return $html;
}




#
# Add EQ for auction
#
sub addAuction {
	my $user = shift;
	return "Unauthorized access." unless (&isValidOfficer($user));

	my $itemhtml = &createItemSelection();
	my $thistime = time();
	my $leaderhtml = &createPlayerSelection("", 1);

	my $select_html = <<until_end;
<select name="partyselect">
<option value="" selected="selected">Choose party OR type</option>
until_end

	my @openparties = &indexList("parties", 1);
	for my $pid (@openparties) {
		my @members = ();
		my %pdata = &getData($pid, "data/parties");
		for my $key (sort keys %pdata) {
			next unless ($key =~ /^member/);
			push @members, &getGameName($pdata{$key});
		}
		my $member_str = join(",", @members);
		$select_html .= qq|<option value="$member_str">$pdata{'name'}</option>\n|;
	}
	$select_html .= qq|</select>\n|;

	my $html = <<until_end;
<h2>Add auction</h2>

<form method="post" action="forumplus/addauction.pl" name="auctionform" onSubmit='if(document.auctionform.leader.value==""){alert("No leader selected!");return false;} if(document.auctionform.names.value==""){alert("No names selected"); return false;}'>
<input type="hidden" name="bidsociety" value="0;$thistime" />
<input type="hidden" name="status" value="open" />
<table class="vertical">
<tr><td>Item(s): (hold ctrl for multiple)</td><td><select name="itemid" multiple size="20">$itemhtml</select></td></tr>
<tr><td>Leader:</td><td><select name="leader">$leaderhtml</select></td></tr>
<tr><td>Party/names:</td>
<td>$select_html
<input type="button" value="=>" onClick="document.auctionform.names.value=document.auctionform.partyselect.value;" />
<input type="text" size="60" maxlength="255" name="names" value="" />
</td></tr>
<tr><td>Outsiders:</td><td><input type="text" name="outsiders" value="" size="75" maxlength="255" /></td></tr>
<tr><td>Helpers:</td><td><input type="text" name="helpers" value="" size="75" maxlength="255" /></td></tr>
<tr><td class="footer" colspan="2"><input type="submit" value="Add item for auction" /></td></tr>
</table>
</form>

until_end

	return $html;
}




#
# list eqs
#
sub eqList {
	my $user = shift;
	my @items = &listFiles("data/items");
	return "No access" unless (&isValidMember($user));

	# If officer, we have a tad different view
	my ($off_tr, $off_td, $off_span) = ("", "", 4);
	if (&isValidOfficer($user)) {
		$off_tr = "<td>Edit:</td>";
		$off_span = 5;
	}


	my $html = <<until_end;
<h2>Equipment list</h2>

<table>
<tr class="header"><td>ItemID:</td><td>Short desc:</td><td>Slot:</td>
<td>Bonuses:</td>$off_tr</tr>

until_end
	my $cntr = 0;
	for my $iid (sort {&itemsort($a,$b,0)} @items) {
		my %idata = &getData($iid, "data/items");
		my ($name, $short, $slot) = (encode_entities($idata{'name'}),
			encode_entities($idata{'shortdesc'}), $idata{'slots'});
		my $bonuses = &itemBonusString($iid);

		$off_td = "<td><a href=\"forumplus/index.pl?pageid=52&amp;action=edit&amp;id=$iid\">edit</a></td>"
			if (&isValidOfficer($user));
		my $color = ($cntr++ %2) ? "#ffffff" : "#eeeeee";

		$html .= <<until_end;
<tr style="background-color: $color;"><td><a href="forumplus/index.pl?pageid=52&amp;action=view&amp;id=$iid">$name</a></td>
<td>$short</td><td>$slot</td><td>$bonuses</td>$off_td</tr>
until_end
	}

	$html .= "<tr style=\"font-weight: bold;\"><td colspan=$off_span align=right>Number of items in DB: ".(scalar @items)."</td></tr>\n";
	$html .= "</table>\n";

	return $html;
}





sub listPartySchedules {
	my $user = shift;
	return "Not available until you have updated your profile" unless (&isProfiledMember($user));
	return "No access" unless (&isValidMember($user));

	my $type = param('type') || 'open';
	my $typedesc = $type eq "open" ? "Active" : "Past";
	my $ptype = $type eq "open" ? 1 : 0;

	my @parties = &indexList("parties", $ptype);
	my $pcounttotal = scalar @parties;

	my $html  = <<until_end;
<h2>Party schedules</h2>
<p>
<a href="forumplus/index.pl?pageid=43&amp;action=create">Create</a> a new party,
view <a href="forumplus/index.pl?pageid=40&amp;type=open">incoming</a> parties or
<a href="forumplus/index.pl?pageid=40&amp;type=closed">past</a> parties.
<a href="forumplus/rss.pl?user=$user">RSS-feed</a> also available.
</p>


<h3>$typedesc parties</h3>
<table>
<tr class="header"><td>Party&nbsp;name:</td><td>Leader:</td>
<td>Start&nbsp;date:</td><td>Time&nbsp;left:</td><td>Membermap:</td></tr>
until_end

	my $pcount1 = 0;
	for my $pid (sort {sortdate(($type eq "open")?$a:$b,($type eq "open")?$b:$a)} @parties) {
		my %pdata = &getData($pid, "data/parties");
#		if ($type eq "open") {
#			next unless ($pdata{'status'} =~ /full|open/i);
#		} else {
#			next if ($pdata{'status'} =~ /full|open/i);
#		}

		my $color = (++$pcount1 % 2) ? "#ffffff" : "#eeeeee";
		my $partyhtml .= &getPartyLine($user, $pid);
		$partyhtml =~ s/<tr>/<tr style="background-color: $color;">/;
		$html .= $partyhtml;
	}

	$html .= <<until_end;
<tr class="footer"><td colspan="5" align=right>Number of parties: $pcount1</td></tr>
</table>
until_end


	return $html;
}




sub viewParty {
	my $user = shift;
	my $pid = param('id');
	return "Unknown user or bad party id ($pid)" unless ($pid && &isValidMember($user));
	return "Unable to view, you have no profile" unless (&isProfiledMember($user));

	my %pdata = &getData($pid, "data/parties");
	my $isOfficer = &isValidOfficer($user);
	my $startdate = &datefmt($pdata{'starting'});
	my $starttime = &verboseDate($pdata{'starting'});
	my @members = &listPartyMembers($pid);
	my $ok_members = scalar @members;
	my $creator = &getDisplayName($pdata{'creator'});
	my $link = length($pdata{'link'})>10 ? "Link to boards about party: <a href=\"$pdata{'link'}\">$pdata{'name'}</a>\n" : "";
	my $html = "<h2>$pdata{'name'}</h2>\n";


	# Edit party
	# <!-- <p>You may <a href="forumplus/index.pl?pageid=43&amp;action=delete&amp;id=$pid">DELETE this party.</a></p> -->
	if ($pdata{'creator'} eq $user || &isValidOfficer($user)) {
		$html .= <<until_end;
<p>You may <a href="forumplus/index.pl?pageid=43&amp;action=edit&amp;id=$pid">edit this party.</a></p>
<!-- <p>Party deleting was disabled. Make them cancelled instead.</p> -->
until_end
	}


	# Leave party
	if (&isPartyMember($user, $pid)) {
		if ($pdata{'status'} =~ /full|open/) {
			$html .= <<until_end;
<p>You are a member of this party.
You may <a href="forumplus/index.pl?pageid=42&amp;action=leave&amp;id=$pid">leave this party.</a></p>
until_end
		} else {
			$html .= <<until_end;
<p>You were a member of this party. Party is $pdata{'status'}.</p>
until_end
		}
	}


	my %pform = (
		"p11"	=> (length($pdata{'member11'}) > 2 ? &describeMember($pdata{'member11'}) : "<a href=\"forumplus/index.pl?pageid=42&amp;action=join&amp;id=$pid&amp;pos=11\">Join</a>"),
		"p12"	=> (length($pdata{'member12'}) > 2 ? &describeMember($pdata{'member12'}) : "<a href=\"forumplus/index.pl?pageid=42&amp;action=join&amp;id=$pid&amp;pos=12\">Join</a>"),
		"p13"	=> (length($pdata{'member13'}) > 2 ? &describeMember($pdata{'member13'}) : "<a href=\"forumplus/index.pl?pageid=42&amp;action=join&amp;id=$pid&amp;pos=13\">Join</a>"),
		"p21"	=> (length($pdata{'member21'}) > 2 ? &describeMember($pdata{'member21'}) : "<a href=\"forumplus/index.pl?pageid=42&amp;action=join&amp;id=$pid&amp;pos=21\">Join</a>"),
		"p22"	=> (length($pdata{'member22'}) > 2 ? &describeMember($pdata{'member22'}) : "<a href=\"forumplus/index.pl?pageid=42&amp;action=join&amp;id=$pid&amp;pos=22\">Join</a>"),
		"p23"	=> (length($pdata{'member23'}) > 2 ? &describeMember($pdata{'member23'}) : "<a href=\"forumplus/index.pl?pageid=42&amp;action=join&amp;id=$pid&amp;pos=23\">Join</a>"),
		"p31"	=> (length($pdata{'member31'}) > 2 ? &describeMember($pdata{'member31'}) : "<a href=\"forumplus/index.pl?pageid=42&amp;action=join&amp;id=$pid&amp;pos=31\">Join</a>"),
		"p32"	=> (length($pdata{'member32'}) > 2 ? &describeMember($pdata{'member32'}) : "<a href=\"forumplus/index.pl?pageid=42&amp;action=join&amp;id=$pid&amp;pos=32\">Join</a>"),
		"p33"	=> (length($pdata{'member33'}) > 2 ? &describeMember($pdata{'member33'}) : "<a href=\"forumplus/index.pl?pageid=42&amp;action=join&amp;id=$pid&amp;pos=33\">Join</a>"),
	);

	my %kicks = ('p11'=>'', 'p12'=>'', 'p13'=>'', 'p21'=>'', 'p22'=>'', 'p23'=>'', 'p31'=>'', 'p32'=>'', 'p33'=>'');

	if (($pdata{'creator'} eq $user || &isValidOfficer($user)) && $pdata{'status'} =~ /open|full/) {
		%kicks = (
			"p11"	=> (length($pdata{'member11'}) > 2) ? qq|<a href="forumplus/index.pl?pageid=42&amp;action=kick&amp;target=$pdata{'member11'}&amp;id=$pid">Kick</a>| : "",
			"p12"	=> (length($pdata{'member12'}) > 2) ? qq|<a href="forumplus/index.pl?pageid=42&amp;action=kick&amp;target=$pdata{'member12'}&amp;id=$pid">Kick</a>| : "",
			"p13"	=> (length($pdata{'member13'}) > 2) ? qq|<a href="forumplus/index.pl?pageid=42&amp;action=kick&amp;target=$pdata{'member13'}&amp;id=$pid">Kick</a>| : "",
			"p21"	=> (length($pdata{'member21'}) > 2) ? qq|<a href="forumplus/index.pl?pageid=42&amp;action=kick&amp;target=$pdata{'member21'}&amp;id=$pid">Kick</a>| : "",
			"p22"	=> (length($pdata{'member22'}) > 2) ? qq|<a href="forumplus/index.pl?pageid=42&amp;action=kick&amp;target=$pdata{'member22'}&amp;id=$pid">Kick</a>| : "",
			"p23"	=> (length($pdata{'member23'}) > 2) ? qq|<a href="forumplus/index.pl?pageid=42&amp;action=kick&amp;target=$pdata{'member23'}&amp;id=$pid">Kick</a>| : "",
			"p31"	=> (length($pdata{'member31'}) > 2) ? qq|<a href="forumplus/index.pl?pageid=42&amp;action=kick&amp;target=$pdata{'member31'}&amp;id=$pid">Kick</a>| : "",
			"p32"	=> (length($pdata{'member32'}) > 2) ? qq|<a href="forumplus/index.pl?pageid=42&amp;action=kick&amp;target=$pdata{'member32'}&amp;id=$pid">Kick</a>| : "",
			"p33"	=> (length($pdata{'member33'}) > 2) ? qq|<a href="forumplus/index.pl?pageid=42&amp;action=kick&amp;target=$pdata{'member33'}&amp;id=$pid">Kick</a>| : "",
		);
	}


	$html .= <<until_end;
<table>
<tr><td><b>Leader:</b> $creator</td><td><b>Start&nbsp;time:</b> $startdate</td><td><b>Time left:</b> $starttime</td></tr>
<tr><td colspan="3"><b>Notes:</b> $pdata{'notes'}</td></tr>
<tr><td><b>Estimated length:</b> $pdata{'length'}</td><td colspan=2>$link</td></tr>
<tr><td colspan="3">&nbsp;</td></tr>
<tr class="partyformation">
	<td><b>$pdata{'wanted11'}:</b> $kicks{'p11'}<br/>$pform{'p11'}</td>
	<td><b>$pdata{'wanted12'}:</b> $kicks{'p12'}<br/>$pform{'p12'}</td>
	<td><b>$pdata{'wanted13'}:</b> $kicks{'p13'}<br/>$pform{'p13'}</td>
</tr>
<tr class="partyformation">
	<td><b>$pdata{'wanted21'}:</b> $kicks{'p21'}<br/>$pform{'p21'}</td>
	<td><b>$pdata{'wanted22'}:</b> $kicks{'p22'}<br/>$pform{'p22'}</td>
	<td><b>$pdata{'wanted23'}:</b> $kicks{'p23'}<br/>$pform{'p23'}</td>
</tr>
<tr class="partyformation">
	<td><b>$pdata{'wanted31'}:</b> $kicks{'p31'}<br/>$pform{'p31'}</td>
	<td><b>$pdata{'wanted32'}:</b> $kicks{'p32'}<br/>$pform{'p32'}</td>
	<td><b>$pdata{'wanted33'}:</b> $kicks{'p33'}<br/>$pform{'p33'}</td>
</tr>

<tr class="footer"><td colspan=3 align=right>Enlisted members: $ok_members</td></tr>
</table>

until_end


	my $comment_html = &getCommentsHtml($pid, "party");
	my $postcomment_html = &getAddCommentHtml($pid, "party");

	$html .= $comment_html;
	$html .= $postcomment_html;

	return $html;
}




sub createParty {
	my $user = shift;
	my $action = param('action') || 'edit';
	my $pid = param('id');
	return "Unknown user" unless (&isValidMember($user));
	return "Unable to process, you have no profile" unless (&isProfiledMember($user));

	my ($time, $created) = (time(), time());
	my %ppos = ();
	my $act = ucfirst $action;
	my ($name, $notes, $starting1, $starting2, $status, $link, $length) = ("", "", 0, "0000", "open", "", "0h");
	my ($html, $hiddenfields) = ("", "");
	my %pdata = ();

	my $admindelete = ($user eq "admin" && $pid) ? qq|<p>Delete this party: <a href="forumplus/index.pl?pageid=43&amp;action=delete&amp;id=$pid">$pid</a></p>|."\n" : "";

	# Create
	if ($action eq "create") {
		my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime();
		my $time1 = mktime(0, 0, 0, $mday, $mon, $year, 0, 0, 0);

		$pid = time();
		%pdata = (
			"id"			=> $pid,
			"creator"		=> $user,
			"starting1"		=> $time1,
			"starting2"		=> "1800",
			"status"		=> "new",
		);


	# Delete
	} elsif ($action eq "delete") {
		my %pdata = &getData($pid, "data/parties");
		if ($pdata{'creator'} eq $user || &isValidOfficer($user)) {
			`rm data/parties/$pid.dat`;

			&writeUserLog($user, "Deleted party id $pid.");
			return "<p>Deleted party $pid.</p>";
		}

	# Edit
	} else {
		%pdata = &getData($pid, "data/parties");
	}


	if ($pdata{'creator'} eq $user || &isValidOfficer($user)) {
		($name, $notes, $starting1, $starting2, $status, $link, $length) =
			($pdata{'name'}, $pdata{'notes'}, $pdata{'starting1'},
			$pdata{'starting2'}, $pdata{'status'},
			$pdata{'link'}, $pdata{'length'});

		if (&isValidOfficer($user)) {
			$html .= "Party is not created by you, but officer access granted.<br />\n";
		} else {
			$html .= "This is a party created by you, access granted.<br />\n";
		}
	}

	for my $row (1..3) {
		for my $col (1..3) {
			my $membu = $pdata{"member$row$col"};
			if ($membu) {
				$hiddenfields .= "<input type=\"hidden\" name=\"member$row$col\" value=\"$membu\" />\n";
			}
		}
	}



	my $dateselection = &createDateSelection($starting1);
	for my $row (1..3) {
		for my $col (1..3) {
			if ($action eq "edit") {
				my %pdata = &getData($pid, "data/parties");
				$ppos{"$row$col"} = &createMemberSelection("$row$col", $pdata{"wanted$row$col"});
			} else {
				$ppos{"$row$col"} = &createMemberSelection("$row$col");
			}
		}
	}

	my $statusselection = &createStatusSelection($status);


	$html = <<until_end;
<h2>$act a party:</h2>

$admindelete

<form method="post" action="forumplus/addparty.pl" name="partyform" onSubmit='if(document.partyform.name.value==""){alert("Empty party name"); return false;}'>
<input type="hidden" name="id" value="$pid" />
<input type="hidden" name="creator" value="$pdata{'creator'}" />
<input type="hidden" name="action" value="$action" />

$hiddenfields

<!-- Creator: $user<br /> -->
Status: $statusselection<br />
Party name: <input type="text" name="name" value="$name" size="60" maxlength="1000" /><br />
Notes: <input type="text" name="notes" value="$notes" size="60" maxlength="1000" /><br />
<!-- Link to discussion: <input type="text" name="link" value="$link" size="60" maxlength="200" /><br /> -->
Estimated length: <input type="text" name="length" value="$length" size="60" maxlength="200" /><br />
Start date: (ddmmyy): <select name="starting1">$dateselection</select>
klo (hhmm): <input type="text" name="starting2" value="$starting2" size="4" maxlength="4" /><br />

<table>
<tr><td>Member11: $ppos{'11'}</td><td>Member12: $ppos{'12'}</td><td>Member13: $ppos{'13'}</td></tr>
<tr><td>Member21: $ppos{'21'}</td><td>Member22: $ppos{'22'}</td><td>Member23: $ppos{'23'}</td></tr>
<tr><td>Member31: $ppos{'31'}</td><td>Member32: $ppos{'32'}</td><td>Member33: $ppos{'33'}</td></tr>
</table>

<br/><input type="submit" value="$act party" />
</form>

until_end

	return $html;
}


sub joinParty {
	my $user = shift;
	my $pid = param('id');
	my $action = param('action');
	my $pos = param('pos');

	return "No access" unless (&isValidMember($user));

	my %pdata = &getData($pid, "data/parties");
	my $wantedtype = $pdata{"wanted$pos"};
	my $reserved = $pdata{"member$pos"};

	if ($action eq "join") {
		return "This slot may not be joined." if ($wantedtype eq "CLOSED" || $wantedtype =~ /outsider/i);
		return "You have already joined this party." if (&isPartyMember($user, $pid));
		return "This slot is already reserved to $reserved." if (length($reserved) > 2);

		$pdata{"member$pos"} = defined $pdata{"member$pos"} ? $pdata{"member$pos"}.", $user" : $user;
		$pdata{'status'} = "full" if (&listPartyMembers($pid) == 8 && $pdata{'status'} eq "open");
		&writeData($pid, "data/parties", %pdata);
		&writeUserLog($user, "You joined party <a href=\"forumplus/index.pl?pageid=41&amp;action=view&amp;id=$pid\">$pid</a> as $wantedtype.");

		my $redir_url = qq|http://2-mi.com/batmud/forumplus/index.pl?pageid=41&amp;action=view&amp;id=$pid|;
		&printHeaderRedirect($redir_url."&amp;msg=Joined%20party%20successfully.");

	} elsif ($action eq "kick") {
		return "You are not officer." unless (&isValidOfficer($user) || $pdata{'creator'} eq $user);
		my $target = param('target');
		return "No target specified." unless ($target);

		my $slot = &partyMemberSlot($target, $pid);
		my $wanted = $pdata{"wanted$slot"};
		delete $pdata{"member$slot"};
		$pdata{'status'} = "open" if ($pdata{'status'} eq "full");
		&writeData($pid, "data/parties", %pdata);
		&writeUserLog($target, "You were kicked out of party <a href=\"forumplus/index.pl?pageid=41&amp;action=view&amp;id=$pid\">$pid</a> from slot $slot as $wanted.");
		&writeUserLog($user, "You kicked out $target from party <a href=\"forumplus/index.pl?pageid=41&amp;action=view&amp;id=$pid\">$pid</a> from slot $slot as $wanted.");

		#1136578503: peelo~~About 15:30 tms. voisin p‰‰st tulee jos pappeihin meinaa kaatua..<br />
		if ($pdata{'starting'} - time() < 2*24*60*60) {
			#my $timediff = &verboseDate($pdata{'starting'} - time());
			my %cdata = &getData($pid, "data/comments/party", 1);
			$cdata{"".time()} = "$user~~(Automated message) Kicked ".&getDisplayName($target)." from the party.";
			&writeData($pid, "data/comments/party", %cdata);
		}

		my $redir_url = qq|http://2-mi.com/batmud/forumplus/index.pl?pageid=41&action=view&id=$pid|;
		&printHeaderRedirect($redir_url."&msg=Kicked%20member%20successfully.");

	} else {
		return "You are not member of this party." unless (&isPartyMember($user, $pid));

		my $slot = &partyMemberSlot($user, $pid);
		my $wanted = $pdata{"wanted$slot"};

		delete $pdata{"member$slot"};
		$pdata{'status'} = "open" if ($pdata{'status'} eq "full");
		&writeData($pid, "data/parties", %pdata);
		&writeUserLog($user, "You left party <a href=\"forumplus/index.pl?pageid=41&amp;action=view&amp;id=$pid\">$pid</a> from slot $slot as $wanted.");

		#1136578503: peelo~~About 15:30 tms. voisin p‰‰st tulee jos pappeihin meinaa kaatua..<br />
		if ($pdata{'starting'} - time() < 2*24*60*60) {
			#my $timediff = &verboseDate($pdata{'starting'} - time());
			my %cdata = &getData($pid, "data/comments/party", 1);
			$cdata{"".time()} = "$user~~(Automated message) Left party from $wanted spot.";
			&writeData($pid, "data/comments/party", %cdata);
		}

		my $redir_url = qq|http://2-mi.com/batmud/forumplus/index.pl?pageid=41&action=view&id=$pid|;
		&printHeaderRedirect($redir_url."&msg=Left%20party%20successfully.");
	}
}



sub viewItem {
	my $user = shift;
	my $id = param('id');
	my $action = param('action') || 'view';

	return "No such item" unless (-e "data/items/$id.dat");
	return "Not a member" unless (&isValidMember($user));
	return "Not an officer" unless ($action eq "view" || &isValidOfficer($user));

	my %idata = &getData($id, "data/items");
	my $adminedit = ($action eq "edit" && &isValidOfficer($user));

	if ($action eq "delete" && &isValidOfficer($user)) {
		`rm data/items/$id.dat`;

		return "<p>Deleted item $id.</p>";
	}


	# Variable thingies
	my $name_html = $adminedit ?
		"<input type=\"text\" name=\"name\" value=\"$idata{'name'}\" size=50 maxlength=100 />" :
		$idata{'name'};
	my $shortdesc_html = $adminedit ?
		"<input type=\"text\" name=\"shortdesc\" value=\"$idata{'shortdesc'}\" size=50 maxlength=100 />" :
		$idata{'shortdesc'};
	my $longdesc_html = $adminedit ?
		"<textarea name=\"longdesc\" wrap=virtual rows=7 cols=70 />$idata{'longdesc'}</textarea>" :
		$idata{'longdesc'};
	my $special_html = $adminedit ?
		"<tr><td>Special:</td><td><textarea name=\"special\" wrap=virtual rows=7 cols=70 />$idata{'special'}</textarea></td></tr>" :
		(length ($idata{'special'}) > 0 ? qq|<tr><td>Special:</td><td>$idata{'special'}</td></tr>| : "");
	my $slot_html = $adminedit ?
		"<select name=\"slots\">".&createSlotSelection($idata{'slots'})."</select>" :
		$idata{'slots'};
	my $weight_html = $adminedit ?
		"<input type=\"text\" name=\"weight\" value=\"$idata{'weight'}\" size=5 maxlength=10 />" :
		$idata{'weight'};

	# Bonuses
	my $b1power_html = $adminedit ?
		"<input type=\"text\" name=\"bonus1power\" value=\"$idata{'bonus1power'}\" size=5 maxlength=10 />" :
		$idata{'bonus1power'};
	my $b2power_html = $adminedit ?
		"<input type=\"text\" name=\"bonus2power\" value=\"$idata{'bonus2power'}\" size=5 maxlength=10 />" :
		$idata{'bonus2power'};
	my $b3power_html = $adminedit ?
		"<input type=\"text\" name=\"bonus3power\" value=\"$idata{'bonus3power'}\" size=5 maxlength=10 />" :
		$idata{'bonus3power'};
	my $b4power_html = $adminedit ?
		"<input type=\"text\" name=\"bonus4power\" value=\"$idata{'bonus4power'}\" size=5 maxlength=10 />" :
		$idata{'bonus4power'};
	my $b5power_html = $adminedit ?
		"<input type=\"text\" name=\"bonus5power\" value=\"$idata{'bonus5power'}\" size=5 maxlength=10 />" :
		$idata{'bonus5power'};


	my $b1_html = $adminedit ?
		"<tr><td>Bonus1:</td><td><input type=\"text\" name=\"bonus1power\" size=\"5\" maxlength=\"10\" value=\"$idata{'bonus1power'}\" /><select name=\"bonus1\">".&createBonusSelection($idata{'bonus1'})."</select></td></tr>" :
		(length ($idata{'bonus1'}) > 0 ? qq|<tr><td>Bonus1:</td><td>$b1power_html $idata{'bonus1'}</td></tr>| : "");

	my $b2_html = $adminedit ?
		"<tr><td>Bonus2:</td><td><input type=\"text\" name=\"bonus2power\" size=\"5\" maxlength=\"10\" value=\"$idata{'bonus2power'}\" /><select name=\"bonus2\">".&createBonusSelection($idata{'bonus2'})."</select></td></tr>" :
		(length ($idata{'bonus2'}) > 0 ? qq|<tr><td>Bonus2:</td><td>$b2power_html $idata{'bonus2'}</td></tr>| : "");

	my $b3_html = $adminedit ?
		"<tr><td>Bonus3:</td><td><input type=\"text\" name=\"bonus3power\" size=\"5\" maxlength=\"10\" value=\"$idata{'bonus3power'}\" /><select name=\"bonus3\">".&createBonusSelection($idata{'bonus3'})."</select></td></tr>" :
		(length ($idata{'bonus3'}) > 0 ? qq|<tr><td>Bonus3:</td><td>$b3power_html $idata{'bonus3'}</tr>| : "");

	my $b4_html = $adminedit ?
		"<tr><td>Bonus4:</td><td><input type=\"text\" name=\"bonus4power\" size=\"5\" maxlength=\"10\" value=\"$idata{'bonus4power'}\" /><select name=\"bonus4\">".&createBonusSelection($idata{'bonus4'})."</select></td></tr>" :
		(length ($idata{'bonus4'}) > 0 ? qq|<tr><td>Bonus4:</td><td>$b4power_html $idata{'bonus4'}</td></tr>| : "");

	my $b5_html = $adminedit ?
		"<tr><td>Bonus5:</td><td><input type=\"text\" name=\"bonus5power\" size=\"5\" maxlength=\"10\" value=\"$idata{'bonus5power'}\" /><select name=\"bonus5\">".&createBonusSelection($idata{'bonus5'})."</select></td></tr>" :
		(length ($idata{'bonus5'}) > 0 ? qq|<tr><td>Bonus5:</td><td>$b5power_html $idata{'bonus5'}</td></tr>| : "");


	my $formstart = $adminedit ?
		"<form action=\"forumplus/additem.pl\" method=\"post\">".
		"<input type=\"hidden\" name=\"id\" value=\"$id\" />" : "";
	my $formstop = $adminedit ?
		"</form>" : "";
	my $submitbutton = $adminedit ?
		"<tr><td colspan=2 align=right><input type=\"submit\" value=\"Edit item\" /></td></tr>" :
		"";
	my $editlink = (&isValidOfficer($user) && $action eq "view") ?
		"<a href=\"forumplus/index.pl?pageid=52&amp;action=edit&amp;id=$id\">Edit</a> this item.\n" : "";
	my $deletelink = (&isValidOfficer($user) && $action eq "edit") ?
		"<a href=\"forumplus/index.pl?pageid=52&amp;action=delete&amp;id=$id\">Delete</a> this item." : "";

	# output
	my $html = <<until_end;
<h2>$idata{'name'}</h2>

$formstart
<table class="vertical">
<tr><td>Id:</td><td>$id</td></tr>
<tr><td>Name:</td><td>$name_html</td></tr>
<tr><td>Slot:</td><td>$slot_html</td></tr>
<tr><td>Shortdesc:</td><td>$shortdesc_html</td></tr>
<tr><td>Longdesc:</td><td>$longdesc_html</td></tr>
$special_html
<tr><td>Weight:</td><td>$weight_html kg</td></tr>
$b1_html
$b2_html
$b3_html
$b4_html
$b5_html
$submitbutton
</table>
$formstop

<p>$editlink $deletelink</p>
until_end

	return $html;
}





sub viewAuction {
	my $user = shift;
	my $id = param('id');
	my $action = param('action') || 'view';

	return "No such auction" unless (-e "data/auctions/$id.dat");
	return "Not a member" unless (&isValidMember($user));
	return "Not an officer" unless ($action =~ /^(view|bid)/ || &isValidOfficer($user));

	# Auction info
	my %adata = &getData($id, "data/auctions");
	my $adminedit = ($action eq "edit" && &isValidOfficer($user));
	my $closing = &verboseDate(&getAuctionClosing($id));
	my $opened = &datefmt($id);

	my ($highbid, $highuser, $hightime) = &getHighestBid($id);
	$highuser = &getDisplayName($highuser);
	my $userbid = &getUserBid($user, $id);
	my ($userbidmsg, $userbidcolor) = &getUserAuctionStatus($user, $id, 53);


	if ($action eq "delete" && &isValidOfficer($user)) {
		return "<p>Auction is already closed, cannot delete it.</p>\n"
			if ($adata{'status'} ne "open");

		`rm data/auctions/$id.dat`;
		`rm data/bids/$id.dat`;

		&redoAuctIndex();
		return "<p>Deleted auction $id.</p>";
	}

	my $itemid = $adata{'itemid'};
	my %idata = &getData($itemid, "data/items");
	my $itemname = $idata{'name'};
	my $bonuses  = &itemBonusString($itemid);
	my $dispnames = &getAuctionNames($id);
	my $helpnames = &getAuctionNames($id, 2);
	my $outsiders = $adata{'outsiders'};


	# Some nice boxes
	my $item_html = $adminedit ?
		"<select name=\"itemid\">".&createItemSelection($itemid)."</select>" :
		"<a href=\"forumplus/index.pl?pageid=52&amp;action=view&amp;id=$itemid\">$itemname</a>";
	my $names_html = $adminedit ?
		"<input type=\"text\" name=\"names\" value=\"$adata{'names'}\" size=80 maxlength=150 />" :
		$dispnames;
	my $outsiders_html = $adminedit ?
		"<input type=\"text\" name=\"outsiders\" value=\"$adata{'outsiders'}\" size=80 maxlength=150 />" :
		$outsiders;
	my $helpers_html = $adminedit ?
		"<input type=\"text\" name=\"helpers\" value=\"$adata{'helpers'}\" size=80 maxlength=150 />" :
		$helpnames;
	my $leader_html = $adminedit ?
		"<select name=\"leader\">".&createPlayerSelection($adata{'leader'})."</select>" :
		&getDisplayName($adata{'leader'});
	my $status_html = $adminedit ?
		"<select name=\"status\">".&createAuctionStatusSelection($adata{'status'})."</select>" :
		$adata{'status'};
	my $bid_html = $adminedit ? "$highbid - $highuser" : $userbidmsg;

	# These only if admins
	my $formstart = $adminedit ?
		qq|<form action="forumplus/addauction.pl" method="post">\n|.
		qq|<input type="hidden" name="id" value="$id" />| : "";
	my $formstop = $adminedit ?
		"</form>" : "";
	my $submitbutton = $adminedit ?
		qq|<tr><td colspan="2" align="right"><input type="submit" value="Edit auction" /></td></tr>| :
		"";
	my $editlink = (&isValidOfficer($user) && $action eq "view") ?
		"<a href=\"forumplus/index.pl?pageid=53&amp;action=edit&amp;id=$id\">Edit</a> this auction." : "";
	my $deletelink = (&isValidOfficer($user) && $action eq "edit") ?
		"<a href=\"forumplus/index.pl?pageid=53&amp;action=delete&amp;id=$id\">Delete</a> this auction." : "";

	# output
	my $html = <<until_end;
<h2>Auction on $idata{'name'}</h2>

$formstart
<table class="vertical">
<tr><td>Auction id:</td><td>$id</td></tr>
<tr><td>Status:</td><td>$status_html</td></tr>
<tr><td>Opened:</td><td>$opened</td></tr>
<tr><td>Closing:</td><td>$closing</td></tr>
<tr><td>Leader:</td><td>$leader_html</td></tr>
<tr><td>Society names:</td><td>$names_html</td></tr>
<tr><td>Outsider names:</td><td>$outsiders_html</td></tr>
<tr><td>Accredited helpers:</td><td>$helpers_html</td></tr>
<tr><td>Item:</td><td>$item_html</td></tr>
<tr><td>Slot:</td><td>$idata{'slots'}</td></tr>
<tr><td>Bonuses:</td><td>$bonuses</td></tr>
<tr><td>Highest bid:</td><td class="$userbidcolor">$bid_html</td></tr>
$submitbutton
</table>
$formstop

<p>$editlink $deletelink</p>


<h3>Bid history:</h3>

<table class="narrow">
<tr class="header"><td>Name:</td><td>Time:</td><td>Bid:</td></tr>
until_end

	my @bidlines = &getLines($id, "data/bids");
	my $bidcount = scalar @bidlines;
	for my $line (@bidlines) {
		my ($who, $details) = split/: /, $line;
		$who =~ s/^bid//g;
		$who = &getDisplayName($who);
		my ($bid, $timer) = split/;/, $details;
		$timer = &datefmt($timer);

		$html .= <<until_end;
<tr><td>$who</td><td>$timer</td><td>$bid</td></tr>
until_end

	}

	$html .= <<until_end;
<tr class="footer"><td colspan=3>Total bids: $bidcount</td></tr>
</table>
until_end


	return $html;
}





sub handoutItem {
	my $user = shift;
	my $action = param('action') || 'list';
	my $id = param('id');
	my $handoutuser = param('user');
	my $type = param('type') || 'paid';
	return "Unauthorized" unless (&isValidOfficer($user));

	my $html = "";

	if ($action eq "handout") {
		my %ddata = &getData($handoutuser, "data/debts", 1);
		my ($debt, $maxdebt, $prevtime, $status) = split/;/, $ddata{$id};

		$html .= qq|<p>Item not paid in full, cannot handout.</p>| if ($debt > 0);
		$html .= qq|<p>Item already handed out!</p>| if ($status eq "delivered");

		if (($debt < 1 && $status eq "paid") || $handoutuser eq "society") {
			$html .= qq|<p style="color: Red;">Item marked to delivered!</p>|;
			$ddata{$id} = "$debt;$maxdebt;$prevtime;delivered_by_$user";
			&writeData($handoutuser, "data/debts", %ddata);

		} else {
			$html .= qq|<p style="color: Red;">Item may not be given out yet!</p>|;
		}
	}


	$html .= <<until_end;
<h2>Debts list ($type)</h2>


<p>
View <a href="forumplus/index.pl?pageid=64&amp;type=all">all</a>,
<a href="forumplus/index.pl?pageid=64&amp;type=paid">paid</a>,
<a href="forumplus/index.pl?pageid=64&amp;type=debted">debted</a> or
<a href="forumplus/index.pl?pageid=64&amp;type=delivered">delivered</a>.
</p>

<table>
<tr class="header">
<td>Name:</td><td>Item:</td>
<!-- <td>Item&nbsp;created:</td> -->
<td>Unpaid/Maxdebt:</td><td>Next&nbsp;payment:</td><td>Item&nbsp;status:</td>
<td>Delivery&nbsp;status:</td></tr>
until_end

	my $cntr = 0;
	for my $member (&listFiles("data/debts")) {
		my %ddata = &getData($member, "data/debts", 1);
		my $display = &getDisplayName($member);

		for my $iid (sort keys %ddata) {
			my ($debt, $maxdebt, $prevtime, $status) = split/;/, $ddata{$iid};
			next unless ($type eq "all" || $status =~ /^$type/);
			my %idata = &getData($iid, "data/items");
			my $nextpayment = $status =~ /^(delivered|paid)/ ? "-" : &verboseDate($prevtime+30*24*60*60);
			my $nextstyle = "color: #000000";
			$nextstyle = "color: #00cccc font-weight: bold;" if ($prevtime+30*24*60*60-time() < 7*24*60*60);
			$nextstyle = "color: #ee0000; font-weight: bold;" if ($prevtime+30*24*60*60 < time());
			#my $datestr = &verboseDate($aid);

			my $handoutlink = $debt > 0 ? "Not paid" : (
					$status =~ /delivered/ ? "Handed out" :
						qq|<a href="forumplus/index.pl?pageid=64&amp;action=handout&amp;id=$iid&amp;user=$member&amp;type=$type">Hand-out item</a>|
						);
			my $color = (++$cntr % 2) ? "#ffffff;" : "#eeeeee;";
			$html .= <<until_end;
<tr style="background-color: $color;">
<td>$display</td><td><a href="forumplus/index.pl?pageid=52&amp;action=view&amp;id=$iid">$idata{'name'}</a></td>
<td>$debt&nbsp;/&nbsp;$maxdebt</td><td style="$nextstyle;">$nextpayment</td><td>$status</td>
<td>$handoutlink</td>
</tr>
until_end
		}
	}

	$html .= <<until_end;
</table>
until_end

	return $html;
}


sub checkAuctions {
#	my $something_updated = 0;

	for my $aid (&indexList("auctions", 1)) {
		#my %adata = &getData($aid, "data/auctions");
		if (time() > &getAuctionClosing($aid)) {
			&closeAuction("admin", $aid, "close") ;
			&setIndexValue("auctions", $aid, 0);
#			$something_updated++;
		}
	}

#	&redoPointIndex() if ($something_updated);
}





sub closeAuction {
	my $user = shift;
	my $id = shift || param('id');
	my $action = shift || param('action') || 'list';

	return "Unauthorized access" unless (&isValidOfficer($user));
	my $html = "";

	if ($action eq "close") {
		my %adata = &getData($id, "data/auctions");
		my ($hibid, $hiuser, $hitime) = &getHighestBid($id);

		my @names = grep {$_ = &getLoginName($_); 1} split/,/, $adata{'names'};
		my @helpers = grep {$_ = &getLoginName($_); 1;} split/,/, $adata{'helpers'};

		my $leader = $adata{'leader'};
		my $members = scalar @names + scalar @helpers;
		my $oneshare = (1 / $members) * (1 - 1/($members*($members-1)));
		my $leadshare = (1 / $members) * (1 + 1/$members);
		my $onepts = int($hibid * $oneshare);
		my $leadpts = int($hibid * $leadshare);
		my $iid = $adata{'itemid'};
		my %idata = &getData($iid, "data/items");

		my %udata = ();
		my ($before, $after);
		my $totalshare = ($leadshare + $oneshare*($members-1)) * 100;
		my $totalpoints = $leadpts + $onepts*($members-1);

		$adata{'status'} = "closed";
		&writeData($id, "data/auctions", %adata);


		$html = <<until_end;
<h2>Dividing auction $id shares</h2>

<p><a href="forumplus/index.pl?pageid=60">Go back to Officer Club</a></p>

<table>
<tr class="header"><td>Name:</td><td>Share %:</td><td>Share pt:</td><td>Before:</td><td>Now:</td></tr>
until_end


		# winner negation
		%udata = &getData($hiuser, "data/users");
		$before = &countDebts($hiuser);

		&addDebt($hiuser, $iid, $hibid);
		#&addDebt($hiuser, $id, $hibid); # DEBTTUNE

		$after = &countDebts($hiuser);
		$html .= qq|<tr><td>Winner: $hiuser</td><td>0 %</td><td>0</td><td>Debt before: $before</td><td>Debt now: $after</td></tr>|."\n";


		# leader share
		#%udata = &getData($leader, "data/users");
		#$before = &getPoints($user);
		#&transferPoints("society", $leader, $leadpts, "Leadershare from $idata{'name'}");
		&addPointsLog($leader, $leadpts, "share;$id");
		#%udata = &getData($leader, "data/users", 1);
		#$after = &getPoints($user);
		$html .= qq|<tr><td>Leader: $leader</td><td>$leadshare %</td><td>$leadpts</td><td>$before</td><td>$after</td></tr>|."\n";


		# each members share
		for my $member (@names, @helpers) {
			next if ($member eq $leader);
			#%udata = &getData($member, "data/users");
			#$before = &getPoints($user);
			#&transferPoints("society", $member, $onepts, "Share from $idata{'name'}");
			&addPointsLog($member, $onepts, "share;$id");
			#%udata = &getData($member, "data/users", 1);
			#$after = &getPoints($user);
			$html .= qq|<tr><td>Member: $member</td><td>$oneshare %</td><td>$onepts</td><td>$before</td><td>$udata{'poolpoints'}</td></tr>|."\n";
		}

		$html .= <<until_end;
<tr class="footer"><td colspan=2>Totals:</td><td>$totalshare %</td><td>$totalpoints pts</td><td colspan=2>&nbsp;</td></tr>
</table>
until_end

		#my $fh = new IO::File "data/auctions/$id.html", "w";
		#print $fh $html;
	}



	$html .= <<until_end;
<h2>Closeable auctions</h2>

<p>
Go back to <a href="forumplus/index.pl?pageid=60">Officer Club</a>.
</p>

<table>
<tr class="header"><td>Auction ID:</td><td>Closed:</td><td>Bid status:<td>Leader:</td><td>Members:</td><td>Action:</td></tr>
until_end

	my $closeable = 0;
	for my $aid (&indexList("auctions", 1)) {
		my %adata = &getData($aid, "data/auctions");
		my ($hibid, $hiuser, $hitime) = &getHighestBid($aid);
		next unless (time() > &getAuctionClosing($aid) && $adata{'status'} eq "open");

		my $closed = &verboseDate(&getAuctionClosing($aid));
		my @ppl = split/,/,$adata{'names'};
		my @ppl2 = split/,/,$adata{'helpers'};
		my $membercount = scalar @ppl + scalar @ppl2;
		$closeable++;


		my %idata = &getData($adata{'itemid'}, "data/items");

		$html .= <<until_end;
<tr><td><a href="forumplus/index.pl?pageid=53&amp;action=view&amp;id=$aid">$idata{'name'}</a></td>
<td>$closed</td><td>$hibid ($hiuser)</td><td>$adata{'leader'}</td><td>$membercount</td>
<td><a href="forumplus/index.pl?pageid=63&amp;action=close&amp;id=$aid">Close&nbsp;&amp;&nbsp;share</a></td></tr>
until_end

	}

	$html .= qq|<tr class="footer"><td colspan=6>Closeable auctions: $closeable</td></tr></table>|."\n";

	return $html;
}





sub paybackDebts {
	my $user = shift;
	my $action = param('action');
	my $id = param('id');
	my $amount = param('amount') || 'partial';

	if ($action eq "payback") {
		my $msg = &payDebt($user, $id, $amount);
		my $redir_url = qq|http://2-mi.com/batmud/forumplus/index.pl?pageid=01|;
		&printHeaderRedirect($redir_url."&msg=Debt%20paid%20successfully.");
	}

	return "Undefined action";
}



sub viewPoints {
	my $user = shift;
	my $target = param('target') || "";
	return "Unauthorized access" unless ($user eq "admin");
	my $html = qq|<h2>Viewing points</h2>\n|;

	my $list = &createPlayerSelection();

	$html .= <<until_end;
<form method="post" action="forumplus/index.pl" name="memberform">
<table class="vertical">
<tr><td>Choose target:</td>
<td>
<select name="target" onChange='window.location="http://2-mi.com/batmud/forumplus/index.pl?pageid=65&amp;target="+document.memberform.target.value;'>
$list<option value="all">All</option></select>
</td></tr>
<!-- <tr class="footer"><td colspan="2"><input type="submit" value="View member" /></td></tr> -->
</table>
</form>

until_end

	return $html if ($target eq "");

	$html .= <<until_end;
<table>
<tr class="header"><td>Name:</td>
<td>Points from auctions</td><td>-</td><td>Debtspaid</td><td>+</td><td>Transfers</td>
<td>+</td><td>Fixes</td>
<td>=</td><td>Points</td><td>vs</td><td>True points</td><td>Diff</td>
<td>Debts in detail</td><td>Points in detail</td></tr>
until_end

	my @users = $target eq "all" ? &listFiles("data/users") : ($target);
	for my $member (sort @users) {
		my ($points, %pointhash) = &countAuctionPoints($member, 1);
		my $display = &getDisplayName($member);
		my ($debtsleft, $maxdebts) = &countDebts($member, 1);
		my %ddata = &getData($member, "data/debts");
		my %udata = &getData($member, "data/users");
		my ($xfersnow, $fixes) = &countXferPoints($member, 1);
		my $dispxfers = $xfersnow - $fixes;
		my $pointsnow = &getPoints($member);
		my $debtspaid = $maxdebts - $debtsleft;
		my $truepoints = $points - $debtspaid + $xfersnow - $fixes;
		my $pointsdiff = $truepoints - $pointsnow;

		#print STDERR "user: $member, points: $points, dleft: $debtsleft, dmax: $maxdebts, ".
		#	"xfersnow: $xfersnow, fixes: $fixes\n";

		$html .= <<until_end;
<tr><td>$display</td>
<td>$points</td><td>-</td><td>$debtspaid</td><td>+</td><td>$dispxfers</td>
<td>+</td><td>$fixes</td>
<td>=</td><td>$pointsnow</td><td>vs</td><td>$truepoints</td><td>$pointsdiff</td>
<td>
<table><tr class="header"><td>Name</td><td>Left</td><td>Max</td></tr>
until_end

		my ($td_left, $td_max) = (0, 0);
		for my $iid (sort keys %ddata) {
			my ($id_left, $id_max, $id_prev, $id_st) = split/;/, $ddata{$iid};
			my %idata = &getData($iid, "data/items");
			$td_left += $id_left;
			$td_max += $id_max;

			$html .= <<until_end;
<tr><td>$idata{'name'}</td><td>$id_left</td><td>$id_max</td></tr>
until_end
		}

		$html .= <<until_end;
<tr class="footer"><td colspan=3>Debtleft: $td_left  Debtmax: $td_max</td></tr>
</table></td>
<td>
<table>
<tr class="header"><td>Name</td><td>Hibid</td><td>Share%</td><td>Share</td></tr>
until_end

		my ($td_pts, $td_sharept) = (0, 0);
		for my $aid (sort keys %pointhash) {
			my ($hibid, $share, $sharept) = split/;/, $pointhash{$aid};
			next if ($share == 0);
			my %adata = &getData($aid, "data/auctions");
			my %idata = &getData($adata{'itemid'}, "data/items");
			$td_pts += int($share * $hibid);
			$td_sharept += $sharept;
			$share = sprintf("%4.2f", 100*$share);


			$html .= <<until_end;
<tr><td>$idata{'name'}</td><td>$hibid</td><td>$share</td><td>$sharept</td></tr>
until_end
		}

		$html .= <<until_end;
<tr class="footer"><td colspan=2>Pts: $td_pts</td><td colspan=2>Sharept: $td_sharept</td></tr>
</table></td>
</tr>
until_end

	}

	my $usrcnt = scalar @users;
	$html .= <<until_end;
<tr class="footer"><td colspan=15>Players: $usrcnt</td></tr>
</table>

until_end

	return $html;
}



sub adminPoints {
	my $user = shift;
	return "Unauthorized" unless ($user eq "admin");

	my $players_html = &createPlayerSelection();
	my $html .= <<until_end;

<h2>Admin points</h2>

<form method="get" action="forumplus/index.pl">
<input type="hidden" name="pageid" value="70" />
<input type="hidden" name="action" value="admintransfer" />
<table class="vertical">
<tr><td>Transfer from:</td><td><select name="from"><option value="society">Society</option>$players_html</select></td></tr>
<tr><td>Transfer to:</td><td><select name="to"><option value="society">Society</option>$players_html</select></td></tr>
<tr><td>Amount:</td><td><input type="text" name="amount" size="10" maxlength="10" value="0" /></td></tr>
<tr><td>Reason:</td><td><input type="text" name="reason" size="100" maxlength="255" value="" /><br /></td></tr>
<tr class="footer"><td colspan="2"><input type="submit" value="Transfer points" /></td></tr>
</table>
</form>

until_end

	my $action = param('action') || '';
	if ($action eq "admintransfer") {
		my $from = param('from');
		my $to = param('to');
		my $amount = param('amount');
		my $reason = param('reason');

		if ($amount > 0) {
			&addTransferLog($user, $amount, $reason, 1, $from, $to);
			$html .= <<until_end;
<p>Sent $amount points from $from to $to.</p>
until_end
		}
	}


	return $html;
}



sub clearStuff {
	my $user = shift;
	my $type = param('type');
	my $action = param('action') || 'error';
	return "Disabled";

	return "Not authorized" if ($user ne "admin");

	if ($action eq "recount") {
		&recountPoints();
		return;
	}

	if ($type eq "points") {
		return &clearPoints();
	} elsif ($type eq "debts") {
		return &clearDebts();
	}
	return "No such type";
}



sub printRules {
	my $lines = join("\n", &readFile("data/rules.txt"));

	my $html = <<until_end;
<h1>Rules of Forum+</h1>

<pre>
$lines
</pre>
until_end

	return $html;
}




sub adminUsers {
	my $user = shift;
	return "No access" unless ($user eq "admin");

	my $html .= <<until_end;
<form action="forumplus/index.pl" method="post">
<table>
<tr><td>Name:</td><td>Creator:</td><td>Officer:</td><td>Member:</td><td>Inactive:</td><td>Admin_opts:</td></tr>
until_end

	for my $member (sort {lc$a cmp lc$b} &listFiles("data/users")) {
		my ($cre, $off, $mem, $ina) = &checkYabb2ForumAccess($member);
		my $password = &checkYabb2Login($member, "_jummi");

		$html .= <<until_end;
<tr><td>$member</td><td>$cre</td><td>$off</td><td>$mem</td><td>$ina</td><td>$password</td></tr>
until_end
	}

	$html .= <<until_end;
</table>
</form>
until_end

	return $html;
}


# auction status,closing,names,itemid,item
# parties: status,state,start,com_nro,leader,members
sub searchLists {
    my $user = shift;
    my $field = param('field') || "";
    my $str = param('str') || "";

    my %sel = ($field => 'selected="selected"');

    my $html = <<until_end;
<h3>Search (beta):</h3>
<form action="forumplus/index.pl" method="post">
<input type="hidden" name="pageid" value="55" />
<table class="vertical">
<tr>
<td>Search what:</td>
<td>
<select name="field">
<option value="auction,2" $sel{'auction,2'}>Auction by names</option>
<option value="auction,4" $sel{'auction,4'}>Auction by item</option>
<option value="party,1" $sel{'party,1'}>Party by state</option>
<option value="party,4" $sel{'party,4'}>Party by leader</option>
<option value="party,5" $sel{'party,5'}>Party by member</option>
</select>
</td>
</tr>
<tr>
<td>Containing:</td>
<td>
<input type="text" size="30" maxlength="50" name="str" value="$str" />
</td>
<tr><td class="footer" colspan="2">
<input type="submit" value="Search" />
</td>
</table>
</form>

until_end

    return $html
       if ($field eq "" || $str eq "");

    my ($type, $fieldnro) = split/,/,$field;
    my @ids = &searchCache($type, $fieldnro, $str);
    my $count = scalar @ids;

    $html .= <<until_end;

<h3>Search results:</h3>
<p style="font-size: 0.8em;">$count hits found.</p>

<table>
until_end

    for my $id (reverse sort @ids) {
	$html .= &getAuctionLine($user, $id, "55")
	    if ($type eq "auction");
	$html .= &getPartyLine($user, $id)
	    if ($type eq "party");
    }

    $html .= qq|</table>\n|;
    return $html;
}




sub checkBidding {
    my $user = shift;
    return unless (&isProfiledMember($user));

    if ($action eq "bid") {
	my $bid = param('bid') || 0;
	my $aid = param('id') || 0;
	my $pagetgt = param('pageid') || "53";
	my $ok = &addBid($user, $aid, $bid);

	my $redir_url = qq|http://2-mi.com/batmud/forumplus/index.pl?pageid=$pagetgt&action=view&id=$aid|;
        # ok, success
	if ($ok =~ /is recorded/) {
	    &printHeaderRedirect($redir_url."&msg=Your%20bid%20of%20$bid%20was%20recorded.");
	# some problem
	} else {
	    $ok =~ s/ /\%20/g;
	    &printHeaderRedirect($redir_url."&msg=$ok");
	}
    }

}



__END__
