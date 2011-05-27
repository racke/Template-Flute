#!perl -T

use strict;
use warnings;
use Test::More tests => 8;

use Template::Flute;
use Template::Flute::Specification::XML;
use Template::Flute::HTML;

my $xml_cut = <<EOF;
<specification name="select">
<form name="select" id="dropdown">
<field name="regions" id="regions" iterator="regions"/>
</form>
</specification>
EOF

my $xml_keep = <<EOF;
<specification name="select">
<form name="select" id="dropdown">
<field name="regions" id="regions" iterator="regions" keep="empty_value"/>
</form>
</specification>
EOF

my $html = <<EOF;
<form name="dropdown" id="dropdown">
<select name="regions" id="regions">
<option value="">Your Region</option>
</select>
</form>
EOF

# parse XML specifications
my ($spec_cut, $spec_keep, $ret_cut, $ret_keep);

$spec_cut = new Template::Flute::Specification::XML;

$ret_cut = $spec_cut->parse($xml_cut);

isa_ok($ret_cut, 'Template::Flute::Specification');

$spec_keep = new Template::Flute::Specification::XML;

$ret_keep = $spec_keep->parse($xml_keep);

isa_ok($ret_keep, 'Template::Flute::Specification');

# add iterator
$ret_cut->set_iterator('regions',
					   Template::Flute::Iterator->new([{value => 'EUR'},
													   {value => 'AF'}]));
$ret_keep->set_iterator('regions',
						Template::Flute::Iterator->new([{value => 'EUR'},
													   {value => 'AF'}]));

# parse HTML template
my ($html_object_cut, $html_object_keep, $form, $flute, $ret);

$html_object_cut = new Template::Flute::HTML;

$html_object_cut->parse($html, $ret_cut);

# locate form
$form = $html_object_cut->form('select');

isa_ok ($form, 'Template::Flute::Form');

$form->fill({});

$flute = new Template::Flute(specification => $ret_cut,
							  template => $html_object_cut,
);

eval {
	$ret = $flute->process();
};

ok($ret !~ /Your Region/, $ret);
ok($ret =~ /AF/, $ret);

$html_object_keep = new Template::Flute::HTML;

$html_object_keep->parse($html, $ret_keep);

# locate form
$form = $html_object_keep->form('select');

isa_ok ($form, 'Template::Flute::Form');

$form->fill({});

$flute = new Template::Flute(specification => $ret_keep,
							 template => $html_object_keep,
);

eval {
	$ret = $flute->process();
};

ok($ret =~ /Your Region/, $ret);
ok($ret =~ /AF/, $ret);
