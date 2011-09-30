#!perl -T

use strict;
use warnings;
use Test::More tests => 2;

use Template::Flute;

my ($xml, $html, $flute, $ret);

# upper filter
$xml = <<EOF;
<specification name="filters">
<value name="text" filter="upper"/>
</specification>
EOF

$html = <<EOF;
<div class="text">foo</div>
EOF

$flute = Template::Flute->new(specification => $xml,
			      template => $html,
			      values => {text => 'bar'});

$ret = $flute->process();

ok($ret =~ m%<div class="text">BAR</div>%, "Output: $ret");

# currency filter
$xml = <<EOF;
<specification name="filters">
<value name="text" filter="currency"/>
</specification>
EOF

$flute = Template::Flute->new(specification => $xml,
			      template => $html,
			      values => {text => '30'});

$ret = $flute->process();

ok($ret =~ m%<div class="text">USD 30.00</div>%, "Output: $ret");
