#
# Tests for separators

use strict;
use warnings;

use Test::More tests => 2;
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

# first test: separator outside the list
$html_outside = q{<html><div class="list"><span class="key">KEY</span></div><span class="sep"> | </span></html>};

$tf = Template::Flute->new(template => $html_outside,
			   specification => $spec,
			   values => {tokens => $iter},
    );

$out = $tf->process();

ok ($out =~ m%<html><div class="list"><span class="key">FOO</span></div><span class="sep"> | </span><div class="list"><span class="key">BAR</span></div></html>%, "Out: $out.");

# second test: separator inside the list
$html_inside = q{<html><div class="list"><span class="key">KEY</span><span class="sep"> | </span></div></html>};

$tf = Template::Flute->new(template => $html_inside,
			   specification => $spec,
			   values => {tokens => $iter},
    );

$out = $tf->process();

ok ($out =~ m%<html><div class="list"><span class="key">FOO</span><span class="sep"> | </span></div><div class="list"><span class="key">BAR</span></div></html>%, "Out: $out.");
