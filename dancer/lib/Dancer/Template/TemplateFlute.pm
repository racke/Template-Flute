package Dancer::Template::TemplateFlute;

use strict;
use warnings;

use Template::Flute;
use Template::Flute::Iterator;
use Template::Flute::Utils;

use Dancer::Config;

use base 'Dancer::Template::Abstract';

our $VERSION = '0.0023';

=head1 NAME

Dancer::Template::TemplateFlute - Template::Flute wrapper for Dancer

=head1 VERSION

Version 0.0023

=head1 DESCRIPTION

This class is an interface between Dancer's template engine abstraction layer
and the L<Template::Flute> module.

In order to use this engine, use the template setting:

    template: template_flute

The default template extension is ".html".

=head2 ITERATORS

Iterators can be specified explicitly in the configuration file as below.

  engines:
    template_flute:
      iterators:
        fruits:
          class: JSON
          file: fruits.json

=head2 FILTER OPTIONS

Filter options and classes can be specified in the configuration file as below.

  engines:
    template_flute:
      filters:
        currency:
          options:
            int_curr_symbol: "$"
        image:
          class: "Flowers::Filters::Image"
    
=head1 METHODS

=head2 default_tmpl_ext

Returns default template extension.

=head2 render TEMPLATE TOKENS

Renders template TEMPLATE with values from TOKENS.

=cut

sub default_tmpl_ext {
	return 'html';
}

sub render ($$$) {
	my ($self, $template, $tokens) = @_;
	my (%args, $flute, $html, $name, $value, %parms, %template_iterators, %iterators, $class);

	%args = (template_file => $template,
		 scopes => 1,
		 auto_iterators => 1,
		 values => $tokens,
		 filters => $self->config->{filters},
	    );

	$flute = Template::Flute->new(%args);

	# process HTML template to determine iterators used by template
	$flute->process_template();

	# instantiate iterators where object isn't yet available
	if (%template_iterators = $flute->template()->iterators) {
	    my $selector;

		for my $name (keys %template_iterators) {
			if ($value = $self->config->{iterators}->{$name}) {
				%parms = %$value;
				
				$class = "Template::Flute::Iterator::$parms{class}";

				if ($parms{file}) {
					$parms{file} = Template::Flute::Utils::derive_filename($template,
																		   $parms{file}, 1);
				}

				if (($selector = delete $parms{selector})
				    && $tokens->{$selector}) {
				    $parms{selector} = {$selector => $tokens->{$selector}};
				}

				eval "require $class";
				if ($@) {
					die "Failed to load class $class for iterator $name: $@\n";
				}

				eval {
					$iterators{$name} = $class->new(%parms);
				};
				
				if ($@) {
					die "Failed to instantiate class $class for iterator $name: $@\n";
				}

				$flute->specification->set_iterator($name, $iterators{$name});
			}
		}
	}

	# check for forms
	my (@forms, $iter, $action);
	
	if (@forms = $flute->template->forms()) {
	    if (@forms == 1) {
		unless ($tokens->{form}) {
		    die "Missing form parameters for form " . $forms[0]->name;
		}
		    
		for my $name ($forms[0]->iterators) {
		    if (ref($tokens->{$name}) eq 'ARRAY') {
			$iter = Template::Flute::Iterator->new($tokens->{$name});
			$flute->specification->set_iterator($name, $iter);
		    }
		}

		$forms[0]->set_action($tokens->{form}->action());
		$tokens->{form}->fields([map {$_->{name}} @{$forms[0]->fields()}]);
		$forms[0]->fill($tokens->{form}->fill());

		if (Dancer::Config::settings->{session}) {
		    $tokens->{form}->to_session;
		}
	    }
	    else {
		die "Got multiple (", scalar(@forms), ") forms.";
	    }
	}
	
	$html = $flute->process();

	return $html;
}

=head1 SEE ALSO

L<Dancer>, L<Template::Flute>

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

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dancer-Template-TemplateFlute>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dancer-Template-TemplateFlute>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dancer-Template-TemplateFlute>

=item * Search CPAN

L<http://search.cpan.org/dist/Dancer-Template-TemplateFlute/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
