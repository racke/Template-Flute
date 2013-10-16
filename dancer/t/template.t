#! perl

use strict;
use warnings;

use Test::More tests => 19;

use File::Spec;
use Data::Dumper;

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
check_sticky_form($resp, %form);

$resp = dancer_response(POST => '/login', { body =>  { %form } });

diag "Checking form keyword and stickyness";
response_status_is($resp, 200, "POST /login found")|| exit;
check_sticky_form($resp, %form);

my %other_form = (
                  email_2 => 'pinco',
                  password_2 => 'pazzw0rd',
                 );

# unclear why we have to repeat the request twice. The first call gets
# empty params. It seems more a Dancer::Test bug, because from the app it works.
$resp = dancer_response(POST => '/login', { body => { login => "Login", %other_form } });
$resp = dancer_response(POST => '/login', { body => { login => "Login", %other_form } });

foreach my $f (keys %other_form) {
    my $v = $other_form{$f};
    response_content_like $resp, qr/<input[^>]*name="\Q$f\E"[^>]*value="\Q$v\E"/,
      "Found form field $f => $v";
}



set logger => 'capture';

response_status_is [GET => '/bugged_single'] => 200, "route to bugged single found";

response_status_is [GET => '/bugged_multiple'] => 200, "route to bugged multiple found";

response_status_is [POST => '/bugged_single'] => 200, "route to bugged single found";

response_status_is [POST => '/bugged_multiple'] => 200, "route to bugged multiple found";

is_deeply(read_logs, [
                      {
                       'level' => 'debug',
                       'message' => 'Missing form parameters for forms registration'
                      },
                      {
                       'level' => 'debug',
                       'message' => 'Missing form parameters for forms login, registration'
                      },
                      {
                       'level' => 'debug',
                       'message' => 'Missing form parameters for forms registration'
                      },
                      {
                       'level' => 'debug',
                       'message' => 'Missing form parameters for forms login, registration'
                      },
                     ], "Warning logged in debug as expected");



sub check_sticky_form {
    my ($res, %params) = @_;
    foreach my $f (keys %params) {
        my $v = $params{$f};
        response_content_like $resp, qr/<input[^>]*name="\Q$f\E"[^>]*value="\Q$v\E"/,
          "Found form field $f => $v";
    }
}
