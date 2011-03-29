#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Template::Flute::Iterator' ) || print "Bail out!
";
}

diag( "Testing Template::Flute::Iterator, Perl $], $^X" );
