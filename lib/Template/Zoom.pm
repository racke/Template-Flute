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
use Rose::DB::Object::QueryBuilder qw(build_select);

use Template::Zoom::Query;

# Constructor

sub new {
	my ($class, $template) = @_;
	my ($self);

	$class = shift;

	$self = {template => $template};
	bless $self;
}

sub process {
	my ($self, $params) = @_;
	my ($dbref, $sth, $row);
	
	# determine database queries
	for my $list ($self->{template}->lists()) {
		# check for (required) input
		unless ($list->input()) {
			die "Input missing for " . $list->name . "\n";
		}
		
		$dbref = $list->query();
		$dbref->{dbh} = $self->{dbh};
		$dbref->{query_is_sql} = 1;

		# prepare and run database query
		my ($sql, $bind) = build_select(%$dbref);

		$sth = $dbref->{dbh}->prepare($sql);
		$sth->execute(@$bind);

		# process template
		my ($lel, %paste_pos);
		
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

		my ($row, $param, $key, $value, $rep_str, $att_name, $att_spec,
		   $att_tag_name, $att_tag_spec, %att_tags, $att_val);
		my $row_pos = 0;
		
		while ($row = $sth->fetchrow_hashref) {
			# now fill in params
			for $param (@{$list->params}) {
				$key = $param->{name};
				
				$rep_str = $row->{$value->{field} || $key};

				if ($value->{increment}) {
					$rep_str = $value->{increment}->value();
				}
				
				if ($value->{subref}) {
					$rep_str = $value->{subref}->($row);
				}
				
				if ($value->{filter}) {
					$rep_str = Vend::Tags->filter({op => $value->{filter}, body => $rep_str});
				}
				
				for my $elt (@{$value->{elts}}) {
					if ($elt->{zoom_rep_sub}) {
						# call subroutine to handle this element
						$elt->{zoom_rep_sub}->($elt, $rep_str);
					}
					elsif ($elt->{zoom_rep_att}) {
						# replace attribute instead of embedded text (e.g. for <input>)
						$elt->set_att($elt->{zoom_rep_att}, $rep_str);
					}
					elsif ($elt->{zoom_rep_elt}) {
						# use provided text element for replacement
						$elt->{zoom_rep_elt}->set_text($rep_str);
					}
					else {
						$elt->set_text($rep_str);
					}

					# replace attributes on request
					if ($value->{attributes}) {
						while (($att_name, $att_spec) = each %{$value->{attributes}}) {
							if (exists ($att_spec->{filter})) {
								# derive tags from current record
								if (exists ($att_spec->{filter_tags})) {
									while (($att_tag_name, $att_tag_spec) = each %{$att_spec->{filter_tags}}) {
										$att_tags{$att_tag_name} = $row->{$att_tag_spec};
									}
								}
								else {
									%att_tags = ();
								}
								
								$att_val = Vend::Interpolate::filter_value($att_spec->{filter}, undef, \%att_tags, $att_spec->{filter_args});
								$elt->set_att($att_name, $att_val);
							}
						}
					}
				}
			}
			
			$row_pos++;
			
			# now add to the template
			my $subtree = $lel->copy();

			# alternate classes?
#			if ($sref->{lists}->{$name}->[2]->{alternate}) {
#				my $idx = $row_pos % $sref->{lists}->{$name}->[2]->{alternate};
#				
#				$subtree->set_att('class', $sref->{lists}->{$name}->[1]->[$idx]);
#			}
#::logError("Paste pos: " . ::uneval(\%paste_pos));

			$subtree->paste(%paste_pos);

			# call increment functions
#			for my $inc (@{$sref->{increments}->{$name}->{array}}) {
#				$inc->{increment}->increment();
#			}
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
				
		return $self->{template}->{xml}->sprint;
	}
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
