package Template::Flute::Filter::LanguageName;

use strict;
use warnings;

use Locales;

use base 'Template::Flute::Filter';

=head1 NAME

Template::Flute::Filter::LanguageName - language name filter

=head1 DESCRIPTION

Language name filter based on L<Locales>.

=head1 PREREQUISITES

L<Locales> module.

=head1 METHODS

=head2 filter

Language name filter.

=cut

sub filter {
    my ($self, $code) = @_;
    my $name = '';

    if ($code) {
        # cut off sub locales
        $code =~ s/_(\w+)$//;

        $name = Locales->new->get_language_from_code($code);
    }
    
    return $name;
}

=head1 AUTHOR

Stefan Hornburg (Racke), <racke@linuxia.de>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
