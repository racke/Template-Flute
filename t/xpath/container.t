#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Deep;

use Template::Flute;

my $spec =<<'EOF';
<specification>
<container name="description" xpath="//div[@id]" value="enabled">
<value name="test"/>
</container>
</specification>
EOF

my $html =<<'EOF';
<html>
<body>
<div id="whatever"><span class="test">TEST</span></div>
</body>
</html>
EOF

{
    # test whether container is removed if variable doesn't have a truth value
    my $flute = Template::Flute->new(
        template => $html,
        specification => $spec,
        values => {enabled => 0, test => 'FOO'},
    );


    isa_ok($flute, 'Template::Flute');

    my $out = $flute->process;

    unlike $out, qr/<div id="whatever">/, "check whether container has been removed.";
}

{
    # test whether variable is replaced if variable is set to a truth value
     my $flute = Template::Flute->new(
        template => $html,
        specification => $spec,
        values => {enabled => 1, test => 'FOO'},
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

     # check number of containers
     my @container = $flute->template->containers;
     my $container_count = scalar(@container);

     ok($container_count == 1, "Test number of containers found")
         || diag "Found $container_count containers instead of 1.";

     # number of elements for this containers
     my @elt = $container[0]->elts;
     my $elt_count = scalar(@elt);

     ok($elt_count == 1, "Test number of elts found")
         || diag "Found $elt_count elts instead of 1.";

     like $out, qr/FOO/, "check whether replacement of TEST was successful.";
 }

done_testing;
