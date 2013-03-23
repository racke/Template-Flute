#! perl

use strict;
use warnings;

use Test::More tests => 2;

use File::Spec;
use lib File::Spec->catdir( 't', 'lib' );

use MyTestApp;
use Dancer::Test;

my $resp = dancer_response GET => '/';

response_status_is $resp, 200, "GET / is found";
response_content_like $resp, qr/Hello world/;
