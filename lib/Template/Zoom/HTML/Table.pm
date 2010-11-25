# Template::Zoom::HTML::Table - Zoom HTML table class
#
# Copyright (C) 2010 Stefan Hornburg (Racke) <racke@linuxia.de>.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public
# License along with this program; if not, write to the Free
# Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA 02110-1301, USA.

package Template::Zoom::HTML::Table;

use strict;
use warnings;

sub new {
	my ($proto, @args) = @_;
	my ($class, $self);

	$class = ref($proto) || $proto;
	$self = {@args};

	$self->{rows} = 0;
	$self->{cells} = 0;
	$self->{cell_widths} = [];
		
	bless ($self, $class);
}

sub walk {
	my ($self, $root) = @_;
	my ($elt, $elt_cell, $gi, $row_pos, $cell_pos, @data, $i, $j, $width);

	$i = $j = 0;
	
	for $elt ($root->children()) {
		if ($elt->gi() eq 'tr') {
			# table row
			for $elt_cell ($elt->children()) {
				$gi = $elt_cell->gi();
				
				# table cell
				if ($gi eq 'th' || $gi eq 'td') {
					if ($width = $elt_cell->att('width')) {
						$self->{cell_widths}->[$j] = $width;
					}

					$data[$i][$j++] = $elt_cell->text();
				}
			}

			if ($j > $self->{cells}) {
				$self->{cells} = $j;
			}
			
			$i++;
			$j = 0;
		}
	}

	$self->{rows} = $i;
	$self->{data} = \@data;
		
	return \@data;
}

1;
