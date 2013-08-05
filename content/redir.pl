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

# Strict is always good
use strict;
use CGI qw/param/;

# what we use ourselves
# use lib '/home/twomi/web/libs';
use lib '/home/customers/tumi/public_html/archives/batmud';
use lib '/home/customers/tumi/tumilib';
use Tumi::Helper;
use BatmudTools::Vars;
use BatmudTools::Site;

my $error = "";
my $outlink = param('url');
my $logf = param('id');
#$logf =~ tr/[a-z]//cd;
unless ($logf =~ /^[a-z]+$/) {
	$error = <<until_end;
<h3>X1173R!!!1</h3>
<div class="tools"><p>j00 tr13d 70 h4x0r teh l1nk, f00k j00 n00b! ;)</p></div>
until_end

	&pageOutput('index', $error);
	exit;
}

# log it and do it
my $logfile = &getVar('logpath')."/links/$logf.log";
&sendRedirect($outlink, 0, $logfile);

# unknown error, shoudlnt return
$error = <<until_end;
<h3>Error occured</h3>
<div class="tools"><p>You were redirected to
<a href="$outlink">$logf</a>, but it didn't work. Click on the link to continue.</p>
</div>

until_end


&pageOutput('index', $error);

1;

__END__

