package Template::Flute::Expression;

use strict;
use warnings;

use Parse::RecDescent;
use Scalar::Util qw/reftype/;
use Template::Flute::Types qw/HashRef Maybe Object/;
use Moo;
with 'Template::Flute::Role::Core';
use namespace::clean;

=head1 NAME

Template::Flute::Expression - Parser for expressions

=head1 CONSTRUCTOR

=head2 new

Takes a single argument:

=over

=item expression

=back

Creates Template::Flute::Expression object.

    $expr = Template::Flute::Expression->new('!username');

Possible expressions are:

=over 4

=item username

Evaluates to value C<username>.

=item !username

Reverse.

=item foo.bar

Evaluates to value C<foo.bar>, e.g. $values->{foo}->{bar}.

=item !foo.bar

Reverse.

=item foo|bar

Evaluates to value C<foo> or value C<bar>.

=item foo&bar

Evaluates to value C<foo> and value C<bar>.

=item foo|bar

Evaluates to value C<foo> or reverse of value C<bar>.

=item foo&bar

Evaluates to value C<foo> and reverse of value C<bar>.

=back
    
=cut

my $grammar = q{
<autoaction: { [@item] } >

var : /\w[a-z0-9_]*/

dottedvar : var '.' var

andor : term /[|&]/ term

notvar: '!' var

notdottedvar: '!' dottedvar

term: var | notvar | dottedvar | notdottedvar

expression : andor | dottedvar | notdottedvar | var | notvar
};

# FIXME: (SysPete 29/4/16) Keep old api for now.
sub BUILDARGS {
    my $class = shift;
    return { expression => shift };
}

has expression => (
    is => 'ro',
    required => 1,
);

has _rd => (
    is => 'ro',
    init_arg => undef,
    default => sub { Parse::RecDescent->new($grammar) },
);

has '+values' => (
    isa => Maybe [ HashRef | Object ],
);

=head1 METHODS

=head2 evaluate 

    $expr->evaluate({foo => 'bar'});

Evaluates the expression with a hash reference of values
and returns the result.

=cut

sub evaluate {
    my ($self, $value_ref) = @_;
    my ($tree);
    
    $self->set_values($value_ref);
    $tree = $self->_build();
    $self->_walk($tree);
}

sub _build {
    my ($self) = @_;
    my ($tree);

    $tree = $self->_rd->expression($self->expression);

    return $tree;
}

sub _walk {
    my ($self, $tree) = @_;

    if ($tree->[0] eq 'expression') {
        return $self->_walk($tree->[1]);
    }
    elsif ($tree->[0] eq 'term') {
        return $self->_walk($tree->[1]);
    }
    elsif ($tree->[0] eq 'andor') {
        my ($val_one, $val_two, $op);

        $val_one = $self->_walk($tree->[1]);
        $op = $tree->[2];
        $val_two = $self->_walk($tree->[3]);

        if ($op eq '&') {
            return $val_one && $val_two;
        }
        elsif ($op eq '|') {
            return $val_one || $val_two;
        }
    }
    elsif ($tree->[0] eq 'notvar') {
        # do reverse
        if ($self->_walk($tree->[2])) {
            return 0;
        }
        return 1;
    }
    elsif ($tree->[0] eq 'var') {
        # just the value
        return $self->_value($tree->[1]);
    }
    elsif ($tree->[0] eq 'dottedvar') {
        # get value for current level
        my $values_ref = $self->_value($tree->[1]->[1]);
        my $reftype = reftype($values_ref);

        if ($reftype && $reftype eq 'HASH') {
            return $self->_value($tree->[3]->[1], $values_ref);
        }
        else {
            return 0;
        }
    }
    elsif ($tree->[0] eq 'notdottedvar') {
        # do reverse
        if ($self->_walk($tree->[2])) {
            return 0;
        }
        return 1;
    }
    elsif ($tree->[0]) {
        die "Invalid operation: ", $tree->[0];
    }
}

sub _value {
    my ($self, $name, $values_ref) = @_;
    my ($value);

    if (! ref($values_ref)) {
        $values_ref = $self->values;
    }
    
    if (exists($values_ref->{$name}) 
	&& defined($values_ref->{$name})
	&& $values_ref->{$name} =~ /\S/) {
	$value = $values_ref->{$name};
    } elsif ($self->_is_record_object($values_ref) && $values_ref->can($name)) {
        $value = $values_ref->$name;
    }
    else {
	$value = '';
    }

    return $value;
}

1;
