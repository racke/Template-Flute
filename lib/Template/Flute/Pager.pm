package Template::Flute::Pager;

use strict;
use warnings;

use Moo;
use Data::Page;
use Scalar::Util;
use Sub::Quote qw/quote_sub/;
use Types::Standard qw/HasMethods InstanceOf Int/;

use Template::Flute::Iterator;
use namespace::clean;
use MooX::StrictConstructor;

=head1 NAME

Template::Flute::Pager - Data::Page class for Template::Flute

=head1 SYNOPSIS

    $pager = Template::Flute::Pager->new;

    # set page size
    $pager->page_size(10);

    # retrieve number of pages
    $pager->pages;

    # retrieve current page (numering starts at 1)
    $pager->current_page;

    # retrieve global position numbers for current page
    $pager->position_first;
    $pager->position_last;

    # select a page (numbering starts at 1)
    $pager->select_page(5);

=head1 ATTRIBUTES

=head2 pager

Pager object.

An instance of L<Data::Page>

=over

=item clearer: clear_pager

=item predicate: has_pager

=back

=cut

has pager => (
    is        => 'lazy',
    isa       => InstanceOf ['Data::Page'],
    clearer   => 1,
    predicate => 1,
);

sub _build_pager {
    my $self = shift;
    my $iterator = $self->iterator;
    my $pager;

    # try to use pager supplied by the iterator

    if ( $iterator->can('pager') ) {
        if ($iterator->can('is_paged')) {
            # DBIC throws exception if we call pager on a resultset
            # that is not paged so be paranoid
            if ($iterator->is_paged) {
                $pager = $iterator->pager;
            }
        }
        else {
            $pager = $iterator->pager;
        }
    }

    # if we have a pager then return it

    return $pager if $pager;

    # if we got this far then create a new Data::Page object

    return Data::Page->new( $self->count, $self->page_size,
        $self->current_page );
}

=head2 iterator

Data iterator object which has data and should support the following methods:

=over

=item * next

=back

=cut

has iterator => (
    is     => 'ro',
    isa    => HasMethods [ "count", "next" ],
    writer => 'seed',
    coerce => quote_sub q{
    Scalar::Util::blessed( $_[0] ) ? $_[0] : Template::Flute::Iterator->new(@_)
    },
);

after 'seed' => sub {
    my $self = shift;
    $self->clear_count;
    $self->clear_pager;
};

=head2 page_size

Page size (defaults to 20).

=cut

has page_size => (
    is      => 'lazy',
    isa     => Int,
);

sub _build_page_size {
    my $self = shift;
    if ( $self->has_pager ) {
        return $self->pager->entries_per_page;
    }
    else {
        return 20;
    }
}

=head2 current_page

Pager page we want to display. Defaults to 1.

=over

=item writer:  select_page

=back

=cut

has current_page => (
    is     => 'lazy',
    isa    => Int,
    writer => 'select_page',
);

sub _build_current_page {
    my $self = shift;
    if ( $self->has_pager ) {
        return $self->pager->current_page;
    }
    else {
        return 1;
    }
}

# set current_page in the pager and reset page_position to 0
after 'select_page' => sub {
    my ($self, $page) = @_;
    $self->pager->current_page($page);
    if ( $self->iterator->can("is_paged") && $self->iterator->is_paged ) {
        $self->iterator->page($page);
    }
    else {
        $self->iterator->reset;
        for (1..$self->position_first-1) {
            $self->iterator->next;
        }
    }
    $self->set_page_position(0);
};

=head2 page_position

Returns the position on the current page (starts at 0).

=over

=item writer: set_page_position

=back

=cut

has page_position => (
    is       => 'ro',
    isa      => Int,
    default  => 0,
    init_arg => undef,
    writer   => 'set_page_position',
);

=head2 pages

Returns number of pages.

=cut

has pages => (
    is       => 'lazy',
    isa      => Int,
    init_arg => undef,
);

sub _build_pages {
    return $_[0]->pager->last_page;
}

=head2 count

Returns total number of records.

=over

=item clearer: clear_count

=back

=cut

has count => (
    is      => 'lazy',
    isa     => Int,
    clearer => 1,
);

sub _build_count {
    my $self = shift;
    if ( $self->has_pager ) {
        return $self->pager->total_entries;
    }
    else {
        return $self->iterator->count;
    }
}

=head1 METHODS


=head2 position_first

Returns global position number of first item on current page.

NOTE: First position on first page is 1 (not zero-based)

=cut

sub position_first {
    $_[0]->pager->first;
}

=head2 position_last

Returns global position number of last item on current page.

NOTE: First position on first page is 1 (not zero-based)

=cut

sub position_last {
    $_[0]->pager->last;
}

=head2 next

Returns next record or undef.

=cut

sub next {
    my $self = shift;

    if ($self->page_size > 0) {
        if ($self->page_position < $self->page_size) {
            $self->set_page_position($self->page_position + 1);
            return $self->iterator->next;
        }
        else {
            # advance current page
            $self->select_page( $self->current_page + 1 );
            return;
        }
    }
    else {
        $self->set_page_position($self->page_position + 1);
        return $self->iterator->next;
    }
}

=head2 reset

Resets iterator.

=cut

sub reset {
    my $self = shift;
    $self->select_page(1);
}

sub BUILDARGS {
    my ( $class, @args ) = @_;

    if (ref($args[0]) eq 'ARRAY') {
        # create iterator
        my $data = shift @args;
        my $iter = Template::Flute::Iterator->new(data => $data);
        unshift @args, iterator => $iter;
    }
    my %ret = @args;
    # catch and remove undef page size
    delete $ret{page_size} if !defined $ret{page_size};
    return \%ret;
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

L<Template::Flute::Iterator>

=cut

1;
