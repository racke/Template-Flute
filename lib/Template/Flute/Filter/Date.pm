package Template::Flute::Filter::Date;

use strict;
use warnings;

use DateTime;
use DateTime::Format::ISO8601;

use base 'Template::Flute::Filter';

=head1 NAME

Template::Flute::Filter::Date - Date filter

=head1 DESCRIPTION

Date filter based on L<DateTime>.

=head1 PREREQUSITES

L<DateTime> and L<DateTime::Format::ISO8601> modules.

=head1 METHODS

=head2 init

The init method allows you to set the following options:

=over 4

=item format

Format string for L<DateTime>'s strftime method. Defaults to %c.
    
=back

=cut

sub init {
    my ($self, %args) = @_;
    
    $self->{format} = $args{options}->{format} || '%c';
}

=head2 filter

Date filter.

=cut

sub filter {
    my ($self, $date, %args) = @_;
    my ($dt, $fmt);

    if ($args{format}) {
	$fmt = $args{format};
    }
    else {
	$fmt = $self->{format};
    }

    # parsing date
    $dt = DateTime::Format::ISO8601->parse_datetime($date);

    return $dt->strftime($fmt);
}


=head1 AUTHOR

Stefan Hornburg (Racke), <racke@linuxia.de>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
