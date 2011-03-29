package Dancer::Template::TemplateFlute;

use strict;
use warnings;

use Template::Flute;

use base 'Dancer::Template::Abstract';

our $VERSION = '0.0001';

=head1 NAME

Dancer::Template::TemplateFlute - Template::Flute wrapper for Dancer

=head1 VERSION

Version 0.0001

=head1 DESCRIPTION

This class is an interface between Dancer's template engine abstraction layer
and the L<Template::Flute> module.

In order to use this engine, use the template setting:

    template: template_flute

The default template extension is ".html".

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
	my ($flute, $html);

	# derive file name for specification from template file names
	$flute = new Template::Flute(template_file => $template,
								 scopes => 1,
								 auto_iterators => 1,
								 values => $tokens,
							  );
	
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
