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
use lib '/home/twomi/web/libs';
use Tumi::DB;
use BatmudTools::Vars;

my %lochash = ();
my %dbhash = ();

1;


sub parseLocationsFromDB {
	my $sql = <<until_end;
SELECT xpos,ypos,areaname,areatype,hidden,open,mapchar
FROM bat.areadata
ORDER BY ypos,xpos;
until_end

	my $outfh = new IO::File "source/dbgen.txt", "w";
	&dbSetup('bat@www-i', &getVar('mysql_user'), &getVar('mysql_pass'));
	my $sth = &dbGet('bat@www-i', $sql);
	while (my $row = $sth->fetchrow_hashref()) {
		my $title = $row->{'areaname'};

		# shorten shrine lines
		if ($row->{'areatype'} eq "shrine") {
			$title = $1 if ($title =~ /the ([a-z]+) race/i);
		}

		# make cap prefixes
		if ($row->{'areatype'} ne "area") {
			$title = (uc $row->{'areatype'})." $title"; }

		# or if area, leave it alone
		else {
			my $hidden = $row->{'hidden'} ? "HIDDEN " : "";
			my $open = $row->{'open'} ? "" : " CLOSED";
			$title = "$hidden$open$title";
		}

		my $x = $row->{'xpos'}+1;
		my $y = $row->{'ypos'}+1;
		my $scenic_x = $row->{'xpos'}+0;
		my $scenic_y = $row->{'ypos'}+0;
		$dbhash{"$y,$x"} = $title;
		$dbhash{"$scenic_y,$scenic_x"} = $row->{'mapchar'};
		#print STDERR "Added '$y,$x' => '$title'\n";
		#print $outfh "$y,$x:  $title\n";
		print $outfh "$scenic_y,$scenic_x:  ?\n"
			unless ($row->{'mapchar'} =~ /\?|\%/);
	}

	return (%dbhash);
}



## parseLocations return a hash where index is "y,x" and value the name
## of the location
sub parseLocations {
	my @locarray = @_;
	my $howmany = 0;
	return (%lochash) if ((keys %lochash) > 0);

	# load em from DB
	return &parseLocationsFromDB() if (&getVar('map_uses_db'));

	# load em from files
	foreach my $line (@locarray) {
		$line =~ tr/\x0D\x0A//d;
		next if (length($line)<5);
		next if (substr($line, 0, 1) eq ";");

		my ($coord, $site) = split(/:/, $line);
		$coord =~ s/^\s+|\s+$//g;
		$site =~ s/^\s+|\s+$//g;
		$lochash{$coord} = $site;
		$howmany++;
	}

	return (%lochash);
}


sub findAreaNearCoord {
	my ($map_y, $map_x, %areas) = @_;
	return "" unless ($map_y && $map_x && keys %areas > 0);

	# search offsets
	my $off_y = 1;
	my $off_x = 35;

	# search for close entrys
	my %matches = ();
	for my $coord (sort keys %areas) {
		my ($this_y, $this_x) = split/,/, $coord;
		my $diff_y = abs($this_y - $map_y);
		my $diff_x = abs($this_x - $map_x);

		# check if y is true
		next unless ($diff_y <= $off_y);

		# check if x is close enough
		next unless ($diff_x <= $off_x);
		my $dist_x = $map_x > $this_x ?
			($this_x + length($areas{$coord}) - $map_x) :
			($map_x - $this_x);

		# put in hash based on distance
		my $dist = $diff_y + $dist_x;
		my $area = $areas{$coord};
		$area =~ tr/\?//d;
		$matches{$dist} = $area;
	}

	# pick the closest one
	return "" if ((keys %matches) < 1);
	return $matches{(sort {abs($a)<=>abs($b)} keys %matches)[0]};
}



# counts the char index
sub posNum {
	my ($a_y, $a_x) = split/,/,shift;
	my $map_x = 481;

	return ($a_y*$map_x + $a_x);
}


__END__

