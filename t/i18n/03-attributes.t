#!perl

use strict;
use warnings;
use utf8;

use Test::More tests => 4;

use Template::Flute;
use Template::Flute::I18N;

my %lexicon = (
               "Enter your username..." => "Inserisci il nome utente...",
               "Submit result" => "Invia i risultati",
               "Title" => "Titolo",
               "Do-not-translate" => "FAIL",
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
<input placeholder=" Enter your username... ">
<input type="submit" data-role="button" data-icon="arrow-r"
         data-iconpos="right" data-iconpos="" data-theme="b"
         value=" Submit result">
<input type="hidden" name="blabla" value="Do-not-translate">
</div>
</body>
</html>
HTML

my $flute = Template::Flute->new(specification => $spec,
                                 template => $template,
                                 i18n => $i18n);
my $output = $flute->process();

like $output, qr/Titolo/, "Title translated";
like $output, qr/value=" Invia i risultati"/, "input submit translated";
like $output, qr/placeholder=" Inserisci il nome utente... "/,
  "placeholder translated";
like $output, qr/value="Do-not-translate"/, "hidden input preserved";
