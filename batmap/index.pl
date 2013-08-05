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

use strict;
use CGI qw/param/;

# my stuff
# use lib '/home/twomi/web/libs';
use lib '/home/customers/tumi/public_html/archives/batmud';
use lib '/home/customers/tumi/tumilib';
use BatmudTools::Site;




my $content = <<until_end;
<h2>Batmap-in-
<span class="forest">c</span>
<span class="volcano">o</span>
<span class="beach">l</span>
<span class="deepforest">o</span>
<span class="sea">u</span>
<span class="highlands">r</span>
<span class="playercity">s</span>
project by Tumi</h2>

<div class="tool-link"><strong>Version:</strong> 2.0-beta4</div>

<h3>1. Contents</h3>
<div class="tools">
	<ul>
		<li>1. Contents</li>
		<li>2. View the map</li>
		<li>3. Latest changes</li>
		<li>4. Technical information</li>
		<li>5. Contributers</li>
	</ul>
</div>


<h3>2. View the map</h3>
<div class="tools">
	<p>
	<a href="batmap/webmap.pl">HTML-version of Batmap (with locations, 977kB), searchable</a><br />
	<a href="batmap/webmap.pl?labels=yes">PNG-image with overlaid area name tags (320kB), searchable (NEW)</a><br />
	<a href="batmap/webmap.pl?labels=yes&batorg=yes">GIF-map from bat.org with overlaid area name tags (50kB), searchable (NEW)</a><br />
	<a href="batmap/webmap.pl?gd=yes">PNG-version of Batmap (with locations, 346kB)</a><br />
	<a href="batmap/webmap.pl?plain=yes">HTML-version of Batmap (plain, just in color, 939kB)</a><br />
	<a href="batmap/webmap.pl?gd=yes&amp;plain=yes">PNG-version of Batmap (plain, just in color, 311kB)</a><br />
	</p>
</div>

<h4>2.1 Other maps</h4>
<div class="tools">
	<p>
	<a href="batmap/citymap.pl">Plain ASCII-version of BatCity streets</a><br />
	</p>
</div>


<h3>3. Latest changes</h3>
<div class="tools">
	<p><strong>7th Sep 2006:</strong><br />
	Replaced the table which hold the ascii map with div+pre+code, again. It was too slow and using
	!important, I think it works now too.
	</p>

	<p><strong>1st Sep 2006:</strong><br />
	Inspired by Moss, I made a new type of map, a HTML page with PNG image on it with
	overlaid scenic tags. It sort of replaces the whole PNG map, but both versions will
	still exist as there are separate uses for both.
	</p>

	<p><strong>31st Aug 2006:</strong><br />
	Made general tunes to the batmap engine, updated basemap as well.
	</p>

    <p><strong>17th May 2006:</strong><br />
    Added Kender mansion.
    </p>

    <p><strong>23rd Feb 2006:</strong><br />
    Added Darol's Ancona Manor and Fizzl's Domgroth's Mansion, thanks Juo.
    </p>

	<p><strong>2nd Feb 2006:</strong><br />
	Added Blasterr's new place, Abandoned study, near the Calythien.
	</p>

	<p><strong>26th Jan 2006:</strong><br />
	Added a place called Snootling Farm, near Donaru. Thanks Lyriikka.
	</p>

	<p><strong>24th Jan 2006:</strong><br />
	Recoded the batmap engine, took the newest map (which isn't up-to-date however, the
	bug is in bat server, not in my maps), and added a SHITLOAD of places (15 or so).
	Thanks for everyone for reporting those places to me.
	</p>

	<p>
	<a href="batmap/changes.pl">View older news about the map</a>
	</p>
</div>


<h3>4. Technical information</h3>
<div class="tools">
	<p>
	The Batmap is generated from a textmap of Batworld, available from
	<a href="http://www.bat.org/">bat.org</a>, provided by the archwizards, so it is
	as current and perfect as the wizards want it to be (except the bug Amarth accounced
	it has.) It is then coloured by a Perl-script
	using HTML and Cascading Stylesheets, for managebility and flexibility.
	Because the map is ascii, text, it is fully searchable by
	the usual Ctrl-F, or Edit/Find etc. The map is dynamical, so when Batworld changes,
	the Batmap is easily redone, without much work. Therefore this map is always up-to-date.
	</p>

	<p>
	You surely notice there is a few places marked <i>Unknown</i>, if you know the name
	in question or have other suggestions, completely new places to add and such,
	please mail me at <a href="mailto:tumi%20(at)%202-mi%20(dot)%20com">tumi (at) 2-mi (dot) com</a> or
	use a tell in Bat (<strong>Twomi</strong>
	is the name, Tumi is my old name in Bat). I'll appreciate all help.
	</p>

	<p>
	However, do NOT tell me there is new pcities in X or Y, those come from bat.org maps,
	I don't add them by hand. So its waste of time for you and me. They will appear on my
	maps whenever they will appear on the official maps generated by bat wizards.
	</p>
</div>



<h3>5. Contributers</h3>
<div class="tools">
	<p>
	Big thanks to archwizards Amarth &amp; Gore, Badaxe, Blackadder, Bmoa, Desos, Cozmo, Div,
	Ikira, Jameo, Juo, Kiraffi, Lyriikka, Rjak, Sitruuna, Skaree, Solstice, Toag and Valtava,
	and all those I forget, and all those new ones that I'm too lazy to add here anymore :)
	</p>
</div>


until_end



&pageOutput('mapindex', $content);


1;

__END__
