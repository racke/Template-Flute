#!perl

use strict;
use warnings;
use utf8;

use Test::More tests => 3;

use Template::Flute;
use Template::Flute::I18N;

my %lexicon = (
               "Enter your username..." => "Inserisci il nome utente...",
               "Submit result" => "Invia i risultati",
               "Title" => "Titolo",
              );

sub translate {
    my $text = shift;
    return $lexicon{$text};
};

my $i18n = Template::Flute::I18N->new(\&translate);
my $spec = '<specification></specification>';
my $template =<<HTML;
<html>
<body>
<div>
<h3>Title</h3>
<input placeholder="Enter your username...">
<input type="submit" data-role="button" data-icon="arrow-r"
         data-iconpos="right" data-iconpos="" data-theme="b"
         value="Submit result">
</div>
</body>
</html>
HTML

my $flute = Template::Flute->new(specification => $spec,
                                 template => $template,
                                 i18n => $i18n);
my $output = $flute->process();

like $output, qr/Titolo/;
like $output, qr/value="Invia i risultati"/;
like $output, qr/placeholder="Inserisci il nome utente..."/;


