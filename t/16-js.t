#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
binmode STDOUT, ":encoding(utf-8)";

use Test::More;
use Template::Flute;

use XML::Twig;
use Data::Dumper;

if ($XML::Twig::VERSION > 3.39) {
    plan skip_all => "WARNING! Your XML::Twig version probably contains a bug when parsing entities!. Skipping test";
}
else {
    plan tests => 7;
}

my $template_html =<< 'HTML';
<!doctype html>
<html>
<head>
<title>test</title>
</head>
<body>
<div id="body">body</div>
<script>if ( this.value && ( !request.term || matcher.test(text) ) && 0 < 1 )</script>
<div id="test">&nbsp; v&amp;r</div>
<span id="spanning" style="display:none">&nbps;</span>
</body>
</html>
HTML

my $template_spec = q{<specification><value name="body" id="body"/><value name="none" id="spanning"/></specification>};

my $flute = Template::Flute->new(specification => $template_spec,
                                 template => $template_html,
                                 values => {
                                            body => "v&r",
                                            none => "hello",
                                           });

my $output = $flute->process();

print "\nOUTPUT:\n", $output, "\n\n";


ok(index($output, q{>v&amp;r<}) > 0, "rendering ok");
ok(index($output, q{&& 0 < 1}) > 0, "&& has NOT been escaped");
ok(index($output, q{0 &lt; 1}) < 0, "< has been NOT escaped");

my $fixed_html =<< 'HTML';
<div id="body">body</div>
<script>
//<![CDATA[
if ( this.value && ( !request.term || matcher.test(text) ) && 1 > 0 && 0 < 1 )
//]]>
</script>
<div id="test">&nbsp; v&amp;r</div>
<span id="spanning" style="display:none">&nbps;</span>
HTML

$flute = Template::Flute->new(specification => $template_spec,
                              template => $fixed_html,
                              values => {
                                         body => "v&r",
                                         none => "hello",
                                        });

# use Data::Dumper;

$output = $flute->process();

ok((index($output,
         q{if ( this.value && ( !request.term || matcher.test(text) ) && 1 > 0 && 0 < 1 )}) > 0), "script ok");

diag "\nOUTPUT:\n", $output, "\n\n";

diag "End of T::F tests. Testing Twig internals";

my $parser = XML::Twig->new;
my $xml = $parser->safe_parse_html($fixed_html);
my @elts = $xml->get_xpath('#CDATA');
ok(@elts == 0, "no cdata found");

@elts = $xml->get_xpath('//script');
foreach my $el (@elts) {
    $el->set_asis;
    diag "The node is correct? " . $el->text;
    ok((index($el->text, "//]]>") >= 0), "cdata ok");
}

ok((index($xml->sprint, ']]&gt;') >= 0), "but ]]> get escaped for unknown reasons");
diag $xml->sprint;
