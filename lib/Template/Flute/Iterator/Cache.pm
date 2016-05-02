package Template::Flute::Iterator::Cache;

use Template::Flute::Types qw/Bool Iterator/;
use Moo;
with 'Template::Flute::Role::Iterator';
use namespace::clean;
use MooX::StrictConstructor;

=head1 NAME

Template::Flute::Iterator::Cache - Iterator caching class

=head1 DESCRIPTION

This iterator is used for caching another iterator which is used multiple
times in a list. We can safely use reset method on the caching iterator,
but not always on the original iterator.

=head1 ATTRIBUTES

=head2 iterator

Original iterator (required).

=head2 index

Current position.

=head2 data

Cached data.

=head2 filled

Whether cache is filled or not.

=cut

has iterator => (
    is       => 'ro',
    isa      => Iterator,
    required => 1,
);

has filled => (
    is      => 'rwp',
    isa     => Bool,
    default => 0,
);

=head1 METHODS

=head2 count

Returns count of (original) iterator.
=cut

sub count {
    return $_[0]->iterator->count;
}

=head2 next

Returns next record, either from original iterator or our cache.

=cut

sub next {
    my ($self, $index, $record);

    $self = shift;
    $index = $self->index;

    if ($self->filled) {
        # grab record from cache
        if ($index < $self->count) {
            $self->_set_index($index + 1);
            return $self->data->[$index];
        }
        return undef;
    }

    # grab record from original iterator and store it
    if ($record = $self->iterator->next) {
        push @{$self->data}, $record;
        $self->_set_index($index + 1);
        return $record;
    }

    $self->_set_filled(1);
    return undef;
}

=head1 AUTHOR

Stefan Hornburg (Racke), <racke@linuxia.de>

=head1 LICENSE AND COPYRIGHT

Copyright 2014-2016 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
