#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok('Template::Flute') || print "Bail out!
";
}

diag("Testing Template::Flute $Template::Flute::VERSION, Perl $], $^X");
