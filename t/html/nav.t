#!perl

use strict;
use warnings;
use utf8;
use Test::More tests => 16;
use Template::Flute;
use Data::Dumper;
use XML::Twig;

my $spec = q{<specification></specification>};

my $html = q{
<nav class="navbar navbar-default">
    <div class="container-fluid">
        <div class="navbar-header">
            <button type="button" class="navbar-toggle collapsed" data-toggle="collapse" data-target="#bs-example-navbar-collapse-1">
                <span class="sr-only">Toggle navigation</span>
                <span class="icon-bar"></span>
                <span class="icon-bar"></span>
                <span class="icon-bar"></span>
            </button>
            <a class="navbar-brand" href="#">Brand HEY!</a>
        </div>

        <div class="collapse navbar-collapse" id="bs-example-navbar-collapse-1">
            <ul class="nav navbar-nav">
                <li class="active"><a href="#">Link <span class="sr-only">(current)</span></a></li>
            </ul>
        </div>
    </div>
</nav>};

my $flute = Template::Flute->new( specification => $spec, template => $html );
my $out = $flute->process;
unlike $out, qr{/body><nav}, "Template ok";
like $out, qr{<body>\s*<nav}, "Template processing ok";

my $twig = XML::Twig->new->safe_parse_html($html);
like $twig->sprint, qr{<body>\s*<nav}, "XML::Twing prints the parsed html ok";
unlike $twig->sprint, qr{/body><nav}, "XML::Twing prints the parsed html ok";

my $wrappedhtml = '<html><body>' . $html . '</body></html>';

$twig = XML::Twig->new->safe_parse_html($wrappedhtml);
like $twig->sprint, qr{<body>\s*<nav}, "XML::Twing prints the parsed html ok";
unlike $twig->sprint, qr{/body><nav}, "XML::Twing prints the parsed html ok";
like $twig->sprint, qr{</nav></body};

$flute = Template::Flute->new( specification => $spec, template => $wrappedhtml );
$out = $flute->process;
unlike $out, qr{/body><nav}, "Template ok";
like $out, qr{<body>\s*<nav}, "Template processing ok";
like $out, qr{</nav></body};

$wrappedhtml = '<body>' . $html . '</body>';
$twig = XML::Twig->new->safe_parse_html($wrappedhtml);
like $twig->sprint, qr{<body>\s*<nav}, "XML::Twing prints the parsed html ok";
unlike $twig->sprint, qr{/body><nav}, "XML::Twing prints the parsed html ok";
like $twig->sprint, qr{</nav></body};

$flute = Template::Flute->new( specification => $spec, template => $wrappedhtml );
$out = $flute->process;
unlike $out, qr{/body><nav}, "Template ok";
like $out, qr{<body>\s*<nav}, "Template processing ok";
like $out, qr{</nav></body};
