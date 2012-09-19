#! perl

use strict;
use warnings;

use Test::More tests => 2;
use Template::Flute;

my ( $spec_xml, $template, @records, $flute, $output, @matches );

@records = (
    { name => 'Link',         url => 'http://localhost/' },
    { name => 'No Link' },
    { name => 'Another Link', url => 'http://localhost/' },
);

$spec_xml = <<'EOF';
<specification name="link">
<list name="links" class="linklist" iterator="links">
<param name="name"/>
<param name="url" target="href"/>
<param name="link" field="url" op="toggle" args="tree"/>
</list>
</specification>
EOF

$template = qq{<div class="linklist">
<span class="name">Name</span>
<div class="link">
<a href="#" class="url">Goto ...</a>
</div>
</div>};

$flute = Template::Flute->new(
    specification => $spec_xml,
    template      => $template,
    iterators     => { links => \@records }
);

$output = $flute->process();

@matches = $output =~ m%http://localhost/%g;
ok( @matches == 2, 'Number of matching links' )
  || diag $output;

@matches = $output =~ m%<div class="link">%g;
ok( @matches == 2, 'Number of link divs' )
  || diag $output;

