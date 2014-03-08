package Template::Flute::UriAdjust;

use strict;
use warnings;

use URI;
use URI::Escape;
use URI::Escape (qw/uri_unescape/);

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
        elsif ($adjust !~ m%/$%) {
            $adjust .= '/';
        }

        $result->path($adjust . $uri->path);

        # unescape the resulting path
        $result = uri_unescape($result->path);

        if ($uri->fragment) {
            $result .= "#" . uri_unescape($uri->fragment);
        }

        return $result;
    }

    return;
};


1;
