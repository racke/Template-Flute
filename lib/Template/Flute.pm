package Template::Flute;

use strict;
use warnings;

use Template::Flute::Utils;
use Template::Flute::Specification::XML;
use Template::Flute::HTML;
use Template::Flute::Iterator;
use Template::Flute::Paginator;

=head1 NAME

Template::Flute - Modern designer-friendly HTML templating Engine

=head1 VERSION

Version 0.0062

=cut

our $VERSION = '0.0062';

=head1 SYNOPSIS

    use Template::Flute;

    my ($cart, $flute, %values);

    $cart = [{...},{...}];
    $values{cost} = ...

    $flute = new Template::Flute(specification_file => 'cart.xml',
                           template_file => 'cart.html',
                           iterators => {cart => $cart},
                           values => \%values,
                           );

    print $flute->process();

=head1 DESCRIPTION

Template::Flute enables you to completely separate web design and programming
tasks for dynamic web applications.

Templates are designed to be designer-friendly; there's no inline code or mini
templating language for your designers to learn - instead, standard HTML and CSS
classes are used, leading to HTML that can easily be understood and edited by
WYSIWYG editors and hand-coding designers alike.

An example is easier than a wordy description:

Given the following template snippet:

    <div class="customer_name">Mr A Test</div>
    <div class="customer_email">someone@example.com</div>

and the following specification:

   <specification name="example" description="Example">
        <value name="customer_name" />
        <value name="email" field="customer_email" />
    </specification>

Processing the above as follows:

    $flute = Template::Flute->new(
        template_file      => 'template.html',
        specification_file => 'spec.xml',
    );
    $flute->set_values({
        customer_name => 'Bob McTest',
        email => 'bob@example.com',
    });;
    print $flute->process;

The resulting output would be:

    <div class="customer_name">Bob McTest</div>
    <div class="email">bob@example.com</div>


In other words, rather than including a templating language within your
templates which your designers must master and which could interfere with
previews in WYSWYG tools, CSS selectors in the template are tied to your
data structures or objects by a specification provided by the programmer.


=head2 Workflow

The easiest way to use Template::Flute is to pass all necessary parameters to
the constructor and call the process method to generate the HTML.

You can also break it down in separate steps:

=over 4

=item 1. Parse specification

Parse specification based on your specification format (e.g with
L<Template::Flute::Specification::XML> or L<Template::Flute::Specification::Scoped>.).

    $xml_spec = new Template::Flute::Specification::XML;
    $spec = $xml_spec->parse(q{<specification name="cart" description="Cart">
         <list name="cart" class="cartitem" iterator="cart">
         <param name="name" field="title"/>
         <param name="quantity"/>
         <param name="price"/>
         </list>
         <value name="cost"/>
         </specification>});

=item 2. Parse template

Parse template with L<Template::Flute::HTML> object.

    $template = new Template::Flute::HTML;
    $template->parse(q{<html>
        <head>
        <title>Cart Example</title>
        </head>
        <body>
        <table class="cart">
        <tr class="cartheader">
        <th>Name</th>
        <th>Quantity</th>
        <th>Price</th>
        </tr>
        <tr class="cartitem">
        <td class="name">Sample Book</td>
        <td><input class="quantity" name="quantity" size="3" value="10"></td>
        <td class="price">$1</td>
        </tr>
        <tr class="cartheader"><th colspan="2"></th><th>Total</th>
        </tr>
        <tr>
        <td colspan="2"></td><td class="cost">$10</td>
        </tr>
        </table>
        </body></html>},
        $spec);

=item 3. Produce HTML output

    $flute = new Template::Flute(template => $template,
                               iterators => {cart => $cart},
                               values => {cost => '84.94'});
    $flute->process();

=back
	
=head1 CONSTRUCTOR

=head2 new

Create a Template::Flute object with the following parameters:

=over 4

=item specification_file

Specification file name.

=item specification_parser

Select specification parser. This can be either the full class name
like L<MyApp::Specification::Parser> or the last part for classes residing
in the Template::Flute::Specification namespace.

=item specification

Specification object or specification as string.

=item template_file

HTML template file.

=item template

L<Template::Flute::HTML> object or template as string.

=item database

L<Template::Flute::Database::Rose> object.

=item filters

Hash reference of filter functions.

=item i18n

L<Template::Flute::I18N> object.

=item iterators

Hash references of iterators.

=item values

Hash reference of values to be used by the process method.

=item auto_iterators

Builds iterators automatically from values.

=back

=cut

# Constructor

sub new {
	my ($class, $self, $filter_subs, $filter_opts, $filter_class, $filter_objects);

	$class = shift;

	$filter_subs = {};
	$filter_opts = {};
	$filter_class = {};
    $filter_objects = {};
    
	$self = {iterators => {}, @_, 
             _filter_subs => $filter_subs,
             _filter_opts => $filter_opts,
             _filter_class => $filter_class,
             _filter_objects => $filter_objects,
	};

	bless $self, $class;
	
	if (exists $self->{specification}
		&& ! ref($self->{specification})) {
		# specification passed as string
		$self->_bootstrap_specification('string', delete $self->{specification});
	}

	if (exists $self->{template}
		&& ! ref($self->{template})
		&& ref($self->{specification})) {
		$self->_bootstrap_template('string', delete $self->{template});
	}

	if (exists $self->{filters}) {
	    my ($name, $value);

	    while (($name, $value) = each %{$self->{filters}}) {
		if (ref($value) eq 'CODE') {
		    # passing subroutine
		    $filter_subs->{$name} = $value;
		    next;
		}
		if (exists($value->{class})) {
		    # record filter class
		    $filter_class->{$name} = $value->{class};
		}
		if (exists($value->{options})) {
		    # record filter options
		    $filter_opts->{$name} = $value->{options};
		}
	    }
	}

	return $self;
}

sub _bootstrap {
	my ($self) = @_;
	my ($parser_name, $parser_spec, $spec_file, $spec, $template_file, $template_object);
	
	unless ($self->{specification}) {
		unless ($self->{specification_file}) {
			# try to derive specification file name from template file name
			$self->{specification_file} = Template::Flute::Utils::derive_filename($self->{template_file}, '.xml');

			unless (-f $self->{specification_file}) {
				die "Missing Template::Flute specification for template $self->{template_file}\n";
			}
		}

		$self->_bootstrap_specification(file => $self->{specification_file});
	}

	$self->_bootstrap_template(file => $self->{template_file});
}

sub _bootstrap_specification {
	my ($self, $source, $specification) = @_;
	my ($parser_name, $parser_spec, $spec_file);
	
	if ($parser_name = $self->{specification_parser}) {
		# load parser class
		my $class;
			
		if ($parser_name =~ /::/) {
			$class = $parser_name;
		} else {
			$class = "Template::Flute::Specification::$parser_name";
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
	} else {
		$parser_spec = new Template::Flute::Specification::XML;
	}
	
	if ($source eq 'file') {
		unless ($self->{specification} = $parser_spec->parse_file($specification)) {
			die "$0: error parsing $specification: " . $parser_spec->error() . "\n";
		}
	}
	else {
		# text
		unless ($self->{specification} = $parser_spec->parse($specification)) {
			die "$0: error parsing $spec_file: " . $parser_spec->error() . "\n";
		}
	}

	
	my ($name, $iter);
	
	while (($name, $iter) = each %{$self->{iterators}}) {
		$self->{specification}->set_iterator($name, $iter);
	}
	
	return $self->{specification};
}

sub _bootstrap_template {
	my ($self, $source, $template) = @_;
	my ($template_object);

	$template_object = new Template::Flute::HTML;
	
	if ($source eq 'file') {
		$template_object->parse_file($template, $self->{specification});
		$self->{template} = $template_object;
	}
	elsif ($source eq 'string') {
		$template_object->parse($template, $self->{specification});
		$self->{template} = $template_object;
	}

	unless ($self->{template}) {
		die "$0: Missing Template::Flute template.\n";
	}

	return $self->{template};
}

=head1 METHODS

=head2 process [HASHREF]

Processes HTML template, manipulates the HTML tree based on the
specification, values and iterators.

Returns HTML output.

=cut

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
		    for my $elt (@{$container->elts()}) {
			$elt->cut();
		    }
		}
	}
	
	# determine database queries
	for my $list ($self->{template}->lists()) {
		my $name;
		
		# check for (required) input
		unless ($list->input($params)) {
			die "Input missing for " . $list->name . "\n";
		}

		unless ($iter = $list->iterator()) {
			if ($name = $list->iterator('name')) {
				# resolve iterator name to object
				if ($iter = $self->{specification}->iterator($name)) {
					$list->set_iterator($iter);
				}
				elsif (exists $self->{iterators}->{$name}) {
					# iterator name from method parameters
					$iter = $list->set_iterator($self->{iterators}->{$name});
				}
				elsif ($self->{auto_iterators}) {
					if (ref($self->{values}->{$name}) eq 'ARRAY') {
						$iter = Template::Flute::Iterator->new($self->{values}->{$name});
					}
					else {
						$iter = Template::Flute::Iterator->new([]);
					}
					$list->set_iterator($iter);
				}
				else {
					die "Missing iterator object for list " . $list->name . " and iterator name $name";
				}
			}
			elsif ($self->{database}) {
				if ($query = $list->query()) {
					$iter = $self->{database}->build($query);
					$iter->run();
				}
				else {
					die "List " . $list->name . " without iterator and database query.\n";
				}
			}
			else {
				die "List " . $list->name . " without iterator and database object.\n";
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

		my ($row, $sep_copy, $list_elt);
		my $row_pos = 0;
        
		my ($level_last, $level_val, @level_elts, @siblings, @level_stack);
        $level_last = 0;
        my $level_collect_sub;
        
        if ($list->{sob}->{level}) {
            # prepare function for flat trees
            $level_collect_sub = sub {
                my ($record, $list_elt) = @_;
                
                # register as sibling
                if ($record) {
                    $level_val =  $row->{$list->{sob}->{level}} || 0;
                    push (@{$siblings[$level_val]}, $list_elt);
                }
                else {
                    $level_val = 0;
                }
                
                if ($level_val < $level_last) {
                    # fill stack for tree manipulations
                    for my $ll ($level_last - 1 .. $level_val) {
                        unshift (@level_stack,
                                 {parent => $level_elts[$ll],
                                  children => [@{$siblings[$ll+1]}],
                                 });
                            
                        $siblings[$ll+1] = [];
                    }
                }

                if ($record) {
                    $level_elts[$level_val] = $list_elt;
                    $level_last = $level_val;
                }
            };
        }

        if ($list->{paging}) {
            # turn iterator into paginator
            my $page_size = $list->{paging}->{page_size} || 20;

            $iter = Template::Flute::Paginator->new(iterator => $iter,
                                                    page_size => $page_size);

            if ($iter->pages > 1) {
                my ($element_orig, $element_copy, %element_pos, $element_link,
                    $paging_page, $paging_link, $slide_length, $element, $element_active, $paging_min, $paging_max);

                $paging_page = $self->{values}->{$list->{paging}->{page_value}}  || 1;
                $paging_link = $self->{values}->{$list->{paging}->{link_value}};

                $slide_length = $list->{paging}->{slide_length};

                $paging_min = 1;
                $paging_max = $iter->pages;

                if ($slide_length > 0) {
                    # determine the page numbers to show up
                    if ($iter->pages > $slide_length) {
                        $paging_min = int($paging_page - $slide_length / 2);

                        if ($paging_min < 1) {
                            $paging_min = 1;
                        }

                        $paging_max = $paging_min + $slide_length - 1;
                    }
                }

                $iter->select_page($paging_page);

                for my $type (qw/first previous next last active standard/) {
                    if ($element = $list->{paging}->{elements}->{$type}) {
                        $element_orig = shift @{$element->{elts}};
                        next unless $element_orig;

                        # cut any other elements
                        for my $sf (@{$element->{elts}}) {
                            $sf->cut;
                        }
                    }
                    else {
                        next;
                    }

                    if ($element_orig->is_last_child()) {			
                        %element_pos = (last_child => $element_orig->parent());
                    }
                    elsif ($element_orig->next_sibling()) {
                        %element_pos = (before => $element_orig->next_sibling());
                    }
                    else {
                        die "Neither last child nor next sibling.";
                    }
                   
                    if ($element->{type} eq 'active') {
                        $element_active = $element_orig;
                    }
                    elsif ($element->{type} eq 'standard') {
                        for (1 .. $iter->pages) {
                            next if $_ < $paging_min || $_ > $paging_max;

                            if ($_ == $paging_page) {
                                # Move active element here
                                if ($element_active->{"flute_active"}->{rep_elt}) {
                                    $element_active->{"flute_active"}->{rep_elt}->set_text($_);
                                }
                                else {
                                    $element_active->set_text($_);
                                }

                                $element_copy = $element_active->cut;
                                $element_copy->paste(%element_pos);
                                next;
                            }

                            # Adjust text
                            if ($element_orig->{"flute_$element->{name}"}->{rep_elt}) {
                                $element_orig->{"flute_$element->{name}"}->{rep_elt}->set_text($_);
                            }
                            else {
                                $element_orig->set_text($_);
                            }

                            # Adjust link
                            if ($element_link = $element_orig->first_descendant('a')) {
                                $self->_paging_link($element_link, $paging_link, $_);
                            }

                            # Copy HTML element
                            $element_copy = $element_orig->copy;
                            $element_copy->paste(%element_pos);
                        }

                        $element_orig->cut;
                    }
                    elsif ($element->{type} eq 'first') {
                        if ($paging_page > 1) {
                            # Adjust link
                            if ($element_link = $element_orig->first_descendant('a')) {
                                $self->_paging_link($element_link, $paging_link, 1);
                            }
                        }
                        else {
                            $element_orig->cut;
                        }
                    }
                    elsif ($element->{type} eq 'last') {
                        if ($paging_page < $iter->pages) {
                            # Adjust link
                            if ($element_link = $element_orig->first_descendant('a')) {
                                $self->_paging_link($element_link, $paging_link, $iter->pages);
                            }
                        }
                        else {
                            $element_orig->cut;
                        }
                    }
                    elsif ($element->{type} eq 'next') {
                        if ($paging_page < $iter->pages) {
                            # Adjust link
                            if ($element_link = $element_orig->first_descendant('a')) {
                                $self->_paging_link($element_link, $paging_link, $paging_page + 1);
                            }
                        }
                        else {
                            $element_orig->cut;
                        }
                    }
                    elsif ($element->{type} eq 'previous') {
                        if ($paging_page > 1) {
                            # Adjust link
                            if ($element_link = $element_orig->first_descendant('a')) {
                                $self->_paging_link($element_link, $paging_link, $paging_page - 1);
                            }
                        }
                        else {
                            $element_orig->cut;
                        }
                    }
                }
            }
            else {
                # remove paging area
                for my $paging_elt (@{$list->{paging}->{elts}}) {
                    $paging_elt->cut;
                }
            }
        }

		while ($row = $iter->next()) {
			if ($row = $list->filter($self, $row)) {
				$list_elt = $self->_replace_record($list, 'list', $lel, \%paste_pos, $row, $row_pos);

                if ($list->{sob}->{level}) {
                    $level_collect_sub->($row, $list_elt);
                } 

       		$row_pos++;

				$list->increment();

				if ($list->separators()) {
				    for my $sep (@{$list->separators}) {
					for my $elt (@{$sep->{elts}}) {
					    $sep_copy = $elt->copy();
					    $sep_copy->paste(%paste_pos);
					}
				    }
				}
			}
		}

		if ($sep_copy) {
		    # remove last separator and original one(s) in the template
		    $sep_copy->cut();
		    
		    for my $sep (@{$list->separators}) {
			for my $elt (@{$sep->{elts}}) {
			    $elt->cut();
			}
		    }
		}

        # collect last element
        if ($list->{sob}->{level}) {
            $level_collect_sub->();

            for my $lref (@level_stack) {
                # create <ul> element and move inferior elements
                my $ul = $lref->{parent}->insert_new_elt('last_child', 'ul');

                for my $cref (@{$lref->{children}}) {
                    $cref->move(last_child => $ul);
                }
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

		if ($self->{auto_iterators}) {
			for my $iter_name ($form->iterators()) {
				if (ref($self->{values}->{$iter_name}) eq 'ARRAY') {
					$iter = Template::Flute::Iterator->new($self->{values}->{$iter_name});
				}
				else {
					$iter = Template::Flute::Iterator->new([]);
				}

				$self->{specification}->set_iterator($iter_name, $iter);
			}
		}
		
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

sub _paging_link {
    my ($self, $elt, $paging_link, $paging_page) = @_;
    my ($path, $uri);

    if (ref($paging_link) =~ /^URI::/) {
        # add to path
        $uri = $paging_link->clone;
        if ($paging_page == 1) {
            $uri->path(join('/', $paging_link->path));
        }
        else {
            $uri->path(join('/', $paging_link->path, $paging_page));
        }
        $path = $uri->as_string;
    }
    else {
        if ($paging_page == 1) {
            $path = "/$paging_link";
        }
        else {
            $path = "/$paging_link/$paging_page";
        }
    }

    $elt->set_att(href => $path);
}

sub _replace_within_elts {
	my ($self, $param, $rep_str, $elt_handler) = @_;
	my ($name, $zref);

	for my $elt (@{$param->{elts}}) {
	    if ($elt_handler) {
		$elt_handler->($elt, $rep_str);
		next;
	    }

		$name = $param->{name};
		$zref = $elt->{"flute_$name"};

        if (! $elt->parent && $elt->former_parent) {
            # paste back a formerly cut element
            my $pos;

            if (($pos = $elt->former_prev_sibling) && $pos->parent) {
                $elt->paste(after => $pos);
            }
            else {
                $elt->paste(first_child => $elt->former_parent);
            }
        }
        
		if ($zref->{rep_sub}) {
			# call subroutine to handle this element
			$zref->{rep_sub}->($elt, $rep_str);
		} elsif ($zref->{rep_att}) {
			# replace attribute instead of embedded text (e.g. for <input>)
			if (exists $param->{op} && $param->{op} eq 'append') {
			    if (exists $param->{joiner}) {
				$elt->set_att($zref->{rep_att}, $zref->{rep_att_orig} . $param->{joiner} . $rep_str);
			    }
			    else {
				$elt->set_att($zref->{rep_att}, $zref->{rep_att_orig} . $rep_str);
			    }
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
            if (exists $param->{op} && $param->{op} eq 'toggle') {
                unless ($rep_str) {
                    $elt->cut;
                }
            }
            else {
                $elt->set_text($rep_str);
            }
		}
	}
}

=head2 process_template

Processes HTML template and returns L<Template::Flute::HTML> object.

=cut

sub process_template {
	my ($self) = @_;
	
	unless ($self->{template}) {
		$self->_bootstrap();
	}

	return $self->{template};
}

sub _replace_record {
	my ($self, $container, $type, $lel, $paste_pos, $record, $row_pos) = @_;
	my ($param, $key, $filter, $rep_str, $att_name, $att_spec,
		$att_tag_name, $att_tag_spec, %att_tags, $att_val, $class_alt, $elt_handler);

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
				
		if ($param->{value}) {
		    if ($rep_str) {
			$rep_str = $param->{value};
		    }
		    else {
			$rep_str = '';
		    }
		}

		if ($param->{filter}) {
			$rep_str = $self->filter($param, $rep_str);
		}

		unless (defined $rep_str) {
			$rep_str = '';
		}

		if (ref($param->{op}) eq 'CODE') {
		    $self->_replace_within_elts($param, $rep_str, $param->{op});
		}
		else {
		    $self->_replace_within_elts($param, $rep_str);
		}
	}
			
	# now add to the template
	my $subtree = $lel->copy();

	# alternate classes?
	if ($type eq 'list'
		&& ($class_alt = $container->static_class($row_pos))) {
	    if ($att_val = $subtree->att('class')) {
		$subtree->set_att('class', "$att_val $class_alt");
	    }
	    else {
		$subtree->set_att('class', $class_alt);	    
	    }
	}

	$subtree->paste(%$paste_pos);
    return $subtree;
}

=head2 filter ELEMENT VALUE

Runs the filter used by ELEMENT on VALUE and returns the result.

=cut

sub filter {
	my ($self, $element, $value) = @_;
	my ($name, @filters);

	$name = $element->{filter};

    @filters = grep {/\S/} split(/\s+/, $name);

    if (@filters > 1) {
        # chain filters
        for my $f_name (@filters) {
            $value = $self->_filter($f_name, $element, $value);
        }

        return $value;
    }
    else {
        return $self->_filter($name, $element, $value);
    }
}

sub _filter {
    my ($self, $name, $element, $value) = @_;
	my ($filter, $mod_name, $class, $filter_obj, $filter_sub);

    if (exists $self->{_filter_subs}->{$name}) {
        $filter = $self->{_filter_subs}->{$name};
        return $filter->($value);
    }
    
    unless (exists $self->{_filter_objects}->{$name}) {
        # try to bootstrap filter
	    unless ($class = $self->{_filter_class}->{$name}) {
            $mod_name = join('', map {ucfirst($_)} split(/_/, $name));
            $class = "Template::Flute::Filter::$mod_name";
	    }

	    eval "require $class";

	    if ($@) {
            die "Missing filter $name: $@\n";
	    }

	    eval {
            $filter_obj = $class->new(options => $self->{_filter_opts}->{$name});
	    };

	    if ($@) {
            die "Failed to instantiate filter class $class: $@\n";
	    }

        $self->{_filter_objects}->{$name} = $filter_obj;
    }

    $filter_obj = $self->{_filter_objects}->{$name};
    
    if ($filter_obj->can('twig')) {
		$element->{op} = sub {$filter_obj->twig(@_)};
    }

    return $filter_obj->filter($value);
}

=head2 value NAME

Returns the value for NAME.

=cut

sub value {
	my ($self, $value) = @_;
	my ($raw_value, $ref_value, $rep_str);

	$ref_value = $self->{values};
	
	if ($self->{scopes}) {
		if (exists $value->{scope}) {
			$ref_value = $self->{values}->{$value->{scope}};
		}
	}

	if (exists $value->{include}) {
		my (%args, $include_file);

		if ($self->{template_file}) {
			$include_file = Template::Flute::Utils::derive_filename
				($self->{template_file}, $value->{include}, 1,
				 pass_absolute => 1);
		}
		else {
			$include_file = $value->{include};
		}
		
		# process template and include it
		%args = (template_file => $include_file,
			 auto_iterators => $self->{auto_iterators},
             filters => $self->{filters},
			 values => $self->{values});
		
		$raw_value = Template::Flute->new(%args)->process();
	}
	elsif (exists $value->{field}) {
        if (ref($value->{field}) eq 'ARRAY') {
            my $lookup;

            $raw_value = $ref_value;

            for $lookup (@{$value->{field}}) {
                if (ref($raw_value)
                    && exists $raw_value->{$lookup}) {
                    $raw_value = $raw_value->{$lookup};
                }
                else {
                    $raw_value = '';
                    last;
                }
            }

            if (ref $raw_value) {
                # second case: don't pass back stringified reference
                $raw_value = '';
            }
        }
        else {
            $raw_value = $ref_value->{$value->{field}};
        }
	}
	else {
		$raw_value = $ref_value->{$value->{name}};
	}

	if ($value->{filter}) {
		$rep_str = $self->filter($value, $raw_value);
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
	my ($value, $raw, $rep_str, @elts, $elt_handler);

	for my $value ($self->{template}->values()) {
		@elts = @{$value->{elts}};
        $elt_handler = undef;

		# determine value used for replacements
		($raw, $rep_str) = $self->value($value);

		if (exists $value->{op}) {
            if ($value->{op} eq 'append' && ! $value->{target}) {
                $elt_handler = sub {
                    my ($elt, $str) = @_;

                    $elt->set_text($elt->text_only . $str);
                };
            }
		    elsif ($value->{op} eq 'toggle') {
                if (exists $value->{args} && $value->{args} eq 'static') {
                    if ($rep_str) {
                        # preserve static text
                        next;
                    }
                }
                elsif ($rep_str) {
                    for my $elt (@elts) {
                        $elt->set_text($rep_str);
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
		    elsif ($value->{op} eq 'hook') {
                for my $elt (@elts) {
                    Template::Flute::HTML::hook_html($elt, $rep_str);
                }
                next;
		    }
		    elsif (ref($value->{op}) eq 'CODE') {
                $elt_handler = $value->{op};
		    }
		}
		else {
			$rep_str = $self->value($value);
		}

		unless (defined $rep_str) {
			$rep_str = '';
		}

		$self->_replace_within_elts($value, $rep_str, $elt_handler);
	}
}

=head2 set_values HASHREF

Sets hash reference of values to be used by the process method.
Same as passing the hash reference as values argument to the
constructor.

=cut

sub set_values {
	my ($self, $values) = @_;

	$self->{values} = $values;
}

=head2 template

Returns HTML template object, see L<Template::Flute::HTML> for
details.

=cut

sub template {
	my $self = shift;

	return $self->{template};
}

=head2 specification

Returns specification object, see L<Template::Flute::Specification> for
details.

=cut

sub specification {
	my $self = shift;

	return $self->{specification};
}

=head1 SPECIFICATION

The specification ties the elements in the HTML template to the data
(variables, lists, forms) which is added to the template.

The default format for the specification is XML implemented by the
L<Template::Flute::Specification::XML> module. You can use the Config::Scoped
format implemented by L<Template::Flute::Specification::Scoped> module or
write your own specification parser class.

Possible elements in the specification are:

=over 4

=item container

The first container is only shown in the output if the value C<billing_address> is set:

  <container name="billing" value="billing_address" class="billingWrapper">
  </container>

The second container is shown if the value C<warnings> or the value C<errors> is set:

  <container name="account_errors" value="warnings|errors" class="infobox">
  <value name="warnings"/>
  <value name="errors"/>
  </container>

=item list

=item separator

Separator elements for list are added after any list item in the output with
the exception of the last one.

Example specification, HTML template and output:

  <specification>
  <list name="list" iterator="tokens">
  <param name="key"/>
  <separator name="sep"/>
  </list>
  </specification>

  <div class="list"><span class="key">KEY</span></div><span class="sep"> | </span>

  <div class="list"><span class="key">FOO</span></div><span class="sep"> | </span>
  <div class="list"><span class="key">BAR</span></div>

=item param

Param elements are replaced with the corresponding value from the list iterator.

The following operations are supported for param elements:

=over 4

=item append
 
Appends the param value to the text found in the HTML template.

=item toggle

Only shows corresponding HTML element if param value is set.

=back

Other attributes for param elements are:

=over 4

=item filter

Applies filter to param value.

=item increment

Uses value from increment instead of a value from the iterator.

    <param name="pos" increment="1">

=back

=item value

Value elements are replaced with a single value present in the values hash
passed to the constructor of this class or later set with the
L<set_values|/set_values_HASHREF> method.

The following operations are supported for value elements:

=over 4

=item append

Appends the value to the text found in the HTML template.

=item hook

Insert HTML residing in value as subtree of the corresponding HTML element.
HTML will be parsed with L<XML::Twig>. See L</INSERT HTML> for an example.

=item toggle

Only shows corresponding HTML element if value is set.

=back

Other attributes for value elements are:

=over 4

=item filter

Applies filter to value.

=item include

Processes the template file named in this attribute. This implies
the hook operation.

=back

=item form

Form elements are tied through specification to HTML forms.
Attributes for form elements in addition to C<class> and C<id> are:

=over 4

=item link

The link attribute can only have the value C<name> and allows to
base the relationship between form specification elements and HTML
form tags on the name HTML attribute instead of C<class>, which
is usually more convenient.

=back

=item input

=item filter

=item sort	

=item i18n

=back

=head1 CONDITIONALS

=head2 Display image only if present

In this example we want to show an image only on
a certain condition:

HTML:

    <span class="banner-box">
        <img class="banner" src=""/>
    </span>

XML:

    <container name="banner-box" value="banner">
        <value name="banner" target="src"/>
    </container>

Source code:

    if ($organization eq 'Big One') {
        $values{banner} = 'banners/big_one.png';
    }

=head2 Display link in a list only if present

In this example we want so show a link only if
an URL is available:

HTML:

    <div class="linklist">
        <span class="name">Name</span>
        <div class="link">
            <a href="#" class="url">Goto ...</a>
        </div>
    </div>

XML:

    <specification name="link">
        <list name="links" class="linklist" iterator="links">
            <param name="name"/>
            <param name="url" target="href"/>
            <param name="link" field="url" op="toggle" args="tree"/>
        </list>
    </specification>

Source code:

   @records = ({name => 'Link', url => 'http://localhost/'},
               {name => 'No Link'},
               {name => 'Another Link', url => 'http://localhost/'},
              );

   $flute = Template::Flute->new(specification => $spec_xml,
                                 template => $template,
                                 iterators => {links => \@records});

   $output = $flute->process();

=head1 ITERATORS

Template::Flute uses iterators to retrieve list elements and insert them into
the document tree. This abstraction relieves us from worrying about where
the data actually comes from. We basically just need an array of hash
references and an iterator class with a next and a count method. For your
convenience you can create an iterator from L<Template::Flute::Iterator>
class very easily.

=head2 DROPDOWNS

Iterators can be used for dropdowns (HTML <select> elements) as well.

Template:

    <select class="color"></select>

Specification:

    <value name="color" iterator="colors"/>

Code:

    @colors = ({value => 'red', label => 'Red'},
               {value => 'black', label => 'Black'});

    $flute = Template::Flute->new(template => $html,
                              specification => $spec,
                              iterators => {colors => \@colors},
                              values => {color => 'black'},
                             );

HTML output:

      <select class="color">
      <option value="red">Red</option>
      <option value="black" selected="selected">Black</option>
      </select>

=head1 LISTS

Lists can be accessed after parsing the specification and the HTML template
through the HTML template object:

    $flute->template->lists();

    $flute->template->list('cart');

Only lists present in the specification and the HTML template can be
addressed in this way.

See L<Template::Flute::List> for details about lists.

=head1 FORMS

Forms can be accessed after parsing the specification and the HTML template
through the HTML template object:

    $flute->template->forms();

    $flute->template->form('edit_content');

Only forms present in the specification and the HTML template can be
addressed in this way.

See L<Template::Flute::Form> for details about forms.

=head1 FILTERS

Filters are used to change the display of value and param elements in
the resulting HTML output:

    <value name="billing_address" filter="eol"/>

    <param name="price" filter="currency"/>

The following filters are included:

=over 4

=item upper

Uppercase filter, see L<Template::Flute::Filter::Upper>.

=item strip

Strips whitespace at the beginning at the end,
see L<Template::Flute::Filter::Strip>.

=item eol

Filter preserving line breaks, see L<Template::Flute::Filter::Eol>.

=item nobreak_single

Filter replacing missing text with no-break space,
see L<Template::Flute::Filter::NobreakSingle>.

=item currency

Currency filter, see L<Template::Flute::Filter::Currency>.
Requires L<Number::Format> module.

=item date

Date filter, see L<Template::Flute::Filter::Date>.
Requires L<DateTime> and L<DateTime::Format::ISO8601> modules.

=item country_name

Country name filter, see L<Template::Flute::Filter::CountryName>.
Requires L<Locales> module.

=item language_name

Language name filter, see L<Template::Flute::Filter::LanguageName>.
Requires L<Locales> module.

=item json_var

JSON to Javascript variable filter, see L<Template::Flute::Filter::JsonVar>.
Requires L<JSON> module.

=back

Filter classes are loaded at runtime for efficiency and to keep the
number of dependencies for Template::Flute as small as possible.

See above for prerequisites needed by the included filter classes.

=head2 Chained Filters

Filters can also be chained:

    <value name="note" filter="upper eol"/>

Example template:

    <div class="note">
        This is a note.
    </div>

With the following value:

    Update now!
    Avoid security hazards!

The HTML output would look like:

    <div class="note">
    UPDATE NOW!<br />
    AVOID SECURITY HAZARDS!
    </div>

=head1 INSERT HTML AND INCLUDE FILES

=head2 INSERT HTML

HTML can be generated in the code or retrieved from a database
and inserted into the template through the C<hook> operation:

    <value name="description" op="hook"/>

The result replaces the inner HTML of the following C<div> tag:

    <div class="description">
        Sample content
    </div>

=head2 INCLUDE FILES

Files, especially components for web pages can be processed and included
through value elements with the include attribute:

    <value name="sidebar" include="component.html"/>

The result replaces the inner HTML of the following C<div> tag:

    <div class="sidebar">
        Sample content
    </div>

=head1 AUTHOR

Stefan Hornburg (Racke), <racke@linuxia.de>

=head1 BUGS

Please report any bugs or feature requests to C<bug-template-flute at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Flute>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Template::Flute

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Template-Flute>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Template-Flute>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Template-Flute>

=item * Search CPAN

L<http://search.cpan.org/dist/Template-Flute/>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to David Previous (bigpresh) for writing a much clearer introduction for
Template::Flute.

Thanks to Ton Verhagen for being a big supporter of my projects in all aspects.

Thanks to Terrence Brannon for spotting a documentation mix-up.

=head1 HISTORY

Template::Flute was initially named Template::Zoom. I renamed the module because of
a request from Matt S. Trout, author of the L<HTML::Zoom> module.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2013 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
