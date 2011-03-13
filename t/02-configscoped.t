#! perl -T
#
# Tests for specification parser based on Config::Scoped.

use strict;
use warnings;
use Test::More tests => 2;

use Template::Zoom::Specification::Scoped;

my $conf = <<EOF;
list test {
    class = cpan
}
input user {
    list = test
}
EOF

my $spec = new Template::Zoom::Specification::Scoped;
my $ret;

eval {
	$ret = $spec->parse($conf);
};

diag("Failure parsing specification: $@") if $@;
isa_ok($ret, 'Template::Zoom::Specification');

# check for list
ok(exists($ret->{lists}->{test}->{input}));
