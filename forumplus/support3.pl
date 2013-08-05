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

require 'support.pl';
require 'support2.pl';


sub checkIndexes {
	my $dir = &getVar('siteroot')."/forumplus/data";

	&redoPartyIndex() if (not (-e "$dir/parties.dat"));
	&redoAuctIndex() if (not (-e "$dir/auctions.dat"));
#	&redoPointIndex() if (not (-e "$dir/points.dat"));
}

sub redoIndexes {
	&redoPartyIndex();
	&redoAuctIndex();
#	&redoPointIndex();
}


sub redoPointIndex {
	my @members = &listFiles("data/users");
	my %point_cache = ();

	for my $member (@members) {
		my $points = &getPointsFromFile($member);
		$point_cache{$member} = $points;
	}
	&writeData("points", "data", %point_cache);
}


sub redoPartyIndex {
	my @pfiles = &listFiles("data/parties");
	my %pid_cache = ();
	for my $pid (@pfiles) {
		my %pdata = &getData($pid, "data/parties", 1);
		$pid_cache{$pid} = $pdata{'status'} =~ /(open|full)/ ? 1 : 0;
	}
	&writeData("parties", "data", %pid_cache);

	&redoPartyCache();
}

sub redoAuctIndex {
	my @afiles = &listFiles("data/auctions");
	my %aid_cache = ();
	for my $aid (@afiles) {
		my %adata = &getData($aid, "data/auctions", 1);
		$aid_cache{$aid} = $adata{'status'} eq "open" ? 1 : 0;
	}
	&writeData("auctions", "data", %aid_cache);

	&redoAuctCache();
}



sub redoCaches {
    &redoPartyCache();
    &redoAuctCache();
}


sub redoPartyCache {
    my @pfiles = &listFiles("data/parties");
    my %pid_cache = ();
    for my $pid (@pfiles) {
	my $entry = &_formatPartyCache($pid);
	$pid_cache{$pid} = $entry;
    }
    &writeData("parties.cache", "data", %pid_cache);
}


sub redoAuctCache {
    my @afiles = &listFiles("data/auctions");
    my %aid_cache = ();
    for my $aid (@afiles) {
	my $entry = &_formatAuctCache($aid);
	$aid_cache{$aid} = $entry;
    }
    &writeData("auctions.cache", "data", %aid_cache);
}

sub searchCache {
    my $type = shift;
    my $fieldnro = shift || 0;
    my $search_str = shift || "";
    $search_str =~ tr/[a-zA-Z0-9 ]//cd;
    return () if (length($search_str) < 1);

    &redoPartyCache() if ($type eq "party" && !(-e "data/parties.cache.dat"));
    &redoAuctCache() if ($type ne "party" && !(-e "data/auctions.cache.dat"));

    my $file = $type eq "party" ? "parties.cache" : "auctions.cache";
    my %data = &getData($file, "data", 1);

    my @hits = ();
    for my $key (sort keys %data) {
	my @fields = split/;/, $data{$key};

	push @hits, $key
	    if ($fields[$fieldnro] =~ m/$search_str/i);
    }

    return (@hits);
}


sub getCache {
    my $id = shift;
    my $type = shift;
    return "" unless (defined $id && defined $type);

    my $file = $type eq "party" ? "parties.cache" : "auctions.cache";
    my %data = &getData($file, "data");

    return $data{$id};
}


sub _formatPartyCache {
    my $pid = shift;
    return "" unless (-e "data/parties/$pid.dat");

    my %pdata = &getData($pid, "data/parties", 1);
    my $status = $pdata{'status'} =~ /(full|open)/ ? 1 : 0;
    my $members = join(",",&listPartyMembers($pid));
    my $state = $pdata{'status'} || "invalid";
    my $leader = $pdata{'creator'} || "invalid";
    my $start = $pdata{'starting'} || "invalid";

    my %cdata = &getData($pid, "data/comments/party");
    my $com_nro = scalar keys %cdata;

    # pid: status,state,starting,comments,leader,members
    my $cache_str = "$status;$state;$start;$com_nro;$leader;$members";
    return $cache_str;
}


sub _formatAuctCache {
    my $aid = shift;
    return "" unless (-e "data/auctions/$aid.dat");

    my %adata = &getData($aid, "data/auctions", 1);
    my $status = $adata{'status'} eq "open" ? 1 : 0;
    my $names = $adata{'names'} || "invalid";
    my $item = $adata{'itemid'};

    my %idata = &getData($item, "data/items");
    my $name = $idata{'name'} || "invalid";

    my $closing = &getAuctionClosing($aid);

    # aid: state,closing,names,iid,name
    my $cache_str = "$status;$closing;$names;$item;$name";
    return $cache_str;
}



sub setIndexValue {
	my $type = shift;
	my $id = shift;
	my $value = shift;

	return unless (defined $type && defined $id && defined $value);
	return unless ($type =~ /^(auctions|parties|points|debts)$/);

	my %data = &getData($type, "data", 1);
	$data{$id} = $value;
	&writeData($type, "data", %data);
}



sub indexList {
	my $type = shift || ""; # parties, auctions
	my $state = shift || 0; # 0 closed, 1 open
	return () unless ($type =~ /parties|auctions/);

	my %indexhash = &getData($type, "data", 1);
	my @idlist = grep {$indexhash{$_} == $state} (keys %indexhash);

	return @idlist;
}


sub printHeaderRedirect {
	my $url = shift || return;
	print "Location: $url\n\n";
	exit;
}




sub backup {
	my ($day, $month, $year) = (localtime)[3..5];
	($day, $month, $year) = (sprintf("%02d", $day), sprintf("%02d", $month+1), $year+1900);
	my $filename = "backup/data_$year$month$day.tgz";
	return if (-e "$filename");

	`tar zcf $filename data`;
}


__END__

