# Template::Zoom::Container - Zoom container class
#
# Copyright (C) 2010-2011 Stefan Hornburg (Racke) <racke@linuxia.de>.
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

package Template::Zoom::Container;

use strict;
use warnings;

=head1 NAME

Template::Zoom::Container - Container object for Template::Zoom templates.

=cut

# Constructor
sub new {
	my ($class, $sob, $spec, $name) = @_;
	my ($self);
	
	$class = shift;
	
	$self = {sob => $sob};

	bless $self;
	
	return $self;
}

=head1 METHODS

=head2 name

Returns name of the container.

=cut

sub name {
	my ($self) = @_;

	return $self->{sob}->{name};
}

=head2 name

Passes current values to this container.

=cut
	
# set_values method - set values for this container
sub set_values {
	my ($self, $values) = @_;

	$self->{values} = $values;
}

# elt (element) method - returns corresponding template element of the container
sub elt {
	my ($self) = @_;

	return $self->{sob}->{elts}->[0];
}

=head2 visible

Determines whether the container is visible. Possible return values are 1 (visible),
0 (hidden) or undef if the specification for the container misses a value attribute.

=cut
	
# visible
sub visible {
	my ($self) = @_;
	my ($key);
	
	if ($key = $self->{sob}->{value}) {
		if (exists $self->{values}) {
			if ($self->{values}->{$key}) {
				return 1;
			}
			return 0;
		}

		return undef;
	}

	# container is visible if no value is specified
	return 1;
}

=head1 AUTHOR

Stefan Hornburg (Racke), <racke@linuxia.de>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
	
1;
