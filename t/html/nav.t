#!perl

use strict;
use warnings;
use utf8;
use Test::More tests => 18;
use Template::Flute;
use Data::Dumper;
use XML::Twig;
use HTML::TreeBuilder;



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

$wrappedhtml = '<div>' . $html . '</div>';
$twig = XML::Twig->new->safe_parse_html($wrappedhtml);
like $twig->sprint, qr{<body>\s*<div>\s*<nav}, "XML::Twing prints the wrapped html ok";
unlike $twig->sprint, qr{/body><nav}, "XML::Twing prints the wrapped html ok";
like $twig->sprint, qr{</nav>\s*</div>\s*</body};

$flute = Template::Flute->new( specification => $spec, template => $wrappedhtml );
$out = $flute->process;
unlike $out, qr{</body><nav}, "Template ok with wrapping ";
like $out, qr{<body>\s*<div>\s*<nav}s, "Template processing ok wrapping ok";
like $out, qr{</nav>\s*</div>\s*</body}s, "Wrapping is ok";

my $tree= HTML::TreeBuilder->new;
$tree->ignore_ignorable_whitespace( 0);
$tree->ignore_unknown( 0);
$tree->no_space_compacting( 1);
$tree->store_comments( 1);
$tree->store_pis(1);
$tree->parse($html);
$tree->eof;

my $tree_html = $tree->as_HTML;
like $tree_html, qr{<body>\s*<nav}, "Template processing ok";
like $tree_html, qr{</nav></body};

$tree = HTML::TreeBuilder->new;
$tree->ignore_unknown( 0);
$tree->parse('<nav class="navbar navbar-default">
    <div class="container-fluid">Test</div></nav>');
print $tree->as_HTML;

