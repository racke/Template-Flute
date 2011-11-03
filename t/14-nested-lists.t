#! perl -T
#
# Tests for nested lists

use strict;
use warnings;

use Test::More tests => 1;

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
	      ],
	 }
    ];

$tf = Template::Flute->new(template => $html,
			   specification => $spec,
			   iterators => {orders => $iter,
					 items => $iter->[0]->{items}},
    );

warn "Names: ", join(',', map {ref($_), $_->name} $tf->template->lists), "\n";

$out = $tf->process();

ok($out =~ /XXX/, "HTML output for nested lists: $out");
