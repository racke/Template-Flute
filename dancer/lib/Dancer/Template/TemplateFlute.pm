package Dancer::Template::TemplateFlute;

use strict;
use warnings;

use Template::Flute;
use Template::Flute::Iterator;
use Template::Flute::Utils;

use Dancer::Config;

use base 'Dancer::Template::Abstract';

our $VERSION = '0.0061';

=head1 NAME

Dancer::Template::TemplateFlute - Template::Flute wrapper for Dancer

=head1 VERSION

Version 0.0061

=head1 DESCRIPTION

This class is an interface between Dancer's template engine abstraction layer
and the L<Template::Flute> module.

In order to use this engine, use the template setting:

    template: template_flute

The default template extension is ".html".

=head2 LAYOUT

Each layout needs a specification file and a template file. To embed
the content of your current view into the layout, put the following
into your specification file, e.g. F<views/layouts/main.xml>:

    <specification>
    <value name="content" id="content" op="hook"/>
    </specification>

This replaces the contents of the following block in your HTML
template, e.g. F<views/layouts/main.html>:

    <div id="content">
    Your content
    </div>

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

=head2 FORMS

Dancer::Template::TemplateFlute includes a form plugin L<Dancer::Plugin::Form>,
which supports L<Template::Flute> forms.

The token C<form> is reserved for forms. It can be a single
L<Dancer::Plugin::Form> object or an arrayref of
L<Dancer::Plugin::Form> objects.

=head3 Typical usage for a single form.

=head4 XML Specification

  <specification>
  <form name="registration" link="name">
  <field name="email"/>
  <field name="password"/>
  <field name="verify"/>
  </form>
  </specification>

=head4 HTML

  <form class="frm-default" name="registration" action="/register" method="POST">
	<fieldset>
	  <div class="reg-info">Info</div>
	  <ul>
		<li>
		  <label>Email</label>
		  <input type="text" name="email"/>
		</li>
		<li>
		  <label>Password</label>
		  <input type="text" name="password"/>
		</li>
		<li>
		  <label>Confirm password</label>
		  <input type="text" name="verify" />
		</li>
		<li>
		  <input type="submit" value="Register" class="btn-submit" />
		</li>
	  </ul>
	</fieldset>
  </form>

=head4 Code

  any [qw/get post/] => '/register' => sub {
      my $form = form('registration');
      my %values = %{$form->values};
      # VALIDATE, filter, etc. the values
      $form->fill(\%values);
      template register => {form => $form };
  };

=head3 Usage example for multiple forms

=head4 Specification

  <specification>
  <form name="registrationtest" link="name">
  <field name="emailtest"/>
  <field name="passwordtest"/>
  <field name="verifytest"/>
  </form>
  <form name="logintest" link="name">
  <field name="emailtest_2"/>
  <field name="passwordtest_2"/>
  </form>
  </specification>

=head4 HTML

  <h1>Register</h1>
  <form class="frm-default" name="registrationtest" action="/multiple" method="POST">
	<fieldset>
	  <div class="reg-info">Info</div>
	  <ul>
		<li>
		  <label>Email</label>
		  <input type="text" name="emailtest"/>
		</li>
		<li>
		  <label>Password</label>
		  <input type="text" name="passwordtest"/>
		</li>
		<li>
		  <label>Confirm password</label>
		  <input type="text" name="verifytest" />
		</li>
		<li>
		  <input type="submit" name="register" value="Register" class="btn-submit" />
		</li>
	  </ul>
	</fieldset>
  </form>
  <h1>Login</h1>
  <form class="frm-default" name="logintest" action="/multiple" method="POST">
	<fieldset>
	  <div class="reg-info">Info</div>
	  <ul>
		<li>
		  <label>Email</label>
		  <input type="text" name="emailtest_2"/>
		</li>
		<li>
		  <label>Password</label>
		  <input type="text" name="passwordtest_2"/>
		</li>
		<li>
		  <input type="submit" name="login" value="Login" class="btn-submit" />
		</li>
	  </ul>
	</fieldset>
  </form>


=head4 Code

  any [qw/get post/] => '/multiple' => sub {
      my $login = form('logintest');
      debug to_dumper({params});
      if (params->{login}) {
          my %vals = %{$login->values};
          # VALIDATE %vals here
          $login->fill(\%vals);
      }
      else {
          # pick from session
          $login->fill;
      }
      my $registration = form('registrationtest');
      if (params->{register}) {
          my %vals = %{$registration->values};
          # VALIDATE %vals here
          $registration->fill(\%vals);
      }
      else {
          # pick from session
          $registration->fill;
      }
      template multiple => { form => [ $login, $registration ] };
  };

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

				if ($selector = delete $parms{selector}) {
				    if ($selector eq '*') {
					$parms{selector} = '*';
                                    }
				    elsif ($tokens->{$selector}) {
					$parms{selector} = {$selector => $tokens->{$selector}};
				    }
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
    if (my @forms = $flute->template->forms()) {
        if ($tokens->{form}) {
            $self->_tf_manage_forms($flute, $tokens, @forms);
        }
        else {
            Dancer::Logger::debug('Missing form parameters for forms ' .
                                  join(", ", map { $_->name } @forms));
        }
    }
	$html = $flute->process();

	return $html;
}

sub _tf_manage_forms {
    my ($self, $flute, $tokens, @forms) = @_;

    # simple case: only one form passed and one in the flute
    if (ref($tokens->{form}) ne 'ARRAY') {
        my $form_name = $tokens->{form}->name;
        if (@forms == 1) {
            my $form = shift @forms;
            if ($form_name eq 'main' or
                $form_name eq $form->name) {
                # Dancer::Logger::debug("Filling the template form with" . Dumper($tokens->{form}->values));
                $self->_tf_fill_forms($flute, $tokens->{form}, $form, $tokens);
            }
        }
        else {
            my $found = 0;
            foreach my $form (@forms) {
                # Dancer::Logger::debug("Filling the template form with" . Dumper($tokens->{form}->values));
                if ($form_name eq $form->name) {
                    $self->_tf_fill_forms($flute, $tokens->{form}, $form, $tokens);
                    $found++;
                }
            }
            if ($found != 1) {
                Dancer::Logger::error("Multiple form are not being managed correctly, found $found corresponding forms, but we expected just one!")
              }
        }
    }
    else {
        foreach my $passed_form (@{$tokens->{form}}) {
            foreach my $form (@forms) {
                if ($passed_form->name eq $form->name) {
                    $self->_tf_fill_forms($flute, $passed_form, $form, $tokens);
                }
            }
        }
    }
}


sub _tf_fill_forms {
    my ($self, $flute, $passed_form, $form, $tokens) = @_;
    # arguments:
    # $flute is the template object.

    # $passed_form is the Dancer::Plugin::Form object we got from the
    # tokens, which is $tokens->{form} when we have just a single one.

    # $form is the form object we got from the template itself, with
    # $flute->template->forms

    # $tokens is the hashref passed to the template. We need it for the
    # iterators.

    my ($iter, $action);
    for my $name ($form->iterators) {
        if (ref($tokens->{$name}) eq 'ARRAY') {
            $iter = Template::Flute::Iterator->new($tokens->{$name});
            $flute->specification->set_iterator($name, $iter);
        }
    }
    if ($action = $passed_form->action()) {
        $form->set_action($action);
    }
    $passed_form->fields([map {$_->{name}} @{$form->fields()}]);
    $form->fill($passed_form->fill());

    if (Dancer::Config::settings->{session}) {
        $passed_form->to_session;
    }
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

Copyright 2011-2013 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
