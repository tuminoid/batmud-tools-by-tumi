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

package BatmudTools::Layout;
use strict;
use IO::File;
use CGI qw/param/;
use HTTP::Date;
use vars qw($VERSION @ISA @EXPORT);
use vars qw(%items @headers @headelements @navpath);

# use lib '/home/twomi/web/libs';
use lib '/home/customers/tumi/public_html/archives/batmudtools';
use lib '/home/customers/tumi/tumilib/lib';
use Tumi::Helper;
use BatmudTools::Vars;

$VERSION = '0.2';
require Exporter;
use DynaLoader();
@ISA = qw(Exporter DynaLoader);
@EXPORT = qw(setLayoutItem getLayoutItem addLayoutHeader getLayoutHeaders addHeadElement getHeadElements addNavPath getNavPath);

my $siteroot = &getVar('siteroot');

# some presets
$items{"footer"} = &readFile("$siteroot/content/footer.html");
$items{"links"} = &readFile("$siteroot/content/links.html");
$items{"voteurl"} = &readFile("$siteroot/content/voteurl.html");


1;


# supported settable items are:
# "title", "css", "bodyjs", "adsense", "subcontent", "footer", "links"
# "changes", "todo", "intro" either hold text or file:filename for file to be read
sub setLayoutItem($$) {
    my $item = shift;
    my $val = shift || "";

    return 0 unless (defined $item && length($item) > 0);
    $items{$item} = $val;
}


# get specific layout item from store
sub getLayoutItem($) {
    my $key = shift;
	return "" unless (defined $key && length($key) > 0 && defined $items{$key});

    if ($items{$key} =~ /file:(.*?)$/) {
    	return &readFile($1);
    }

    return ($items{$key} || "");
}


# add one complete header
sub addLayoutHeader($) {
    my $header = shift;
    return unless (defined $header && length($header) > 0);
    $header =~ tr/\x0A\x0D//d;
    push @headers, $header;
}


# get all added headers
sub getLayoutHeaders() {
    return (@headers, "Content-Type: text/html; charset=iso-8859-1", "Cache-Control: private",
    	"Last-modified: ".time2str(time() - 5));
}


# add one complete header
sub addHeadElement($) {
    my $elem = shift;
    return unless (defined $elem && length($elem) > 0);
    #print STDERR "Got element: $elem";
    push @headelements, $elem;
}


# get all added headers
sub getHeadElements() {
    #print STDERR "Got elements: ".join(", ", @headelements)."\n";
    return @headelements;
}

# add one complete header
sub addNavPath($$) {
    my $path = shift;
    my $url = shift;
    return unless (defined $path && length($path) > 0 && defined $url && length($url) > 0);
    push @navpath, "$path|$url";
}


# get all added headers
sub getNavPath() {
	my $baseurl = &getVar('website');
    return ("support.bat.org|", "BatMUD Tools|$baseurl", @navpath);
}

__END__
