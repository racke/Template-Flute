package Template::Flute::Value;

=head1 NAME

Template::Flute::Value

=cut

use Template::Flute::Types qw/ArrayRef Enum Str/;
use Moo;
with 'Template::Flute::Role::Element';
use namespace::clean;
use MooX::StrictConstructor;

=head1 ATTRIBUTES

See L<Template::Flute::Role::Element> for additional attributes.

=head2 args

Arguments to L</op>.

=cut

has args => (
    is  => 'ro',
    isa => Str,
);

=head2 field

The field which contains the value to use. Defaults to L</name>.

=cut

has field => (
    is      => 'ro',
    isa     => ArrayRef | Str,
    lazy    => 1,
    default => sub { $_[0]->name },
    coerce  => sub {
        defined $_[0] && $_[0] =~ /\./ ? [ split /\./, $_[0] ] : $_[0];
    },
);

=head2 filter

Applies filter to value.

=cut

has filter => (
    is  => 'ro',
    isa => Str,
);

=head2 include

Processes the template file named in this attribute. This implies
the hook operation. See L<Template::Flute/INCLUDE FILES> for more information.

=cut

has include => (
    is      => 'ro',
    isa     => Str,
    trigger => sub {
        my $self = shift;
        $self->_set_op('hook');
    },
);

=head2 iterator

See L<Temlate::Flute/Custom iterators for dropdowns>.

=cut

has iterator => (
    is  => 'ro',
    isa => Str,
);

=head2 iterator_default

See L<Temlate::Flute/Custom iterators for dropdowns>.

=cut

has iterator_default => (
    is  => 'ro',
    isa => Str,
);

=head2 iterator_name_key

See L<Temlate::Flute/Custom iterators for dropdowns>.

=cut

has iterator_name_key => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    default => 'label',
);

=head2 iterator_value_key

See L<Temlate::Flute/Custom iterators for dropdowns>.

=cut

has iterator_value_key => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    default => 'value',
);

=head2 op

Operation to perform.

=cut

has op => (
    is  => 'rwp',
    isa => Enum [qw/ append hook toggle /],
);

=head2 pattern

See L<Template::Flute/pattern> for full details.

=cut

has pattern => (
    is  => 'ro',
    isa => Str,
);

=head2 skip

If C<skip> is set to C<empty> then we do not replace the template string
if the value is undefined, empty or just whitespace.

=cut

has skip => (
    is  => 'ro',
    isa => Enum [qw/ empty /],
);

=head2 type

Returns 'value'.

=cut

has type => (
    is       => 'ro',
    init_arg => undef,
    default  => 'value',
);

1;
