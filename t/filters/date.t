#! perl -T
#
# Test for date filter

use strict;
use warnings;

use Test::More;
use Template::Flute;

eval "use DateTime";

if ($@) {
    plan skip_all => "Missing DateTime module.";
}

plan tests => 1;

my ($xml, $html, $flute, $ret);

$html =  <<EOF;
<div class="text">foo</div>
EOF

# date filter
$xml = <<EOF;
<specification name="filters">
<value name="text" filter="date"/>
</specification>
EOF

$flute = Template::Flute->new(specification => $xml,
			      template => $html,
			      filters => {date => {options => {format => '%m/%d/%Y'}}},
			      values => {text => '2011-10-30T06:07:07'});

$ret = $flute->process();

ok($ret =~ m%<div class="text">10/30/2011</div>%, "Output: $ret");
