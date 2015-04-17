#! perl
#
# Test for containers inside of lists of lists.

use strict;
use warnings;

use Test::More tests => 4;
use Template::Flute;

my ( $spec, $html, $flute, $out );

$spec = <<'EOS';
<specification>
    <list name="items" iterator="items">
        <param name="itemid" />
        <param name="title" />
        <list name="prices" iterator="prices">
            <container name="on-sale" value="on_sale">
                <param name="price" />
            </container>
            <container name="not-on-sale" value="!on_sale">
                <param name="price" />
                <param name="sale_price" class="sale-price" />
            </container>
        </list>
    </list>
</specification>
EOS

$html = <<'EOH';
<div class="items">
    <span class="itemid">109267</span> <span class="title">Joseph Phelps Insignia</span>
    <div class="prices">
        <div class="on-sale">
            <span class="strikethough price">$109.99</span>
            <span class="sale-price">$99.99</span> 
        </div>
        <div class="not-on-sale">
            <span class="price">$109.99</span>
        </div>
    </div>
</div>
EOH

my $items = [
    {   itemid => 540876,
        title  => q{Freemark Abbey Merlot 2012},
        prices => [ on_sale => 1, price => 35.99, sale_price => 24.97 ]
    },
    {   itemid => 555024,
        title  => q{Rancho Sisquoc Cabernet Sauvignon 2009},
        prices => [ on_sale => 0, price => 24.99, sale_price => undef ]
    },
    {   itemid => 555518,
        title  => q{Paul Hobbs Russian River Valley Pinot Noir 2013},
        prices => [ on_sale => 1, price => 64.99, sale_price => 46.88 ]
    }
];

$flute = Template::Flute->new(
    template      => $html,
    specification => $spec,
    iterators     => { items => $items },
);

$out = $flute->process();

my @ct_arr   = $flute->template->containers;
my $ct_count = scalar @ct_arr;

ok( $ct_count == 1, 'Test for container count' )
    || diag "Wrong number of containers: $ct_count\n";

my $ct      = $ct_arr[0];
my $ct_name = $ct->name;
my $ct_list = $ct->list;

ok( $ct_name eq 'color', 'Test for container name' )
    || diag "Wrong container name: $ct_name\n";

ok( $ct_list eq 'products', 'Test for container list' )
    || diag "Wrong container list: $ct_list\n";

ok( $out
        =~ m%<ul><li class="products"><span class="sku">123</span></li><li class="products"><span class="sku">456</span><span class="color">black</span></li></ul>%,
    'Test for container within list.'
) || diag "Mismatch on elements: $out";

