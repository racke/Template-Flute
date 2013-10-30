#
# Test for alternate CSS classes

use strict;
use warnings;

use Test::More tests => 2;
use Template::Flute;

my ($spec, $html, $flute, $out, $products);

$spec = q{<specification>
<list name="products" iterator="products">
<param name="sku"/>
</list>
</specification>
};

$html = q{
<html>
	<div class="products"><span class="sku">SKU</span></div>
	<div class="products even"><span class="sku">SKU</span></div>
</html>
};

$products = [{sku => 'ABC'}, {sku => 'DEF'}, {sku => 'GHI'}];

$flute = Template::Flute->new(template => $html,
			      specification => $spec,
			      auto_iterators => 1,
			      values => {products => $products},
    );

$out = $flute->process();

ok ($out =~ m%<html><div class="products">.*?</div><div class="products even">.*?</div><div class="products">.*?</div></html>%,
    'list with alternate classes')
    || diag $out;

$html = q{
<html>
	<div class="products odd"><span class="sku">SKU</span></div>
	<div class="products even"><span class="sku">SKU</span></div>
</html>
};

$products = [{sku => 'ABC'}, {sku => 'DEF'}, {sku => 'GHI'}];

$flute = Template::Flute->new(template => $html,
			      specification => $spec,
			      auto_iterators => 1,
			      values => {products => $products},
    );

$out = $flute->process();

ok ($out =~ m%<html><div class="products odd">.*?</div><div class="products even">.*?</div><div class="products odd">.*?</div></html>%,
    'list with alternate classes')
    || diag $out;
