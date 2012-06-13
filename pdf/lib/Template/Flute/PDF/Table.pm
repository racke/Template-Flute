package Template::Flute::PDF::Table;

use strict;
use warnings;

=head1 NAME

Template::Flute::PDF::Table - Class for examining HTML tables for PDF

=head1 CONSTRUCTOR

=head2 new

Creates Template::Flute::PDF::Table object.

=cut

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

=head2 walk ELT

Walks HTML table from HTML template element ELT and returns Perl structure
with rows, cells and table data.

=cut

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

=head1 AUTHOR

Stefan Hornburg (Racke), <racke@linuxia.de>

=head1 LICENSE AND COPYRIGHT

Copyright 2011-2012 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
