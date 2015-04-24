use strict;
use warnings;
use utf8;

use Test::More;
use Template::Flute;

my ($xml, $html, $flute, %currency_options, $ret);

binmode STDOUT, ":encoding(utf-8)";

$html = <<EOF;
<div class="text">foo</div>
EOF

$xml = <<EOF;
<specification name="filters">
<value name="text" filter="decode_html_entities"/>
</specification>
EOF

# HTML entities and UTF-8 counterparts for testing the filter
my @tests =
    (
        {entity => '&raquo;', expected => '»'},
        {entity => '&oelig;', expected => 'œ'},
    );

for my $t (@tests) {
    $flute = Template::Flute->new(specification => $xml,
                                  template => $html,
                                  values => {text => "Foo $t->{entity} Bar"});

    $ret = $flute->process();

    ok($ret =~ m%<div class="text">Foo $t->{expected} Bar</div>%,
       "Conversion of $t->{entity} to $t->{expected}")
        || diag "Output: $ret instead of Foo $t->{expected} Bar< ";
}

done_testing;
