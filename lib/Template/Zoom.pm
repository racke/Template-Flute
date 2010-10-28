# Template::Zoom - Template::Zoom main class
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

package Template::Zoom;

use strict;
use warnings;

use Rose::DB;

use Template::Zoom::Query;
use Template::Zoom::Database::Rose;
use Template::Zoom::Specification::XML;
use Template::Zoom::HTML;

# Constructor

sub new {
	my ($class, $self);

	$class = shift;

	$self = {@_};
	bless $self;
}

sub bootstrap {
	my ($self) = @_;
	my ($xml_file, $xml_spec, $spec, $template_file, $template_object);
	
	unless ($self->{specification}) {
		if ($xml_file = $self->{specification_file}) {
			$xml_spec = new Template::Zoom::Specification::XML;

			unless ($self->{specification} = $xml_spec->parse_file($xml_file)) {
				die "$0: error parsing $xml_file: " . $xml_spec->error() . "\n";
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
		$template_object->parse_template($template_file, $self->{specification});
		$self->{template} = $template_object;
	}
	else {
		die "$0: Missing Template::Zoom template.\n";
	}
}

sub process {
	my ($self, $params) = @_;
	my ($dbobj, $iter, $sth, $row, $lel, %paste_pos);

	if ($self->{dbh}) {
		# create database object
		$dbobj = new Template::Zoom::Database::Rose (dbh => $self->{dbh});
	};

	unless ($self->{template}) {
		$self->bootstrap();
	}
	
	# determine database queries
	for my $list ($self->{template}->lists()) {
		# check for (required) input
		unless ($list->input($params)) {
			die "Input missing for " . $list->name . "\n";
		}

		unless ($iter = $list->iterator()) {
			if ($dbobj) {
				$iter = new Template::Zoom::Iterator::Rose(dbh => $self->{dbh},
														   query => $list->query());
				$iter->build();
				$iter->run();
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
			$self->replace_record($list, $lel, \%paste_pos, $row);
			
			$row_pos++;
		}

		# replacements for simple values
#		while (($key, $value) = each %{$sref->{values}}) {
#			for my $elt (@{$value->{elts}}) {
#				if ($value->{scope} eq 'scratch') {
#					$rep_str = $::Scratch->{$key};
#				}
#				else {
#					$rep_str = $value->{value};
#				}
#				
#				if ($value->{filter}) {
#					$rep_str = Vend::Tags->filter({op => $value->{filter}, body => $rep_str});
#				}
#				
#				$elt->set_text($rep_str);
#			}
#		}
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
		
		if ($form->input()) {
			$iter = $dbobj->build($form->query());

			$self->replace_record($form, $lel, \%paste_pos, $iter->next());
		}
		else {
			$lel->copy();
		}
	}
			
	return $self->{template}->{xml}->sprint;
}

sub replace_record {
	my ($self, $list, $lel, $paste_pos, $record) = @_;
	my ($param, $key, $rep_str, $att_name, $att_spec,
		$att_tag_name, $att_tag_spec, %att_tags, $att_val);
	
	# now fill in params
	for $param (@{$list->params}) {
		$key = $param->{name};
				
		$rep_str = $record->{$param->{field} || $key};

		if ($param->{increment}) {
			$rep_str = $param->{increment}->value();
		}
				
		if ($param->{subref}) {
			$rep_str = $param->{subref}->($record);
		}
				
		if ($param->{filter}) {
			$rep_str = Vend::Tags->filter({op => $param->{filter}, body => $rep_str});
		}

		for my $elt (@{$param->{elts}}) {
			if ($elt->{zoom_rep_sub}) {
				# call subroutine to handle this element
				$elt->{zoom_rep_sub}->($elt, $rep_str);
			} elsif ($elt->{zoom_rep_att}) {
				# replace attribute instead of embedded text (e.g. for <input>)
				$elt->set_att($elt->{zoom_rep_att}, $rep_str);
			} elsif ($elt->{zoom_rep_elt}) {
				# use provided text element for replacement
				$elt->{zoom_rep_elt}->set_text($rep_str);
			} else {
				$elt->set_text($rep_str);
			}

			# replace attributes on request
			if ($param->{attributes}) {
				while (($att_name, $att_spec) = each %{$param->{attributes}}) {
					if (exists ($att_spec->{filter})) {
								# derive tags from current record
						if (exists ($att_spec->{filter_tags})) {
							while (($att_tag_name, $att_tag_spec) = each %{$att_spec->{filter_tags}}) {
								$att_tags{$att_tag_name} = $record->{$att_tag_spec};
							}
						} else {
							%att_tags = ();
						}
								
						$att_val = Vend::Interpolate::filter_value($att_spec->{filter}, undef, \%att_tags, $att_spec->{filter_args});
						$elt->set_att($att_name, $att_val);
					}
				}
			}
		}
	}
			
	# now add to the template
	my $subtree = $lel->copy();

	# alternate classes?
	#			if ($sref->{lists}->{$name}->[2]->{alternate}) {
	#				my $idx = $row_pos % $sref->{lists}->{$name}->[2]->{alternate};
	#				
	#				$subtree->set_att('class', $sref->{lists}->{$name}->[1]->[$idx]);
	#			}
	#::logError("Paste pos: " . ::uneval(\%paste_pos));

	$subtree->paste(%$paste_pos);

	# call increment functions
	#			for my $inc (@{$sref->{increments}->{$name}->{array}}) {
	#				$inc->{increment}->increment();
	#			}
}

	sub database {
		my ($self, $dbconf) = @_;
	
		Rose::DB->register_db(domain => 'default',
							  type => 'default',
							  driver => $dbconf->{dbtype},
							  database => $dbconf->{dbname},
							  username => $dbconf->{dbuser},
							  password => $dbconf->{dbpass},
							 );

		$self->{rose} = new Rose::DB;
		$self->{dbh} = $self->{rose}->dbh() or die $self->{rose}->error();
	}

1;
