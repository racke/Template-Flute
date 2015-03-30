#!perl

use strict;
use warnings;
use utf8;
use Test::More tests => 1;
use Template::Flute;

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
like $out, qr{<body>\s*<nav};
