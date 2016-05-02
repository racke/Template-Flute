package Template::Flute::Role::Element;

=head1 NAME

Template::Flute::Role::Element - common attributes for specification elements

=cut

use Template::Flute::Types qw/Str/;
use Moo::Role;

=head1 ATTRIBUTES

=head2

=head2 name

Name of the element.

=cut

has name => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

=head2 class

Class of corresponding elements in the HTML template.

Defaults to L</name>.

=cut

has class => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    default => sub { $_[0]->name },
);

=head2 id

Id of corresponding element in the HTML template. Overrides the L</class>
attribute for the specification element.

=cut

has id => (
    is  => 'ro',
    isa => Str,
);

=head2 scope

=cut

# FIXME: needs pod ^^

has scope => (
    is  => 'ro',
    isa => Str,
);

=head2 target

Specify the attribute to operate on instead of the tag content. It
can be a named attribute (e.g., "href"), the wildcard
character("*", meaning all the attributes found in the HTML
template), or a comma separated list (e.g., "alt,title").

=cut

has target => (
    is  => 'ro',
    isa => Str,
);

=head2 joiner

String placed between the text and the appended value. The joiner
isn't added if the value is empty.

=cut

has joiner => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    default => '',
);

1;
