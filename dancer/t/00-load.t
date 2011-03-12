#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Dancer::Template::TemplateZoom' ) || print "Bail out!
";
}

diag( "Testing Dancer::Template::TemplateZoom $Dancer::Template::TemplateZoom::VERSION, Perl $], $^X" );
