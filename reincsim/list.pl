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

# my stuff
# use lib '/home/twomi/web/libs';
use lib '/home/customers/tumi/public_html/archives/batmud';
use lib '/home/customers/tumi/tumilib';
use Tumi::Helper;
use BatmudTools::Site;


# Current version number
my $VERSION = "1.0.0";


# Fetching the contents

my @lines = `ls saved/`;
my @files = ();

# Wrapping the files into single array
for my $line (@lines) {
	my @temp = split/\s+/, $line;
	push @files, @temp;
}


my $links = <<until_end;
<h2 id="welcome">ReincList, $VERSION</h2>

<div class="progress-fixed">
<a href="#"><h3>Changes</h3>

<span>
<h4>29th Jan 2004</h4>
<ul>
<li>Invented these hiding todo/bug lists.</li>
</ul>

</span>
</a>
</div>



<table id="reincsim-list">
<tr id="reincsim-list-header">
	<td>Last modified</td><td>Filesize</td><td>ID</td><td>Background</td>
	<td>Race</td><td>Guild1</td><td>Glevel1</td><td>Guild2</td><td>Glevel2</td>
</tr>
until_end



# Going through the files
for my $file (sort @files) {
	my %params = loadParams("saved/$file");
	my $lastmodif = Counter::giveLastModify("/home/twomi/web/reincsim/saved/$file");
	my $filesize = (stat "saved/$file")[7];

	my ($id, $bg, $race, $g1, $g2, $gl1, $gl2) = (
		$params{'id'}, ucfirst $params{'bg'}, ucfirst $params{'race'},
		ucfirst $params{'guild1'} || '', ucfirst $params{'guild2'} || '',
		ucfirst $params{'glevel1'} || 0, ucfirst $params{'glevel2'} || 0);

	next unless $id;

	$links .= <<until_end;
<tr clasS="reincsim-list-item">
	<td>$lastmodif</td><td>$filesize</td>
	<td><a href="http://2-mi.com/batmud/reincsim/reincsim.pl?id=$id" target="_blank">$id</a></td>
	<td>$bg</td><td>$race</td><td>$g1</td><td>$gl1</td><td>$g2</td><td>$gl2</td>
</tr>
until_end
}

$links .= qq|\n</table>\n|;


BatmudIndex::pageOutput('reinclist', $links, param('debug'));


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

