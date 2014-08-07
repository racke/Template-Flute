#!perl

use strict;
use warnings;
use Template::Flute;
use Test::More tests => 2;

my ($spec, $html, $flute, $out, $expected);

$spec =<<'SPEC';
<specification>
<pattern name="pxt" type="string">123</pattern>
<value name="cartline" target="alt" pattern="pxt"/>
</specification>
SPEC

$html =<<'HTML';
<img class="cartline" />
HTML

$flute = Template::Flute->new(template => $html,
                              specification => $spec,
                              values => {
                                         cartline => "42",
                                        });

{
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    $out = $flute->process;
    like $out, qr/alt=""/, "Alt attribute replaced";
    ok (!@warnings, "No warnings issued") or diag join("\n", @warnings);
}

