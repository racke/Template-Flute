#! perl -T
#
# Basic tests for list params

use strict;
use warnings;

use Test::More tests => 5;
use Template::Flute;

my ($spec, $html, $flute, $out);

$spec = q{<specification>
<list name="list" iterator="test">
<param name="value"/>
</list>
</specification>
};

$html = q{<div class="list"><div class="value">TEST</div></div>};

for my $value (0, 1, ' ', 'test') {
    $flute = Template::Flute->new(template => $html,
                                  specification => $spec,
                                  iterators => {test => [{value => $value}]},
    );

    $out = $flute->process();

    ok ($out =~ m%<div class="value">$value</div>%,
        "basic list param test with: $value")
        || diag $out;
}

$spec = q{<specification>
<list name="approval" class="approval" iterator="approvals">
<param name="email" />
</list>
</specification>
};

$html = '<span class="approval"><span class="email">TEST</span></span>';

my $value = 'LIVE';

$flute = Template::Flute->new(template => $html,
                                  specification => $spec,
                                  iterators => {approvals => [{email => $value}]},
                             );

$out = $flute->process();

ok ($out =~ m%<span class="email">$value</span>%,
    "basic list param test with: $value")
    || diag $out;
