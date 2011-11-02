#! perl -T
#
# Tests for containers.

use strict;
use warnings;

use Test::More;
use Template::Flute;

my (@tests, $html, $flute, $out);

@tests = ([q{<container name="box" value="username"/>}, {}, 0],
	  [q{<container name="box" value="username"/>}, 
	   {username => 'racke'}, 1],
	  [q{<container name="box" value="!username"/>}, 
	   {}, 1],
	  [q{<container name="box" value="!username"/>}, 
	   {username => 'racke'}, 0],
	  [q{<container name="box" value="foo|bar"/>}, 
	   {}, 0],
	  [q{<container name="box" value="foo|bar"/>}, 
	   {foo => 1}, 1],
	  [q{<container name="box" value="foo|bar"/>}, 
	   {bar => 1}, 1],
	  [q{<container name="box" value="foo|bar"/>}, 
	   {foo => 1, bar => 1}, 1],
	  [q{<container name="box" value="foo|!bar"/>}, 
	   {}, 1],
	  [q{<container name="box" value="foo|!bar"/>}, 
	   {foo => 1}, 1],
	  [q{<container name="box" value="foo|!bar"/>}, 
	   {bar => 1}, 0],
	  [q{<container name="box" value="foo|!bar"/>}, 
	   {foo => 1, bar => 1}, 1],
	  [q{<container name="box" value="foo&amp;bar"/>}, 
	   {}, 0],
	  [q{<container name="box" value="foo&amp;bar"/>}, 
	   {foo => 1}, 0],
	  [q{<container name="box" value="foo&amp;bar"/>}, 
	   {bar => 1}, 0],
	  [q{<container name="box" value="foo&amp;bar"/>}, 
	   {foo => 1, bar => 1}, 1],
	  [q{<container name="box" value="foo&amp;!bar"/>}, 
	   {}, 0],
	  [q{<container name="box" value="foo&amp;!bar"/>}, 
	   {foo => 1}, 1],
	  [q{<container name="box" value="foo&amp;!bar"/>}, 
	   {bar => 1}, 0],
	  [q{<container name="box" value="foo&amp;!bar"/>}, 
	   {foo => 1, bar => 1}, 0],
    );

plan tests => scalar @tests + 1;   

$html = q{<div class="box">USER</div>};

my $i;

for my $t (@tests) {
    $i++;

    $flute = Template::Flute->new(specification => $t->[0],
				  template => $html,
				  values => $t->[1]);

    $out = $flute->process();

    if ($t->[2]) {
	ok($out =~ m%<div class="box">USER</div>%, "$i: $out");
    }
    else {
	ok($out !~ m%<div class="box">USER</div>%, "$i: $out");
    }
}

# test for a bug where only the first <div> block was removed from the HTML output
$html .= $html;

$flute = Template::Flute->new(specification => q{<container name="box" value="!username"/>},
			      template => $html,
			      values => {username => 'racke'});

$out = $flute->process();

ok ($out !~  m%<div class="box">USER</div>%, "Duplicate container: $out.");
