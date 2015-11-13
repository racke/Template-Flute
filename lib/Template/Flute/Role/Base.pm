package Template::Flute::Role::Base;

use Moo::Role;
use Types::Standard qw/Undef/;
use Types::Common::String qw/NonEmptySimpleStr/;
use namespace::clean;

=head2 class

Class of corresponding elements in the HTML template.

If this attribute is omitted, the value of the L</name> attribute is used
to relate to the class in the HTML template.

=cut

has class => (
    is  => 'lazy',
    isa => NonEmptySimpleStr,
);

sub _build_class {
    return $_[0]->name;
}

=head2 id

Id of corresponding element in the HTML template. Overrides the class
attribute for the specification element.

=cut

has id => (
    is  => 'ro',
    isa => NonEmptySimpleStr | Undef,
);

1;
