package Template::Flute::Role::Component;

use warnings;
use strict;

use Carp;
use Template::Flute::Types qw/ArrayRef Bool HashRef/;
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

=head2 params

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

=cut

has sob => (
    is       => 'ro',
    isa      => HashRef,
    required => 1,
);

=head2 static

=cut

has static => (
    is       => 'ro',
    required => 1,
);

has _valid_input => (
    is       => 'ro',
    isa      => Bool,
    default  => undef,
    init_arg => undef,
    writer   => '_set_valid_input',
);

1;
