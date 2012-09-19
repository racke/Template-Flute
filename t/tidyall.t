#!perl

use strict;
use warnings;
use Test::More;

eval "use Test::Code::TidyAll";

if ($@) {
    plan skip_all => "No Test::Code::TinyAll module.";
}

tidyall_ok();

