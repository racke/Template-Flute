use strict;
use warnings;

use Test::More tests => 9;
use Test::Exception;
use XML::Twig;
use aliased 'Template::Flute::Value';

subtest "Check required attributes" => sub {

    throws_ok { Value->new() } qr/Missing.*arg.*name/,
      "Exception thrown when no attributes supplied";

    lives_ok { Value->new( name => "foo" ) }
    "Testing new when all required attributes are supplied";
};

subtest "Check type constraints for name attribute" => sub {

    lives_ok { Value->new( name => "foo" ) }
    "Testing good value for name attribute";

    throws_ok { Value->new( name => undef ) } 'Error::TypeTiny::Assertion',
      "Testing undef value for name attribute";

    throws_ok { Value->new( name => '' ) } 'Error::TypeTiny::Assertion',
      "Testing empty string as value for name attribute";

    throws_ok { Value->new( name => [] ) } 'Error::TypeTiny::Assertion',
      "Testing arrayref as value for name attribute";

    throws_ok { Value->new( name => Value->new( name => "foo" ) ) }
    'Error::TypeTiny::Assertion',
      "Testing object as value for name attribute";

};

subtest "Check type constraints for class attribute" => sub {

    lives_ok { Value->new( name => "foo", class => "bar" ) }
    "Testing good value for class attribute";

    throws_ok { Value->new( name => "foo", class => undef ) }
    'Error::TypeTiny::Assertion',
      "Testing undef value for class attribute";

    throws_ok { Value->new( name => "foo", class => '' ) }
    'Error::TypeTiny::Assertion',
      "Testing empty string as value for class attribute";

    throws_ok { Value->new( name => "foo", class => [] ) }
    'Error::TypeTiny::Assertion',
      "Testing arrayref as value for class attribute";

    throws_ok {
        Value->new( name => "foo", class => Value->new( name => "foo" ) )
    }
    'Error::TypeTiny::Assertion', "Testing object as value for class attribute";

};

subtest "Check type constraints for id attribute" => sub {

    lives_ok { Value->new( name => "foo", id => "bar" ) }
    "Testing good value for id attribute";

    lives_ok { Value->new( name => "foo", id => undef ) }
    "Testing undef value for id attribute";

    throws_ok { Value->new( name => "foo", id => '' ) }
    'Error::TypeTiny::Assertion',
      "Testing empty string as value for id attribute";

    throws_ok { Value->new( name => "foo", id => [] ) }
    'Error::TypeTiny::Assertion',
      "Testing arrayref as value for id attribute";

    throws_ok {
        Value->new( name => "foo", id => Value->new( name => "foo" ) )
    }
    'Error::TypeTiny::Assertion', "Testing object as value for id attribute";

};

subtest "Check type constraints for target attribute" => sub {

    lives_ok { Value->new( name => "foo", target => "bar" ) }
    "Testing good value for target attribute";

    lives_ok { Value->new( name => "foo", target => undef ) }
    "Testing undef value for target attribute";

    throws_ok { Value->new( name => "foo", target => '' ) }
    'Error::TypeTiny::Assertion',
      "Testing empty string as value for target attribute";

    throws_ok { Value->new( name => "foo", target => [] ) }
    'Error::TypeTiny::Assertion',
      "Testing arrayref as value for target attribute";

    throws_ok {
        Value->new( name => "foo", target => Value->new( name => "foo" ) )
    }
    'Error::TypeTiny::Assertion',
      "Testing object as value for target attribute";

};

subtest "Check type constraints for joiner attribute" => sub {

    lives_ok { Value->new( name => "foo", joiner => "bar" ) }
    "Testing good value for joiner attribute";

    throws_ok { Value->new( name => "foo", joiner => undef ) }
    'Error::TypeTiny::Assertion',
      "Testing undef value for joiner attribute";

    lives_ok { Value->new( name => "foo", joiner => '' ) }
    "Testing empty string as value for joiner attribute";

    throws_ok { Value->new( name => "foo", joiner => [] ) }
    'Error::TypeTiny::Assertion',
      "Testing arrayref as value for joiner attribute";

    throws_ok {
        Value->new( name => "foo", joiner => Value->new( name => "foo" ) )
    }
    'Error::TypeTiny::Assertion',
      "Testing object as value for joiner attribute";

};

subtest "Check type constraints for op attribute" => sub {

    lives_ok { Value->new( name => "foo", op => "append" ) }
    "Testing good value 'append' for op attribute";

    lives_ok { Value->new( name => "foo", op => "hook" ) }
    "Testing good value 'hook' for op attribute";

    lives_ok { Value->new( name => "foo", op => "toggle" ) }
    "Testing good value 'toggle' for op attribute";

    throws_ok { Value->new( name => "foo", op => "foobar" ) }
    'Error::TypeTiny::Assertion',
      "Testing bad value 'foobar' for op attribute";

    throws_ok { Value->new( name => "foo", op => undef ) }
    'Error::TypeTiny::Assertion',
      "Testing undef value for op attribute";

    throws_ok { Value->new( name => "foo", op => '' ) }
    'Error::TypeTiny::Assertion',
      "Testing empty string as value for op attribute";

    throws_ok { Value->new( name => "foo", op => [] ) }
    'Error::TypeTiny::Assertion',
      "Testing arrayref as value for op attribute";

    throws_ok {
        Value->new( name => "foo", op => Value->new( name => "foo" ) )
    }
    'Error::TypeTiny::Assertion', "Testing object as value for op attribute";

};

subtest "Check type constraints for elts attribute" => sub {

    my $elt;

    lives_ok { $elt = XML::Twig::Elt->new } "Create XML::Twig::Elt for testing";

    lives_ok { Value->new( name => "foo", elts => [$elt] ) }
    "Testing arrayef of single elt for elts attribute";

    lives_ok { Value->new( name => "foo", elts => [$elt, $elt, $elt] ) }
    "Testing arrayef of multiple elts for elts attribute";

    lives_ok { Value->new( name => "foo", elts => [] ) }
      "Testing emtpy arrayref as value for elts attribute";

    throws_ok { Value->new( name => "foo", elts => "foobar" ) }
    'Error::TypeTiny::Assertion',
      "Testing bad value 'foobar' for elts attribute";

    throws_ok { Value->new( name => "foo", elts => $elt ) }
    'Error::TypeTiny::Assertion',
      "Testing bad value single elt (not arrayref) for elts attribute";

    throws_ok { Value->new( name => "foo", elts => undef ) }
    'Error::TypeTiny::Assertion',
      "Testing undef value for elts attribute";

    throws_ok { Value->new( name => "foo", elts => '' ) }
    'Error::TypeTiny::Assertion',
      "Testing empty string as value for elts attribute";

    throws_ok {
        Value->new( name => "foo", elts => Value->new( name => "foo" ) )
    }
    'Error::TypeTiny::Assertion', "Testing object as value for elts attribute";

};

subtest "Check lazy builders" => sub {

    my $value = Value->new( name => "foo" );

    is( $value->class, 'foo', "Test lazy setting of class to value of name" );

    $value = Value->new( name => "foo", class => "bar" );

    is( $value->class, 'bar',
        "Test that class does not take value of name when it is set in new" );

};
