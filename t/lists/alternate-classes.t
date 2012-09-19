#! perl -T
#
# Test for alternate CSS classes

use strict;
use warnings;

use Test::More tests => 2;
use Template::Flute;

my ( $spec, $html, $flute, $out, $products );

$spec = q{<specification>
<list name="products" iterator="products">
<param name="sku"/>
</list>
</specification>
};

$html = q{
<div class="products"><span class="sku">SKU</span></div>
<div class="products even"><span class="sku">SKU</span></div>
};

$products = [ { sku => 'ABC' }, { sku => 'DEF' }, { sku => 'GHI' } ];

$flute = Template::Flute->new(
    template       => $html,
    specification  => $spec,
    auto_iterators => 1,
    values         => { products => $products },
);

$out = $flute->process();

ok(
    $out =~
      m%<div class="products">.*?</div><div class="products even">.*?</div><div class="products">.*?</div>%,
    'list with alternate classes'
) || diag $out;

$html = q{
<div class="products odd"><span class="sku">SKU</span></div>
<div class="products even"><span class="sku">SKU</span></div>
};

$products = [ { sku => 'ABC' }, { sku => 'DEF' }, { sku => 'GHI' } ];

$flute = Template::Flute->new(
    template       => $html,
    specification  => $spec,
    auto_iterators => 1,
    values         => { products => $products },
);

$out = $flute->process();

ok(
    $out =~
      m%<div class="products odd">.*?</div><div class="products even">.*?</div><div class="products odd">.*?</div>%,
    'list with alternate classes'
) || diag $out;
