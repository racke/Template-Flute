#! perl -T
#
# Basic tests for values

use strict;
use warnings;

use Test::More tests => 6;
use Template::Flute;

my ( $spec, $html, $flute, $out );

$spec = q{<specification>
<value name="test"/>
</specification>
};

$html = q{<div class="test">TEST</div>};

for my $value ( 0, 1, ' ', 'test' ) {
    $flute = Template::Flute->new(
        template      => $html,
        specification => $spec,
        values        => { test => $value },
    );

    $out = $flute->process();

    ok( $out =~ m%<div class="test">$value</div>%,
        "basic value test with: $value" )
      || diag $out;
}

# test targets in values
$spec = q{<specification>
<value name="test" target="src"/>
</specification>
};

$html = q{<iframe class="test" src="test">};

$flute = Template::Flute->new(
    template      => $html,
    specification => $spec,
    values        => { test => '/test.html' },
);

$out = $flute->process();

ok( $out =~ m%<iframe class="test" src="/test.html">%,
    'basic value target test by class' )
  || diag $out;

$spec = q{<specification>
<value name="test" id="test" target="src"/>
</specification>
};

$html = q{<iframe id="test" src="test">};

$flute = Template::Flute->new(
    template      => $html,
    specification => $spec,
    values        => { test => '/test.html' }
);

$out = $flute->process();

ok( $out =~ m%<iframe id="test" src="/test.html">%,
    'basic value target test by id' )
  || diag $out;

