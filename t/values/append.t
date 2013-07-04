#! perl
#
# Test append with values

use strict;
use warnings;

use Test::More tests => 4;
use Template::Flute;

my ($spec, $html, $flute, $out);

# simple append
$spec = q{<specification>
<value name="test" op="append"/>
</specification>
};

$html = q{<div class="test">FOO</div>};

$flute = Template::Flute->new(template => $html,
                              specification => $spec,
                              values => {test => 'BAR'},
                             );

$out = $flute->process;

ok ($out =~ m%<div class="test">FOOBAR</div>%,
    "value with op=append")
    || diag $out;

# append to target
$spec = q{<specification>
<value name="test" op="append" target="href"/>
</specification>
};

$html = q{<a href="FOO" class="test">FOO</a>};

$flute = Template::Flute->new(template => $html,
                              specification => $spec,
                              values => {test => 'BAR'},
                             );

$out = $flute->process;

ok ($out =~ m%<a class="test" href="FOOBAR">FOO</a>%,
    "value with op=append and target=href")
    || diag $out;

# append with joiner
$spec =  q{<specification>
<value name="test" op="append" target="class" joiner=" "/>
</specification>
};

$html = q{<a href="FOO" class="test">FOO</a>};

$flute = Template::Flute->new(template => $html,
                              specification => $spec,
                              values => {test => 'bar'},
                             );

$out = $flute->process;

ok ($out =~ m%<a class="test bar" href="FOO">FOO</a>%,
    "value with op=append, target=class and joiner")
    || diag $out;


# append with joiner without value
$spec =  q{<specification>
<value name="test" op="append" target="class" joiner=" "/>
</specification>
};

$html = q{<a href="FOO" class="test">FOO</a>};

$flute = Template::Flute->new(template => $html,
                              specification => $spec,
                             );

$out = $flute->process;

ok ($out =~ m%<a class="test" href="FOO">FOO</a>%,
    "value with op=append, target=class and joiner without value")
    || diag $out;
