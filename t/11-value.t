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

like($out, qr{\Q<div class="content"><p>Enter <b>dancefloor</b></p></div>\E},
     'value op=hook test with class')
    or diag $out;

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

like($out,  qr{\Q<div id="content"><p>Enter <b>dancefloor</b></p></div>\E},
     'value op=hook test with id')
  or diag $out;

