# Template::Zoom::List - Zoom list class
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

package Template::Zoom::List;

use strict;
use warnings;

=head1 NAME

Template::Zoom::List - List object for Template::Zoom templates.

=head1 CONSTRUCTOR

=head2 new

Creates Template::Zoom::List object.

=cut

# Constructor
sub new {
	my ($class, $sob, $static, $spec, $name) = @_;
	my ($self);
	
	$class = shift;
	$static ||= [];
	
	$self = {sob => $sob, static => $static, valid_input => undef};

	bless $self;
	
	if ($spec && $name) {
		$self->inputs_add($spec->list_inputs($name));
		$self->filters_add($spec->list_filters($name));
		$self->sorts_add($spec->list_sorts($name));
		$self->paging_add($spec->list_paging($name));
	}
	
	return $self;
}

=head1 METHODS

=head2 params_add PARAMS

Add parameters from PARAMS to list.

=cut
	
sub params_add {
	my ($self, $params) = @_;

	$self->{params} = $params || [];
}

=head2 inputs_add INPUTS

Add inputs from INPUTS to list.

=cut

sub inputs_add {
	my ($self, $inputs) = @_;

	if (ref($inputs) eq 'HASH') {
		$self->{inputs} = $inputs;
		$self->{valid_input} = 0;
	}
}

=head2 increments_add INCREMENTS

Add increments from INCREMENTS to list.

=cut

sub increments_add {
	my ($self, $increments) = @_;

	$self->{increments} = $increments;
}

=head2 filters_add FILTERS

Add filters from FILTERS to list.

=cut

sub filters_add {
	my ($self, $filters) = @_;

	$self->{filters} = $filters;
}

=head2 sorts_add SORT

Add sort from SORT to list.

=cut

sub sorts_add {
	my ($self, $sort) = @_;

	$self->{sorts} = $sort;
}

=head2 paging_add PAGING

Add paging from PAGING to list.

=cut
	
sub paging_add {
	my ($self, $paging) = @_;

	$self->{paging} = $paging;
}

=head1 METHODS

=head2 name

Returns name of the list.

=cut

sub name {
	my ($self) = @_;

	return $self->{sob}->{name};
}

=head2 iterator

Returns iterator for the list.

=cut
	
sub iterator {
	my ($self) = @_;

	return $self->{iterator};
}

=head2 set_iterator NAME

Sets list iterator to NAME.

=cut

sub set_iterator {
	my ($self, $iterator) = @_;
	
	$self->{iterator} = $iterator;
}

=head2 set_static_class CLASS

Set static class for list to CLASS.

=cut

sub set_static_class {
	my ($self, $class) = @_;

	push(@{$self->{static}}, $class);
}

=head2 static_class ROW_POS

Apply static class for ROW_POS.

=cut
	
sub static_class {
	my ($self, $row_pos) = @_;
	my ($idx);

	if (@{$self->{static}}) {
		$idx = $row_pos % scalar(@{$self->{static}});
		
		return $self->{static}->[$idx];
	}
}

=head2 elt

Returns corresponding HTML template element of the list.

=cut

sub elt {
	my ($self) = @_;

	return $self->{sob}->{elts}->[0];
}

=head2 params

Returns list parameters.

=cut

sub params {
	my ($self) = @_;

	return $self->{params};
}

=head2 input PARAMS

Verifies that input parameters are sufficient.
Returns 1 in case of success, 0 otherwise.

=cut

sub input {
	my ($self, $params) = @_;
	my ($error_count);

	if ((! $params || ! (keys %$params)) && $self->{valid_input} == 1) {
		return 1;
	}
	
	$error_count = 0;
	$params ||= {};
	
	for my $input (values %{$self->{inputs}}) {
		if ($input->{optional} && ! $params->{$input->{name}}) {
			# skip optional inputs without a value
			next;
		}
		if ($input->{required} && ! $params->{$input->{name}}) {
			warn "Missing input for $input->{name}.\n";
			$error_count++;
		}
		else {
			$input->{value} = $params->{$input->{name}};
		}
	}

	if ($error_count) {
		return 0;
	}

	$self->{valid_input} = 1;
	return 1;
}

=head2 query

Returns Perl structure for database query based on
the specification.

=cut

sub query {
	my ($self) = @_;
	my (%query, $found_table, $found_param, $name, %cols);

	%query = (tables => [], columns => {}, query => []);
	
	if ($self->{sob}->{table}) {
		push @{$query{tables}}, $self->{sob}->{table};
		$found_table = 1;
	}

	for (@{$self->{params}}) {
		if (exists $_->{field}) {
			$name = $_->{field};
		}
		else {
			$name = $_->{name};
		}
		
		push @{$query{columns}->{$self->{sob}->{table}}}, $name;
		$cols{$name} = 1;
		$found_param = 1;
	}

	# qualifier based on the input
	for (values %{$self->{inputs}}) {
		if (exists $_->{field}) {
			$name = $_->{field};
		}
		else {
			$name = $_->{name};
		}

		if ($_->{optional} && ! exists $_->{value}) {
			next;
		}
		
		if (exists $_->{op}) {
			# specific operator
			push @{$query{query}}, $name => {$_->{op} => $_->{value}};
		}
		else {
			push @{$query{query}}, $name => $_->{value};
		}
		
		# qualifiers need to be present in column specification
		unless (exists $cols{$name}) {
			push @{$query{columns}->{$self->{sob}->{table}}}, $name;
		}
	}

	# filter
	if (exists $self->{filters}) {
		for my $fname (keys %{$self->{filters}}) {
			if (exists $self->{filters}->{$fname}->{field}) {
				push @{$query{columns}->{$self->{sob}->{table}}},
					$self->{filters}->{$fname}->{field};
			}
		}
	}
	
	# sorting
	if (exists $self->{sorts}->{default}) {
		my @sort;

		for my $op (@{$self->{sorts}->{default}->{ops}}) {
			if ($op->{direction}) {
				push (@sort, "$op->{name} $op->{direction}");
			}
			else {
				push (@sort, $op->{name});
			}
		}

		$query{sort_by} = join(',', @sort);
	}

	# limits
	if (exists $self->{limits}) {
		my $limit;

		if (exists $self->{limits}->{all}) {
			$query{limit} = $self->{limits}->{all};
		}
		elsif (exists $self->{limits}->{plus}) {
			$query{limit} = $self->{limits}->{plus} + 1;
		}
	}
	
	if ($found_table && $found_param) {
		return \%query;
	}
}

=head3 set_limit TYPE LIMIT

Set list limit for type TYPE to LIMIT.

=cut

# set_limit method - set list limit
sub set_limit {
	my ($self, $type, $limit) = @_;

	$self->{limits}->{$type} = $limit;
}

=head3 set_filter NAME

Set global filter for list to NAME.

=cut
	
sub set_filter {
	my ($self, $name) = @_;

	$self->{filter} = $name;
}

=head3 filter ZOOM ROW

Run row filter on ROW if applicable.

=cut
	
sub filter {
	my ($self, $zoom, $row) = @_;
	my ($new_row);
	
	if ($self->{filters}) {
		if (ref($self->{filters}) eq 'HASH') {
			$new_row = $row;
			
			for my $f (keys %{$self->{filters}}) {
				$new_row = $zoom->filter($f, $new_row);
				return unless $new_row;
			}

			return $new_row;
		}

		return $zoom->filter($self->{filters}, $row);
	}
	
	return $row;
}

=head3 increment

Increment all increments of the list.

=cut

sub increment {
	my ($self) = @_;

	for my $inc (@{$self->{increments}}) {
		$inc->increment();
	}
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
