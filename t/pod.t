#!perl -T

use strict;
use warnings;
use Test::More;
use Class::Load qw(try_load_class);

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

# Ensure a recent version of Test::Pod
my $min_tp = 1.22;
try_load_class('Test::Pod', {-version => $min_tp})
    or plan skip_all => "Test::Pod $min_tp required for testing POD";
# T::P imports its functions into the caller's scope, hence, in order to
# use the test functions, we still need to 'use' it.
use Test::Pod;

all_pod_files_ok();
