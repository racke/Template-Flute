#! perl -T
#
# Tests for nested lists

use strict;
use warnings;

use Test::More tests => 2;

use Template::Flute;

my ($spec, $html, $iter, $tf, $out);

$spec = q{<specification>
<list name="orders" iterator="orders">
<param name="number"/>
<list name="details" iterator="items">
<param name="sku"/>
<param name="quantity"/>
</list>
</list>
</specification>
};

$html = q{<div class="orders">
<h2 class="number">#NUMBER</h2>
<div class="details">
SKU: <span class="sku">#SKU</span><br>
QTY: <span class="quantity">#QTY</span><br>
</div>
</div>};

$iter = [{number => 'TF0001', 
	  items => [{sku => 'ABC', quantity => 2},
		    {sku => 'DEF', quantity => 1},
	      ],
	 },
	 {number => 'TF0002',
	  items => [{sku => 'GHI', quantity => 5},
		    {sku => 'KLM', quantity => 6},
	      ],
	 },
    ];

$tf = Template::Flute->new(template => $html,
			   specification => $spec,
			   iterators => {orders => $iter,
					 items => $iter->[0]->{items},
			   }
    );

isa_ok($tf->template->list('orders'), 'Template::Flute::List');

$out = $tf->process();

ok($out =~ m%div class="orders"><div class="details">
SKU: <span class="sku">ABC</span><br />
QTY: <span class="quantity">2</span><br /></div><div class="details">
SKU: <span class="sku">DEF</span><br />
QTY: <span class="quantity">1</span><br /></div></div><div class="orders"><div class="details">
SKU: <span class="sku">GHI</span><br />
QTY: <span class="quantity">5</span><br /></div><div class="details">
SKU: <span class="sku">KLM</span><br />
QTY: <span class="quantity">6</span><br /></div></div>%, "HTML output for nested lists: $out");
