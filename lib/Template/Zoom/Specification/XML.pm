# Template::Zoom::Specification::XML - Zoom XML Specification routines
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

package Template::Zoom::Specification::XML;

use strict;
use warnings;

use XML::Twig;

use Template::Zoom::Specification;

# Constructor

sub new {
	my ($class, $self);
	my (%params);

	$class = shift;
	%params = @_;

	$self = \%params;
	bless $self;
}

sub parse_file {
	my ($self, $file) = @_;
	my ($twig, $xml);

	# initialize stash
	$self->{stash} = [];
	
	# specification object
	$self->{spec} = new Template::Zoom::Specification;

	# twig parser object
	$twig = new XML::Twig (twig_handlers => {specification => sub {$self->spec_handler($_[1])},
											 list => sub {$self->list_handler($_[1])},
											 param => sub {$self->param_handler($_[1])},
											 input => sub {$self->input_handler($_[1])}});
	
	$xml = $twig->safe_parsefile($file);

	unless ($xml) {
		$self->add_error(file => $file, error => $@);
		return;
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
		
	# examine stash
	for my $item_elt (@{$self->{stash}}) {
		# check whether we are really the parent
		if ($item_elt->parent() eq $elt) {
			push (@{$list{$item_elt->gi()}}, $item_elt->atts());
		}
		else {
			warn "Misplace item in stash (" . $item_elt->gi() . "\n";
		}
	}

	# clear stash
	$self->{stash} = [];

	# add list to specification object
	$self->{spec}->list_add(\%list);
}

sub param_handler {
	my ($self, $elt) = @_;
	my ($name);

	$name = $elt->att('name');

	push @{$self->{stash}}, $elt;
}

sub input_handler {
	my ($self, $elt) = @_;
	my ($name);

	$name = $elt->att('name');

	push @{$self->{stash}}, $elt;
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
