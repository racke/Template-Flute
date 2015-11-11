package Template::Flute::List;

use Sub::Quote;
use Moo;
use Types::Standard qw/ArrayRef Bool HashRef InstanceOf Int Str Undef/;
use namespace::clean;

with 'Template::Flute::Role::Elements';

=head1 NAME

Template::Flute::List - List object for Template::Flute templates.

=head1 ATTRIBUTES

=head2 name

Name of the list.

=cut

has name => (
    is => 'ro',
    isa => Str,
    required => 1,
);

=head2 iterator_name

Name of the iterator for this list.

=cut

has iterator_name => (
    is => 'ro',
    isa => Str,
    required => 1,
);

=head2 iterator_object

Iterator object for this list.

=over

=item writer: set_iterator

=back

=cut

has iterator_object => (
    is => 'ro',
    isa => InstanceOf['Template::Flute::Iterator'],
    writer => 'set_iterator',
);

=head2 limit

Limit the number of iterations for your list.

=cut

has limit => (
    is => 'ro',
    isa => Int,
    default => 0,
    coerce => quote_sub(q{ defined $_[0] ? $_[0] : 0 }),
);

=head2 limits

=cut

has limits => (
    is      => 'ro',
    isa     => HashRef,
    default => sub {+{}},
);

=head2 static

Static elements.

=cut

has static => (
    is => 'ro',
    isa => ArrayRef,
    default => sub {[]},
);

=head2 params

A list can have multiple params

=over

=item writer: params_add

=back

=cut

has params => (
    is => 'ro',
    isa => ArrayRef,
    writer => 'params_add',
);

=head2 separators

list separators.

=over

=item writer: separators_add

=back

=cut

has separators  => (
    is => 'ro',
    isa => Undef | ArrayRef,
    writer => 'separators_add',
);

=head2 inputs

Form inputs.

=over

=item writer: inputs_add

=back

=cut

has inputs => (
    is => 'ro',
    isa => HashRef,
    writer => 'inputs_add',
);

after 'inputs_add' => sub {
    $_[0]->valid_input(0);
};

=head2 valid_input

=cut

has valid_input => (
    is => 'rw',
    isa => Bool,
);

=head2 increments

=over

=item writer: increments_add

=back

=cut

has increments => (
    is     => 'ro',
    isa    => ArrayRef | Undef,
    writer => 'increments_add',
);

=head2 filters

=over

=item writer: filters_add

=back

=cut

has filters => (
    is     => 'ro',
    isa    => ArrayRef | Undef,
    writer => 'filters_add',
);

=head2 sorts

=over

=item writer: sorts_add

=back

=cut

has sorts => (
    is => 'ro',
    isa => ArrayRef | Undef,
    writer => 'sorts_add',
);

=head2 paging

=over

=item writer: paging_add

=back

=cut
	
has paging => (
    is => 'ro',
    isa => HashRef | Undef,
    writer => 'paging_add',
);
    
=head1 METHODS

=head2 iterator [ARG]

Returns list iterator object when called without ARG.
Returns list iterator name when called with ARG 'name'.

=cut
	
sub iterator {
	my ($self, $arg) = @_;

	if (defined $arg && $arg eq 'name') {
		return $self->iterator_name;
	}

	return $self->iterator_object;
}

=head2 set_static_class CLASS

Set static class for list to CLASS.

=cut

sub set_static_class {
	my ($self, $class) = @_;

	push(@{$self->static}, $class);
}

=head2 static_class ROW_POS

Apply static class for ROW_POS.

=cut
	
sub static_class {
	my ($self, $row_pos) = @_;
	my ($idx);

	if (@{$self->static}) {
		$idx = $row_pos % scalar(@{$self->static});
		
		return $self->static->[$idx];
	}
}

=head2 elt

Returns corresponding HTML template element of the list.

=cut

sub elt {
	my ($self) = @_;

	return $self->{sob}->{elts}->[0];
}

=head2 input PARAMS

Verifies that input parameters are sufficient.
Returns 1 in case of success, 0 otherwise.

=cut

sub input {
	my ($self, $params) = @_;
	my ($error_count);

	if ((! $params || ! (keys %$params)) && $self->valid_input == 1) {
		return 1;
	}
	
	$error_count = 0;
	$params ||= {};
	
	for my $input (values %{$self->inputs}) {
		if ($input->{optional} && (! defined $params->{$input->{name}}
			|| $params->{$input->{name}} !~ /\S/)) {
			# skip optional inputs without a value
			next;
		}
		if ($input->{required} && (! defined $params->{$input->{name}}
                        || $params->{$input->{name}} !~ /\S/)) {
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

	$self->valid_input(1);
	return 1;
}

=head2 set_limit TYPE LIMIT

Set list limit for type TYPE to LIMIT.

=cut

# set_limit method - set list limit
sub set_limit {
	my ($self, $type, $limit) = @_;

	$self->limits->{$type} = $limit;
}

=head2 set_filter NAME

Set global filter for list to NAME.

=cut
	
sub set_filter {
	my ($self, $name) = @_;

	$self->{filter} = $name;
}

=head2 filter FLUTE ROW

Run row filter on ROW if applicable.

=cut
	
sub filter {
	my ($self, $flute, $row) = @_;
	my ($new_row);
	
	if ($self->filters) {
		if (ref($self->filters) eq 'HASH') {
			$new_row = $row;
			
			for my $f (keys %{$self->filters}) {
				$new_row = $flute->filter($f, $new_row);
				return unless $new_row;
			}

			return $new_row;
		}

		return $flute->filter($self->filters, $row);
	}
	
	return $row;
}

=head2 increment

Increment all increments of the list.

=cut

sub increment {
	my ($self) = @_;

	for my $inc (@{$self->increments}) {
		$inc->increment();
	}
}

=head1 AUTHOR

Stefan Hornburg (Racke), <racke@linuxia.de>

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2015 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
