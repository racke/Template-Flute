#! perl -T
#
# Basic tests for list params

use strict;
use warnings;

use Test::More tests => 4;
use Template::Flute;

my ( $spec, $html, $flute, $out );

$spec = q{<specification>
<list name="list" iterator="test">
<param name="value"/>
</list>
</specification>
};

$html = q{<div class="list"><div class="value">TEST</div></div>};

for my $value ( 0, 1, ' ', 'test' ) {
    $flute = Template::Flute->new(
        template      => $html,
        specification => $spec,
        iterators     => { test => [ { value => $value } ] },
    );

    $out = $flute->process();

    ok(
        $out =~ m%<div class="value">$value</div>%,
        "basic list param test with: $value"
    ) || diag $out;
}
