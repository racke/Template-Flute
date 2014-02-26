package Template::Flute::HTML;

use strict;
use warnings;

use Encode;
use File::Slurp ();
use XML::Twig;
use HTML::Entities;

use Template::Flute::Increment;
use Template::Flute::Container;
use Template::Flute::List;
use Template::Flute::Form;
use Scalar::Util qw/blessed/;

=head1 NAME

Template::Flute::HTML - HTML Template Parser

=head1 SYNOPSIS

    $html_object = new Template::Flute::HTML;

    $html_object->parse('<div class="example">Hello world</div>');
    $html_object->parse_file($html_file, $spec);

=head1 CONSTRUCTOR

=head2 new

Create a Template::Flute::HTML object.

=cut

# constructor

sub new {
	my ($class, $self);

	$class = shift;

	$self = {containers => {}, lists => {}, pagings => {}, forms => {},
			 params => {}, values => {}, query => {}, file => undef};
	
	bless $self;
}

=head1 METHODS

=head2 containers

Returns list of L<Template::Flute::Container> objects for this template.

=cut

# containers method - return list of Template::Flute::Container objects for this# template

sub containers {
	my ($self) = @_;

	return values %{$self->{containers}};
}

=head2 container NAME

Returns container object named NAME.

=cut

sub container {
	my ($self, $name) = @_;

	if (exists $self->{containers}->{$name}) {
		return $self->{containers}->{$name};
	}
}

=head2 lists

Returns list of L<Template::Flute::List> objects for this template.

=cut

sub lists {
	my ($self) = @_;

	return values %{$self->{lists}};
}

=head2 list NAME

Returns list object named NAME.

=cut

# list method - returns specific list object
sub list {
	my ($self, $name) = @_;

	if (exists $self->{lists}->{$name}) {
		return $self->{lists}->{$name};
	}
}

=head2 forms
	
Returns list of L<Template::Flute::Form> objects for this template.

=cut

sub forms {
	my ($self) = @_;

	return values %{$self->{forms}};
}

=head2 form NAME

Returns form object named NAME.

=cut

# form method - returns specific form object
sub form {
	my ($self, $name) = @_;

	if (exists $self->{forms}->{$name}) {
		return $self->{forms}->{$name};
	}
}

=head2 values

Returns list of values for this template.

=cut

sub values {
	my ($self) = @_;

	return values %{$self->{values}};
}

=head2 iterators

Returns hash with iterator names as keys and iterator objects
as values.

=cut

sub iterators {
	my ($self) = @_;
	my (%iterators, $name, $object);

	for my $list (CORE::values %{$self->{lists}}) {
		$name = $list->iterator('name');
		next unless $name;
		$iterators{$name} = $list->iterator();
	}

	wantarray ? %iterators : \%iterators;
}

=head2 root

Returns root of HTML/XML tree.

=cut

# root method - returns root of HTML/XML tree
sub root {
	my ($self) = @_;

	return $self->{xml}->root();
}

=head2 translate I18NOBJECT

Localizes static text inside the HTML template through
the I18NOBJECT.

=cut

sub translate {
	my ($self, $i18n) = @_;
	my ($root, @text_elts, $i18n_ret, $parent_gi, $parent_i18n,
	    %parents, $text, $ws_before, $ws_after);

	$root = $self->root();

	@text_elts = $root->descendants('#TEXT');

	for my $elt (@text_elts) {
		$parent_gi = $elt->parent->gi();

		next if $parent_gi eq 'style'
            || $parent_gi eq 'script';
        
		$parent_i18n = $elt->parent->att('i18n-key');
		
		if ($parent_i18n) {
			$i18n_ret = $i18n->localize($parent_i18n);
		}
		else {
            $text = $elt->text;

            # remove surrounding whitespace before passing
            # to translation function
            if ($text =~ s/^(\s+)//s) {
                $ws_before = $1;
            }
            else {
                $ws_before = '';
            }

            if ($text =~ s/(\s+)$//s) {
                $ws_after = $1;
            }
            else {
                $ws_after = '';
            }

            # skip empty text
            next unless $text;
            
			$i18n_ret = $ws_before . $i18n->localize($text) . $ws_after;
		}

		$elt->set_text($i18n_ret);
	}

	# cleanup
	if ($self->{_i18n_key_elts}) {
	    for my $elt (@{$self->{_i18n_key_elts}}) {
		$elt->del_att('i18n-key');
	    }

	    delete $self->{_i18n_key_elts};
	}

	return;
}

=head2 file

Returns name of template file.

=cut

sub file {
	my $self = shift;
	
	return $self->{file};
}

=head2 parse [ STRING | SCALARREF ] SPECOBJECT

Parses HTML template from STRING or SCALARREF with the help
of a L<Template::Flute::Specification> object SPECOBJECT.

=cut

sub parse {
	my ($self, $template, $spec_object, $snippet) = @_;
	my ($object);
	
	if (ref($template) eq 'SCALAR') {
		$object = $self->_parse_template($template, $spec_object, $snippet);
	}
	else {
		$object = $self->_parse_template(\$template, $spec_object, $snippet);
	}

	return $object;
}

=head2 parse_file FILENAME SPECOBJECT

Parses HTML template from file FILENAME with the help
of a L<Template::Flute::Specification> object SPECOBJECT.

=cut
	
sub parse_file {
	my ($self, $template_file, $spec_object, $snippet) = @_;

	return $self->_parse_template($template_file, $spec_object, $snippet);
}

sub _parse_template {
	my ($self, $template, $spec_object, $snippet) = @_;
	my ($twig, %twig_args, $xml, $object, $list, $html_content, $encoding);

	$object = {specs => {}, lists => {}, forms => {}, params => {}};
		
	%twig_args = (twig_handlers => {_all_ => sub {$self->_parse_handler($_[1], $spec_object)}});

	if ($XML::Twig::VERSION > 3.39) {
	    $twig_args{output_html_doctype} = 1;
	}
	
	$twig = new XML::Twig (%twig_args);

	if (ref($template) eq 'SCALAR') {
		$self->{file} = '';
		$html_content = decode_entities($$template);
	}
	else {
		$self->{file} = $template;
		$encoding = $spec_object->encoding();
		$html_content = File::Slurp::read_file($template, binmode => ":encoding($encoding)");
		unless ($encoding eq 'utf8') {
			$html_content = encode('utf8', $html_content);
		}
	}
	$xml = $snippet ? $twig->safe_parse($html_content) : $twig->safe_parse_html($html_content);

	unless ($xml) {
		die "Invalid HTML template: $html_content: $@\n";
	}
	
	$xml = $twig->safe_parse_html($html_content);
        _fix_script_tags($xml);

	$self->{xml} = $object->{xml} = $xml;

	return $object;
}

# parse_handler - Callback for HTML elements

sub _parse_handler {
	my ($self, $elt, $spec_object) = @_;
	my ($gi, @classes, @static_classes, $class_names, $id, $elt_name, $name, $sob, $sob_ref);

	$gi = $elt->gi();
	$class_names = $elt->class();
	$id = $elt->id();
	$elt_name = $elt->att('name');

	# don't act on elements without class, id or name attribute
	return unless $class_names || $id || $elt_name;
	
	# weed out "static" classes
	if ($class_names) {
		for my $class (split(/\s+/, $class_names)) {
			if ($spec_object->elements_by_class($class)) {
				push @classes, $class;
			}
			else {
				push @static_classes, $class;
			}
		}
	}
	
	if ($id) {
        $sob_ref = $spec_object->elements_by_id($id);
        for my $sob (@$sob_ref) {
			$name = $sob->{name} || $id;
			$self->_elt_handler($sob, $elt, $gi, $spec_object, $name);
		}
	}

	if ($elt_name) {
	    $sob_ref = $spec_object->elements_by_name($elt_name);
	
	    for my $sob (@$sob_ref) {
		$name = $sob->{name} || $elt_name;
		$self->_elt_handler($sob, $elt, $gi, $spec_object, $name);
	    }
	}
	
	for my $class (@classes) {
		$sob_ref = $spec_object->elements_by_class($class);
		for my $sob (@$sob_ref) {
			$name = $sob->{name} || $class;
			$self->_elt_handler($sob, $elt, $gi, $spec_object, $name, \@static_classes);
		}
	}

	return $self;
}

sub _elt_handler {
	my ($self, $sob, $elt, $gi, $spec_object, $name, $static_classes) = @_;

	if ($sob->{type} eq 'container') {
	    if (exists $self->{containers}->{$name}) {
		push @{$self->{containers}->{$name}->{sob}->{elts}}, $elt;
	    }
	    else {
		$sob->{elts} = [$elt];
		$self->{containers}->{$name} = new Template::Flute::Container ($sob, $spec_object, $name);
	    }

	    return $self;
	}
	
	if ($sob->{type} eq 'list') {
		my $iter;
		
		if (exists $self->{lists}->{$name}) {
		    # record static classes
		    my ($list, $first_static, $first_classes);
		    
		    $list = $self->{lists}->{$name};

		    if ($first_static = $list->static_class(0)) {
			# remove static class from initial list element
			$first_classes = $list->elt->att('class');
			#$first_classes =~ s/\s*\b$first_static\b//;
			$list->elt->set_att('class', $first_classes);
		    }

		    $list->set_static_class(@$static_classes);
				
		    # discard repeated lists
		    $elt->cut();
		    return;
		}
			
		$sob->{elts} = [$elt];

		# weed out parameters which aren't descendants of list element
		for my $p (@{$self->{params}->{$name}->{array}}) {
			my @p_new;
			
			for my $p_elt (@{$p->{elts}}) {
				for my $a ($p_elt->ancestors()) {
					if ($a eq $elt) {
						push (@p_new, $p_elt);
						last;
					}
				}
			}

			$p->{elts} = \@p_new;
		}
		
		$self->{lists}->{$name} = new Template::Flute::List ($sob, [join(' ', @$static_classes)], $spec_object, $name);
		$self->{lists}->{$name}->params_add($self->{params}->{$name}->{array});
        $self->{lists}->{$name}->paging_add($self->{paging}->{$name});
		$self->{lists}->{$name}->separators_add($self->{separators}->{$name}->{array});
		$self->{lists}->{$name}->increments_add($self->{increments}->{$name}->{array});
			
		if (exists $sob->{iterator}) {
			if ($iter = $spec_object->iterator($sob->{iterator})) {
				$self->{lists}->{$name}->set_iterator($iter);
			}
		}

		if (exists $sob->{filter}) {
			$self->{lists}->{$name}->set_filter($sob->{filter});
		}
		
		return $self;
	}

	if ($sob->{type} eq 'separator') {
		push (@{$sob->{elts}}, $elt);
		$self->_elt_indicate_replacements($sob, $elt, $gi, $name, $spec_object);

		if (exists $self->{lists}->{$sob->{list}}) {
		    $self->{lists}->{$sob->{list}}->separators_add([$sob]);
		}
		else {
		    $self->{separators}->{$sob->{list}}->{hash}->{$name} = $sob;
		    push(@{$self->{separators}->{$sob->{list}}->{array}}, $sob);
		}
	}
    elsif ($sob->{type} eq 'paging') {
        # go through paging elements and record corresponding HTML elements
        for my $element_ref (CORE::values %{$sob->{elements}}) {
            if (exists $self->{paging_elements}->{$name}->{$element_ref->{type}}) {
                $element_ref->{elts} = $self->{paging_elements}->{$name}->{$element_ref->{type}}->{elts};
            }
        }

        push (@{$sob->{elts}}, $elt);
		$self->_elt_indicate_replacements($sob, $elt, $gi, $name, $spec_object);

        if (exists $self->{lists}->{$sob->{list}}) {
            $self->{lists}->{$sob->{list}}->paging_add($sob);
        }
        else {
		    $self->{paging}->{$sob->{list}} = $sob;
        }
    }
    
	if ($sob->{type} eq 'form') {
        # only HTML <form> elements can be tied to 'form'
        return $self if $elt->tag ne 'form';

		$sob->{elts} = [$elt];

		$self->{forms}->{$name} = new Template::Flute::Form ($sob);

		$self->{forms}->{$name}->fields_add($self->{fields}->{$name}->{array});
		$self->{forms}->{$name}->params_add($self->{params}->{$name}->{array});
			
		$self->{forms}->{$name}->inputs_add($spec_object->form_inputs($name));
			
		return $self;
	}
	
	if ($sob->{type} eq 'param') {
		push (@{$sob->{elts}}, $elt);

		$self->_elt_indicate_replacements($sob, $elt, $gi, $name, $spec_object);

		if ($sob->{increment}) {
			# create increment object and record it for increment updates
			my $inc = new Template::Flute::Increment (increment => $sob->{increment});
			
			$sob->{increment} = $inc;
			push(@{$self->{increments}->{$sob->{list}}->{array}}, $inc);
		}

		$self->{params}->{$sob->{list} || $sob->{form}}->{hash}->{$name} = $sob;
		push(@{$self->{params}->{$sob->{list} || $sob->{form}}->{array}}, $sob);
	} elsif ($sob->{type} eq 'separator') {
		push (@{$sob->{elts}}, $elt);
		$self->_elt_indicate_replacements($sob, $elt, $gi, $name, $spec_object);

		$self->{separators}->{$sob->{list}}->{hash}->{$name} = $sob;
		push(@{$self->{separators}->{$sob->{list}}->{array}}, $sob);
    } elsif ($sob->{type} eq 'element') {
        push (@{$sob->{elts}}, $elt);
		$self->_elt_indicate_replacements($sob, $elt, $gi, $name, $spec_object);
        $self->{paging_elements}->{$sob->{paging}}->{$sob->{element_type}} = $sob;
	} elsif ($sob->{type} eq 'value') {
		push (@{$sob->{elts}}, $elt);

		$self->_elt_indicate_replacements($sob, $elt, $gi, $name, $spec_object);
		
		$self->{values}->{$name} = $sob;
	} elsif ($sob->{type} eq 'field') {
         # HTML <form> elements can't be tied to 'field'
        return $self if $elt->tag eq 'form';
        
		# match for form field found in HTML
		push (@{$sob->{elts}}, $elt);

		if ($gi eq 'select') {
			if ($sob->{iterator}) {
				$elt->{"flute_$name"}->{rep_sub} = sub {
					_set_selected($_[0], $_[1],
								 $spec_object->resolve_iterator($sob->{iterator}),
								 $sob,
								 );
				};
			}
			else {
				$elt->{"flute_$name"}->{rep_sub} = \&_set_selected;
			}
		}
		push(@{$self->{fields}->{$sob->{form}}->{array}}, $sob);
	} elsif ($sob->{type} eq 'i18n') {

		$elt->set_att('i18n-key', $sob->{'key'});
		push(@{$self->{_i18n_key_elts}}, $elt);
	} else {
		return $self;
	}
}

# _elt_indicate_replacements - indicate location of replacements

sub _elt_indicate_replacements {
	my ($self, $sob, $elt, $gi, $name, $spec_object) = @_;
	my ($elt_text, $att_orig);
    
	if (exists $sob->{op}) {
		if ($sob->{op} eq 'hook') {
			$elt->{"flute_$name"}->{rep_sub} = \&hook_html;
			return;
		}
        elsif ($sob->{op} eq 'append' && ! $sob->{target}) {
            $elt->{"flute_$name"}->{rep_text_orig} = $elt->text_only;
            $elt->{"flute_$name"}->{rep_sub} = sub {
                my ($elt, $str) = @_;
				$str ||= '';
                $elt->set_text($elt->{"flute_$name"}->{rep_text_orig} . $str);
            };
        }
        elsif ($sob->{op} eq 'toggle' && exists $sob->{args}
               && $sob->{args} eq 'tree') {
            $elt->{"flute_$name"}->{rep_sub} = sub {
                my ($elt, $value) = @_;
                unless (defined $value && $value =~ /\S/) {
                    $elt->cut;
                }

                return;
            };
        }
	}
	
	if ($sob->{target}) {
		if (exists $sob->{op}) {
			if ($sob->{op} eq 'append') {
				# keep original value around
                $att_orig = $elt->att($sob->{target});

				$elt->{"flute_$name"}->{rep_att_orig} =
                    defined $att_orig ? $att_orig : '';
			}
		}
			
		$elt->{"flute_$name"}->{rep_att} = $sob->{target};
	} elsif ($gi eq 'img') {
		# replace src attribute instead of text
		$elt->{"flute_$name"}->{rep_att} = 'src';
	} elsif ($gi eq 'input') {
		my $type = $elt->att('type');
		# replace value attribute instead of text
		$elt->{"flute_$name"}->{rep_att} = 'value';
			
	} elsif ($gi eq 'select') {
		if ($sob->{iterator}) {
			$elt->{"flute_$name"}->{rep_sub} = sub {
				_set_selected($_[0], $_[1],
							  $spec_object->resolve_iterator($sob->{iterator}),
							  $sob,
							 );
			};
		} else {
			$elt->{"flute_$name"}->{rep_sub} = \&_set_selected;
		}
	} elsif (! $elt->contains_only_text()) {
		# contains real elements, so we have to be careful with
		# set text and apply it only to the first PCDATA element
		if ($elt_text = $elt->first_descendant('#PCDATA')) {
			$elt->{"flute_$name"}->{rep_elt} = $elt_text;
		}
	}
}

# _set_selected - Set selected value in a dropdown menu

sub _set_selected {
	my ($elt, $value, $iter, $sob) = @_;
	my (@children, $eltval, $optref, $cond);

	@children = $elt->children('option');
	
	if ($iter) {
		# remove existing children
		if (exists $sob->{keep} && $sob->{keep} eq 'empty_value') {
			$cond = 'option[@value=~/\S/]';
		}
		else {
			$cond = '';
		}
		
		$elt->cut_children($cond);
		
        # determine where to look for labels and values in the iterator
        my $value_k = "value";
        my $label_k = "label";
        if (exists $sob->{iterator_value_key} && $sob->{iterator_value_key}) {
            $value_k = $sob->{iterator_value_key};
        }
        if (exists $sob->{iterator_name_key} && $sob->{iterator_name_key}) {
            $label_k = $sob->{iterator_name_key};
        }

		# get options from iterator		
		$iter->reset();
		while ($optref = $iter->next()) {

            # check the record if is an object
            my $is_an_object = blessed($optref);

			my (%att, $text);
            my ($record_value, $record_label);

            if ($is_an_object) {
                # here we could also peek inside the object, but hey,
                # if it's an object the correct practise is not to
                # look inside it.
                if ($optref->can("$value_k")) {
                    $record_value = $optref->$value_k;
                }
                if ($optref->can("$label_k")) {
                    $record_label = $optref->$label_k;
                }
            }
            else {
                if (exists $optref->{$value_k}) {
                    $record_value = $optref->{$value_k};
                }
                if (exists $optref->{$label_k}) {
                    $record_label = $optref->{$label_k};
                }
            }

            if (defined $record_label) {
                $text = $record_label;
                $att{value} = $record_value;
            }
            else {
                $text = $record_value;
            }
            if (defined $value and
                defined $record_value and
                $record_value eq $value) {
                $att{selected} = 'selected';
            }
			
			$elt->insert_new_elt('last_child', 'option',
									 \%att, $text);
		}

        # reset iterator in case we use it multiple times
        $iter->reset;
	}
	else {
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
}

=head2 hook_html ELT VALUE

Parse HTML provided by VALUE and replace any children of ELT
with the result.

=cut
	
sub hook_html {
	my ($elt, $value) = @_;
	my ($parser, $html, $body, @children, @ret, $elt_hook);

	unless (defined $value && $value =~ /\S/) {
		return '';
	}
	
	$parser = new XML::Twig ();
	unless ($html = $parser->safe_parse("<xmlHook>".$value."</xmlHook>")) {
		die "Failed to parse HTML snippet: $@.\n";
	}
        _fix_script_tags($html);

	$elt->cut_children();

	@children = $html->root()->cut_children();
	
	for my $elt_hook (@children) {
		$elt_hook->paste(last_child => $elt);
	}
	
	return;
}

sub _fix_script_tags {
    my $parsed = shift;
    # script tags should not be escaped. Please note that this should
    # be safe. It affects only the *content* of the <script> tags. If
    # your values contains injected JS, having the & escaped as &amp;
    # or > as &gt; will not save you.
    my @elts = $parsed->get_xpath('//script');
    foreach my $el (@elts) {
        $el->set_asis;
    }
}

=head1 AUTHOR

Stefan Hornburg (Racke), <racke@linuxia.de>

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2014 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;

