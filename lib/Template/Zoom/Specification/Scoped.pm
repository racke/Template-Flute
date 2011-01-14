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

sub parse_file {
	my ($self, $file) = @_;
	my ($scoped, $config, $key, $value, %list);

	# initialize stash
	$self->{stash} = [];
	
	# specification object
	$self->{spec} = new Template::Zoom::Specification;
	
	# twig parser object
	$scoped = new Config::Scoped(file => $file);
	$config = $scoped->parse();

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
				$self->{spec}->value_add({value => $value});
			}
			elsif ($cname eq 'i18n') {
				$self->{spec}->i18n_add({i18n => $value});
			}
		}
	}

	while (($key, $value) = each %{$config->{list}}) {
		$self->{spec}->list_add({list => $value,
								 param => $value->{param},
								 input => $value->{input},
								 filter => $value->{filter}});
	}

	return $self->{spec};
}

sub spec_handler {
	my ($self, $elt) = @_;
	my ($name);

	$name = $elt->att('name');
}

sub list_handler {
	my ($self, $elt) = @_;
	my ($name, %list);
	
	$name = $elt->att('name');

	$list{list} = $elt->atts();
	
	# flush elements from stash into list hash
	$self->stash_flush($elt, \%list);

	# add list to specification object
	$self->{spec}->list_add(\%list);
}

sub sort_handler {
	my ($self, $elt) = @_;
	my (@ops, $name);

	$name = $elt->att('name');
	
	for my $child ($elt->children()) {
		if ($child->gi() eq 'field') {
			push (@ops, {type => 'field',
						 name => $child->att('name'),
						 direction => $child->att('direction')});
		}
		else {
			die "Invalid child for sort $name.\n";
		}
	}

	unless (@ops) {
		die "Empty sort $name.\n";
	}
	
	$elt->set_att('ops', \@ops);
	push @{$self->{stash}}, $elt;	
}

sub stash_handler {
	my ($self, $elt) = @_;

	push @{$self->{stash}}, $elt;
}

sub form_handler {
	my ($self, $elt) = @_;
	my ($name, %form);
	
	$name = $elt->att('name');
	
	$form{form} = $elt->atts();

	# flush elements from stash into form hash
	$self->stash_flush($elt, \%form);
		
	# add form to specification object
	$self->{spec}->form_add(\%form);
}

sub value_handler {
	my ($self, $elt) = @_;
	my (%value);

	$value{value} = $elt->atts();
	
	$self->{spec}->value_add(\%value);
}

sub i18n_handler {
	my ($self, $elt) = @_;
	my (%i18n);

	$i18n{value} = $elt->atts();
	
	$self->{spec}->i18n_add(\%i18n);
}

sub stash_flush {
	my ($self, $elt, $hashref) = @_;

	# examine stash
	for my $item_elt (@{$self->{stash}}) {
		# check whether we are really the parent
		if ($item_elt->parent() eq $elt) {
			push (@{$hashref->{$item_elt->gi()}}, $item_elt->atts());
		}
		else {
			warn "Misplace item in stash (" . $item_elt->gi() . "\n";
		}
	}

	# clear stash
	$self->{stash} = [];

	return;
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
