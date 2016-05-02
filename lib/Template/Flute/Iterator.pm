package Template::Flute::Iterator;

use Template::Flute::Types qw/Int/;
use Moo;
with 'Template::Flute::Role::Iterator';
use namespace::clean;
use MooX::StrictConstructor;

=head1 NAME

Template::Flute::Iterator - Generic iterator class for Template::Flute

=head1 SYNOPSIS

    $cart = [{isbn => '978-0-2016-1622-4',
              title => 'The Pragmatic Programmer',
              quantity => 1},
             {isbn => '978-1-4302-1833-3',
              title => 'Pro Git',
              quantity => 1},
            ];

    $iter = new Template::Flute::Iterator($cart);

    print "Count: ", $iter->count(), "\n";

    while ($record = $iter->next()) {
	    print "Title: ", $record->title(), "\n";
    }

    $iter->reset();

    $iter->seed({isbn => '978-0-9779201-5-0',
                 title => 'Modern Perl',
                 quantity => 10});

=head1 CONSTRUCTOR

=head2 new

Creates a Template::Flute::Iterator object. The elements of the
iterator are hash references. They can be passed to the constructor
as array or array reference.

=cut

sub BUILDARGS {
    my $class = shift;
    return { data => @_ == 1 && ref($_[0]) eq 'ARRAY' ? $_[0] : [@_] };
}

=head1 ATTRIBUTES

=head2 count

The number of items in L</data>.

=cut

has count => (
    is       => 'ro',
    isa      => Int,
    lazy     => 1,
    default  => sub { scalar @{ $_[0]->data } },
    init_arg => undef,
    clearer  => 1,
);

=head1 METHODS

=head2 next

Returns next record or undef.

=cut

sub next {
    my ($self) = @_;

    if ( $self->index <= $self->count ) {
        my $old_index = $self->index;
        $self->_set_index( $old_index + 1 );
        return $self->data->[ $old_index ];
    }
    return undef;
}

=head1 AUTHOR

Stefan Hornburg (Racke), <racke@linuxia.de>

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2016 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 SEE ALSO

L<Template::Flute::Iterator::JSON>

=cut

1;
