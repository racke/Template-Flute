#!perl
use strict;
use warnings;
use Test::More tests => 2;

use Template::Flute;
use Template::Flute::I18N;

my $xml = <<EOF;
<specification name="textarea">
<form name="textarea" id="textarea">
<field name="content"/>
</form>
</specification>
EOF

my $html = <<EOF;
<form name="textarea" id="textarea">
<textarea class="content">
</textarea>
</form>
EOF

sub translate {
    my $l = shift;
    return $l;
}


{
    my $flute = new Template::Flute(
                                    specification => $xml,
                                    template => $html,
                                   );
    my ($form) = $flute->template->forms;
    $form->fill({content => "Hello World\r\nHello There"});
    my $out =  $flute->process;
    like $out, qr/Hello World\r\nHello There/, "new line preserved" or diag $out;
}


{
    my $i18n = Template::Flute::I18N->new(\&translate);
    my $flute = new Template::Flute(
                                    specification => $xml,
                                    template => $html,
                                    i18n => $i18n,
                                   );
    my ($form) = $flute->template->forms;
    $form->fill({content => "Hello World\r\nHello There"});
    my $out =  $flute->process;
    like $out, qr/Hello World\r\nHello There/, "new line preserved" or diag $out;
}

