#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Template::Zoom::PDF' ) || print "Bail out!
";
}

diag( "Testing Template::Zoom::PDF $Template::Zoom::PDF::VERSION, Perl $], $^X" );
