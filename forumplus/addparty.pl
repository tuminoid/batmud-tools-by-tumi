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


unless ($user && &isValidMember($user)) {
	$content .= "Bad user, cannot create party.<br />";

} else {

	# Writing into parties dir
	my $action = param('action');
	my $id = param('id') || param('created') || time();


	if ($action eq "edit") {
		my %pdata = &getData($id, "data/parties");
	}

	my $filename = "$id.dat";
	my $fh = new IO::File "data/parties/$filename", "w";

	my ($hours, $mins) = (param('starting2') =~ /^(.+)(\d{2})$/);
	my $starting = param('starting1') + $hours*60*60 + $mins*60;
	print $fh "starting: $starting\n";

	for my $key (param()) {
		my $val = defined param($key) ? param($key) : "";
		$val =~ s/(\x0D\x0A|\x0D|\x0A)/<br \/>/g if ($key eq "longdesc");
		print $fh "$key: $val\n";
	}
	undef $fh;

	$content .= "<p>You edited a <a href=\"forumplus/index.pl?pageid=41&amp;action=view&amp;id=$id\">party $id</a>.</p>\n";
	&writeUserLog($user, "You created party (<a href=\"forumplus/index.pl?pageid=41&amp;action=view&amp;id=$id\">$id</a>).")
		if ($action eq "create");

	&redoPartyIndex();
	my $redir_url = qq|http://2-mi.com/batmud/forumplus/index.pl?pageid=41&amp;action=view&amp;id=$id|;
	&printHeaderRedirect($redir_url."&amp;msg=Modifications%20saved%20successfully.");
}


&pageOutput('forumplus', $content);

1;

__END__
