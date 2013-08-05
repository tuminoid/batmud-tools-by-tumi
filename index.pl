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

use strict;
use CGI qw/param/;
use CGI::Carp qw/fatalsToBrowser/;

# my stuff
# use lib '/home/twomi/web/libs';
use lib '/home/customers/tumi/public_html/archives/batmudtools';
use lib '/home/customers/tumi/tumilib/lib';
use BatmudTools::Site;
use Tumi::Helper;
use BatmudTools::Login;
use BatmudTools::Layout;

my $id = param('id') || "index";
my $content = "";



if ($id eq "intro") {
	my $batmap = &readFile('index/batmap.html');
	my $reincsim = &readFile('index/reincsim.html');
	my $raceinfo = &readFile('index/raceinfo.html');
	my $expplaque = &readFile('index/expplaque.html');
	my $sscounter = &readFile('index/sscounter.html');
	my $sales = &readFile('index/sales.html');
	#my $findaplace = &readFile('index/findaplace.html');
	my $booncalc = &readFile('index/booncalc.html');
	my $boards = &readFile('index/boards.html');
	my $thanks = &readFile('index/thanks.html');
	my $help = &readFile('index/help.html');

	$content = <<until_end;

	<div class="tools">
	$batmap
	$reincsim
	$raceinfo
	$expplaque
	$sscounter
	$sales
	$booncalc
	$boards
	</div>

	$thanks
	$help

until_end


# donations page
} elsif ($id eq "donations") {
	$content = &readFile('index/donations.html');


# links page
} elsif ($id eq "othersites") {
	$content = &readFile('index/links.html');



# logout page
} elsif ($id eq "logout") {
	my $logoutmsg = &logOut();
	&setLayoutItem('user', '');

	$content = <<until_end;
<h2>You've logged out</h2>

<div class="tools"><p>$logoutmsg</p></div>
until_end

	$id = 'login';



# login page
} elsif ($id eq "login") {
	my $redir = param('redirto') || "/";
	my $loginmsg = &getLogin($redir);
	my ($user, $login_ok, $session_ok) = &checkYabb2Session();

	if ($login_ok) {
		&setLayoutItem('user', $user);
		$loginmsg = <<until_end;
You are logged in as '$user'. You can
<a href="/index.pl?id=logout">logout</a> if you wish.
until_end
	}

	$content = <<until_end;
<h2>Login to Batmud Tools</h2>

<div class="tools">
<p>Logging in to Batmud Tools enables you to customize some parts of the site
to your personal needs. It also enables you to fully browse, read and post on the
Batmud Tools Forums.
</p>

<p>$loginmsg</p>
</div>

until_end

	$id = 'login';

# debug page
} elsif ($id eq "idcheck") {
	my ($msg, $user) = &checkLogin();

	# ok
	if ($user) {
		&setLayoutItem('user', $user);
		my $redir = param('redir') || "/";
		$content = qq|Login OK! You can <a href="$redir">continue</a>.|;
		&addHeadElement(&getHtmlRedirect($redir));

	# fail
	} else {
		$content = $msg;
	}

	$id = 'login';


# visitor count
} elsif ($id eq "visitors") {
	my ($users, $visits) = &getOneHourVisits();
	my $total = $users + $visits;
	$content = "$users + $visits = $total";
	$id = 'login';


# default index page
} else {
	$content = &readFile('index/index.html');
	$id = "index";
}


# output it
&pageOutput($id, $content);


1;


__END__

