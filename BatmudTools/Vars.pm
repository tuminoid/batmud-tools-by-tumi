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

package BatmudTools::Vars;
use strict;
use vars qw($VERSION @ISA @EXPORT);

$VERSION = '0.2';
require Exporter;
use DynaLoader();
@ISA = qw(Exporter DynaLoader);
@EXPORT = qw(getVar setVar);


my %conf = (
#	'siteroot'		=> '/home/twomi/web',
#	'website'		=> 'http://support.bat.org/',
	'siteroot'		=> '/home/customers/tumi/public_html/archives/batmudtools',
	'website'		=> 'http://batmudtools.tanskanen.org/',
#	'logpath'		=> '/home/twomi/web/content/logs',
#	'loginpath'		=> '/home/twomi/web/content/logins',
	'logpath'		=> '/home/customers/tumi/public_html/archives/batmudtools/content/logs',
	'loginpath'		=> '/home/customers/tumi/public_html/archives/batmudtools/content/logins',

	'forumdata'		=> '/home/customers/tumi/public_html/archives/batmudtools/forumplus',

	'yabb2members'	=> '/home/customers/tumi/public_html/archives/batmudtools/forum/Members',
	'yabb2user'		=> 'Y2User-85209',
	'yabb2pass'		=> 'Y2Pass-85209',
	'yabb2sess'		=> 'Y2Sess-85209',

	'map_uses_db'	=> 0,
	'exp_uses_db'	=> 0,

	'mysql_user'	=> '',  # MUST CHANGE THIS
	'mysql_pass'	=> '',  # MUST CHANGE THIS

	'favicon'		=> qq|http://tanskanen.org/images/favicon.ico|,
	'maincss'		=> qq|content/site.css|,

	'h1title'		=> qq|<h1>Collection of BatMUD Tools by Tumi</h1>|,
	'titlepostfix'	=> qq|BatMUD Tools by Tumi|,

	'navdelim'		=> " &#187; ",

	'debug_on'		=> 0,
);


1;


sub getVar($) {
	my $key = shift || return undef;
	return $conf{$key};
}


sub setVar($$) {
	my $key = shift || return undef;
	my $var = shift;

	$conf{$key} = $var;
}


__END__

