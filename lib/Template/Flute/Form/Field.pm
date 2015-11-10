package Template::Flute::Form::Field;

use Moo;
use Types::Standard qw/ArrayRef HashRef InstanceOf/;
use namespace::clean;

=head1 NAME

Template::Flute::Form::Field - Form object for Template::Flute templates.

=head1 ATTRIBUTES

=head2 type

Type of form field.

=cut

has type => (
    is => 'ro',
);

=head2 name

Name of form field.

=cut

has name => (
    is => 'ro',
);

=head2 iterator

Name of iterator for this form field (if any).

=cut

has iterator => (
    is => 'ro',
);

=head2 elts

List of twig elements.

=cut

has elts => (
    is => 'ro',
    isa => ArrayRef [ InstanceOf ['XML::Twig::Elt'] ],
    weak_ref => 1,
);

1;
