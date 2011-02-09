# Template::Zoom - Template::Zoom main class
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

package Template::Zoom;

use strict;
use warnings;

use Template::Zoom::Specification::XML;
use Template::Zoom::HTML;

# Constructor

sub new {
	my ($class, $self);

	$class = shift;

	$self = {@_};
	bless $self;
}

sub _bootstrap {
	my ($self) = @_;
	my ($parser_name, $parser_spec, $spec_file, $spec, $template_file, $template_object);
	
	unless ($self->{specification}) {
		if ($parser_name = $self->{specification_parser}) {
			# load parser class
			my $class;
			
			if ($parser_name =~ /::/) {
				$class = $parser_name;
			}
			else {
				$class = "Template::Zoom::Specification::$parser_name";
			}

			eval "require $class";
			if ($@) {
				die "Failed to load class $class as specification parser: $@\n";
			}

			eval {
				$parser_spec = $class->new();
			};

			if ($@) {
				die "Failed to instantiate class $class as specification parser: $@\n";
			}
		}
		else {
			$parser_spec = new Template::Zoom::Specification::XML;
		}
		
		if ($spec_file = $self->{specification_file}) {
			unless ($self->{specification} = $parser_spec->parse_file($spec_file)) {
				die "$0: error parsing $spec_file: " . $parser_spec->error() . "\n";
			}
		}
		else {
			die "$0: Missing Template::Zoom specification.\n";
		}
	}

	my ($name, $iter);
	
	while (($name, $iter) = each %{$self->{iterators}}) {
		$self->{specification}->set_iterator($name, $iter);
	}
	
	if ($template_file = $self->{template_file}) {
		$template_object = new Template::Zoom::HTML;
		$template_object->parse_file($template_file, $self->{specification});
		$self->{template} = $template_object;
	}
	else {
		die "$0: Missing Template::Zoom template.\n";
	}
}

sub process {
	my ($self, $params) = @_;
	my ($dbobj, $iter, $sth, $row, $lel, %paste_pos, $query);

	unless ($self->{template}) {
		$self->_bootstrap();
	}
	
	if ($self->{i18n}) {
		# translate static text first
		$self->{template}->translate($self->{i18n});
	}

	# replace simple values
	$self->_replace_values();

	for my $container ($self->{template}->containers()) {
		if (exists $self->{values}) {
			$container->set_values($self->{values});
		}
		
		unless ($container->visible()) {
			$container->elt()->cut();
		}
	}
	
	# determine database queries
	for my $list ($self->{template}->lists()) {
		# check for (required) input
		unless ($list->input($params)) {
			die "Input missing for " . $list->name . "\n";
		}

		unless ($iter = $list->iterator()) {
			if ($self->{database}) {
				if ($query = $list->query()) {
					$iter = $self->{database}->build($query);
					$iter->run();
				}
				else {
					die "$0: List " . $list->name . " without iterator and database query.\n";
				}
			}
			else {
				die "$0: List " . $list->name . " without iterator and database object.\n";
			}
		}
		
		# process template
		$lel = $list->elt();

		if ($lel->is_last_child()) {			
			%paste_pos = (last_child => $lel->parent());
		}
		elsif ($lel->next_sibling()) {
			%paste_pos = (before => $lel->next_sibling());
		}
		else {
			# list is root element in the template
			%paste_pos = (last_child => $self->{template}->{xml});
		}
		
		$lel->cut();

		my ($row,);
		my $row_pos = 0;
		
		while ($row = $iter->next()) {
			if ($row = $list->filter($self, $row)) {
				$self->_replace_record($list, 'list', $lel, \%paste_pos, $row, $row_pos);
			
				$row_pos++;

				$list->increment();
			}
		}
	}

	for my $form ($self->{template}->forms()) {
		$lel = $form->elt();

		if ($lel->is_last_child()) {			
			%paste_pos = (last_child => $lel->parent());
		}
		elsif ($lel->next_sibling()) {
			%paste_pos = (before => $lel->next_sibling());
		}
		else {
			# list is root element in the template
			%paste_pos = (last_child => $self->{template}->{xml});
		}
		
		$lel->cut();
		
		if (keys(%{$form->inputs()}) && $form->input()) {
			$iter = $dbobj->build($form->query());

			$self->_replace_record($form, 'form', $lel, \%paste_pos, $iter->next());
		}		
		else {
			$self->_replace_record($form, 'form', $lel, \%paste_pos, {});
		}
	}

	return $self->{template}->{xml}->sprint;
}

sub _replace_within_elts {
	my ($self, $param, $rep_str) = @_;
	my ($name, $zref);

	for my $elt (@{$param->{elts}}) {
		$name = $param->{name};
		$zref = $elt->{"zoom_$name"};
			
		if ($zref->{rep_sub}) {
			# call subroutine to handle this element
			$zref->{rep_sub}->($elt, $rep_str);
		} elsif ($zref->{rep_att}) {
			# replace attribute instead of embedded text (e.g. for <input>)
			if (exists $param->{op} && $param->{op} eq 'append') {
				$elt->set_att($zref->{rep_att}, $zref->{rep_att_orig} . $rep_str);
			} elsif (exists $param->{op} && $param->{op} eq 'toggle') {
				if ($rep_str) {
					$elt->set_att($zref->{rep_att}, $rep_str);
				} else {
					$elt->del_att($zref->{rep_att});
				}
			} else {
				$elt->set_att($zref->{rep_att}, $rep_str);
			}
		} elsif ($zref->{rep_elt}) {
			# use provided text element for replacement
			$zref->{rep_elt}->set_text($rep_str);
		} else {
			$elt->set_text($rep_str);
		}
	}
}

sub _replace_record {
	my ($self, $container, $type, $lel, $paste_pos, $record, $row_pos) = @_;
	my ($param, $key, $filter, $rep_str, $att_name, $att_spec,
		$att_tag_name, $att_tag_spec, %att_tags, $att_val, $class_alt);

	# now fill in params
	for $param (@{$container->params}) {
		$key = $param->{name};
				
		$rep_str = $record->{$param->{field} || $key};

		if ($param->{increment}) {
			$rep_str = $param->{increment}->value();
		}
				
		if ($param->{subref}) {
			$rep_str = $param->{subref}->($record);
		}
				
		if ($param->{filter}) {
			$rep_str = $self->filter($param->{filter}, $rep_str);
		}

		$self->_replace_within_elts($param, $rep_str);	
	}
			
	# now add to the template
	my $subtree = $lel->copy();

	# alternate classes?
	if ($type eq 'list'
		&& ($class_alt = $container->static_class($row_pos))) {
		$subtree->set_att('class', $class_alt);
	}

	$subtree->paste(%$paste_pos);
}

sub filter {
	my ($self, $filter, $value) = @_;
	my ($rep_str);

	if (exists $self->{filters}->{$filter}) {
		$filter = $self->{filters}->{$filter};
		$rep_str = $filter->($value);
	}
	else {
		die "Missing filter $filter\n";
	}

	return $rep_str;
}

sub value {
	my ($self, $value) = @_;
	my ($raw_value, $rep_str);
	
	if ($self->{scopes}) {
		if (exists $value->{scope}) {
			$raw_value = $self->{values}->{$value->{scope}}->{$value->{name}};
		}
	}
	else {
		$raw_value = $self->{values}->{$value->{name}};
	}

	if ($value->{filter}) {
		$rep_str = $self->filter($value->{filter}, $raw_value);
	}
	else {
		$rep_str = $raw_value;
	}

	if (wantarray) {
		return ($raw_value, $rep_str);
	}
	
	return $rep_str;
}

sub _replace_values {
	my ($self) = @_;
	my ($value, $rep_str, @elts);
	
	for my $value ($self->{template}->values()) {
		@elts = @{$value->{elts}};

		if (exists $value->{op} && $value->{op} eq 'toggle') {
			my $raw;

			($raw, $rep_str) = $self->value($value);

			if (exists $value->{args} && $value->{args} eq 'static') {
				if ($rep_str) {
					# preserve static text
					next;
				}
			}
			
			unless ($raw) {
				# remove corresponding HTML elements from tree
				for my $elt (@elts) {
					$elt->cut();
				}
				next;
			}
		}
		else {
			$rep_str = $self->value($value);
		}

		$self->_replace_within_elts($value, $rep_str);
	}
}

sub set_values {
	my ($self, $values) = @_;

	$self->{values} = $values;
}

sub template {
	my $self = shift;

	return $self->{template};
}

1;
