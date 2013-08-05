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

# our stuff
# use lib '/home/twomi/web/libs';
use lib '/home/customers/tumi/public_html/archives/batmud';
use lib '/home/customers/tumi/tumilib';
use BatmudTools::Site;
use BatmudTools::Vars;
use Tumi::Helper;


## Version number
my $VERSION = "1.0";

my $citymap = &readFile('source/streets.txt');

##
my $content = <<until_end;
<h2>Streetmap of BatCity</h2>

<div class="tool-link"><strong>Version:</strong> $VERSION</div>

<div class="tools">
<p>
The plain ascii citymap was created by Delveling. The streetmap has its uses,
especially when dealing with hunting quest, Biff Swift event and so on.
</p>

<p>
There will be more versions of this map as well, including the coloured ascii
and graphic version with floating streetname labels, just like there is from the
official batmap too. Enjoy, report bugs to me.
</div>

<h3>Plain ascii streetmap</h3>

<div id="citymap1">
<pre>
<code>
$citymap


</code>
</pre>
</div>

until_end


&pageOutput('mapcity1', $content);

1;

__END__
