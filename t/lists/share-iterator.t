#
# Tests for lists sharing the same iterator
#

use strict;
use warnings;

use Test::More;
use Template::Flute;

my $spec = q{
<specification>
<list name="view-compact" class="product-box-compact" iterator="products">
<param name="name" class="product-name"/>
</list>
<list name="view-grid" class="navigation-view-grid" iterator="products">
<param name="name" class="product-name"/>
</list>
</specification>
};

my $html = q{
<div class="product-box-compact">
<a href="/" class="product-name">Organic gift basket for babies</a>
</div>
<div class="navigation-view-grid">
<a href="/" class="product-name">Organic gift basket for babies</a>
</div>
};

my $products = [{name => 'Blue ball'}];

my $flute = Template::Flute->new(specification => $spec,
                                 template => $html,
                                 iterators => {
                                     products => $products,
                                 },
                             );

my $out = $flute->process;

my $matches = $out =~ /Blue ball/;

ok ($matches == 2)
    || diag $out;

done_testing;
