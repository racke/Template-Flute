# Test for op="hook" in params
use strict;
use warnings;

use Test::More tests => 3;
use Template::Flute;

my $badspec = q{
<specification>
<list name="list" iterator="tokens">
<param field="html" class="htmlx" op="hook"/>
</list>
</specification>
};

my $goodspec = q{<specification>
<list name="list" iterator="tokens">
<param name="html" class="htmlx" op="hook"/>
</list>
</specification>
};

my $iter = [
            { html => '<em>my test</em>' },
            { html => '<div>my test</div>'},
           ];

my $html = q{
<div class="list"><div class="htmlx">KEY</div></div>
};

{
    my $tf = Template::Flute->new(template => $html,
                                  specification => $badspec,
                                  values => {
                                             tokens => $iter,
                                            },
                                 );
    eval { $tf->process };
    ok "$@", "Crash when missing name in the param";
}


{
    my $tf = Template::Flute->new(template => $html,
                                  specification => $goodspec,
                                  values => {
                                             tokens => $iter,
                                            },
                                 );
    my $out = $tf->process;
    like $out, qr{\Q$iter->[0]->{html}\E}, "Found $iter->[0]->{html}";
    like $out, qr{\Q$iter->[1]->{html}\E}, "Found $iter->[1]->{html}";
}
