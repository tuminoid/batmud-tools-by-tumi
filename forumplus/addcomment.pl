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
my $redir_url = "http://2-mi.com/batmud/forumplus/index.pl?pageid=01&amp;msg=Add%20comment%20failed.";

unless ($user && &isProfiledMember($user) && param('id') && param('type')) {
	$content .= "Bad user, bad profile or bad request, cannot add comment.<br />";
	&pageOutput('forumplus', $content);

} else {

	my %idtable = {
		'party' => 41,
		'item' => 52,
		'auction' => 53,
	};

	# Writing into comment file
	my $id = param('id') || return "invalid params";
	my $type = param('type') || "party";
	my $pageid = $idtable{$type} || "41";
	my $time = time();
	my $filename = "$id.dat";

	my %cdata = &getData($id, "data/comments/$type", 1);
	my $prev= scalar (keys %cdata);
	my $comment = param('comment') || "&nbsp;";
	$comment =~ s#\n#<br />#g;
	$cdata{$time} = "$user~~$comment";
	&writeData($id, "data/comments/$type", %cdata);

	$redir_url = qq|http://2-mi.com/batmud/forumplus/index.pl?pageid=$pageid&amp;action=view&amp;id=$id|;
	&printHeaderRedirect($redir_url."&amp;msg=Your%20comment%20was%20added.");
}


1;

__END__
