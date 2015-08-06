#! perl
#
# Testing JSON iterator.

use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

eval "use JSON";

if ($@) {
	plan skip_all => "No JSON module.";
}

require Template::Flute::Iterator::JSON;

plan tests => 7;

my ($json, $json_iter);

$json = q{[
{"sku": "orange", "image": "orange.jpg"},
{"sku": "pomelo", "image": "pomelo.jpg"}
]};

# JSON string as is
$json_iter = Template::Flute::Iterator::JSON->new($json);

isa_ok($json_iter, 'Template::Flute::Iterator');

ok($json_iter->count == 2);

isa_ok($json_iter->next, 'HASH');

# JSON string as scalar
$json_iter = Template::Flute::Iterator::JSON->new(\$json);

isa_ok($json_iter, 'Template::Flute::Iterator');

ok($json_iter->count == 2);

isa_ok($json_iter->next, 'HASH');

# JSON from file
subtest "Read JSON from file" => sub {
    plan tests => 5;

    my ($json_fh, $json_file) = tempfile;
    print $json_fh $json, "\n";
    close $json_fh;
    my $json_file_iter = Template::Flute::Iterator::JSON->new(file => $json_file);

    isa_ok $json_file_iter, 'Template::Flute::Iterator';
    is $json_iter->count, 2, "Iterator count is correct";
    isa_ok $json_iter->next, 'HASH', "Next item is a hash";

    {
        eval {Template::Flute::Iterator::JSON->new(file => "non-existent-file") };
        like $@, qr/failed to open JSON file non-existent-file/,
            "Fails with expected message when file doesn't exist";
    }

    {
        eval {Template::Flute::Iterator::JSON->new() };
        like $@, qr/Missing JSON file/, "Fails without JSON string, ref or file";
    }
};
