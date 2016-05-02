package Template::Flute::List;

use Carp;
use Template::Flute::Types qw/ArrayRef Elt HashRef Int Maybe Specification Str/;
use Moo;
#with 'Template::Flute::Role::Component';
use namespace::clean;
use MooX::StrictConstructor;

=head1 NAME

Template::Flute::List - List object for Template::Flute templates.

=head1 CONSTRUCTOR

=head2 new

Creates Template::Flute::List object.

=cut

=head1 ATTRIBUTES

=head2 elt

The L<XML::Twig::Elt> associated with this list.

=cut

has elt => (
    is       => 'ro',
    isa      => Elt,
    required => 1,
);

#=head2 filter
#
#Name of the global filter for the list.
#
#=cut
#
#has filter => (
#    is     => 'ro',
#    isa    => Str,
#    writer => 'set_filter',
#);

=head2 filters

=cut

has filters => (
    is      => 'ro',
    isa     => HashRef,
    lazy    => 1,
    writer  => 'filters_add',
    default => sub {
        return $_[0]->specification && $_[0]->name
          ? $_[0]->specification->list_filters( $_[0]->name )
          : {};
    },
);

=head2 increments

=cut

has increments => (
    is      => 'ro',
    isa     => ArrayRef,
    writer  => 'increments_add',
    default => sub { [] },
);

=head2 inputs

Hash reference of inputs.

#=over
#
#=item writer: inputs_add
#
#=back

=cut

has inputs => (
    is      => 'ro',
    isa     => HashRef,
    trigger => sub { $_[0]->_set_valid_input(0) },
#    writer  => 'inputs_add',
    lazy    => 1,
    default => sub {
        return $_[0]->specification && $_[0]->name
          ? $_[0]->specification->list_inputs( $_[0]->name )
          : {};
    },
);

=head2 iterator

The iterator for this list.

=cut

has iterator => (
    is       => 'ro',
    isa      => HashRef,
);

=head2 limit

=cut

has limit => (
    is      => 'ro',
    isa     => Int,
);

=head2 limits

=cut

has limits => (
    is      => 'ro',
    isa     => HashRef,
    default => sub { +{} },
);

=head2 name

Name associated with the component.

Required.

=cut

has name => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

=head2 paging

=cut

has paging => (
    is     => 'ro',
    isa    => HashRef,
    writer => 'paging_add',
    default => sub { +{} },
);

=head2 params

Array reference of params.

Defaults to an empty array reference.

=over

=item writer: params_add

=back

=cut

has params => (
    is      => 'ro',
    isa     => ArrayRef,
    default => sub { [] },
    coerce  => sub { defined $_[0] ? $_[0] : [] },
    writer  => 'params_add',
);

=head2 separators

=cut

has separators => (
    is      => 'ro',
    isa     => ArrayRef,
    writer  => 'separators_add',
    default => sub { [] },
);

=head1 sorts

=cut

has sorts => (
    is      => 'ro',
    isa     => HashRef,
    lazy    => 1,
    writer  => 'sorts_add',
    default => sub {
        return $_[0]->specification
          && $_[0]->name ? $_[0]->specification->list_sorts( $_[0]->name ) : {};
    },
);

=head2 specification

A L<Template::Flute::Specification> object.

=cut

has specification => (
    is  => 'ro',
    isa => Specification,
);

=head2 static

=cut

has static => (
    is      => 'ro',
    isa     => ArrayRef,
    default => sub { [] },
);

=head1 METHODS

=head2 iterator [ARG]

Returns list iterator object when called without ARG.
Returns list iterator name when called with ARG 'name'.

=cut
	
around iterator => sub {
    my ( $orig, $self, $arg ) = @_;
    my $iterator = $orig->($self);
    if ( $arg && $arg eq 'name' ) {
        return $iterator->{name};
    }
    else {
        return $iterator->{object};
    }
};

#=head2 set_iterator ITERATOR
#
#Sets list iterator object to ITERATOR.
#
#=cut
#
#sub set_iterator {
#	my ($self, $iterator) = @_;
#	
#	$self->_iterator->{object} = $iterator;
#}

=head2 set_static_class $class

Add C<$class> to L</static>.

=cut

sub set_static_class {
    my ( $self, $class ) = @_;

    push( @{ $self->static }, $class );
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

=head2 input PARAMS

Verifies that input parameters are sufficient.
Returns 1 in case of success, 0 otherwise.

=cut

sub input {
	my ($self, $params) = @_;
	my ($error_count);

	if ((! $params || ! (keys %$params)) && $self->_valid_input ) {
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

	$self->_set_valid_input(1);
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

Copyright 2010-2016 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
