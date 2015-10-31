package Template::Flute::Value;

use Moo;
use Types::Standard qw/Str Undef/;

=head1 NAME

Template::Flute::Value - template value class

=head1 ACCESSORS

=head2 name

Name of the value object.

=cut

has name => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

=head2 class

Class of corresponding elements in the HTML template.

If this attribute is omitted, the value of the L</name> attribute is used
to relate to the class in the HTML template.

=cut

has class => (
    is  => 'lazy',
    isa => Str,
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
    isa => Str | Undef,
);

=head2 target

HTML attribute to fill the value instead of replacing the body of the
HTML element.

=cut

has target => (
    is  => 'ro',
    isa => Str | Undef,
);

=head2 joiner

String placed between the text and the appended value. The joiner
isn't added if the value is empty.

=cut

has joiner => (
    is      => 'ro',
    isa     => Str,
    default => '',
);

1;
