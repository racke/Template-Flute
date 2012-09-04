#! perl
#
# Test append with values

use strict;
use warnings;

use Test::More tests => 1;
use Template::Flute;

my ($spec, $html, $flute, $out);

$spec = q{<specification>
<value name="test" op="append"/>
</specification>
};

$html = q{<div class="test">FOO</div>};

$flute = Template::Flute->new(template => $html,
                              specification => $spec,
                              values => {test => 'BAR'},
                             );

$out = $flute->process;

ok ($out =~ m%<div class="test">FOOBAR</div>%,
    "value with op=append")
    || diag $out;
