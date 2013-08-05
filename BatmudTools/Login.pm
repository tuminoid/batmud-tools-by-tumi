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

package BatmudTools::Login;
use strict;
use IO::File;
use Digest::MD5 qw/md5_hex md5_base64/;
use CGI qw/param cookie/;
use HTML::Entities;
use vars qw($VERSION @ISA @EXPORT);

# own stuff
# use lib '/home/twomi/web/libs';
use lib '/home/customers/tumi/public_html/archives/batmudtools';
use lib '/home/customers/tumi/tumilib/lib';
use Tumi::Helper;
use BatmudTools::Vars;
use BatmudTools::Layout;

$VERSION = '0.2';
require Exporter;
use DynaLoader();
@ISA = qw(Exporter DynaLoader);
@EXPORT = qw(logOut checkLogin getLastLogin	getYabb2Userinfo checkYabb2Login checkYabb2ForumAccess checkYabb2Session getLogin getHello getOneHourVisits);


sub getOneHourVisits() {
	my $usercnt = 0;
	my $visitorcnt = 0;

	my $loginpath = &getVar('loginpath');
	my @allfiles = &getDir($loginpath, "*.log");

	for my $file (@allfiles) {
		if (time() - (stat("$loginpath/$file"))[9] > 3600) {
			unlink "$loginpath/$file";
			next;
		}
		$file =~ /visitor/i ? $visitorcnt++ : $usercnt++;
	}

	return ($usercnt, $visitorcnt);
}



sub _updateLoginRecords($$) {
	my ($ip, $user) = @_;

	if ($user eq "") {
		my $newip = $ip;
		$newip =~ tr/[0-9]//cd;
		$user = "visitor_$newip";
	}

	my $loginpath = &getVar('loginpath');
	my $fh = new IO::File "$loginpath/$user.log", "w";
	print $fh time();
	undef $fh;
}




# check if session is still usable
sub checkYabb2Session() {
	my $user_ip = $ENV{'REMOTE_ADDR'} || "127.0.0.1";
	chomp $user_ip;

	my $this_session = md5_base64($user_ip);
	chomp $this_session;

	my $cookie_session = cookie(&getVar('yabb2sess')) || "";
	my $user = cookie(&getVar('yabb2user')) || "";
	my $pass = cookie(&getVar('yabb2pass')) || "";
	my %info = &getYabb2Userinfo($user);
	my $y2pass = $info{'password'} || "";

	my $login_ok = $user && ($pass eq $y2pass);
	my $session_ok = $this_session eq $cookie_session;

	# do some logging too
	&_updateLoginRecords($user_ip, $user);

	return ($user, $login_ok, $session_ok);
}


# check if general login to forums is ok
sub checkYabb2Login($$;$) {
	my $user = shift;
	my $pass = shift;
	my $md5ed = shift || 0;
	return 0 unless (defined $user && defined $pass && length($user) >= 2);

	my %info = &getYabb2Userinfo($user);
	my $pass_base64 =  $md5ed ? $pass : md5_base64($pass);
	my $pass_yabb2_base64 = $info{'password'} || "";

	return 1 if ($pass_base64 eq $pass_yabb2_base64);
	return 0;
}


# check the status on forums
sub checkYabb2ForumAccess($) {
	my $user = shift;
	return (0, 0, 0, 0) unless (defined $user && length($user) >= 2);
	return (1, 1, 1, 0) if ($user eq "admin");

	my %info = &getYabb2Userinfo($user);
	my $groups = $info{'addgroups'} || "";
	my @gids = split/,/, $groups;

	my ($cid, $oid, $mid, $iid) = (3, 10, 7, 5);
	my ($creator, $officer, $member, $inactive) = (0, 0, 0, 0);

	for my $gid (@gids) {
		$creator = 1 if ($gid == $cid);
		$officer = 1 if ($gid == $oid);
		$member = 1 if ($gid == $mid);
		$inactive = 1 if ($gid == $iid);
	}

	return ($creator, ($officer || $creator), (($member || $officer) || $creator), $inactive);
}


# check login based on form/cookie input to certain area
sub checkLogin(;$) {
	my $pageid = shift || 'index';

	# Getting username and password from cookie
	my $cookie_user = cookie(&getVar('yabb2user')) || "";
	my $cookie_pass = cookie(&getVar('yabb2pass')) || "";
	my $param_user = param('yabb2user') || "";
	my $param_pass = param('yabb2pass') || "";

	my $user = ($param_user ? $param_user : $cookie_user) || "";
	my $pass = ($param_pass ? $param_pass : $cookie_pass) || "";
	my $md5ed = $user eq $param_user ? 0 : 1;

	my $user_ip = $ENV{'REMOTE_ADDR'} || "127.0.0.1";
	chomp $user_ip;
	my $sess_md5 = md5_base64($user_ip);

	# Some variables
	my $content = "";

	# we might have open session
	my ($sessuser, $login_ok, $sess_ok) = &checkYabb2Session();
	if ($login_ok) {
		return &printLogin("Not a forum+ member")
			if ($pageid eq 'forumplus' && (&checkYabb2ForumAccess($sessuser))[2] < 1);
		return ($login_ok, $sessuser);
	}


	# Logging in if we have params named username and passwd
	if ($user && $pass) {
		# user regged in yabb2?
		return &printLogin("No such user and/or bad password")
			unless (&checkYabb2Login($user, $pass, $md5ed));
		# member of forum+?
		return &printLogin("Not a forum+ member")
			if ($pageid eq 'forumplus' && (&checkYabb2ForumAccess($user))[2] < 1);

		my %info = &getYabb2Userinfo($user);
		my $pass_md5 = $info{'password'};

		&addLayoutHeader(&getCookieHeader(&getVar('yabb2user'), $user, "+3d"));
		&addLayoutHeader(&getCookieHeader(&getVar('yabb2pass'), $pass_md5, "+3d"));
		&addLayoutHeader(&getCookieHeader(&getVar('yabb2sess'), $sess_md5, "+3d"));

	# No cookie, no params -> goto login
	} else {
		print STDERR "failure: no cookies, no params\n" if (param('debug'));
		return &printLogin("Please login for Forum+ access");
	}

	# do some logging too
	&_updateLoginRecords($user_ip, $user);

	return ($content, $user);
}


sub getHello() {
	my ($user, $login_ok, $session_ok) = &checkYabb2Session();

	# default is visitor actions
	my $display = "Visitor";
	my $logmsg = <<until_end;
Hello, Visitor. You can <a href="/forum/YaBB.pl?action=login">login</a> or
<a href="/forum/YaBB.pl?action=register">register</a>.
until_end

	# if logged in already
	if ($user && $login_ok) {
		my %info = &getYabb2Userinfo($user);
		$display = $info{'realname'};
		$logmsg = qq|Logged in as $display (<a href="/forum/YaBB.pl?action=logout">logout</a>)|;

		unless ($session_ok) {
			$logmsg .= " (your ip has changed)";
		}
	}

	return $logmsg;
}


sub getLogin($) {
	my $redir_addr = shift || "/";
	$redir_addr = &encode_entities($redir_addr);

	my $content = <<until_end;
<div id="login">
<form action="/index.pl" method="post">
<input type="hidden" name="redir" value="$redir_addr" />
<input type="hidden" name="id" value="idcheck" />
Player: <input type="text" maxlength="16" size="16" name="yabb2user" value="" />
Password: <input type="password" maxlength="32" size="16" name="yabb2pass" value="" />
<input type="submit" value="Login" />
</form>
</div>

until_end

	return $content;
}



# print login form
sub printLogin(;$) {
	my $errormsg = shift || "";
	my $loginform = &getLogin();

	my $login = <<until_end;
<p style="color: Red;">$errormsg</p>
$loginform

until_end

	return $login;
}


# send cookie clearing cookies for logout
sub logOut() {
	my ($user, $login_ok, $sess_ok) = &checkYabb2Session();

	&addLayoutHeader(&getCookieHeader(&getVar('yabb2user'), "", "Thursday, 01-Jan-1970 00:00:00 GMT"));
	&addLayoutHeader(&getCookieHeader(&getVar('yabb2pass'), "", "Thursday, 01-Jan-1970 00:00:00 GMT"));
	&addLayoutHeader(&getCookieHeader(&getVar('yabb2sess'), "", "Thursday, 01-Jan-1970 00:00:00 GMT"));

	return 1;
}


# get memberinfo from yabb files
sub getYabb2Userinfo($) {
	my $username = shift;
	return () unless $username;

	my $file = &getVar('yabb2members')."/$username.vars";
	unless (-e $file) {
		#print STDERR "Couldn't read useinfo\n";
		return ();
	}
	my $fh = new IO::File $file, "r";

	# cut first two header lines off
	my %info = ();
	my $line1 = <$fh>;
	my $line2 = <$fh>;

	# read the info
	while (my $line=<$fh>) {
		$line =~ tr/\x0D\x0A//d;
		my ($key, $var) = $line =~ /^'(\w+)',"(.*?)"$/;
		$info{$key} = $var || "";
	}

	return (%info);
}


# when user was on previous time
sub getLastLogin($$;$) {
	my $loginpath = shift;
	my $user = shift;
	my $path = shift || "";
	my $file = "$loginpath/$path$user.log";

	return (-1) unless (-e $file);
	return ((stat $file)[9]);
}



__END__

