# Template::Zoom::Specification - Zoom Specification class
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

package Template::Zoom::Specification;

use strict;
use warnings;

# Constructor

sub new {
	my ($class, $self);
	my (%params);

	$class = shift;
	%params = @_;

	$self = \%params;

	# lookup hash for elements by class
	$self->{classes} = {};
	
	bless $self;
}

sub list_add {
	my ($self, $new_listref) = @_;
	my ($listref, $list_name, $class);

	$list_name = $new_listref->{list}->{name};
	
	$listref = $self->{lists}->{$new_listref->{list}->{name}} = {input => {}};

	$class = $new_listref->{list}->{class} || $list_name;

	$self->{classes}->{$class} = {%{$new_listref->{list}}, type => 'list'};

	# loop through inputs for this list
	for my $input (@{$new_listref->{input}}) {
		print "Input $input for $list_name\n";
		$listref->{input}->{$input->{name}} = $input;
	}
	
	# loop through params for this list
	for my $param (@{$new_listref->{param}}) {
		$class = $param->{class} || $param->{name};

		$self->{classes}->{$class} = {%{$param}, type => 'param', list => $list_name};	
	}

	return $listref;
}

sub inputs {
	my ($self, $list_name) = @_;

	if (exists $self->{lists}->{$list_name}) {
		return $self->{lists}->{$list_name}->{input};
	}
}

sub element_by_class {
	my ($self, $class) = @_;

	if (exists $self->{classes}->{$class}) {
		return $self->{classes}->{$class};
	}

	return;
}

1;
