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

# my stuff
# use lib '/home/twomi/web/libs';
use lib '/home/customers/tumi/public_html/archives/batmud';
use lib '/home/customers/tumi/tumilib';
use Tumi::Helper;
use BatmudTools::Site;
use BatmudTools::Login;

require 'support.pl';
require 'support3.pl';


my ($content, $user) = &checkLogin(860);


unless ($user && &isValidOfficer($user)) {
	$content .= "Bad user or non-officer, cannot add auction.<br />";

} else {

	# Writing into eq file
	my $time = param('id') || time();

	my $cnt = 0;
	for my $iid (param('itemid')) {
		my $aid = $time+$cnt;
		my $filename = "".$aid.".dat";
		my $fh = new IO::File "data/auctions/$filename", "w";

		for my $key (param()) {
			my $val = defined param($key) ? param($key) : "";
			if ($key =~ /^bid(\w+)/) {
				my $fh2 = new IO::File "data/bids/$filename", "a+";
				print $fh2 "$1: $val\n";
				next;
			}
			if ($key =~ /itemid/) {
				print $fh "itemid: $iid\n";
				next;
			}
			print $fh "$key: $val\n";
		}
		print $fh "opened: $time\n";
		$cnt++;

		$content .= "You fiddled with auction <a href=\"forumplus/index.pl?pageid=53&amp;action=view&amp;id=$aid\">$aid</a> (item <a href=\"forumplus/index.pl?pageid=52&amp;action=view&amp;id=$iid\">$iid</a>).<br />";
		&writeUserLog($user, "You fiddled with auction <a href=\"forumplus/index.pl?pageid=53&amp;action=view&amp;id=$aid\">$aid</a>.");
	}

	&redoAuctIndex();
	my $redir_url = qq|http://2-mi.com/batmud/forumplus/index.pl?pageid=50|;
	&printHeaderRedirect($redir_url."&amp;msg=Auctions%20saved%20successfully.");
}


&pageOutput('forumplus', $content);


1;

__END__
