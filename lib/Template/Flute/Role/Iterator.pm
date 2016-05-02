package Template::Flute::Role::Iterator;

=head1 NAME

Template::Flute::Role::Iterator - role consumed by iterators

=cut

use Template::Flute::Types qw/ArrayRef HashRef Int Object Str/;
use Moo::Role;

=head1 ATTRIBUTES

=head2 data

The data to be iterated over.

A hash reference.

=cut

has data => (
    is       => 'rwp',
    isa      => ArrayRef [ HashRef | Object | Str ],
    required => 1,
    lazy => 1,
    default  => sub { [] },
    trigger => sub { $_[0]->clear_count },
);

=head2 index

The current index (position) in the iterator starting at 0.

=cut

has index => (
    is      => 'rwp',
    isa     => Int,
    lazy    => 1,
    default => sub { 0 },
    clearer => 'reset',
);

=head1 METHODS

=head2 reset

Resets the iterator.

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
            push( @tmp, $record );
        }

        $self->_set_data( [@tmp] );
    }
    else {
        $self->_set_data( [@data] );
    }
}

=head2 seed \@data

Change iterator's L</data> to C<\@data> and reset L</index>.

=cut

sub seed {
    my $self = shift;
    my $data = @_ == 1 && ref( $_[0] ) eq 'ARRAY' ? $_[0] : [@_];
    $self->_set_data($data);
    $self->reset;
}

=head1 AUTHORS

Stefan Hornburg (Racke), <racke@linuxia.de>

Peter Mottram (SysPete), C<< <peter at sysnix.com > >>

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2016 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
