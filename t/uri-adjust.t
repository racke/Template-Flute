use strict;
use warnings;

use Template::Flute;
use Test::More;
use URI;

my @tests = (
    # base tag
    {html => q{<html><head><base href="/foo"><body><img src="foo.png"></body></html>},
     spec => q{<specification></specification>},
     uri => URI->new('/t/', 'http'),
     match => qr{base href="/t/foo"},
    },
    # images
    {html => q{<html><body><img src="foo.png"></body></html>},
     spec => q{<specification></specification>},
     uri => URI->new('/t/', 'http'),
     match => qr{img src="/t/foo.png"},
    },
    {html => q{<html><body><img src="http://example.com/foo.png"></body></html>},
     spec => q{<specification></specification>},
     uri => URI->new('/t/', 'http'),
     match => qr{img src="http://example.com/foo.png"},
    },
    # links with anchor
    {html => q{<html><body><a href="#login">Log in</a></body></html>},
     spec => q{<specification></specification>},
     uri => URI->new('/t/', 'http'),
     match => qr{<a href="/t/#login">Log in</a>},
    },
     # links used for Angular
    {html => q{<html><body><a href="{{link.url}}" class="">{{link.name}}</a></body></html>},
     spec => q{<specification></specification>},
     uri => URI->new('/t/', 'http'),
     match => qr{<a class="" href="/t/{{link.url}}">{{link.name}}</a>},
    },
    # link elements without href attributes
    {html => q{<html><body><a class="">{{link.name}}</a></body></html>},
     spec => q{<specification></specification>},
     uri => URI->new('/t/', 'http'),
     match => qr{<a class="">{{link.name}}</a>},
    },
    # stylesheets
    {html => q{<html><head><link href="/css/main.css" rel="stylesheet"></head></html>},
     spec => q{<specification></specification>},
     uri => URI->new('/t/', 'http'),
     match => qr{link href="/t/css/main.css"},
    },
);

plan tests => scalar @tests;

for my $t (@tests) {
    my $tf = Template::Flute->new(template => $t->{html},
                                  specification => $t->{spec},
                                  uri => $t->{uri},
                                  );

    #isa_ok($tf, 'Template::Flute');

    my $out = $tf->process;

    ok ($out =~ /$t->{match}/)
        || diag "Out: $out.";
}

