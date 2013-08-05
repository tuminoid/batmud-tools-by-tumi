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

# my stuff
# use lib '/home/twomi/web/libs';
use lib '/home/customers/tumi/public_html/archives/batmud';
use lib '/home/customers/tumi/tumilib';
use Tumi::Helper;
use BatmudTools::Site;
use Tumi::HiresTime;


my $SCRIPT = "sales.pl";
my $VERSION = "1.0.5";

my $str = param('str') || "";
my $num = param('num') || 10;
my $selex = param('seller') || "";
$str =~ tr/[a-zA-Z0-9 ]//cd;
$selex =~ tr/[a-zA-Z]//cd;

my $pointofsite = &readFile('html/pointofsite.html');
my $nums_html = &createNumSelect($num);
my $content = "";



# Header
$content .= <<until_end;

<h2>Batmud Sales Search Engine by Tumi</h2>
<div class="tool-link"><strong>Version:</strong> $VERSION</div>

$pointofsite

<form action="sales/$SCRIPT" method="get">
<table id="searchtable">
<tr>
	<td>Search for:</td><td><input type="text" size="30" maxlength="50" name="str" value="$str" /></td>
        <td>Seller:</td><td><input type="text" size="15" maxlength="15" name="seller" value="$selex" /></td>
	<td>Results:</td><td>$nums_html</td>
	<td><input type="submit" value="Search" /></td>
</tr>
</table>
</form>

until_end


if ($str ne "" || $selex ne "") {
	my $grep_template = 'grep -i "<term>" <files>';
	my $grep_join = ' | ';
	my @greps = ();

	my @terms = split/ /, $str;
	my $grep_string = "";
	push @terms, $selex if (length($selex) > 0);

	for my $term (@terms) {
		my $copy = $grep_template;
		$copy =~ s/<term>/$term/;
		(@greps < 1) ? $copy =~ s/ <files>/ source\/sales\*\.txt/ : $copy =~ s/ <files>//;
		push @greps, $copy;
	}

	$grep_string = join($grep_join, @greps);
	#$content .= "Grep string: $grep_string\n";

	my $timer1 = &getHiresTime();
	my @output = `$grep_string`;
	my $searchtime = sprintf("Search took %.3f seconds", (&getHiresTime() - $timer1)/1000000.0);

	$content .= <<until_end;
<table id="resulttable">
<tr><td>Num</td><td>Date</td><td>Seller</td><td>Item</td><td>Minbid</td></tr>
until_end

	my $count = 0;
	my $total_price = 0;
	my %shown = ();
	for my $line (reverse @output) {

		# data
		my $color = ($count % 2 == 0) ? "c1" : "c2";
		my ($date, $seller, $item, $price) = split/;/,$line;
		$date =~ s/^.*?://;

		# if seller is defined
		next if (length($selex) > 0 && !($seller =~ /$selex/i));
		if (length($str) > 0) {
			my $nextone = 0;
			for my $term (@terms) {
				if (!($item =~ /$term/i)) {
					$nextone = 1;
					last;
				}
			}
			next if ($nextone);
		}

		# if its displayed once for that day
		my $def_string = "$date;$seller;$item;$price";
		next if (defined $shown{$def_string});
		$shown{$def_string} = 1;

		# terminated if enough
		last if (++$count > $num);

		# average price
		my $temp_price = $price;
		$temp_price =~ s/[mM]/000000/;
		$temp_price =~ s/[kK]/000/;
		$temp_price =~ s/00/0/ if ($temp_price =~ /[\.,]/);
		$temp_price =~ tr/,\.//d;
		$total_price += $temp_price;

		$content .= qq|<tr class="$color"><td>$count</td><td>$date</td><td><b>$seller</b></td><td>$item</td><td>$price</td></tr>\n|;
	}
	my $avg_price = sprintf("%d", $count > 0 ? $total_price / $count : 0);
	my $items_in_db = &countMatches("200");

	$content .= <<until_end;
<tr class="footer"><td colspan="5">Average price: $avg_price</td></tr>
</table>

<p style="text-align: center; font-size: 0.7em;">$searchtime among $items_in_db items.</p>

until_end

}


&pageOutput('sales', $content);


1;


sub createNumSelect {
	my $prev = shift || 10;
	my @nums = (10, 25, 50, 100, 250);

	my $html = qq|<select name="num">\n|;
	for my $num (@nums) {
		my $sel = $num == $prev ? ' selected="selected"' : '';
		$html .= qq|<option value="$num"$sel>$num</option>\n|;
	}
	$html .= qq|</select>\n|;

	return $html;
}


sub countMatches {
	my $str = shift;
	return 0 unless (defined $str);

	my @input = `grep -c "$str" source/sales*.txt`;
	my $items = 0;
	for my $line (@input) {
		$line =~ /^.*?:(\d+)/;
		$items += $1;
	}

	return $items;
}


__END__

