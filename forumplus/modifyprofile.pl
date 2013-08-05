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
use HTML::Entities;

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

unless ($user) {
	$content .= "Bad user, profile could not be updated. ";

} else {
	my %hash = ();
	for my $key (param()) {
	    my $val = param($key);
	    $val =~ tr/[0-9]//cd if ($key =~ /pmax/); # spmax, hpmax
	    $hash{$key} = encode_entities($val);
	}
	&writeData($user, "data/users", %hash);

	$content .= "Profile was updated successfully.<br/>\n";
	&writeUserLog($user, "Changed profile successfully.");

	my $redir_url = qq|http://2-mi.com/batmud/forumplus/index.pl?pageid=10|;
	&printHeaderRedirect($redir_url."&msg=Updated%20profile%20successfully.");
}


&pageOutput('forumplus', $content);

1;

__END__
