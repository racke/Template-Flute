#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Deep;

use Template::Flute;

my $spec =<<'EOF';
<specification>
<value name="description" xpath="//div[@id]" />
</specification>
EOF

my $html =<<'EOF';
<html>
<body>
<div id="whatever">TEST</div>
</body>
</html>
EOF

my $flute = Template::Flute->new(
    template => $html,
    specification => $spec,
    values => {description => 'FOO'},
);

isa_ok($flute, 'Template::Flute');

my $out = $flute->process;

# inspect specification for xpath value
my @xpaths = $flute->specification->_xpaths;

cmp_deeply @xpaths, ('//div[@id]');

# check whether we find nodes
my @nodes = $flute->template->root->findnodes($xpaths[0]);
my $node_count = scalar(@nodes);

ok($node_count == 1, "Test number of nodes found")
    || diag "Found $node_count nodes instead of 1.";

like $out, qr/FOO/, "check whether replacement of TEST was successful.";

done_testing;
