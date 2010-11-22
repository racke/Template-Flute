# Template::Zoom::Iterator - Template::Zoom iterator class
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

package Template::Zoom::Iterator;

use strict;
use warnings;

# Constructor
sub new {
	my ($proto, @args) = @_;
	my ($class, $self);
	
	$class = ref($proto) || $proto;

	if (ref($args[0]) eq 'ARRAY') {
		$self = {DATA => $args[0], INDEX => 0};
	}
	else {
		$self = {DATA => \@args};
	}

	$self->{INDEX} = 0;
	$self->{COUNT} = scalar(@{$self->{DATA}});
	
	bless $self, $class;
}

# Next method - return next element or undef
sub next {
	my ($self) = @_;


	if ($self->{INDEX} <= $self->{COUNT}) {
		return $self->{DATA}->[$self->{INDEX}++];
	}
	
	return;
};

# Count method - return number of elements
sub count {
	my ($self) = @_;

	return $self->{COUNT};
}

1;
