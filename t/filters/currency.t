#! perl -T
#
# Test for currency filter

use strict;
use warnings;

use POSIX;
use Test::More;
use Template::Flute;

eval "use Number::Format";

if ($@) {
    plan skip_all => "Missing Number::Format module.";
}

plan tests => 2;

POSIX::setlocale(&POSIX::LC_ALL, 'C');

my ($xml, $html, $flute, $ret);

$html = <<EOF;
<div class="text">foo</div>
EOF

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

# currency filter (options: int_curr_symbol)
$xml = <<EOF;
<specification name="filters">
<value name="text" filter="currency"/>
</specification>
EOF

$flute = Template::Flute->new(specification => $xml,
			      template => $html,
			      filters => {currency => {options => {int_curr_symbol => '$'}}},
			      values => {text => '30'});

$ret = $flute->process();

ok($ret =~ m%<div class="text">\$ 30.00</div>%, "Output: $ret");
