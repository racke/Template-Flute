# Template::Zoom::Specification::Scoped - Zoom Config::Scoped Specification routines
#
# Copyright (C) 2010-11 Stefan Hornburg (Racke) <racke@linuxia.de>.
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

package Template::Zoom::Specification::Scoped;

use strict;
use warnings;

use Template::Zoom::Specification;
use Config::Scoped;

# Constructor

sub new {
	my ($class, $self);
	my (%params);

	$class = shift;
	%params = @_;

	$self = \%params;

	bless ($self, $class);
}

sub parse {
	my ($self, $text) = @_;
	my ($scoped, $config);
	
	# create Config::Scoped parser and parse text
	$scoped = new Config::Scoped;

	if (ref($text) eq 'SCALAR') {
		$config = $scoped->parse(text => $$text);
	}
	else {
		$config = $scoped->parse(text => $text);
	}

	$self->{spec} = $self->create_specification($config);

	return $self->{spec};
}

sub parse_file {
	my ($self, $file) = @_;
	my ($scoped, $config, $key, $value, %list);

	# create Config::Scoped parser and parse file
	$scoped = new Config::Scoped(file => $file);
	$config = $scoped->parse();

	$self->{spec} = $self->create_specification($config);

	return $self->{spec};
}

sub create_specification {
	my ($self, $config) = @_;
	my ($spec, $scoped, $key, $value, %list);

	# specification object
	$spec = new Template::Zoom::Specification;
	
	# lists
	while (($key, $value) = each %{$config->{list}}) {
		$value->{name} = $key;
		$list{$key} = $value;
	}

	# adding list tokens: params, inputs and filters
	my ($list);

	for my $cname (qw/param input filter/) {
		while (($key, $value) = each %{$config->{$cname}}) {
			$list = delete $value->{list};
			$value->{name} = $key;
		
			if ($list) {
				if (exists $list{$list}) {
					push @{$list{$list}->{$cname}}, {%$value};
				}
				else {
					die "List missing for $cname $key.";
				}
			}
			else {
				die "No list assigned to $cname $key.";
			}
		}
	}

	# adding other tokens: values and i18n
	for my $cname (qw/value i18n/) {
		while (($key, $value) = each %{$config->{$cname}}) {
			$value->{name} = $key;

			if ($cname eq 'value') {
				$spec->value_add({value => $value});
			}
			elsif ($cname eq 'i18n') {
				$spec->i18n_add({i18n => $value});
			}
		}
	}

	while (($key, $value) = each %{$config->{list}}) {
		$spec->list_add({list => $value,
								 param => $value->{param},
								 input => $value->{input},
								 filter => $value->{filter}});
	}

	return $spec;
}

sub error {
	my ($self) = @_;

	if (@{$self->{errors}}) {
		return $self->{errors}->[0]->{error};
	}
}

sub add_error {
	my ($self, @args) = @_;
	my (%error);

	%error = @args;
	
	unshift (@{$self->{errors}}, \%error);
}

1;
