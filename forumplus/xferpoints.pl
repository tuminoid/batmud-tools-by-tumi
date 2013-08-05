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

# my stuff
# use lib '/home/twomi/web/libs';
use lib '/home/customers/tumi/public_html/archives/batmud';
use lib '/home/customers/tumi/tumilib';
use Tumi::Helper;
use BatmudTools::Site;
use BatmudTools::Login;

require 'support.pl';
require 'support2.pl';
require 'support3.pl';


my ($content, $user) = &checkLogin(860);
my $successmsg = "";

unless ($user) {
	$content .= "Bad user, cannot xfer points.<br />";

} else {

	# What we are doing
	my $xferpoints = param('xferpoints');
	my $xferto = param('xferto');
	my $msg = param('msg') || "";
	$successmsg = &transferPoints($user, $xferto, $xferpoints, $msg);

	my $redir_url = qq|http://2-mi.com/batmud/forumplus/index.pl?pageid=24|;
	&printHeaderRedirect($redir_url."&msg=Points%20transferred%20successfully.");
}


&pageOutput('forumplus', $content);

1;

__END__
