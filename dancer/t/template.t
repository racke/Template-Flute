#! perl

use strict;
use warnings;

use Test::More tests => 9;

use File::Spec;
use lib File::Spec->catdir( 't', 'lib' );

use Dancer qw/:tests/;

set template => 'template_flute';
set views => 't/views';
set log => 'debug';
set logger => 'console';


use MyTestApp;
use Dancer::Test;

my $resp = dancer_response GET => '/';

response_status_is $resp, 200, "GET / is found";
response_content_like $resp, qr/Hello world/;

$resp = dancer_response GET => '/register';
response_status_is $resp, 200, "GET /register is found";
response_content_like $resp, qr/input name="password"/;

my %form = (
            email => 'pallino',
            password => '1234',
            verify => '5678',
           );

$resp = dancer_response(POST => '/register', { body =>  { %form } });

diag "Checking form keyword and stickyness";
response_status_is $resp, 200, "POST /register found";
foreach my $f (keys %form) {
    my $v = $form{$f};
    response_content_like $resp, qr/<input[^>]*name="\Q$f\E"[^>]*value="\Q$v\E"/,
      "Found form field $f => $v";
}

$resp = dancer_response(POST => '/login', { body =>  { %form } });

diag "Checking form keyword and stickyness";
response_status_is($resp, 200, "POST /login found")|| exit;
exit;
foreach my $f (keys %form) {
    my $v = $form{$f};
    response_content_like $resp, qr/<input[^>]*name="\Q$f\E"[^>]*value="\Q$v\E"/,
      "Found form field $f => $v";
}

