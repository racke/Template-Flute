#!perl

use strict;
use warnings;
use Template::Flute;
use Test::More tests => 2;
use Data::Dumper;

my ($spec, $html, $flute, $out, $expected);

$spec =<<'SPEC';
<specification>
<pattern name="pxt" type="string">123</pattern>
<list name="items" iterator="items">
  <param name="number"/>
  <param name="category" pattern="pxt"/>
</list>
<value name="cartline" pattern="pxt"/>
</specification>
SPEC

# here we use the same 123 pattern to interpolate two unrelated things
$html =<<'HTML';
<p class="cartline">There are 123 items in your shopping cart.</p>
<ul>
  <li class="items">
    <span class="number">1</span>
    <span class="category">in category 123</span>
  </li>
</ul>
HTML

my $iterator = [
                { number => 1,
                  category => "tofu" },
                { number => 2,
                  category => "pizza" },
               ];

$flute = Template::Flute->new(template => $html,
                              specification => $spec,
                              values => {
                                         items => $iterator,
                                         cartline => "42",
                                        });

$out = $flute->process;

$expected =<<'EXPECTED';
<p class="cartline">There are 42 items in your shopping cart.</p>
EXPECTED

$expected =~ s/\n//g;
like $out, qr/\Q$expected\E/, "Interpolation value by pattern";

$expected =<<'EXPECTED';
<ul>
<li class="items">
<span class="number">1</span>
<span class="category">in category tofu</span>
</li>
<li class="items">
<span class="number">2</span>
<span class="category">in category pizza</span>
</li>
</ul>
EXPECTED

$expected =~ s/\n//g;
like $out, qr/\Q$expected\E/, "Interpolation param by pattern";

=pod

Example: <p>There are 123 items in your shopping cart.</p>

<pattern
   name="foo"
   type="string|regex|..."
>123</a>

<value name="bar" pattern="foo">

Applicable for "value" and "param" elements.

=cut

