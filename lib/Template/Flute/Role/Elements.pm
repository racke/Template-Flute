package Template::Flute::Role::Elements;

use Moo::Role;
use Types::Standard qw/ArrayRef InstanceOf/;
use namespace::clean;

=head2 elts

List of twig elements.

=cut

has elts => (
    is => 'ro',
    isa => ArrayRef [ InstanceOf ['XML::Twig::Elt'] ],
    default => sub {[]},
);

1;
