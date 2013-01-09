#! perl -T
#
# Test for date filter

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Template::Flute;

eval "use DateTime";

if ($@) {
    plan skip_all => "Missing DateTime module.";
}

eval "use DateTime::Format::ISO8601";

if ($@) {
    plan skip_all => "Missing DateTime::Format::ISO8601 module.";
}

plan tests => 5;

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

# date filter (missing date)

$flute = Template::Flute->new(specification => $xml,
			      template => $html,
			      filters => {date => {options => {format => '%m/%d/%Y'}}},
			      values => {text => ''});

like(exception{$ret = $flute->process()},
     qr/Empty date/,
     'Died as excepted on an empty date.');


# date filter (missing date with different strict setting)

$flute = Template::Flute->new(specification => $xml,
			      template => $html,
			      filters => {date => {options => {format => '%m/%d/%Y',
                                                   strict => {empty => 0}}},
                              values => {text => ''},
                             });

$ret = $flute->process();

ok($ret =~ m%<div class="text"></div>%, "Output: $ret");

# date filter (invalid date)
$flute = Template::Flute->new(specification => $xml,
			      template => $html,
			      filters => {date => {options => {format => '%m/%d/%Y'}}},
			      values => {text => '2011-11-31T06:07:07'});

like(exception{$ret = $flute->process()},
     qr/Invalid day of month/,
     'Died as excepted on an invalid date.');

# date filter (invalid date with different strict setting)
$flute = Template::Flute->new(specification => $xml,
			      template => $html,
			      filters => {date => {options => {format => '%m/%d/%Y',
                                                   strict => {invalid => 0}}}},
			      values => {text => '2011-11-31T06:07:07'},
                              );

ok($ret =~ m%<div class="text"></div>%, "Output: $ret");

