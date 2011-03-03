#!perl -T

use strict;
use warnings;
use Test::More tests => 2;

use Template::Zoom;
use Template::Zoom::Specification::Scoped;
use Template::Zoom::HTML;

my $xml = <<EOF;
<specification name="helloworld">
<value name="hello"/>
</specification>
EOF

my $scoped = <<EOF;
value hello {
    name=hello
}
EOF

my $html = <<EOF;
<span class="hello">TEXT</span>
EOF

# parse scoped specification
my ($spec, $ret);

$spec = new Template::Zoom::Specification::Scoped;

$ret = $spec->parse($scoped);

isa_ok($ret, 'Template::Zoom::Specification');

# parse HTML template
my ($html_object);

$html_object = new Template::Zoom::HTML;

$html_object->parse($html, $ret);

my $zoom = new Template::Zoom(specification => $ret,
							  template => $html_object,
							  values => {hello => 'Hello World'},
);

eval {
	$ret = $zoom->process();
};

ok($ret =~ /Hello World/);


