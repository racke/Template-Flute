package Template::Flute::UriAdjust;

use strict;
use warnings;

use URI;
use Moo;

has adjust => (
    is => 'rw',
    required => 1,
);

has uri => (
    is => 'rw',
    required => 1,
);

has scheme => (
    is => 'rw',
    default => 'http',
);

sub result {
    my ($self) = @_;
    my $uri = URI->new($self->uri);

    # set scheme if necessary
    if (! $uri->scheme) {
        $uri->scheme($self->scheme);
    }

    my $result = $uri->clone;

    if (! $uri->host) {
        # add prefix to link
        my $adjust = $self->adjust;

        if ($uri->path =~ m%^/%) {
            $adjust =~ s%/$%%;
        }

        $result->path($adjust . $uri->path);
        return $result;
    }

    return;
};


1;
