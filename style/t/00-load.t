#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Template::Zoom::Style::CSS' ) || print "Bail out!
";
}

diag( "Testing Template::Zoom::Style::CSS $Template::Zoom::Style::CSS::VERSION, Perl $], $^X" );
