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

sub localize {
	my ($self, $text) = @_;
	my ($trans);
	
	$trans = $self->{func}->($text);

	if (defined $trans && $trans =~ /\S/) {
		return $trans;
	}

	return $text;
}

1;
