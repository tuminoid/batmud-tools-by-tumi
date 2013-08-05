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
use IO::File;
use CGI qw/param/;

# what we use ourselves
# use lib '/home/twomi/web/libs';
use lib '/home/customers/tumi/public_html/archives/batmud';
use lib '/home/customers/tumi/tumilib';
use Tumi::Helper;
use BatmudTools::Site;
use Tumi::ChangeLog;



# Current version number
my $VERSION = "0.2";

my %files = (
	"boons-changes" =>
		{ "Boons calculator changes"	=> "../boons/html/fixlist.html" },
	"boons-todo" =>
		{ "Boons calculator todo"		=> "../boons/html/buglist.html" },
	"raceinfo-changes" =>
		{ "Raceinfo changes"			=> "../raceinfo/html/fixlist.html" },
	"raceinfo-todo" =>
		{ "Raceinfo todo"				=> "../raceinfo/html/buglist.html" },
	"reincsim-changes" =>
		{ "Reinc Simulator changes"		=> "../reincsim/html/fixlist.html" },
	"reincsim-todo" =>
		{ "Reinc Simulator todo"		=> "../reincsim/html/buglist.html" },
	"hcreincsim-changes" =>
		{ "HC Reinc Simulator changes"	=> "../reincsim/html/fixlist_hc.html" },
	"hcreincsim-todo" =>
		{ "HC Reinc Simulator todo"		=> "../reincsim/html/buglist_hc.html" },
	"webplaque-changes" =>
		{ "Top Expmakers changes"		=> "../expplaque/html/fixlist.html" },
	"webplaque-todo" =>
		{ "Top Expmakers todo"			=> "../expplaque/html/buglist.html" },
#	"reincsim-list-changes" =>
#		{ "Reinc Simulator list util changes" => "../reincsim/html/list-fixlist.html" },
#	"reincsim-list-todo" =>
#		{ "Reinc Simulator list util todo" => "../reincsim/html/list-buglist.html" },
	"list" =>
		{ "List of Changelogs"			=> "" },
);


my $id = param('item') || 'list';
$id = 'list'
	unless (defined $files{$id});
my %datahref = %{$files{$id}};
my $title = (keys %datahref)[0];
my $file = (values %datahref)[0];
my $alink_template = qq|<a href="/content/clog.pl?item=__ITEM__">__TARGET__</a>|;


my $default = <<until_end;
<div class="progress-fixed">
<h2>No changes</h2>
</div>
until_end


my $links = <<until_end;
<h2>ChangeLogs by Tumi</h2>
<div class="tool-link"><strong>Version:</strong> $VERSION</div>

<table id="show-list">
<tr id="show-header">
	<td>Title</td><td>Filesize</td><td>Last modified</td>
</tr>
until_end


for my $item (sort keys %files) {
	my $title = (keys %{$files{$item}})[0];
	my $file = (values %{$files{$item}})[0];

	next unless (-e $file);

	my $lastmodif = &getModifiedTime($file);
	my $filesize = (stat $file)[7] || 0;

	my $alink = $alink_template;
	$alink =~ s/__ITEM__/$item/;
	$alink =~ s/__TARGET__/$title/;

	$alink = $title
		if ($id eq $item);

	$links .= <<until_end;
<tr class="show-item">
	<td>$alink</td><td>$filesize</td><td>$lastmodif</td>
</tr>
until_end
}

$links .= qq|\n</table>\n|;




$links .= qq|<h3 style="text-align: center;">$title</h3>\n|
	unless ($id eq "list");


if ($file ne "" && -e $file) {
	my $content = &readFile($file);
	$links .= $content."\n\n";
} else {
	$links .= $default."\n\n"
		unless ($id eq "list");
}


&pageOutput('changelogs', $links);



1;


#####################################################################
#
# loadParams - Loads parameters from the file and inserts them into
#              a params hash
#
# Params      - Id based filename
#
# Returns     - Hash, containing the file contents
#
#####################################################################

sub loadParams {
	my $file = shift || 'foo.txt';
	my %parhash = ();

	return ()
		unless (-e $file);

	my $handle = new IO::File $file, "r";
	while (my $line = <$handle>) {
		$line =~ tr/\x0D\x0A//d;
		next unless ($line =~ /^(\w+): (\w+)$/);
		$parhash{$1} = $2;
	}

	return %parhash;
}




__END__

