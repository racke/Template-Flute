#!perl -T

use strict;
use warnings;
use Test::More tests => 3;

use Template::Flute;
use Template::Flute::Specification::XML;
use Template::Flute::HTML;

my $xml = <<EOF;
<specification name="textarea">
<form name="textarea" id="textarea">
<field name="content"/>
</form>
</specification>
EOF

my $html = <<EOF;
<form name="textarea" id="textarea">
<textarea class="content">
</textarea>
</form>
EOF

# parse XML specification
my ($spec, $ret);

$spec = new Template::Flute::Specification::XML;

$ret = $spec->parse($xml);

isa_ok($ret, 'Template::Flute::Specification');

# parse HTML template
my ($html_object);

$html_object = new Template::Flute::HTML;

$html_object->parse($html, $ret);

# locate form
my ($form);

$form = $html_object->form('textarea');

isa_ok ($form, 'Template::Flute::Form');

$form->fill({content => 'Hello World'});

my $flute = new Template::Flute(specification => $ret,
							  template => $html_object,
);

eval {
	$ret = $flute->process();
};

ok($ret =~ /Hello World/, $ret);

