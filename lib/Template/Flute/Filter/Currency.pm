package Template::Flute::Filter::Currency;

use strict;
use warnings;

use Number::Format;

use base 'Template::Flute::Filter';

=head1 NAME

Template::Flute::Filter::Currency - Currency filter

=head1 DESCRIPTION

Currency filter based on L<Number::Format>.

=head1 METHODS

=head2 init

=cut

sub init {
    my ($self, %args) = @_;
    
    $self->{format} = Number::Format->new(%args);
}

=head2 filter

Currency filter.

=cut

sub filter {
    my ($self, $amount) = @_;

    return $self->{format}->format_price($amount);
}


=head1 AUTHOR

Stefan Hornburg (Racke), <racke@linuxia.de>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
