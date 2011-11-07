#! perl -T
#
# Tests for specification parser based on XML::Twig.

use strict;
use warnings;
use Test::More tests => 2;

use Template::Flute;

my ($spec, $html, $iter, $tf, $out);

$spec = q{
<specification>
<list name="test" class="cpan" iterator="users">
<param name="user"/>
</list>
</specification>
};

$html = q{<div class="cpan"><span class="user">#USER</span></div>
};

$tf = Template::Flute->new(template => $html,
			   specification => $spec,
			   iterators => {users => [{user => 'racke'},
						   {user => 'nevairbe'}]});
						    
$out = $tf->process();

ok ($out =~ m%<span class="user">racke</span>%, 'test for user racke')
    || diag("Output was $out");

ok ($out =~ m%<span class="user">nevairbe</span>%, 'test for user nevairbe')
    || diag("Output was $out");

diag("Output was $out");
