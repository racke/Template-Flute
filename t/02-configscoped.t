#! perl -T
#
# Tests for specification parser based on Config::Scoped.

use strict;
use warnings;
use Test::More tests => 2;

use Template::Flute::Specification::Scoped;

my $conf = <<EOF;
list test {
    class = cpan
}
input user {
    list = test
}
EOF

my $spec = new Template::Flute::Specification::Scoped;
my $ret;

eval {
	$ret = $spec->parse($conf);
};

diag("Failure parsing specification: $@") if $@;
isa_ok($ret, 'Template::Flute::Specification');

# check for list
ok(exists($ret->{lists}->{test}->{input}));
