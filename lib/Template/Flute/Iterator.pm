package Template::Flute::Iterator;

use Moo;
use Types::Standard qw/ArrayRef Int/;

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

=head1 ATTRIBUTES

=head2 data

The data to be iterated over.

=over

=item writer: seed

=back

=cut

has data => (
    is     => 'ro',
    isa    => ArrayRef,
    coerce => sub { ref( $_[0] ) eq 'ARRAY' ? $_[0] : \@_ },
    default => sub { [] },
    writer  => 'seed',
);

after 'seed' => sub {
    my $self = shift;
    $self->set_index(0);
    $self->clear_count;
};

=head2 count

Returns number of elements in L</data>.

=over

=item clearer: clear_count

=back

=cut

has count => (
    is       => 'lazy',
    isa      => Int,
    init_arg => undef,
    clearer  => 1,
);

sub _build_count {
    return scalar @{ $_[0]->data };
}

=head2 index

The current index within L</data> that the iterator points to.

=over

=item writer: set_index

=back

=cut

has index => (
    is       => 'ro',
    isa      => Int,
    default  => 0,
    init_arg => undef,
    writer   => 'set_index',
);

=head1 METHODS

=head2 next

Returns next record or undef if iterator is exhausted.

=cut

sub next {
    my $self  = shift;
    my $index = $self->index;
    if ( $index <= $self->count ) {
        $self->set_index( $index + 1 );
        return $self->data->[$index];
    }
    return undef;
}

=head2 reset

Resets iterator.

=cut

sub reset {
    $_[0]->set_index(0);
}

=head2 sort

Sorts records of the iterator.

Parameters are:

=over 4

=item $sort

Field used for sorting.

=item $unique

Whether results should be unique (optional).

=back

=cut
    
sub sort {
    my ( $self, $sort, $unique ) = @_;
    my ( @data, @tmp );

    @data = sort { lc( $a->{$sort} ) cmp lc( $b->{$sort} ) } @{ $self->data };

    if ($unique) {
        my $sort_value = '';

        for my $record (@data) {
            next if $record->{$sort} eq $sort_value;
            $sort_value = $record->{$sort};
            push (@tmp, $record);
        }

        $self->seed(\@tmp);
    }
    else {
        $self->seed(\@data);
    }
}


sub BUILDARGS {
    my ( $class, @args ) = @_;
    my %args;

    if (ref($args[0]) eq 'ARRAY') {
        $args{data} = $args[0];
    }
    else {
        %args = @args;
    }

    return \%args;
}

=head1 AUTHOR

Stefan Hornburg (Racke), <racke@linuxia.de>

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2015 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 SEE ALSO

L<Template::Flute::Iterator::JSON>

=cut

1;
