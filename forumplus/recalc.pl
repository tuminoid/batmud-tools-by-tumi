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

require 'support.pl';
require 'support2.pl';

my $DEBUG_SUMMARY = 0;
my $DEBUG_POINTS = 0;
my $DEBUG_DEBTS = 0;
my $DEBUG_TRANSFERS = 0;
my $DEBUG_BIDS = 0;


&recalcPoints();
&recalcBids();
&recalcDebts();
&recalcTransfers();


1;



sub recalcTransfers {
	`rm new/transfers/*.dat` if (-d "new/transfers");

    # Converting transfers
    for my $user (&listFiles("data/transfers")) {
		my %tdata = &getData($user, "data/transfers", 1);
		my %newdata = ();

		for my $tid (keys %tdata) {
		    my ($sign, $amnt, $action, $from, $time, $reason) =
			$tdata{$tid} =~ /^(\-|\+)?(\d+);(\w+);(\w+);(\d+);(.*?)$/;
		    $sign = "+" unless (defined $sign && length ($sign) > 0);

		    next unless ($action =~ /transfer/);
		    $newdata{$tid} = "$sign$amnt;$action;$from;$time;$reason";
		}

		&writeData($user, "new/transfers", %newdata);
    }
}



sub recalcBids {
	`rm new/bids/*.dat` if (-d "new/bids");

    # Converting bids
    for my $bid (&listFiles("data/bids")) {
		my @lines = reverse (split/\n/, &readFile("data/bids/$bid.dat"));
		my %newdata = ();

		print "Converting bids on $bid.. (old winline: $lines[0])\n" if ($DEBUG_BIDS);
		for my $line (reverse sort @lines) {
		    next if (length ($line) < 10);
		    my ($extra, $who, $bid, $time) = $line =~ /^(bid)?(\w+): (\d+);(\d+)/;
		    $newdata{"$who,$time"} = $bid;
		}

		&writeData($bid, "new/bids", %newdata);
    }
}



sub recalcDebts {
	`rm new/debts/*.dat` if (-d "new/debts");

    for my $aid (&listFiles("new/bids")) {
		my %adata = &getData($aid, "data/auctions");
		print STDERR "error: AID $aid has no keys\n" if (keys (%adata) < 1);
		next if ($adata{'status'} ne "closed");

		my ($bidder, $bid, $time) = ("", -1, 0);
		my %bdata = &getData($aid, "new/bids", 1);
		for my $key (keys %bdata) {
		    my ($this_bidder, $this_time) = split/,/, $key;
		    my $this_bid = $bdata{$key};

		    if ($this_bid > $bid) {
				$bidder = $this_bidder;
				$bid = $this_bid;
				$time = $this_time;
		    }
		}

		my $debt_left = $bid;
		my $wintime = $time + 36*60*60;
		my $nexttime = $wintime + 30*24*60*60;
		my $iid = $adata{'itemid'};
		my $found = 0;
		my %olddata = &getData($bidder, "data/debts", 1);
		for my $old_iid (keys %olddata) {
		    my ($old_left, $old_max, $old_time, $old_status) =
				$olddata{$old_iid} =~ /(\d+);(\d+);(\d+);(.*?)/;

		    if ($old_iid == $iid) {
				if ($old_max == $bid) {
			    	$debt_left = $old_left;
			    	$nexttime = $old_time;
			    	$found = 1;
			    	last;
				} else {
			    	$debt_left = 0;
			    	print STDERR "Guessing double item, marking as 0 debt.\n" if ($DEBUG_DEBTS);
			    	last;
				}
		    }
		}
		if ($found == 0 && $DEBUG_DEBTS) {
		    my %idata = &getData($iid, "data/items");
		    print STDERR "Couldn't find matching payment for AID: $aid  WINNER: $bidder  ITEM: $idata{'name'}\n";
		}


		my %ddata = &getData($bidder, "new/debts", 1);
		my $debts = scalar (keys %ddata) + 1;
		print sprintf("AID: $aid  WIN: %10s  BID: %7d  DEBTS: %3d\n", $bidder, $bid, $debts) if ($DEBUG_DEBTS);
		$ddata{"$aid,$wintime"} = "$debt_left;$bid;$nexttime;debted";
		&writeData($bidder, "new/debts", %ddata);
    }
}




sub recalcPoints {
	`rm new/points/*.dat` if (-d "new/points");

    # Handling auctions
    my $royalty = 0.0;

    for my $aid (&listFiles("data/auctions")) {
	my %adata = &getData($aid, "data/auctions", 1);
	next if ($adata{'status'} ne "closed");

	my %idata = &getData($adata{'itemid'}, "data/items");
	my @ig_names = ($adata{'names'}, $adata{'helpers'});
	my @names = map {&getLoginFromGameName($_)} split(/,/, $adata{'names'});
	my $leader = $adata{'leader'};
	my $closed = &getAuctionClosing($aid);
	my $itemname = $idata{'name'} || $adata{'itemid'};

	print "AID: $aid  Item: $itemname\n" if ($DEBUG_POINTS);
	for my $user (@names) {
	    my %pdata = &getData($user, "new/points", 1);
	    my $share = &_getAuctionSharePoints($user, $aid);
	    $royalty += $share-int($share);
	    $share = int($share);

	    $pdata{"$aid,$closed"} = "+$share;share";
	    print
		sprintf("Mbr: %10s  AID: %d  Item: %20s  Ldr: %10s  Clo: %d  Shr: %5d\n",
			$user, $aid,
			(length ($itemname) > 20 ? substr($itemname, 0, 20) : $itemname),
			 $leader, $closed, $share)
		if ($DEBUG_POINTS);
	    &writeData($user, "new/points", %pdata);
	}
    }

    my %tdata = &getData("admin", "new/points", 1);
    $tdata{"10,".time().""} = "+".int($royalty).";royalty";
    print STDERR "Paid $royalty points of royalty.\n" if ($DEBUG_POINTS);
    &writeData("admin", "new/points", %tdata);
}


sub _getAuctionSharePoints {
	my $user = shift;
	my $aid = shift;

	my %adata = &getData($aid, "data/auctions");
	my @aname = split/,/, $adata{'names'};
	my @ahelp = split/,/, $adata{'helpers'};
	my $members = scalar (@aname) + scalar (@ahelp);
	print "  getting share: $user  aid: $aid  mbrs: $members  disp: ".getDisplayName($user)."\n" if ($DEBUG_POINTS);

	my $share = 0;
	if (lc$user eq lc$adata{'leader'}) {
	    $share = ((1.0 / $members) * (1.0 + 1.0/$members));
	} else {
	    $share = ((1.0 / $members) * (1.0 - 1.0/($members*($members-1))));
	}

        my ($hibid, @rest) = &getHighestBid($aid);
	print "  ..share was $share\%, bid = $hibid => ".($hibid*$share)."\n" if ($DEBUG_POINTS);

	return ($share*$hibid);
}



__END__


