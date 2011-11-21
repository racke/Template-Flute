#! perl -T
#
# Extended tests for values

use strict;
use warnings;

use Test::More tests => 2;
use Template::Flute;

my ($spec, $html, $flute, $out);

# value with op=hook, using class
$spec = q{<specification>
<value name="content" op="hook"/>
</specification>
};

$html = q{<div class="content">CONTENT</div>};

$flute = Template::Flute->new(template => $html,
			      specification => $spec,
			      values => {content => q{<p>Enter <b>dancefloor</b></p>}},
    );

$out = $flute->process();

ok ($out =~ m%<div class="content"><p>Enter <b>dancefloor</b></p></div>%,
    'value op=hook test with class')
    || diag $out;

# value with op=hook, using id
$spec = q{<specification>
<value name="content" id="content" op="hook"/>
</specification>
};

$html = q{<div id="content">CONTENT</div>};

$flute = Template::Flute->new(template => $html,
			      specification => $spec,
			      values => {content => q{<p>Enter <b>dancefloor</b></p>}},
    );

$out = $flute->process();

ok ($out =~ m%<div id="content"><p>Enter <b>dancefloor</b></p></div>%,
    'value op=hook test with id')
    || diag $out;

