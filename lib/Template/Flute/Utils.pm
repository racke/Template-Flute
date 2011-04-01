package Template::Flute::Utils;

use strict;
use warnings;

use File::Basename;
use File::Spec;

=head1 NAME

Template::Flute::Utils - Template::Flute utility functions

=head1 FUNCTIONS

=head2 derive_filename FILENAME SUFFIX [FULL]

Derives a filename with a different SUFFIX from FILENAME, e.g.

    derive_filename('templates/helloworld.html', '.xml')

returns

    templates/helloworld.xml

With the FULL parameter set it can be used to produce a path
for a relative filename from another filename with a directory,
e.g.

    derive_filename('templates/helloworld.html', 'foobar.png', 1)

returns

    templates/foobar.png

=cut

sub derive_filename {
	my ($orig_filename, $suffix, $full) = @_;
	my ($orig_dir, @frags);

	@frags = fileparse($orig_filename, qr/\.[^.]*/);

	if ($full) {
		return $frags[1] . $suffix;
	}
	else {
		return $frags[1] . $frags[0] . $suffix;
	}
}

=head1 AUTHOR

Stefan Hornburg (Racke), <racke@linuxia.de>

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2011 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
