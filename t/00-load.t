#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Template::Zoom' ) || print "Bail out!
";
}

diag( "Testing Template::Zoom $Template::Zoom::VERSION, Perl $], $^X" );
