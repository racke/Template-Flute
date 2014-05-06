#
# Tests for separators
use strict;
use warnings;

use Test::More tests => 4;
use Template::Flute;

my ($html_outside, $html_inside, $spec, $tf, $out, $iter);

$spec = q{<specification>
<list name="list" iterator="tokens">
<param name="key"/>
<separator name="sep"/>
</list>
</specification>
};

$iter = [{key => 'FOO'}, {key => 'BAR'}];

diag "first test: separator outside the list";
$html_outside = q{
<div class="list">
<span class="key">KEY</span>
</div>
<span class="sep"> | </span>
};

$tf = Template::Flute->new(template => $html_outside,
			   specification => $spec,
			   values => {tokens => $iter},
    );

$out = $tf->process();
diag $out;

like $out, qr%<div class="list"><span class="key">FOO</span></div><span class="sep"> \| </span><div class="list"><span class="key">BAR</span></div>%, "Checking list";

unlike $out, qr/KEY/;

diag "second test: separator inside the list";
$html_inside = q{
<div class="list">
<span class="key">KEY</span>
<span class="sep"> | </span>
</div>};

$tf = Template::Flute->new(template => $html_inside,
			   specification => $spec,
			   values => {tokens => $iter},
    );

$out = $tf->process();
diag $out;
like $out, qr%<div class="list"><span class="key">FOO</span><span class="sep"> \| </span></div><div class="list"><span class="key">BAR</span></div>%, "Checking separator";

unlike $out, qr/KEY/;
