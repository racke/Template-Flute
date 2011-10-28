#!perl -T

use strict;
use warnings;
use Test::More tests => 7;

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

# linebreak filter (single linebreaks in between)
$xml = <<EOF;
<specification name="filters">
<value name="text" filter="eol"/>
</specification>
EOF

$flute = Template::Flute->new(specification => $xml,
			      template => $html,
			      values => {text => q{First line
Second line
Third line}});

$ret = $flute->process();

ok($ret =~ m%div class="text">First line<br />Second line<br />Third line</div>%, "Output: $ret");

# linebreak filter (multiple linebreak in between)
$xml = <<EOF;
<specification name="filters">
<value name="text" filter="eol"/>
</specification>
EOF

$flute = Template::Flute->new(specification => $xml,
			      template => $html,
			      values => {text => q{First line

Third line}});

$ret = $flute->process();

ok($ret =~ m%div class="text">First line<br /><br />Third line</div>%, "Output: $ret");

# linebreak filter (empty string)
$xml = <<EOF;
<specification name="filters">
<value name="text" filter="eol"/>
</specification>
EOF

$flute = Template::Flute->new(specification => $xml,
			      template => $html,
			      values => {text => q{}});

$ret = $flute->process();

ok($ret =~ m%div class="text"></div>%, "Output: $ret");

# linebreak filter (leading linebreak)
$xml = <<EOF;
<specification name="filters">
<value name="text" filter="eol"/>
</specification>
EOF

$flute = Template::Flute->new(specification => $xml,
			      template => $html,
			      values => {text => q{
One line}});

$ret = $flute->process();

ok($ret =~ m%div class="text"><br />One line</div>%, "Output: $ret");

# linebreak filter (trailing linebreak)
$xml = <<EOF;
<specification name="filters">
<value name="text" filter="eol"/>
</specification>
EOF

$flute = Template::Flute->new(specification => $xml,
			      template => $html,
			      values => {text => q{One line
}});

$ret = $flute->process();

ok($ret =~ m%div class="text">One line<br /></div>%, "Output: $ret");
