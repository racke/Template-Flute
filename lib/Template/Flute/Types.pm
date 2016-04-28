package Template::Flute::Types;

=head1 NAME

Template::Flute::Types - Type::Tiny types for Template::Flute

=head1 DESCRIPTION

Extends L<Types::Standard> with extra L<Template::Flute> type constraints.

=cut

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;

BEGIN { extends "Types::Standard" }

=head1 TYPES

=head2 SpecificationFile

=cut

declare 'SpecificationFile',
  as 'Str',
  where { -f $_ },
  message { "Template::Flute specification file does not exist: $_" };

1;
