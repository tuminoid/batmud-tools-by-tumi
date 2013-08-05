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
use Tumi::Helper;
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

<a name="contents" />
<h3>1. Contents</h3>
<div class="tools">
	<ul>
		<li><a href="/batmap/changes.pl#contents">1. Contents</a></li>
		<li><a href="/batmap/changes.pl#news">2. Latest changes</a></li>
		<li><a href="/batmap/">3. Go back to index</a></li>
	</ul>
</div>


<a name="news" />
<h3>2. Latest changes</h3>
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

	<p><strong>23rd Sep 2005:</strong><br />
	Refreshed to current map, added couple ?: the gnome crashsite, some unknown near
	Kutanakor and the new area from Heidel, the Oakvale.
	</p>

	<p><strong>22nd Apr 2005:</strong><br />
	Refreshed to current, let me know if any new ? is found.
	</p>

	<p><strong>21st Apr 2004:</strong><br />
	Made a PNG versions of maps, added Temple of the Wind. Version to 1.2.0.
	</p>

	<p><strong>12th Apr 2004:</strong><br />
	Added Knights, fixed Ship Navigators overlapping normal Navigators.
	</p>

	<p><strong>10th Apr 2004:</strong><br />
	Added two new Runemages guild entraces, Lighthouse, Rilynttar docks,
	new Savage Coast area, Silver Lake City and Ship Navigators.
	Closed old Immortal guild, as it no longer exists. Thanks to Presence
	for spotting the scenics, I hadn't had time to search for new places.
	</p>

	<p><strong>4th Apr 2004:</strong><br />
	Added new LoCs, Temple of Tzarakk (part of new LoCs I assume?),
	Pier and Dopperganger shrine (since the race isn't so secret
	anymore, being in bat.org etc too).
	</p>

	<p><strong>3rd Mar 2004:</strong><br />
	Added Old fort, closed Shipwreck, opened Corabandor, updated map etc.
	</p>

	<p><strong>28th Jan 2004:</strong><br />
	Made old-style version map available for those users (or places) with no access
	to decent browsers (IE 5.0 series bug badly with new layout). The link for old
	maps is available at the end of the page.
	</p>

	<p><strong>25th Jan 2004:</strong><br />
	Outlooks of this site was configured to match the main <a href="http://2-mi.com/batmud/">
	BatMUD Tools by Tumi</a> site. It may look a little bad in old explorers, upgrade!
	</p>

	<p><strong>29th Nov 2003:</strong><br />
	Added Malar's new place, Output, to the map.
	</p>

	<p><strong>30th Oct 2003:</strong><br />
	Added Zith's new places to the map.  Removed the counter, it bugged too bad.
	</p>

	<p><strong>16th Oct 2003:</strong><br />
	Hmm, my counter is resetting itself like all the time :-) I'll fix it sometimes.
	Added couple places to map, total count of places now 309.
	</p>

	<p><strong>29th Sep 2003:</strong><br />
	Weblaskuri people are getting greedy and making their counter services pricy. Decided
	not to take that shit and coded my own counter. Its a bit crude looking but its easily
	improved if I have the time.
	</p>

	<p><strong>11th Sep 2003:</strong><br />
	Added new spidershrine, updated basemap, as lots of new shallow areas appeared. This
	has something to do with incoming ships etc.
	</p>

	<p><strong>25th Aug 2003:</strong><br />
	Version 1.0.1. 50k loads passed long ago. Explore tune caused 6 times higher load
	count compared to what it used to be. Wonder :-)
	</p>

	<p><strong>4th Aug 2003:</strong><br />
	<a href="http://2-mi.com/batmud/webplaque.pl">The Top Expmakers</a> now
	features with a GRAPH.. compare your expmaking to your friends! Check
	it out!
	</p>

	<p><strong>22nd Jul 2003:</strong><br />
	Well, this is not related to map, but lets put a link here.
	<a href="http://2-mi.com/batmud/webplaque.pl">Top Expmakers</a>-script
	now available. Its very crappy looky etc, but will improve it over time.
	</p>

	<p><strong>21st Jul 2003:</strong><br />
	Added Ant hill and Spider cave, thanks to Solstice and Ikira respectively.
	</p>

	<p><strong>12th Jun 2003:</strong><br />
	Added Beastlands, making the area count 300! Cheerios! Version 0.9.7 only to
	rejoice that! :-)
	</p>

	<p><strong>27th Apr 2003:</strong><br />
	Added Psi quest area, located bit north from Jungle Cave, contributed by Rjak.
	Some internal crap complete, version 0.9.6.. Its a total of 299 areas now,
	so who wants to be the contributer of the 300th location!
	</p>

	<p><strong>21st Apr 2003:</strong><br />
	Scenic location near barb guild renamed to Plakhstan, the Unknown
	located near nw-corner of map to Stone circle2, due to connection
	to that another stone circle north from BatCity. Thanks Garok!
	</p>

	<p><strong>15th Apr 2003:</strong><br />
	General updates on map and basemap. There is alarmingly many
	Unknowns on the map, so could people contribute and tell me the
	names of those locations. New information needed too!
	</p>

	<p><strong>31st March 2003:</strong><br />
	Added five locations near Dalesmen, together creating 'Battlefields'.
	Also 100 acre forest and Abandoned house areas were off by one,
	fixed those locations too. Closing 300 locations quickly, now at
	296. Keep the places coming!
	</p>

	<p><strong>26th March 2003:</strong><br />
	Changed the plains-tile color much closer to the original color
	(yellow -> dull yellow).. Much easier to eyes and distinct color
	to separate from beach/shore. Changed also line spacing to have
	better proportions (ie the map should be a square, not taller than wide)..
	Thanks to Jameo for these tips. Version 0.9.5a.
	</p>

	<p><strong>24th March 2003:</strong><br />
	Nocilis Valley has been reopened sometime, so its no longer marked closed
	in the map. It can be found near Alch guild.
	</p>

	<p><strong>21st March 2003:</strong><br />
	A new guild, Squire, was introduced in Batmud. It is located 3e, 1n from
	Batcity east gate (see map).
	</p>

	<p><strong>19th March 2003:</strong><br />
	Did a quick (1 minute) poll on mud about do people view the map online
	or download it first and look it from local drive. Got about 25 viewers
	and 2 downloaders... Suppose everyone got xDSL home :) Don't be afraid,
	not going to remove the zip's, just wanted to ask, since statistics
	are pretty limited on the server.
	</p>

	<p><strong>18-19th March 2003:</strong><br />
	Added Zith's new area, City of Stagira, located east from lich/skeleton
	shrines, and Nalle's Circus, located some southwest from BC. Enjoy. Version
	0.9.5 as I did some changes in the parsing code (not visible to users).
	</p>

	<p><strong>19th February 2003:</strong><br />
	Added few scenics by Juo. Event towers near Halls of the Dead and
	Ranger quest area south of Babylon. Also Taiga by Lyriikka.
	Thanks guys. Basemap update also as usual, won't report those anymore
	from now on, I'll do it everytime. Location count closing to 300 soon,
	now at 289. Version 0.9.4a.
	</p>

	<p><strong>4th February 2003:</strong><br />
	Couple new scenics found, updated basemap, general script optimizing.
	Version up to 0.9.4.
	</p>

	<p><strong>16th January 2003:</strong><br />
	Added Spiders and Priests guilds to the map. Basemap updated too.
	</p>

	<p><strong>23rd December 2002:</strong><br />
	Sorry to all english folk, I noticed I had put the counter text in
	finnish, not english. Fixed now.<br />
	Merry xmas to everyone! Don't be a no-lifer even there is double exp
	available until 26th's boot!
	</p>

	<p><strong>17th December 2002:</strong><br />
	Due to lack of statistics available from hut.fi, I installed a counter
	to map to count how many times the map has been viewed online. If you load
	the zip and view that offline, it doesn't count. If you're online, it loads
	the counter and image across the web anyways, so you can't hide! :-)
	Also updated basemap and undid all the thingies I did to map yesterday..
	Those who are concerned, I'll fix em next week or so, when I have no exams
	anymore. Updated map number to 0.9.3.
	</p>

	<p><strong>10th December 2002:</strong><br />
	Added location of Nalle's castle, contribution of Juo. Located near
	Rudraprayag. Updated the basemap too, it seems to be updated every boot
	now, big hugs to Gore.
	</p>

	<p><strong>26th November 2002:</strong><br />
	Trologdyte village was repositioned once more, should be right this time.
	Added Harazam tower to the map, somebody could tell me its real name, if
	anyone has better. Thanks go to Dupre and Lung. Updated basemap, not much
	changes.
	Map revision up to 0.9.2a.
	</p>

	<p><strong>12th November 2002:</strong><br />
	The basemap was updated and two locations, Moongate and Abandoned House
	reported to me by Rjak were added. Don't know what has changed in basemap,
	but didn't found any new scenics marked on it, so prolly a terrain update.
	Map revision bumped up to 0.9.2.
	</p>

	<p><strong>5th November 2002:</strong><br />
	Added Tinmen Monastery to map, and fixed couple area names. Thanks go
	to Desos. Map revision 0.9.1b.
	</p>

	<p><strong>3rd November 2002:</strong><br />
	Added two new, currently as Unknown, areas reported by Blackadder. Moved
	two other areas to correct places, that were misplaced by a square or two.
	Map revision up to 0.9.1a (see I'm running out of version numbers soon :P).
	</p>

	<p><strong>2nd November 2002:</strong><br />
	Changes list grew too big, moved it to another page.
	</p>

	<p><strong>27th October 2002:</strong><br />
	Corrected couple names, typos and such little things. Added two areas.
	Map revision up to 0.9.1.
	</p>

	<p><strong>26th October 2002:</strong><br />
	Rjak gave two new locations and Valtava informed that some were misplaced. Thanks guys!
	</p>

	<p><strong>24th October 2002:</strong><br />
	Gore has updated the map, therefore this map updated as well. If I counted right,
	6 locations got a ? on the map, two of them were completely new to this map, therefore
	marked as Unknown. The others location texts were just slightly moved to be on exact
	correct spot. Map revision up to 0.9.0.
	</p>

	<p><strong>24th October 2002:</strong><br />
	Made a plain version of map. It has no locations marked, it is exactly what archs wish
	us to see it, only in color. Enjoy. <a href="/batmap/index.pl#download">Go to view/download</a>.
	</p>

	<p><strong>23rd October 2002:</strong><br />
	Added few more areas to map, renamed couple and added ? marks to area names for
	locations that aren't marked as ? in original map. Those will be removed when the
	Gore gets the map fixed. Map revision 0.8.2.
	</p>

	<p><strong>22nd October 2002:</strong><br />
	Added four areas part of Savage Coast to the map, thanks to Kiraffi. Made minor fixes
	to area names and their positioning etc. Still waiting the map to be fixed, Amarth
	told me that Gore told him it'd be any day now. Map revision to 0.8.1.
	</p>

	<p><strong>21st October 2002:</strong><br />
	I've reviewed the site statistics which include the weekend downloads and
	the map or the zip have been downloaded total of 932 times.
	I have received a load of thank yous from
	mortals and wizards alike. I'm glad to notice that map was generally
	very much needed.
	</p>

	<p><strong>19th October 2002:</strong><br />
	Rewrote the map generating engine completely, the first version
	was next to complete shit :-) The map 'leaked' tags, meaning that there were
	like 400 open tags at the end of the document, total number being over 24000.
	Its fixed now, should be little faster for browser to display, when the code
	is well-formed.	Updated the version number to 0.8.0.
	</p>

	<p><strong>18th October 2002:</strong><br />
	Added or fixed 6 locations hinted by Badaxe and Kiraffi. Map revision 0.7.4.
	</p>

	<p><strong>18th October 2002:</strong><br />
	Archwizard Amarth told me that reviewing my map made him notice
	that the Bat's map engine is buggy and doesn't include all scenic locations.
	This means that the map does NOT include all the places there is, not even
	marked as Unknown.. Once Amarth has fixed it, the map updates right away and
	you'll have plenty more scenic locations to hint me about :-)
	</p>

	<p><strong>17th October 2002:</strong><br />
	Added or fixed 13 locations hinted by Div, Kiraffi, Sitruuna and Toag. Map
	revisions from 0.7.1 to 0.7.3.
	</p>

	<p><strong>17th October 2002:</strong><br />
	Released the map as revision 0.7.0. Posted the announcement on the general
	newsgroup.
	</p>
</div>


until_end



&pageOutput('mapindex', $content);


1;

__END__
