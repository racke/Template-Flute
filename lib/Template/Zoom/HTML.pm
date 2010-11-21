# Template::Zoom::HTML - Zoom HTML template parser
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

package Template::Zoom::HTML;

use strict;
use warnings;

use Template::Zoom::Increment;
use Template::Zoom::List;
use Template::Zoom::Form;

# constructor

sub new {
	my ($class, $self);

	$class = shift;

	$self = {lists => {}, forms => {}, params => {}, query => {}};
	bless $self;
}

# lists method - return list of Template::Zoom::List objects for this template
sub lists {
	my ($self) = @_;

	return values %{$self->{lists}};
}

# forms method - return list of Template::Zoom::Form objects for this template
sub forms {
	my ($self) = @_;

	return values %{$self->{forms}};
}

sub parse_template {
	my ($self, $template, $spec_object) = @_;
	my ($twig, $xml, $object, $list);

	$object = {specs => {}, lists => {}, forms => {}, params => {}};
		
	$twig = new XML::Twig (twig_handlers => {_all_ => sub {$self->parse_handler($_[1], $spec_object)}});
	$xml = $twig->safe_parsefile_html($template);

	unless ($xml) {
		die "Invalid HTML template: $template: $@\n";
	}

	# examine list on alternates
	for my $name (keys %{$object->{lists}}) {
		$list = $object->{lists}->{$name};

		if (@{$list->[1]} > 1) {
			$list->[2]->{alternate} = @{$list->[1]};
		}
	}

	$self->{xml} = $object->{xml} = $xml;

	return $object;
}

# parse_handler - Callback for HTML elements

sub parse_handler {
	my ($self, $elt, $spec_object) = @_;
	my ($gi, @classes, @static_classes, $class_names, $id, $name, $sob);

	$gi = $elt->gi();
	$class_names = $elt->class();
	$id = $elt->id();
	
	# don't act on elements without class or id
	return unless $class_names || $id;
	
	# weed out "static" classes
	if ($class_names) {
		for my $class (split(/\s+/, $class_names)) {
			if ($spec_object->element_by_class($class)) {
				push @classes, $class;
			}
			else {
				push @static_classes, $class;
			}
		}
	}
	
	if ($id) {
		if ($sob = $spec_object->element_by_id($id)) {
			$name = $sob->{name} || $id;
			$self->elt_handler($sob, $elt, $gi, $spec_object, $name);
			return $self;
		}
	}

	for my $class (@classes) {
		$sob = $spec_object->element_by_class($class);
		$name = $sob->{name} || $class;
		$self->elt_handler($sob, $elt, $gi, $spec_object, $name, \@static_classes);
	}

	return $self;
}

sub elt_handler {
	my ($self, $sob, $elt, $gi, $spec_object, $name, $static_classes) = @_;
	my ($elt_text);

#	if ($sob->{permission}) {
#		unless (Vend::Tags->acl('check', $sob->{permission})) {
#			# no permission for this document part
#			$elt->cut();
#			return;
#		}
#	}
	
	if ($sob->{type} eq 'list') {
		my $iter;
		
		if (exists $self->{lists}->{$name}) {
			# record static classes
			push (@{$self->{lists}->{$name}->[1]}, join(' ', @$static_classes));
				
			# discard repeated lists
			$elt->cut();
			return;
		}
			
		$sob->{elts} = [$elt];

		$self->{lists}->{$name} = new Template::Zoom::List ($sob, [join(' ', @$static_classes)], $spec_object, $name);
		$self->{lists}->{$name}->params_add($self->{params}->{$name}->{array});
			
		if (exists $sob->{iterator}) {
			if ($iter = $spec_object->iterator($sob->{iterator})) {
				$self->{lists}->{$name}->set_iterator($iter);
			}
			else {
				die "$0: Iterator $sob->{iterator} not found.\n";
			}
				
		}
		return $self;
	}

	if (exists $sob->{list} && exists $self->{lists}->{$sob->{list}}) {
		return $self;
	}

	if ($sob->{type} eq 'form') {
		$sob->{elts} = [$elt];

		$self->{forms}->{$name} = new Template::Zoom::Form ($sob);
		$self->{forms}->{$name}->params_add($self->{params}->{$name}->{array});
			
		$self->{forms}->{$name}->inputs_add($spec_object->form_inputs($name));
			
		return $self;
	}
	
	if ($sob->{type} eq 'param') {
		push (@{$sob->{elts}}, $elt);

		if ($sob->{target}) {
			$elt->{"zoom_$name"}->{rep_att} = $sob->{target};
		}
		elsif ($gi eq 'input') {
			my $type = $elt->att('type');
			
			if (defined $type && $type eq 'checkbox') {
				$elt->{"zoom_$name"}->{rep_sub} = \&set_checked;
			}
			else {
				# replace value attribute instead of text
				$elt->{"zoom_$name"}->{rep_att} = 'value';
			}
		} elsif ($gi eq 'select') {
			$elt->{"zoom_$name"}->{rep_sub} = \&set_selected;
		} elsif (! $elt->contains_only_text()) {
			# contains real elements, so we have to be careful with
			# set text and apply it only to the first PCDATA element
			if ($elt_text = $elt->first_child('#PCDATA')) {
				$elt->{"zoom_$name"}->{rep_elt} = $elt_text;
			}
		}
			
		if ($sob->{sub}) {
			# determine code reference for named function
			my $subref = $Vend::Cfg->{Sub}{$sob->{sub}} || $Global::GlobalSub->{$sob->{sub}};

			if (exists $sob->{scope} && $sob->{scope} eq 'element') {
				$elt->{"zoom_$name"}->{rep_sub} = $subref;
			} else {
				$sob->{subref} = $subref;
			}
		}

		$self->{params}->{$sob->{list} || $sob->{form}}->{hash}->{$name} = $sob;
		push(@{$self->{params}->{$sob->{list} || $sob->{form}}->{array}}, $sob);
	} elsif ($sob->{type} eq 'increment') {
		# increments
		push (@{$sob->{elts}}, $elt);

		# create increment object and record it for increment updates
		$sob->{increment} = new Template::Zoom::Increment;
		push(@{$self->{increments}->{$sob->{list}}->{array}}, $sob);

		# record it for increment values
		$self->{params}->{$sob->{list}}->{hash}->{$name} = $sob;
	} elsif ($sob->{type} eq 'value') {
		push (@{$sob->{elts}}, $elt);
		$self->{values}->{$name} = $sob;
	} else {
		return $self;
	}
}

# set_checked - Set checked value in a checkbox/radio button
sub set_checked {
	my ($elt, $value) = @_;

	if ($value) {
		$elt->set_att('checked', 'checked');
	}
	else {
		$elt->del_att('checked', 'checked');
	}
	
	$elt->set_att('value', 1);
}

# set_selected - Set selected value in a dropdown menu

sub set_selected {
	my ($elt, $value) = @_;
	my (@children, $eltval);

	@children = $elt->children('option');

	for my $node (@children) {
		$eltval = $node->att('value');

		unless (length($eltval)) {
			$eltval = $node->text();
		}
		
		if ($eltval eq $value) {
			$node->set_att('selected', 'selected');
		}
		else {
			$node->del_att('selected', '');
		}
	}
}

1;

