package Template::Flute::Filter::DecodeHTMLEntities;

use strict;
use warnings;

use base 'Template::Flute::Filter';
use HTML::Entities 'decode_entities';

sub filter {
    my ($self, $value) = @_;

    return decode_entities($value);
}

1;
