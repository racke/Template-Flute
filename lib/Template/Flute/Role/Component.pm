package Template::Flute::Role::Component;

use warnings;
use strict;

use Carp;
use Template::Flute::Types qw/ArrayRef Bool HashRef Maybe Str/;
use Moo::Role;

=head1 NAME

Template::Flute::Role::Component

=head1 ATTRIBUTES

=head2 inputs

Hash reference of inputs.

=over

=item writer: inputs_add

=back

=cut

has inputs => (
    is      => 'ro',
    isa     => HashRef,
    trigger => sub { $_[0]->_set_valid_input(0) },
    writer  => 'inputs_add',
);

=head2 name

Name associated with the component.

Defaults to the value of the C<name> key in L</sob>.

=cut

has name => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    default => sub { $_[0]->sob->{name} },
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

=head2 sob

Special Object (?). These things get everywhere.

A hash reference. Required.

=cut

has sob => (
    is       => 'ro',
    isa      => HashRef,
    required => 1,
);

=head2 static

=cut

has static => (
    is      => 'ro',
    isa     => ArrayRef,
    default => sub { [] },
);

has _valid_input => (
    is       => 'ro',
    isa      => Bool,
    default  => undef,
    init_arg => undef,
    writer   => '_set_valid_input',
);

=head1 METHODS

=head2 set_static_class $class

Add C<$class> to L</static>.

=cut

sub set_static_class {
    my ( $self, $class ) = @_;

    push( @{ $self->static }, $class );
}

1;
