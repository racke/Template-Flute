#!perl

use strict;
use warnings;
use Template::Flute;
use Test::More tests => 1;

my ($spec, $html, $flute, $out, $expected);

$spec =<<'SPEC';
<specification>
<pattern name="pxt" type="string">123</pattern>
<value name="cartline" pattern="pxt" target="alt"/>
</specification>
SPEC

$html =<<'HTML';
<img class="cartline" alt="There are 123 items in your shopping cart." />
HTML

$flute = Template::Flute->new(template => $html,
                              specification => $spec,
                              values => {
                                         cartline => "42",
                                        });

$out = $flute->process;
like $out, qr/alt="There are 42 items in your shopping cart/, "Pattern replaced in attribute";

