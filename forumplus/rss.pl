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
use CGI qw/param/;
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
require 'support3.pl';

my $user = param('user') || "unknown";
my $logdir = &getVar('logpath');

my $fh = new IO::File "$logdir/forumrss.log", "a+";
print $fh localtime().": '$user' reads the rss feed.\n";

unless (&isProfiledMember($user)) {
    print <<until_end;
Location: http://humdi.net/evo/

until_end
    exit;
}

my %days = (
	"0" => "Sun", "1" => "Mon", "2" => "Tue", "3" => "Wed",
	"4" => "Thu", "5" => "Fri", "6" => "Sat",
);
my %months = (
	"0" => "Jan", "1" => "Feb", "2" => "Mar", "3" => "Apr",
	"4" => "May", "5" => "Jun", "6" => "Jul", "7" => "Aug",
	"8" => "Sep", "9" => "Oct", "10" => "Nov", "11" => "Dec",
);
my @parties = &listFiles("data/parties");
my $newest = (reverse sort @parties)[0];

# Tue, 03 Jun 2003 09:39:21 GMT
my $nowdate = &formatTime(time);
my $builddate = &formatTime($newest);


my $rss_header = <<until_end;
<?xml version="1.0" encoding="ISO-8859-1"?>
<rss version="2.0">
\t<channel>
\t\t<title>Forum+ parties</title>
\t\t<link>http://2-mi.com/batmud/forumplus/</link>
\t\t<description>Forum+ Party Schedules</description>
\t\t<language>en-gb</language>
\t\t<pubDate>$nowdate</pubDate>
\t\t<lastBuildDate>$builddate</lastBuildDate>
\t\t<docs>http://blogs.law.harvard.edu/tech/rss</docs>
\t\t<generator>rss.pl</generator>
\t\t<managingEditor>tumi\@2-mi.com</managingEditor>
\t\t<webMaster>tumi\@2-mi.com</webMaster>
\t\t<ttl>60</ttl>
until_end

my $rss_items = "";


for my $pid (sort {sortByStartdate($a,$b)} &indexList("parties", 1)) {
	my %pdata = &getData($pid, "data/parties");
	next if ($pdata{'starting'} < time() || $pdata{'status'} =~ m/(cancelled|over)/);

	my %encode = (
		"&"	=> "&amp;",
		">"	=> "&gt;",
		"<"	=> "&lt;",
	);

	my $creatorgamename = lc &getGameName($pdata{'creator'});
	my $partydate = &formatTime($pid);

	my $desc = $pdata{'name'}." - ".&datefmt($pdata{'starting'});

	for my $string ($desc) {
		for my $entity (sort keys %encode) {
			my $replacement = $encode{$entity};
			$string =~ s/$entity/$replacement/g;
		}
	}

	my %this_item = (
		"title"			=> $desc,
		"link"			=> &getVar('website')."/forumplus/index.pl?pageid=41&amp;action=view&amp;id=$pid",
		"description"	=> $desc,
		"pubDate"		=> $partydate,
		"guid"			=> &getVar('website')."/forumplus/index.pl?pageid=41&amp;action=view&amp;id=$pid",
		"author"		=> "$creatorgamename\@batmud.bat.org (".&getDisplayName($pdata{'creator'}).")",
	);

	my $this_rss = qq|\t\t<item>\n|;
	for my $keyword (sort keys %this_item) {
		$this_rss .= qq|\t\t\t<$keyword>$this_item{$keyword}</$keyword>\n| if (length($this_item{$keyword}) > 0);
	}
	$this_rss .= qq|\t\t</item>\n|;

	$rss_items .= $this_rss;
}


my $rss_footer = <<until_end;
\t</channel>
</rss>

until_end

$rss_items = "" unless (&isValidMember($user));


print <<until_end;
Content-Type: text/xml; charset=iso-8859-1

$rss_header
$rss_items
$rss_footer
until_end



1;



sub formatTime {
	my $tim = shift || time;

	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($tim);
	my $date = sprintf("%3s, %02d %3s %4d %02d:%02d:%02d %4s",
						$days{$wday}, $mday, $months{$mon}, $year+1900, $hour, $min, $sec, "+0200");

	return $date;
}



sub sortByStartdate {
    my ($a, $b) = @_;
    my @info_a = split/;/, &getCache($a, "party");
    my @info_b = split/;/, &getCache($b, "party");

    return ($info_a[2] <=> $info_b[2]);
}

__END__


