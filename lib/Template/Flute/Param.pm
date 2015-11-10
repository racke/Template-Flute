package Template::Flute::Param;

use Moo;
use Types::Standard qw/ArrayRef Enum InstanceOf Str Undef/;
use Types::Common::String qw/NonEmptySimpleStr/;
use namespace::clean;

=head1 NAME

Template::Flute::Param - template param class

=head1 ACCESSORS

=head2 name

Name of the param object.

=cut

has name => (
    is       => 'ro',
    isa      => NonEmptySimpleStr,
    required => 1,
);

=head2 type

Type of the param object.

=cut

has type => (
    is       => 'ro',
    isa      => Enum [ 'param' ] || undef,
    default  => 'param',
);

=head2 field

Field used to lookup the param.

=cut

has field => (
    is       => 'ro',
    isa      => ArrayRef | NonEmptySimpleStr,
);


=head2 class

Class of corresponding elements in the HTML template.

If this attribute is omitted, the param of the L</name> attribute is used
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

=head2 target

HTML attribute to fill the param instead of replacing the body of the
HTML element.

=cut

has target => (
    is  => 'ro',
    isa => NonEmptySimpleStr | Undef,
);

=head2 joiner

String placed between the text and the appended param. The joiner
isn't added if the param is empty.

=cut

has joiner => (
    is      => 'ro',
    isa     => Str,
    default => '',
);

=head2 op

operation

=cut

has op => (
    is  => 'ro',
    isa => Enum [ 'append', 'hook', 'toggle' ],
);

=head2 pattern

Name of pattern used for this element.

=cut

has pattern => (
    is => 'ro',
    isa => NonEmptySimpleStr,
);

=head2 filter

Name of filter used for this param.

=cut

has filter => (
  is => 'ro',
  isa => NonEmptySimpleStr,
);

=head2 include

Name of include file.

=cut

has include => (
    is  => 'ro',
    isa => NonEmptySimpleStr,
);

=head2 iterator_name

Name of iterator for this param.

=cut

has iterator_name => (
    is  => 'ro',
    isa => NonEmptySimpleStr | Undef,
);

=head2 skip

If set to C<empty> and param is an empty string,
replacement will be skipped.

=cut

has skip => (
  is => 'ro',
  isa => Enum [ 'empty' ],
);

=head2 elts

Stores associated L<XML::Twig::Elt>s.

=cut

has elts => (
    is      => 'ro',
    isa     => ArrayRef [ InstanceOf 'XML::Twig::Elt' ],
    default => sub { [] },
);

1;
