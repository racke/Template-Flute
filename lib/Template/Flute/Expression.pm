package Template::Flute::Expression;

use strict;
use warnings;

=head1 NAME

Template::Flute::Expression - Parser for expressions

=head1 CONSTRUCTOR

=head2 new

Creates Template::Flute::Expression object.

    $expr = Template::Flute::Expression->new('!username');

Possible expressions are:

=over 4

=item username

Evaluates to value C<username>.

=item !username

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

use Parse::RecDescent;

sub new {
    my ( $class, $self );

    $class = shift;
    $self = { expression => shift };
    bless $self, $class;

    $self->{_rd} = Parse::RecDescent->new(
        q{
<autoaction: { [@item] } >

var : /\w[a-z0-9_]*/

andor : term /[|&]/ term

notvar: '!' var

term: var | notvar

expression : andor | notvar
}
    );

    return $self;
}

=head1 METHODS

=head2 evaluate 

    $expr->evaluate({foo => 'bar'});

Evaluates the expression with a hash reference of values and returns the
result.

=cut

sub evaluate {
    my ( $self, $value_ref ) = @_;
    my ($tree);

    $self->{values} = $value_ref;
    $tree = $self->_build();
    $self->_walk($tree);
}

sub _build {
    my ($self) = @_;
    my ($tree);

    $tree = $self->{_rd}->expression( $self->{expression} );

    return $tree;
}

sub _walk {
    my ( $self, $tree ) = @_;

    if ( $tree->[0] eq 'expression' ) {
        return $self->_walk( $tree->[1] );
    }
    elsif ( $tree->[0] eq 'term' ) {
        return $self->_walk( $tree->[1] );
    }
    elsif ( $tree->[0] eq 'andor' ) {
        my ( $val_one, $val_two, $op );

        $val_one = $self->_walk( $tree->[1] );
        $op      = $tree->[2];
        $val_two = $self->_walk( $tree->[3] );

        if ( $op eq '&' ) {
            return $val_one && $val_two;
        }
        elsif ( $op eq '|' ) {
            return $val_one || $val_two;
        }
    }
    elsif ( $tree->[0] eq 'notvar' ) {

        # do reverse
        if ( $self->_walk( $tree->[2] ) ) {
            return 0;
        }
        return 1;
    }
    elsif ( $tree->[0] eq 'var' ) {

        # just the value
        return $self->_value( $tree->[1] );
    }
}

sub _value {
    my ( $self, $name ) = @_;
    my ( $value, $values_ref );

    $values_ref = $self->{values};

    if (   exists( $values_ref->{$name} )
        && defined( $values_ref->{$name} )
        && $values_ref->{$name} =~ /\S/ )
    {
        $value = $values_ref->{$name};
    }
    else {
        $value = '';
    }

    return $value;
}

1;
