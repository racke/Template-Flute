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
use Sub::Quote 'quote_sub';

BEGIN { extends "Types::Standard" }

=head1 TYPES

=head2 HtmlParser

An instance of L<Template::Flute::HTML>.

=head2 Specification

An instance of L<Template::Flute::Specification>.

=head2 URI

An instance of L<URI>.

=cut

declare 'Container',
  as InstanceOf ['Template::Flute::Container'];

declare 'Elt',
  as InstanceOf ['XML::Twig::Elt'];

declare 'Form',
  as InstanceOf ['Template::Flute::Form'];

declare 'HtmlParser',
  as InstanceOf ['Template::Flute::HTML'];

declare 'Iterator',
  as InstanceOf ['Template::Flute::Iterator'];

declare 'List',
  as InstanceOf ['Template::Flute::List'];

declare 'Param',
  as InstanceOf ['Template::Flute::Param'];

declare 'ReadableFilePath',
  constraint => quote_sub q{ -e $_ && -r $_ };

declare 'Specification',
  as InstanceOf ['Template::Flute::Specification'];

declare 'Twig',
  as InstanceOf ['XML::Twig'];

declare 'URI',
  as InstanceOf ['URI'];

declare 'FluteValue',
  as InstanceOf ['Template::Flute::Value'];

1;
