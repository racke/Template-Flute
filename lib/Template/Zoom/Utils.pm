# Template::Zoom::Utils -  Template::Zoom utility functions
#
# Copyright (C) 2010-2011 Stefan Hornburg (Racke) <racke@linuxia.de>.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public
# License along with this program; if not, write to the Free
# Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA 02110-1301, USA.

package Template::Zoom::Utils;

use strict;
use warnings;

use File::Basename;
use File::Spec;

=head1 NAME

Template::Zoom::Utils - Template::Zoom utility functions

=head1 FUNCTIONS

=head2 derive_filename FILENAME SUFFIX

Derives a filename with a different SUFFIX from FILENAME.

=cut

sub derive_filename {
	my ($orig_filename, $suffix) = @_;
	my ($orig_dir, @frags);

	@frags = fileparse($orig_filename, qr/\.[^.]*/);

	return $frags[1] . $frags[0] . $suffix;
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
