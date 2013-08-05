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

## Strict is always good
use strict;
use CGI qw/param/;
use IO::File;

# my stuff
# use lib '/home/twomi/web/libs';
use lib '/home/customers/tumi/public_html/archives/batmud';
use lib '/home/customers/tumi/tumilib';
use Tumi::Helper;
use BatmudTools::Vars;
use BatmudTools::Site;


my $point_of_site = &readFile('html/pointofsite.html');
my $fixlist = &readFile('html/fixlist.html');
my $buglist = &readFile('html/buglist.html');

my $VERSION = "1.2.1";

# data
my @weekly = reverse sort &getDir('source', 'weekly-*.txt');
my @monthly = reverse sort &getDir('source', 'monthly-*.txt');
my @special = reverse sort &getDir('source', 'special-*.txt');
my @image_sizes = ("640x480", "800x600", "1024x768", "1280x1024", "1600x1200");
my $image_html = &_createSelectHtml2('image', '800x600', @image_sizes);
my @weeks_list = (5, 10, 16, 26, 52, 78, 104, 156, 204);
my $weeks_html = &_createSelectHtml2('num', 16, @weeks_list);
my ($day, $mon, $year, $wday) = (localtime)[3..6];

# process data
map {s/(special\-|\.txt)//g;} @special;
map {s/(weekly\-|\.txt)//g;} @weekly;
map {s/(monthly\-|\.txt)//g;} @monthly;

# input
my $wp1 = param('old') || $weekly[1];
my $wp2 = param('new') || $weekly[0];
my $mp1 = param('old') || $monthly[1];
my $mp2 = param('new') || $monthly[0];
my $sp1 = param('old') || $special[1];
my $sp2 = param('new') || $special[0];
my $type = param('type') || "weekly";
$type = "weekly" unless ($type =~ /^(special|weekly|monthly)$/);

#print STDERR "w1: $wp1\nw2: $wp2\n";

#print STDERR "MONTHLY\n", join("\n", @monthly), "\n";
#print STDERR "SPECIAL\n", join("\n", @special), "\n";
#print STDERR "WEEKLY\n", join("\n", @weekly), "\n";


my $weekly_p1 = &_createSelectHtml('old', $wp1, @weekly);
my $weekly_p2 = &_createSelectHtml('new', $wp2, @weekly);
my $monthly_p1 = &_createSelectHtml('old', $mp1, @monthly);
my $monthly_p2 = &_createSelectHtml('new', $mp2, @monthly);
my $special_p1 = &_createSelectHtml('old', $sp1, @special);
my $special_p2 = &_createSelectHtml('new', $sp2, @special);




my $content = <<until_end;
<h2>Top Expmakers by Tumi</h2>
<div class="tool-link"><strong>Version:</strong> $VERSION</div>

$point_of_site
$fixlist


<h3>Top Expmakers</h3>
<div class="webplaque-expmakers">

<h4>Weekly</h4>
<form class="main" method="get" action="expplaque/plaque.pl">
<input type="hidden" value="weekly" name="type" />
Start date: $weekly_p1
End date: $weekly_p2
<input type="submit" value="Calculate weekly plaque" />
</form>

<h4>Monthly</h4>
<form class="main" method="get" action="expplaque/plaque.pl">
<input type="hidden" value="monthly" name="type" />
Start date: $monthly_p1
End date: $monthly_p2
<input type="submit" value="Calculate monthly plaque" />
</form>

<h4>Special</h4>
<form class="main" method="get" action="expplaque/plaque.pl">
<input type="hidden" value="special" name="type" />
Start date: $special_p1
End date: $special_p2
<input type="submit" value="Calculate special plaque" />
</form>
</div>


<br />

<h3>Cumulative expmakers</h3>
<div class="webplaque-expmakers">
<form class="main" method="get" action="expplaque/plaque.pl">
<input type="hidden" value="1" name="web" />

Calculate cumulative exp made and lost during the whole year.
<select name="cumulative">
<option value="2006">2006</option>
<option value="2005">2005</option>
<option value="2004">2004</option>
<option value="2003">2003</option>
</select>
<input type="submit" value="Calculate cumulative plaque" />

</form>
</div>


<br />

<h3>Expgraph</h3>
<div class="webplaque-graph">
<form class="main" method="get" action="expplaque/showgraph.pl">

<p>
Type names of people you want (max 6), separated with commas
(eg. twomi,ssmud,gitador):
<input type="text" name="who" value="" maxlength="80" size="60" />
</p>

<p>
How many weeks should the graph show: $weeks_html
</p>

<p>
Size of the graph: $image_html
</p>

<div id="bottom">
<input type="submit" value="Display graph" />
</div>

</form>
</div>


until_end


&pageOutput('expplaque', $content);

1;





sub _createSelectHtml($$@) {
	my $name = shift;
	my $presel = shift;
	my @dates = @_;
	my $output = qq|<select name="$name">\n|;

	for my $id (@dates) {
		my $sel = $presel eq $id ? ' selected="selected"' : '';
		my ($v1, $v2, $v3) = $id =~ /(\d{4,4})(\d{2,2})(\d{2,2})/;
		$output .= qq|<option value="$id"$sel>$v1-$v2-$v3</option>\n|;
	}

	$output .= qq|</select>\n|;

	return $output;
}

sub _createSelectHtml2($$@) {
	my $name = shift;
	my $presel = shift;
	my @dates = @_;
	my $output = qq|<select name="$name">\n|;

	for my $id (@dates) {
		my $sel = $presel eq $id ? ' selected="selected"' : '';
		$output .= qq|<option value="$id"$sel>$id</option>\n|;
	}

	$output .= qq|</select>\n|;

	return $output;
}



__END__

