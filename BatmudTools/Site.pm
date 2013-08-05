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

package BatmudTools::Site;
use strict;
use CGI qw/param/;
use IO::File;
use vars qw($VERSION @ISA @EXPORT);

# what we use ourselves
# use lib '/home/twomi/web/libs';
use lib '/home/customers/tumi/public_html/archives/batmudtools';
use lib '/home/customers/tumi/tumilib/lib';
use BatmudTools::Vars;
use BatmudTools::Layout;
use BatmudTools::Login;
use BatmudTools::Update;
use Tumi::ChangeLog;
use Tumi::Helper;
use Tumi::DB qw/dbDisconnectAll/;

# what we export
$VERSION = '0.3';
require Exporter;
use DynaLoader();
@ISA = qw(Exporter DynaLoader);
@EXPORT = qw(pageOutput);


# the stuff itself
my $logpath = &getVar('logpath');
my $loginpath = &getVar('loginpath');


# new way of generating the site
# menunro, title, url, visible, css, linkdesc, metakeywords
my %site_items = (
	"index"		=> [ 1, "Site index", "/", 1, "",
		"BatMUD Tools index with general info about the site",
		[ "batmud", "batmud tools", "batmud tools by tumi", "support", "tools" ] ],
	"intro"		=> [ 5, "Introduction", "/index.pl?id=intro", 1, "",
		"BatMUD Tools index with descriptions of tools available and general info about the site",
		[ "batmud", "batmud tools", "intro", "introduction" ] ],
	"mapindex"	=> [ 10, "Batmap-in-colour", "/batmap/", 1, "batmap/batmap.css",
		"Batmap in colour, with nearly all the scenics marked on it",
		[ "batmud", "batmap", "batmap-in-colour", "coloured map" ] ],
	"mapcolor"	=> [ 20, "Batmap-in-colour with scenics", "/batmap/webmap.pl", 0, "batmap/batmap.css",
		"",
		[ "batmud", "batmap", "batmap-in-colour", "scenic location", "scenics", "map" ] ],
	"mapplain"	=> [ 30, "Batmap-in-colour, plain", "/batmap/webmap.pl", 0, "batmap/batmap.css",
		"",
		[ "batmud", "batmap", "batmap-in-colour", "plain", "map" ] ],
	"mapfind"	=> [ 35, "Find-a-place", "/findaplace/", 0, "batmap/batmap.css",
		"Paste a piece of map and this tool will search the map for this location",
		[ "batmud", "batmap", "findplace", "findaplace", "map search" ] ],
	"mapcity1"	=> [ 40, "BatCity streetmap", "/batmap/citymap.pl", 1, "batmap/citymap.css",
		"Map of the streets in the BatCity",
		[ "batmud", "batmap", "citymap", "streetmap", "batcity", "streets" ] ],
	"reincsim"	=> [ 50, "Reinc simulator", "/reincsim/", 1, "reincsim/reincsim.css",
		"Live a what-if life or plan your next reincarnation very closely, including most of the guild specials, races, boons, quests etc",
		[ "batmud", "reincsim", "reinc simulator", "reincarnation", "simulator" ] ],
	"reinchc"	=> [ 60, "HC Reincsim", "/reincsim/hcreincsim.pl", 0, "reincsim/reincsim.css",
		"",
		[ "batmud", "reincsim", "reinc simulator", "reincarnation", "simulator" ] ],
	"reinclist"	=> [ 70, "List of reincs", "/reincsim/list.pl", 0, "reincsim/list.css",
		"",
		[ "batmud", "reincsim", "reinc simulator", "reincarnation", "simulator" ] ],
	"reincview" => [ 80, "View a reinc", "/reincsim/viewreinc.pl", 0, "reincsim/viewreinc.css",
		"Have a read-only look at certain saved reinc, including commands which actually train you the planned reinc!",
		[ "batmud", "reincsim", "reinc simulator", "reincarnation", "simulator" ] ],
	"raceinfo"	=> [ 90, "Raceinfo", "/raceinfo/", 1, "raceinfo/raceinfo.css",
		"Raceinfo contains detailed information about races, their special abilities etc",
		[ "batmud", "raceinfo", "races", "info", "race" ] ],
	"expplaque"	=> [ 100, "Expplaque", "/expplaque/", 1, "expplaque/plaque.css",
		"The tool for calculating gained/lost experience during any period of time, for any mortal on the official exp plaque",
		[ "batmud", "experience", "expplaque", "plaque", "expgraph", "top expmakers", "expmaker" ] ],
	"expgraph"	=> [ 110, "Expgraph", "/expplaque/", 0, "expplaque/plaque.css",
		"The tool for creating a graph of given players total experience",
		[ "batmud", "experience", "expplaque", "plaque", "expgraph", "top expmakers", "expmaker" ] ],
	"explore"	=> [ 120, "Exploreplaque", "/explore/", 0, "explore/explore.css",
		"Similar to the expplaque, but measures people by explored rooms instead of experience",
		[ "batmud", "explore", "exploreplaque", "plaque", "exploregraph" ] ],
	"exploregraph"	=> [ 130, "Exploregraph", "/exploreplaque/", 0, "exploreplaque/explore.css",
		"Similar to the expgraph, but draws graphs based on explorecount instead of gained experience",
		[ "batmud", "explore", "exploreplaque", "plaque", "exploregraph" ] ],
	"sscounter"	=> [ 140, "SS counter", "/sscounter/", 1, "sscounter/ss.css",
		"S(ecret) S(ocietys) bonus counter helps you plan the bonuses you are getting by joining a SS, with template generator",
		[ "batmud", "sscounter", "secret society", "ss counter", "bonus", "counter", "ss" ] ],
	"sales"		=> [ 150, "Sales Search", "/sales/", 1, "sales/sales.css",
		"Search the sales channel for specific items or items by specific seller",
		[ "batmud", "bsse", "sales", "search", "sales search", "engine", "sales logs" ] ],
	"booncalc"	=> [ 160, "Boon calculator", "/boons/", 1, "boons/boons.css",
		"A bit outdated tool for calculating the amount of cash required to get some number of boons",
		[ "batmud", "boon", "boons", "booncalc", "boon calculator", "calculator" ] ],
	"boards"	=> [ 200, "Discussion board", "/forum/", 1, "",
		"Discuss about BatMUD, BatMUD Tools, players of bat, regen fodder or generally about anything" ],
	"changelogs"=> [ 300, "ChangeLogs", "/content/clog.pl?item=list", 1, "content/clog.css",
		"View the changelogs for the tools on this site",
		[ "batmud", "changelog", "changelogs", "changes", "latest news" ] ],
	"donations"	=> [ 400, "Donations", "/index.pl?id=donations", 1, "",
		"See the list of donations I've received from the mortals appreciating the work on this site",
		[ "batmud", "donations", "donates" ] ],
	"othersites"=> [ 450, "Other sites", "/index.pl?id=othersites", 1, "",
		"List of other, BatMUD related sites that I've found helpful myself. No portals, just direct links",
		[ "batmud", "other sites", "related sites", "links" ] ],
	"login"		=> [ 500, "Login", "/index.pl?id=login", 0, "",
		"Login to the BatMUD Tools to gain full advantage of the site",
		[ "batmud", "batmud tools", "login" ] ],
	"forumplus"	=> [ 900, "Forum+ SS", "/forumplus/", 0, "forumplus/plus.css",
		"Forum+ is a eq-society, limited membership",
		[ "batmud", "forumplus", "forum+" ] ],
);

my @categories = (
	"menu_tools|index|intro|boards",
	"menu_info|mapindex|mapcolor|mapplain|mapcity1|raceinfo|sales",
	"menu_sims|reincsim|reincview|reinclist|sscounter|booncalc",
	"menu_plaques|expplaque|expgraph|explore|exploregraph",
	"menu_misc|changelogs|donations|othersites|forumplus",
);



1;






sub _printPage($) {
    my $content = shift;
	my $contenttype = "";

	for my $hdr (&getLayoutHeaders()) {
		$hdr =~ tr/\x0D\x0A//d;
		$contenttype .= $hdr."\n" if (length($hdr) > 5);
	}
	$contenttype .= "\n";

	# very important, otherwise data will be rollback
	&dbDisconnectAll();

	print $contenttype, $content;
	1;
}




sub pageOutput($$) {
	my $pageid = shift || 'index';
	my $content = shift || "Empty page, this shouldn't happen. Please report this!\n";

	# run update on every page output - it has checks
	&updateAll();

	# basics
	my $siteroot = &getVar('siteroot');
	my $website = &getVar('website');
	my $template = &readFile("$siteroot/content/template.html");
	my ($num, $title, $url, $visible, $css, $desc) = @{$site_items{$pageid}};

	# tags - title
	my $autotitle = $title || "Unindexed page";
	my $pagetitle = &getLayoutItem('title');
	my $titlepostfix = &getVar('titlepostfix');
	my $fulltitle = $pagetitle ? "$pagetitle / $autotitle" : $autotitle;
	$template = &tagReplace($template, "title", "$fulltitle / $titlepostfix");

	# tags - basehref
	my $basehref = qq|<base href="$website" />|;
	$template = &tagReplace($template, "basehref", $basehref);

	# tags - favicon
	$template = &tagReplace($template, "favicon", &getVar('favicon'));

	# tags - maincss
	$template = &tagReplace($template, "maincss", &getVar('maincss'));

	# tags - subcss
	my $css_templ = qq|\t<link href="__file__" type="text/css" rel="stylesheet" />|;
	my @subcss = ();
	if ($css) {
		foreach my $thiscss (split/\|/, $css) {
		    my $tmp = $css_templ;
		    $tmp =~ s/__file__/$thiscss/;
		    push @subcss, $tmp;
		}
	}
	if (&getLayoutItem('css')) {
	  my $css = &getLayoutItem('css');
	  $css_templ =~ s/__file__/$css/;
	  push @subcss, $css_templ;
	}
	$template = &tagReplace($template, "subcss", @subcss);

	# tags - body
	my $body_js = &getLayoutItem('body_js');
	$template = &tagReplace($template, "body", qq|<body$body_js>|);

	# tags - h1title
	$template = &tagReplace($template, "h1title", &getVar('h1title'));

	# tags - menu
	my $menu_div = &_getMenu($pageid);
	$template = &tagReplace($template, "menu", $menu_div);

	# tags - headelements (misplaced, because content made up in _getmenu
	$template = &tagReplace($template, "headelements", &getHeadElements());

	# tags - submenu
	$template = &tagReplace($template, "submenu", &getLayoutItem('submenu'));

	# tags - login
	my $login_div = &_getLogin();
	#$template = &tagReplace($template, "login", $login_div);

	# tags - adsense
	&_setAdsenseLayout($pageid);
	$template = &tagReplace($template, "adsense", &getLayoutItem('adsense'));

	# tags - links
	#$template = &tagReplace($template, "links", &getLayoutItem('links'));

	# tags - voteurl
	$template = &tagReplace($template, "voteurl", &getLayoutItem('voteurl'));

	# tags - counter
	my $counter_div = &_getCounter($pageid);
	$template = &tagReplace($template, "counter", $counter_div);

	# tags - content
	$template = &tagReplace($template, "content", $content);

	# tags - subcontent
	$template = &tagReplace($template, "subcontent", &getLayoutItem('subcontent'));

	# tags - adsense2
	my $adsense1 = &getAdsense('728', '90');
	my $adsense2 = qq|<div id="adsense2">\n$adsense1</div>\n|;
	$template = &tagReplace($template, "adsense2", $adsense2);

	# tags - footer
	$template = &tagReplace($template, "footer", &getLayoutItem('footer'));

	# remove all the unused tags
	$template =~ s{^\s*<!\-\- TAG:\w+ \-\->.*?$}{}g;

	# Logging
	my $fh = new IO::File ">> $logpath/$pageid.log";
	print $fh "X" if ($fh);
	undef $fh;

	# all done - congrats
    return &_printPage($template);
}




# when page was created
sub _getCreationDate(;$) {
	my $pageid = shift || "index";

	return "14th Sep 2006" if ($pageid =~ /^citymap/);
	return "17th Aug 2006";
}



# TODO: Implement
sub _getLogin() {
    my $siteroot = &getVar('siteroot');
	return&readFile("$siteroot/content/login.html");
}


# sortby internal id
sub _sortbyid {
    my @a_stuff = @{$site_items{$a}};
    my @b_stuff = @{$site_items{$b}};
    return ($a_stuff[0] <=> $b_stuff[0]);
}



# generate our menu
sub _getMenu($) {
	my $curid = shift;
	my $siteroot = &getVar('siteroot');
	my $menu = &readFile("$siteroot/content/menu.html");

	for my $cat (@categories) {
		my @catitems = split/\|/, $cat;
		my $tag = shift @catitems;
		my $output = "";

		for my $pageid (@catitems) {
			my ($id, $title, $url, $visible, $css, $desc, $keywords) = @{$site_items{$pageid}};

			if ($pageid eq $curid) {
				$output .= qq|\t<div class="menuitem_active">$title</div>\n|;

				&addHeadElement(qq|<meta name="description" content="$desc" />|) if ($desc);
				&addHeadElement(qq|<meta name="keywords" content="|.join(", ", @{$keywords}).qq|" />|)
					if (scalar (@{$keywords}) > 0);

			} else {
				if ($visible) {
					my $href_title = $desc ? qq| title="$desc"| : "";
					$output .= qq|\t<div class="menuitem"><a href="$url"$href_title>$title</a></div>\n|;
				}
			}
		}

		$menu = &tagReplace($menu, $tag, $output);
	}

	# navpath
	# nothing yet

	# login
	$menu = &tagReplace($menu, 'login', &getHello());

	# visitors
	my ($users, $visitors) = &getOneHourVisits();
	$menu = &tagReplace($menu, 'visitors', qq|Currently online: $users users and $visitors visitors.|);

	return $menu;

}



sub _getCounter($) {
	my $pageid = shift;

	my $visitorcount = &_getVisitors($pageid);
	my $previousload = &getModifiedTime("$logpath/$pageid.log");
	my $cdate = &_getCreationDate($pageid);

	my $counter_div = <<until_end;
<div id="counter">
	This subpage has been loaded
	<span class="counter_data">$visitorcount</span>
	times since
	<span class="counter_data">$cdate</span>.
	Previous pageload
	<span class="counter_data">$previousload</span>
	ago.
</div> <!-- counter -->
until_end

	return $counter_div;
}


# get pageloads for certain id
sub _getVisitors($) {
	my $pageid = shift || 'index';
	my $filename = "$logpath/$pageid.log";
	my $addon = 0;

	# different pages, stupid way of logging
	# aug 17 2006 numbers, not used
#	my %addons = (
#		"index" => 174019,
#		"expplaque" => 55949,
		#"expgraph" => 0, # didn't exist separately
#		"raceinfo" => 92094,
#   	"sscounter" => 8276,
#		"booncalc" => 22476,
#		"reincsim" => 1521689,
#		"reincview" => 97795,
		#"reinchc"
#		"mapindex" => 24420,
#		"mapcolor" => 48594,
#		"mapplain" => 99,
#		"changelogs" => 10304,
#		"sales" => 69746,
#		"forumplus" => 307399,
#	);
#	$addon = $addons{$pageid} || 0;


	# count lines, ie. visitorcount
	if (-e $filename) {
		my $retval = `wc -c $filename`;
		my ($cnt) = $retval =~ /^\s*(\d+)/;
		return $cnt+$addon;
	}

	return 1;
}



# getget adsense, currently all pages have same ad
sub _setAdsenseLayout($) {
	my $pageid = shift || 'index';

	&setLayoutItem('adsense',
		qq|<div id="adsense">\n|.
		&getAdsense(468, 60).
		qq|</div>\n|);
}





__END__

