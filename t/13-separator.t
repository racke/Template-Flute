#! perl -T
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

# first test: separator outside the list
$html_outside = q{<div class="list"><span class="key">KEY</span></div><span class="sep"> | </span>};

$tf = Template::Flute->new(template => $html_outside,
			   specification => $spec,
			   iterators => {tokens => $iter},
    );

$out = $tf->process();

ok ($out =~ m%<div class="list"><span class="key">FOO</span></div><span class="sep"> | </span><div class="list"><span class="key">BAR</span></div>%, "Out: $out.");

# second test: separator inside the list
$html_inside = q{<div class="list"><span class="key">KEY</span><span class="sep"> | </span></div>};

$tf = Template::Flute->new(template => $html_inside,
			   specification => $spec,
			   iterators => {tokens => $iter},
    );

$out = $tf->process();

ok ($out =~ m%<div class="list"><span class="key">FOO</span><span class="sep"> | </span></div><div class="list"><span class="key">BAR</span></div>%, "Out: $out.");

# repeat tests with Config::Scoped specification parser

SKIP: {
    eval "use Config::Scoped";

    skip "No Config::Scoped module", 2 if $@;

$spec = <<EOF;
list list {
    iterator = tokens
}
param key {
    list = list
}
separator sep {
    list = list
}
EOF

$tf = Template::Flute->new(template => $html_outside,
			   specification => $spec,
			   specification_parser => 'Scoped',
			   iterators => {tokens => $iter},
    );

$out = $tf->process();

ok ($out =~ m%<div class="list"><span class="key">FOO</span></div><span class="sep"> | </span><div class="list"><span class="key">BAR</span></div>%, "Out: $out.");

$tf = Template::Flute->new(template => $html_inside,
			   specification => $spec,
			   specification_parser => 'Scoped',
			   iterators => {tokens => $iter},
    );

$out = $tf->process();

ok ($out =~ m%<div class="list"><span class="key">FOO</span><span class="sep"> | </span></div><div class="list"><span class="key">BAR</span></div>%, "Out: $out.");

}
