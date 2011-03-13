# Template::Zoom::Config - Template::Zoom configuration file loader
#
# Copyright (C) 2010 Stefan Hornburg (Racke) <racke@linuxia.de>.
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

package Template::Zoom::Config;

use strict;
use warnings;

use Config::Any;

=head1 NAME

Template::Zoom::Config - Configuration file handling for Template::Zoom

=head1 FUNCTIONS

=head2 load FILE

Loads configuration file FILE with L<Config::Any>.

=cut

sub load {
	my ($file) = @_;
	my ($cf_any, $cf_file, $cf_struct);

	$cf_any = Config::Any->load_files({files => [$file], use_ext => 1});

	for (@$cf_any) {
		($cf_file, $cf_struct) = %$_;
	}

	return $cf_struct;
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
