package Template::Flute::Filter::Boolean;

use strict;
use warnings;

use base 'Template::Flute::Filter';

=head1 NAME

Template::Flute::Filter::Boolean

=head1 DESCRIPTION

Boolean filter.

=head1 METHODS

=head2 filter

=cut

sub filter {
    my ($self, $value, %args) = @_;
   	if($value and lc($value) ne 'false'){
   		return $value;
   	}
   	else {
   		return undef;
   	}
}

=head1 AUTHOR

Grega Pompe <grega.pompe@informa.si>

=head1 LICENSE AND COPYRIGHT

Copyright 2013-2016 Grega Pompe <grega.pompe@informa.si>

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
