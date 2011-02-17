# Template::Zoom::I18N - Template::Zoom localization class
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

package Template::Zoom::I18N;

use strict;
use warnings;

=head1 NAME

Template::Zoom::I18N - Localization class for Template::Zoom

=head1 SYNOPSIS




=head1 CONSTRUCTOR

=head2 new [CODEREF]

Create a new Template::Zoom::I18N object. CODEREF is used by
localize method for the text translation.

=cut

sub new {
	my ($proto, @args) = @_;
	my ($class, $self);

	$class = ref($proto) || $proto;
	$self = {};
	
	if (ref($args[0]) eq 'CODE') {
		# use first parameter as localization function
		$self->{func} = shift(@args);
	}
	else {
		# noop translation
		$self->{func} = sub {return;}
	}

	bless ($self, $class);
}

=head1 METHODS

=head2 localize STRING

Calls localize function with provided STRING. The result is
returned if it contains non blank characters. Otherwise the
original STRING is returned.

=cut

sub localize {
	my ($self, $text) = @_;
	my ($trans);
	
	$trans = $self->{func}->($text);

	if (defined $trans && $trans =~ /\S/) {
		return $trans;
	}

	return $text;
}

=head1 AUTHOR

Stefan Hornburg (Racke), <racke@linuxia.de>

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
