#! perl
#
# Test append with values

use strict;
use warnings;

use Test::More tests => 2;
use Template::Flute;

my ($spec, $html, $flute, $out);

# simple append
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

# append to target
$spec = q{<specification>
<value name="test" op="append" target="href"/>
</specification>
};

$html = q{<a href="FOO" class="test">FOO</a>};

$flute = Template::Flute->new(template => $html,
                              specification => $spec,
                              values => {test => 'BAR'},
                             );

$out = $flute->process;

ok ($out =~ m%<a class="test" href="FOOBAR">FOO</a>%,
    "value with op=append and target=href")
    || diag $out;
