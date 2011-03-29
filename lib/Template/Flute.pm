package Template::Flute;

use strict;
use warnings;

use Template::Flute::Utils;
use Template::Flute::Specification::XML;
use Template::Flute::HTML;
use Template::Flute::Iterator;

=head1 NAME

Template::Flute - Modern HTML Engine

=head1 VERSION

Version 0.0003

=cut

our $VERSION = '0.0003';

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

Templates are plain HTML files without inline code or mini language, thus
making it easy to maintain them for web designers and to preview them with
a browser.

The CSS selectors in the template are tied to your data structures or
objects by a specification, which relieves the programmer from changing
his code for mere changes of class names.

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

=item template_file

HTML template file.

=item database

L<Template::Flute::Database::Rose> object.

=item filters

Hash reference of filter functions.

=item i18n

L<Template::Flute::I18N> object.

=item values

Hash reference of values to be used by the process method.

=item auto_iterators

Builds iterators automatically from values.

=back

=cut

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
		unless ($self->{specification_file}) {
			# try to derive specification file name from template file name
			$self->{specification_file} = Template::Flute::Utils::derive_filename($self->{template_file}, '.xml');

			unless (-f $self->{specification_file}) {
				die "Missing Template::Flute specification for template $self->{template_file}\n";
			}
		}
			
		if ($parser_name = $self->{specification_parser}) {
			# load parser class
			my $class;
			
			if ($parser_name =~ /::/) {
				$class = $parser_name;
			}
			else {
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
		}
		else {
			$parser_spec = new Template::Flute::Specification::XML;
		}
		
		if ($spec_file = $self->{specification_file}) {
			unless ($self->{specification} = $parser_spec->parse_file($spec_file)) {
				die "$0: error parsing $spec_file: " . $parser_spec->error() . "\n";
			}
		}
		else {
			die "$0: Missing Template::Flute specification, template: $self->{template_file}.\n";
		}
	}

	my ($name, $iter);
	
	while (($name, $iter) = each %{$self->{iterators}}) {
		$self->{specification}->set_iterator($name, $iter);
	}
	
	if ($template_file = $self->{template_file}) {
		$template_object = new Template::Flute::HTML;
		$template_object->parse_file($template_file, $self->{specification});
		$self->{template} = $template_object;
	}
	else {
		die "$0: Missing Template::Flute template.\n";
	}
}

=head1 METHODS

=head2 process [HASHREF]

Processes HTML template and returns HTML output.

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
			$container->elt()->cut();
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
			if ($self->{database}) {
				if ($query = $list->query()) {
					$iter = $self->{database}->build($query);
					$iter->run();
				}
				else {
					die "$0: List " . $list->name . " without iterator and database query.\n";
				}
			}
			elsif ($self->{auto_iterators} &&
				   ($name = $list->iterator('name'))) {
				if (ref($self->{values}->{$name}) eq 'ARRAY') {
					$iter = Template::Flute::Iterator->new($self->{values}->{$name});
				}
				else {
					$iter = Template::Flute::Iterator->new([]);
				}
				$list->set_iterator($iter);
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
		$zref = $elt->{"flute_$name"};
			
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

=head2 filter FILTER VALUE

Runs the filter named FILTER on VALUE and returns the result.

=cut

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

=head2 value NAME

Returns the value for NAME.

=cut

sub value {
	my ($self, $value) = @_;
	my ($raw_value, $rep_str);
	
	if ($self->{scopes}) {
		if (exists $value->{scope}) {
			$raw_value = $self->{values}->{$value->{scope}}->{$value->{name}};
		}
		else {
			$raw_value = $self->{values}->{$value->{name}};
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

		if (exists $value->{op}) {
			if ($value->{op} eq 'toggle') {
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
			elsif ($value->{op} eq 'hook') {
				for my $elt (@elts) {
					Template::Flute::HTML::hook_html($elt, $self->value($value));
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

Returns HTML template object.

=cut

sub template {
	my $self = shift;

	return $self->{template};
}

=head2 specification

Returns specification object.

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

This container is only shown in the output if the value billing_address is set:

  <container name="billing" value="billing_address" class="billingWrapper">
  </container>

=item list

=item param

=item value

Value elements are replaced with a single value present in the values hash
passed to the constructor of this class or later set with the
L<set_values|/set_values_HASHREF> method.

The following operations are supported for value elements:

=over 4

=item hook

Insert HTML residing in value as subtree of the corresponding HTML element.
HTML will be parsed with L<XML::Twig>.

=item toggle

Only shows corresponding HTML element if value is set.

=back

=item input

=item filter

=item sort	

=item i18n

=back

=head1 ITERATORS

Template::Flute uses iterators to retrieve list elements and insert them into
the document tree. This abstraction relieves us from worrying about where
the data actually comes from. We basically just need an array of hash
references and an iterator class with a next and a count method. For your
convenience you can create an iterator from L<Template::Flute::Iterator>
class very easily.

=head1 LIST

L<Template::Flute::List>

=head1 FORMS

L<Template::Flute::Form>

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

=head1 HISTORY

Template::Flute was initially named Template::Zoom. I renamed the module because of
a request from Matt S. Trout, author of the L<HTML::Zoom> module.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2011 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
