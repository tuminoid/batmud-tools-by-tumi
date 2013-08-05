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

# my stuff
# use lib '/home/twomi/web/libs';
use lib '/home/customers/tumi/public_html/archives/batmud';
use lib '/home/customers/tumi/tumilib';
use Tumi::Helper;
use BatmudTools::Site;

require 'support.pl';
require 'support2.pl';

# define what dir to look info from
my $DATADIR = "new";


print STDERR sprintf("%10s %9s (%9s-%9s)=%9s %9s %9s  = %9s (-%6s=%6s)\n",
		     "User", "Shares", "Maxdebt", "Payments", "Debt_left", "Xfer_SEND", "Xfer_RECV", "Total","CurPTS", "Diff");
print STDERR "----------------------------------------------------------------------------------------------------------\n";


my ($t_po, $t_de, $t_pa, $t_le, $t_to, $t_fr, $t_tot, $o_tot) = (0, 0, 0, 0, 0, 0, 0, 0);

for my $user (sort {(lc$a)cmp(lc$b)} &listFiles("data/users")) {

    my ($points, $debts, $lefts, $payments, $xferto, $xferfrom, $total) = (0, 0, 0, 0, 0, 0, 0);

    # Counting points
    my %pdata = &getData($user, "$DATADIR/points", 1);
    for my $key (keys %pdata) {
	my $val = $pdata{$key};
	my ($sign, $share, $reason) = $val =~ /^(\+)(\d+);(\w+)/;
	$points += $share if ($sign eq "+" && ($reason =~ /share|royalty/));
    }


    # Counting debts
    my %ddata = &getData($user, "$DATADIR/debts", 1);
    for my $aidtime (keys %ddata) {
	my ($left,$max,$lasttime,$status) =
	    $ddata{$aidtime} =~ /(\d+);(\d+);(\d+);(\w+)/;
	$payments += ($max-$left);
	$lefts += $left;
	$debts += $max;
    }

    # Counting transfers
    my %tdata = &getData($user, "$DATADIR/transfers", 1);
    for my $tid (keys %tdata) {
	my ($sign, $amnt, $action, $from, $time, $reason) =
	    $tdata{$tid} =~ /^(\-|\+)?(\d+);(\w+);(\w+);(\d+);(.*?)$/;
	$sign = "+" unless (defined $sign && length ($sign) > 0);

	$xferto += $amnt if ($action eq "transferto");
	$xferfrom += $amnt if ($action eq "transferfrom");
    }


    $total = $points - $payments + $xferfrom - $xferto;
    $t_po += $points;
    $t_pa += $payments;
    $t_de += $debts;
    $t_to += $xferto;
    $t_fr += $xferfrom;
    $t_le += $lefts;

    my $cur_pts = &getPoints($user);
    my $diff = $total - $cur_pts;
    $o_tot += $cur_pts;

    print STDERR sprintf("%10s %9d+(%9d-%9d)=%9d-%9d-%9d+ = %9d (-%6d=%6d)\n",
			 $user, $points, $debts, $payments, $lefts, $xferto, $xferfrom, $total,
			 $cur_pts, $diff);
}

$t_tot = $t_po - $t_pa - $t_to + $t_fr - $t_le;
print STDERR "----------------------------------------------------------------------------------------------------------\n";
print STDERR sprintf("%10s %9d (%9d-%9d)=%9d %9d %9d  = %9d (-%6d=%6d)\n",
		     "Totals", $t_po, $t_de, $t_pa, $t_le, $t_to, $t_fr, $t_tot, $o_tot, $t_tot-$o_tot);




1;

