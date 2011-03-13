#! perl -T
#
# Tests for specification parser based on XML::Twig.

use strict;
use warnings;
use Test::More tests => 2;

use Template::Zoom::Specification::XML;

my $conf = <<EOF;
<specification>
<list name="test" class="cpan">
<input name="user"/>
</list>
</specification>
EOF

my $spec = new Template::Zoom::Specification::XML;
my $ret;

eval {
	$ret = $spec->parse($conf);
};

diag("Failure parsing specification: $@") if $@;
isa_ok($ret, 'Template::Zoom::Specification');

# check for list
ok(exists($ret->{lists}->{test}->{input}));
