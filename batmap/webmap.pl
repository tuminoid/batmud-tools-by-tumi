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
use IO::File;
use CGI qw/param/;
use POSIX qw/floor ceil/;
use GD;

# our stuff
# use lib '/home/twomi/web/libs';
use lib '/home/customers/tumi/public_html/archives/batmud';
use lib '/home/customers/tumi/tumilib';
use BatmudTools::Site;
use BatmudTools::Vars;
use Tumi::Helper;


## Some of the code is in other files
require 'colorfuncs.pl';
require 'colorhash.pl';
require 'phpmap_parser.pl';


## Version number
my $VERSION = "v2.0-beta4";
my $update = localtime(&getSourceModDate()); #localtime((stat('source/locations.txt'))[9]);
my $labels = param('labels') || "no";

## Some magic number definitions
my $map_x = 481;
my $map_y = 481;

## cache file names
my $html_normal = 'cache/batmap.html';
my $html_plain = 'cache/plain.html';
my $html_labels = 'cache/labels.html';
my $png_normal = 'cache/batmap.png';
my $png_plain = 'cache/plain.png';


# Using those funcs we do the preloading
my @textmap = split/\n/, &readFile('source/batmap.txt');
my @locats = split/\n/, &readFile('source/locations.txt');
my @autolocs = split/\n/, &readFile('source/autogen.txt');
my @dblocs = split/\n/, &readFile('source/dbgen.txt');

my %locations = &parseLocations(@locats, @autolocs);
#&parseLocationsFromDB();
#my %locations = &parseLocations(@dblocs);
my %colours = &getColourHash();
my $plain = param('plain') || 'no';
my $load_file = "";

# Graphic additions
my $graphic = param('gd') || 'no';
my $fontsize = 9;
my ($image_x, $image_y) = ($map_x * 9, $map_y * 9);
my $linex_pos = 0;
my @locs_in_order = ();

# params
my $mapsize = param('size') || 100;
my $batorg = param('batorg') || "";
$mapsize = ($mapsize > 100 ? 100 : ($mapsize < 50 ? 50 : $mapsize));
my $img_src = $batorg ? "http://www.bat.org/maps/batmap.gif" : "batmap/$png_plain";
$mapsize = 50 if ($batorg);

## pre-HTML before the map
my $precontent = <<until_end;
<h2>Batmap-in-
<span class="forest">c</span>
<span class="volcano">o</span>
<span class="beach">l</span>
<span class="deepforest">o</span>
<span class="sea">u</span>
<span class="highlands">r</span>
<span class="playercity">s</span>
project by Tumi</h2>

<div class="tool-link"><strong>Version:</strong> $VERSION</div>

<div class="tools">
<p>
One thing I had always missed was a possibility to search within map. Before
the map loading before you, there were no searchable maps, only images. Those
gifs may have had some area locations within them, but sooner or later, those
are hard to maintain, due the fact world is changing constantly and those
names and map modifications had to be done by hand. My solution for it was to
write those locations in a separate file and use scripts to compile a map,
including coloring. Only downside for this is the size of the file, which is
closing one meg and getting 500-800 loads each day, producing heavy traffic.
</p>
<p>
Send updates to me in mudmail, in-game tells or use the email at the page footer.
Enjoy!
</p>

<p>
Last update on map $update.
</p>
</div>

until_end


my $content = <<until_end;

<!--
<table id="batmap">
<tr><td> -->

<div id="batmap">
<pre style="background-color: Black !important;">
<code style="background-color: Black !important;">


until_end


# if we have newer cache files than sources, use the cache
if ($labels ne 'yes') {

# no label stuff
if (($plain eq 'no') && ($graphic eq 'no')) {
	&loadCache($html_normal, $precontent) if (&getSourceModDate() < &getModDate($html_normal));
}
if (($plain eq 'yes') && ($graphic eq 'no')) {
	&loadCache($html_plain, $precontent) if (&getSourceModDate() < &getModDate($html_plain));
}
if (($plain eq 'no') && ($graphic eq 'yes')) {
	&loadCache($png_normal, $precontent) if (&getSourceModDate() < &getModDate($png_normal));
}
if (($plain eq 'yes') && ($graphic eq 'yes')) {
	&loadCache($png_plain, $precontent) if (&getSourceModDate() < &getModDate($png_plain));
}


# label stuff
} else {
	#print STDERR "doing label stuff\n";

	$content = <<until_end;
<?xml version="1.0" encoding="iso-8859-1"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml0/DTD/xhtml0-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
	<title>Batmap-in-colour with scenics / BatMUD Tools by Tumi / support.bat.org</title>
	<base href="http://support.bat.org/" />
	<link href="images/favicon.ico" rel="SHORTCUT ICON" />
	<link href="batmap/labels.pl?size=$mapsize&batorg=$batorg" type="text/css" rel="stylesheet" />
	<meta name="keywords" content="batmud, batmap, batmap-in-colour, scenic location, scenics, map" />
</head>
<body>
<div id="pngdiv">

until_end

	#print STDERR "we need new label map\n";
	# we need new version
	my $abs_x = ceil($image_x * $mapsize / 100);
	my $abs_y = ceil($image_y * $mapsize / 100);

	# do the locs
	for my $loc (keys %locations) {
		my $name = $locations{$loc};
		my $cssname = lc $name;
		$cssname =~ s/\?/qmark/g;
		$cssname =~ tr/[a-z0-9]//cd;
		$cssname =~ s/^[0-9]+//;

		$content .= qq|<div id="$cssname" class="arealabel">$name</div>\n|;
	}

	$content .= <<until_end;
<img src="$img_src" alt="png map" width="$abs_x" height="$abs_y" />
</div> <!-- pngdiv -->
</body>
</html>

until_end

	my $fh = new IO::File &getVar('logpath')."/maplabels.log", "a";
	print $fh "X";
	undef $fh;

	print "Content-Type: text/html; charset=iso-8859-1\n";
	print "Cache-Control: private\n\n";
	print $content;

	exit;
	# exits
}



# remove some terrain if the labels are going to be printed
if ($plain ne 'yes') {
	for my $loc (sort {&posNum($a) <=> &posNum($b)} keys %locations) {
		my ($y, $x) = split/,/, $loc;
		my $loc_length = length($locations{$loc});
		substr($textmap[$y-1], $x-1, $loc_length, "*" x $loc_length);
		push @locs_in_order, $locations{$loc};
		#print STDERR "Added '$locations{$loc}' to list, yx '$y,$x', length '$loc_length'\n";
	}
}


# each terrain at its own {} block
my $map = join("\n", @textmap);
for my $chr (keys %colours) {
	$map =~ s#([\Q$chr\E]+)#{$1}#g;
}

# span the blocks
for my $chr (keys %colours) {
	my $class = $colours{$chr};
	$map =~ s#{([\Q$chr\E]+)}#<span class="$class">$1</span>#g;
}

# add labels to their reserved places
if ($plain ne 'yes') {
	for my $loc (@locs_in_order) {
		$map =~ s#([\*]+)#<span class="name">$loc</span>#;
	}
}

## post-HTML
$content .= <<until_end;
$map

</code>
</pre>
</div>

<!--
</td>
</tr>
</table>
-->

until_end

$load_file = $plain eq 'yes' ? $html_plain : $html_normal;
my $fh = new IO::File $load_file, "w";
print $fh $content;
undef $fh;



if ($graphic eq 'yes') {

	# Some basic dimensions
	my $im = new GD::Image($image_x, $image_y);
	#$im->interlaced('true');

	## Lets define some colors
	my $name_white  = $im->colorAllocate(255, 255, 255);
	my $unkn_black  = $im->colorAllocate(0, 0, 0);
	my $peak_bbb    = $im->colorAllocate(176, 176, 176);
	my $ruin_777    = $im->colorAllocate(112, 112, 112);
	my $cros_999    = $im->colorAllocate(144, 144, 144);
	my $deep_green  = $im->colorAllocate(0, 200, 0);
	my $deep_blue   = $im->colorAllocate(0, 0, 200);
	my $shal_0ff    = $im->colorAllocate(0, 255, 255);
	my $volc_red    = $im->colorAllocate(255, 0, 0);
	my $beac_yellow = $im->colorAllocate(255, 255, 0);
	my $fore_lime   = $im->colorAllocate(0, 255, 0);
	my $hill_f0f    = $im->colorAllocate(255, 0, 255);
	my $badl_f40    = $im->colorAllocate(255, 64, 0);
	my $fiel_olive  = $im->colorAllocate(128, 128, 0);
	my $shor_fe8  = $im->colorAllocate(240, 224, 140);

	# Painting image black
	$im->filledRectangle(0, 0, $image_x-1, $image_y-1, $unkn_black);

	# Maps maps span classes to colours
	my %mapping = (
		'name'		=> $name_white,
		'unknown'	=> $unkn_black,
		'peak'		=> $peak_bbb,
		'ruins'		=> $ruin_777,
		'speciallocation'	=> $name_white,
		'crossing'	=> $cros_999,
		'eastwestroad'	=> $ruin_777,
		'swneroad'	=> $ruin_777,
		'bridge'	=> $ruin_777,
		'sceniclocation'	=> $name_white,
		'playercity'	=> $cros_999,
		'deepforest'	=> $deep_green,
		'deepriver'	=> $deep_blue,
		'shallow'	=> $shal_0ff,
		'volcano'	=> $volc_red,
		'nwseroad'	=> $ruin_777,
		'mountain'	=> $hill_f0f,
		'beach'		=> $beac_yellow,
		'city'		=> $cros_999,
		'desert'	=> $beac_yellow,
		'forest'	=> $fore_lime,
		'hills'		=> $hill_f0f,
		'highlands'	=> $hill_f0f,
		'jungle'	=> $deep_green,
		'lake'		=> $deep_blue,
		'plain'		=> $fore_lime,
		'river'		=> $deep_blue,
		'swamp'		=> $volc_red,
		'tundra'	=> $name_white,
		'valley'	=> $fore_lime,
		'waterfall'	=> $shal_0ff,
		'badlands'	=> $badl_f40,
		'field'		=> $fiel_olive,
		'shore'		=> $shor_fe8,
		'northsouthroad'	=> $ruin_777,
		'sea'		=> $deep_blue,
	);


	my $graphy_line = 0;
	my @readylines = split/\n/, $map;
	for my $line (@readylines) {
		while (scalar ($line =~ m/\G<span class=\"(\w+)\">(.*?)<\/span>/g)) {
			# Where it starts
			my $this_color = defined $mapping{$1} ? $mapping{$1} : $name_white;
			# Printing
			&printGraphChar($im, $this_color, $graphy_line, $2);
		}
		$graphy_line++;
		$linex_pos = 0;
	}

	$linex_pos = 400;
	&printGraphChar($im, $name_white, 479, "Batmap-in-colour project (c) Tumi 2002-2006, http://support.bat.org/batmap/");

	$load_file = $plain eq 'yes' ? $png_plain : $png_normal;
	my $pngfh = new IO::File $load_file, "w";
	binmode $pngfh;
	print $pngfh $im->png(9);
	undef $pngfh;
}


&loadCache($load_file, $precontent);


1;



sub printGraphChar {
	my $image= shift;
	my $color = shift;
	my $yline = shift || 0;
	my $string = shift;


	unless ($image && $string && length $string > 0) {
		#print STDERR "Color ",($color||'')," string ",($string||''),", returing.\n";
		return;
	}

	#print STDERR "printGraphChar: yline= $yline, x= $linex_pos, string '$string'\n";


	# Writing to image
	my @chars = split//, $string;
	for my $char (@chars) {
		my $extratune = $char eq "~" ? 3 : 0;

		$image->string(gdSmallFont,
						$linex_pos,
						$yline * $fontsize + $extratune,
						$char,
						$color);

		# Advancing the linex
		$linex_pos += $fontsize;
	}

	return;
}


sub getModDate {
	my $file = shift;
	return 0 unless (defined $file);
	return 0 unless (-e $file);

	return ((stat($file))[9]);
}

sub getSourceModDate {
	my @files = ('source/locations.txt', 'source/batmap.txt', 'source/autogen.txt');
	my @times = ();
	push(@times, &getModDate($_)) for (@files);

	my $latest_chance = (reverse sort {$a<=>$b} @times)[0];
	return (time()+1) if (&getVar('map_uses_db') > 1); # force update if we have 2 or more (debug status)
	return $latest_chance;
}


sub loadCache {
	my $file = shift;
	my $precontent = shift;
	my $fh = new IO::File $file, "r";
	my $pageid = ($file =~ /plain/ ? "mapplain" : "mapcolor");

	# png cache
	if ($file =~ /\.png/) {
		#binmode $fh;
		#print "Content-Type: image/png\n\n" unless (param('noheader'));
		#binmode STDOUT;
		#print STDOUT <$fh> unless (param('debug'));

		my $output = <<until_end;
<img src="/batmap/$file" alt="Batmap-in-colour" width="4329" height="4329" />
until_end

		&pageOutput($pageid, "$precontent\n$output");

	# html cache
	} else {
		my $output = join("", <$fh>);
		&pageOutput($pageid, "$precontent\n$output");
	}

	undef $fh;
	exit;
}


__END__
