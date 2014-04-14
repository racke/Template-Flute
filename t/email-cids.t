use strict;
use warnings;

use Template::Flute;
use Test::More;


my $html = <<'HTML';
<html><head><body>
<img src="foo.png" alt="Foo" />
<img src="foo2.png" />
</body></html>"
HTML

my $spec = <<'SPEC';
<specification></specification>
SPEC

my $cids = {};
my $flute = Template::Flute->new(template => $html,
                                 specification => $spec,
                                 email_cids => $cids);

my $out = $flute->process;

like $out, qr/src="cid:foopng".*src="cid:foo2png"/, "Found the cids";

is_deeply $cids, {
                  foopng => {
                             filename => "foo.png",
                            },
                  foo2png => {
                              filename => "foo2.png",
                             }
                 }, "the email_cids has been correctly populated";





