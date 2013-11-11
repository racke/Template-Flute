#
# Toggle tests for values

use strict;
use warnings;

use Test::More tests => 4;
use Template::Flute;

my ($spec, $html, $flute, $out);

$spec = q{<specification>
<value name="test" op="toggle"/>
</specification>
};

$html = q{<html><div class="test">TEST</div></html>};

for my $value (0, 1, ' ', 'test') {
    $flute = Template::Flute->new(template => $html,
                                  specification => $spec,
                                  values => {test => $value},
    );

    $out = $flute->process();

    if ($value) {
        ok ($out =~ m%<div class="test">$value</div>%,
            "toggle value test with: $value")
            || diag $out;
    }
    else {
        ok ($out !~ /div/,
            "toggle value test with: $value")
            || diag $out;
    }
}
