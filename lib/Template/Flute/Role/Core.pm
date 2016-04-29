package Template::Flute::Role::Core;

use warnings;
use strict;

use Carp;
use Scalar::Util qw/blessed/;
use Template::Flute::Types qw/HashRef/;
use Moo::Role;

=head1 NAME

Template::Flute::Role::Core

=head1 ATTRIBUTES

=head2 autodetect

A configuration option. It should be an hashref with a key C<disable>
and a value with an arrayref with a list of B<classes> for objects
which should be considered plain hashrefs instead. Example:

  my $flute = Template::Flute->new(....
                                   autodetect => { disable => [qw/My::Object/] },
                                   ....
                                  );

Doing so, if you pass a value holding a C<My::Object> object, and you have a specification with something like this:

  <specification>
   <value name="name" field="object.method"/>
  </specification>

The value will be C<$object->{method}>, not C<$object->$method>.

The object is checked with C<isa>.

Classical example: C<Dancer::Session::Abstract>.

=cut

has autodetect => (
    is  => 'ro',
    isa => HashRef,
);

=head2 values

Hash reference of values.

=cut

has values => (
    is      => 'ro',
    isa     => HashRef,
    writer  => 'set_values',
    default => sub { +{} },
);

sub _autodetect_ignores {
    my $self = shift;
    my @ignores;
    if ($self->autodetect and exists $self->autodetect->{disable}) {
        @ignores = @{ $self->autodetect->{disable} };
    }
    foreach my $f (@ignores) {
        croak "empty string in the disabled autodetections" unless length($f);
    }
    return @ignores;
}

sub _is_record_object {
    my ($self, $record) = @_;
    my $class = blessed($record);
    return unless defined $class;

    # it's an object. Check if we have it in the blacklist
    my @ignores = $self->_autodetect_ignores;
    my $is_good_object = 1;
    foreach my $i (@ignores) {
        if ($record->isa($i)) {
            $is_good_object = 0;
            last;
        }
    }
    return $is_good_object;
}

1;
