package Template::Flute::Form::Field;

use Moo;
with 'Template::Flute::Role::Base';
with 'Template::Flute::Role::Elements';

use Types::Standard qw/ArrayRef HashRef InstanceOf Str/;
use namespace::clean;
use MooX::StrictConstructor;

=head1 NAME

Template::Flute::Form::Field - Form object for Template::Flute templates.

=head1 ATTRIBUTES

=head2 type

Type of form field.

=cut

has type => (
    is => 'ro',
    isa => Str,
);

=head2 name

Name of form field.

=cut

has name => (
    is => 'ro',
    isa => Str,
);

=head2 form

=cut

has form => (
    is => 'ro',
    isa => Str,
);

=head2 keep

=cut

has keep => (
    is => 'ro',
    isa => Str,
);

=head2 iterator

Name of iterator for this form field (if any).

=cut

has iterator => (
    is => 'ro',
    isa => Str,
);

=head2 iterator_default

=cut

has iterator_default => (
    is => 'ro',
    isa => Str,
);

=head2 iterator_name_key

=cut

has iterator_name_key => (
    is => 'ro',
    isa => Str,
);

=head2 iterator_value_key

=cut

has iterator_value_key => (
    is => 'ro',
    isa => Str,
);

1;
