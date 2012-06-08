#! perl -T
#
# Basic tests for values

use strict;
use warnings;

use Test::More tests => 4;
use Template::Flute;

my ($spec, $html, $flute, $out);

$spec = q{<specification>
<value name="test"/>
</specification>
};

$html = q{<div class="test">TEST</div>};

for my $value (0, 1, ' ', 'test') {
    $flute = Template::Flute->new(template => $html,
                                  specification => $spec,
                                  values => {test => $value},
    );

    $out = $flute->process();

    ok ($out =~ m%<div class="test">$value</div>%,
        "basic value test with: $value")
        || diag $out;
}

