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

# Strict is always good
use strict;
use CGI qw/param/;
use POSIX qw/ceil/;

# my stuff
# use lib '/home/twomi/web/libs';
use lib '/home/customers/tumi/public_html/archives/batmud';
use lib '/home/customers/tumi/tumilib';
use BatmudTools::Site;
use Tumi::Helper;
use BatmudTools::Layout;


my $point_of_site = &readFile('html/pointofsite.html');
my $fixlist = &readFile('html/fixlist.html');
my $buglist = &readFile('html/buglist.html');


my $VERSION = "1.0.1";
my $name = param('name') || "";

my @boons = split/\n/, &readFile('boons.txt');
my $boonlist = "";
for my $boon (@boons) {
  my $cpb = $boon;
  $cpb =~ s/[A-Z\-]/[a-z_]/g;
  $cpb =~ tr/[a-z]//cd;

  $boonlist .= <<until_end;
document.write('     <option value="$cpb" selected>$boon</option>');
until_end
}



my $headelement = <<until_end;
<script language="JavaScript">
<!--
var amount=15;

function countBoons() {
var totalboons=0;
var totaltps=0;
var i,j,tmp,mult,booncost;
  for (i=0; i<amount; i++) {
    with (window.document.boons) {
      booncost=0;
      for (j=0; j<=boon[i].selectedIndex; j++) {
        mult = Math.floor(totalboons/6) + 1;
        switch (j) {
	  case 0:
	    break;
          case 1:
            booncost += mult*10;
	  totalboons++;
            break;
          case 2:
            booncost += mult*20;
	  totalboons++;
	  break;
          case 3:
            booncost += mult*40;
	  totalboons++;
	  break;
          case 4:
            booncost += mult*80;
	  totalboons++;
	  break;
          default:
        }
      }//>
      totaltps += booncost;
      cost[i].value = booncost;
      total[i].value= totaltps;
    }
  }
  return false;
}

function printFormLine(nro) {
document.write('<tr>');
document.write('  <td>Boon ' + nro + ':</td>');
document.write('  <td>');
document.write('   <select name="boon" onChange="countBoons();">');
document.write('     <option value="0" selected="selected">none (0%)');
document.write('     <option value="1">tiny (10%)</option>');
document.write('     <option value="2">small (25%)</option>');
document.write('     <option value="3">medium (50%)</option>');
document.write('     <option value="4">full (100%)</option>');
document.write('   </select>');
document.write('   </td>');
document.write('   <td>');
document.write('     <input disabled type="text" name="cost" size="5" onChange="countBoons()" />');
document.write('   </td>');
document.write('   <td>');
document.write('     <input disabled type="text" name="total" size="5" onChange="countBoons()" />');
document.write('   </td>');
document.write('   <td>');
document.write('     <select onChange="countBoons();">');
$boonlist
document.write('     </select>');
document.write('   </td>');
document.write('</tr>');
}

//-->
</script>
until_end



my $content = <<until_end;
<h2>Boon calculator by Tumi</h2>
<div class="tool-link"><strong>Version:</strong> $VERSION</div>

<form name="boons" onsubmit="countBoons();return false;">
<p>Name for this plan: <input type="text" name="name" value="$name" size="40" maxlength="80" /></p>
<table border="1">
<tbody>
<tr><th>Nro:</th><th>Strength:</th><th>Cost for this:</th><th>Total cost:</th><th>Actual boon (optional):</th></tr>
<script language="JavaScript">
  for (i=1; i<= amount; i++) {
    printFormLine(i);
  }
</script>
</tbody>
</table>
</form>


<script language="JavaScript">
<!--
countBoons();
//-->
</script>

until_end




&addHeadElement($headelement);
&pageOutput('booncalc', $content);


1;


