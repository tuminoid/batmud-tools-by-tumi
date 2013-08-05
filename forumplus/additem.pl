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
	$content .= "Bad user or non-officer, cannot add item.<br />";

} else {

	# Writing into eq file
	my $time = param('id') || time();
	my $filename = "$time.dat";
	my $fh = new IO::File "data/items/$filename", "w";

	my $desc = "";

	for my $key (param()) {
		my $val = defined param($key) ? param($key) : "";
		$val =~ s/(\x0D\x0A|\x0D|\x0A)/<br \/>/g if ($key =~ /(longdesc|special)/);
		print $fh "$key: $val\n";

		$desc = $val if ($key =~ /shortdesc/);
	}

	#$content .= "You fiddled with item <a href=\"forumplus/index.pl?pageid=52&amp;action=view&amp;id=$time\">$desc</a>.<br />\n";
	my $msg = "Item%20was%20added%20successfully.";
	&writeUserLog($user, "You fiddled with (<a href=\"forumplus/index.pl?pageid=51&amp;action=view&amp;id=$time\">$desc</a>).");

	my $redir_url = qq|http://2-mi.com/batmud/forumplus/index.pl?pageid=61|;
	&printHeaderRedirect($redir_url."&amp;msg=$msg");
}


&pageOutput('forumplus', $content);

1;

__END__
