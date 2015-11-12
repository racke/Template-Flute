package Template::Flute::I18N;

use Moo;
use Types::Standard qw/CodeRef/;
use Sub::Quote qw/quote_sub/;
use namespace::clean;
use MooX::StrictConstructor;

=head1 NAME

Template::Flute::I18N - Localization class for Template::Flute

=head1 SYNOPSIS

    %german_map = (Cart=> 'Warenkorb', Price => 'Preis');

    sub translate {
        my $text = shift;

        return $german_map{$text};
    };

    $i18n = Template::Flute::I18N->new(\&translate);

    # OR:

    $i18n = Template::Flute::I18N->new(coderef => \&translate);

    # then:

    $flute = Template::Flute(specification => ...,
                             template => ...,
                             i18n => $i18n);

=head1 ATTRIBUTES

=head2 coderef

Coderef used by L</localize> method for the text translation.

=cut

has coderef => (
    is      => 'ro',
    isa     => CodeRef,
    default => quote_sub q{},
);

sub BUILDARGS {
	my ($class, @args) = @_;

	if (ref($args[0]) eq 'CODE') {
		# use first parameter as localization function
        return { coderef => $args[0] };
	}
	else {
		# noop translation
        return {};
	}
}

=head1 METHODS

=head2 localize STRING

Calls localize function with provided STRING. The result is
returned if it contains non blank characters. Otherwise the
original STRING is returned.

=cut

sub localize {
	my ($self, $text) = @_;
	my ($trans);
	
	$trans = $self->coderef->($text);

	if (defined $trans && $trans =~ /\S/) {
		return $trans;
	}

	return $text;
}

=head1 AUTHOR

Stefan Hornburg (Racke), <racke@linuxia.de>

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2015 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
