#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
binmode STDOUT, ":encoding(utf-8)";

use Test::More;
use Template::Flute;

use XML::Twig;
use Data::Dumper;

plan tests => 4;


my $template_html =<< 'HTML';
<!doctype html>
<html>
<head>
<title>test</title>
</head>
<body>
<div id="body">body</div>
<script>if ( this.value && ( !request.term || matcher.test(text) ) && 0 < 1 )</script>
<div id="test">hello</div>
<span id="spanning" style="display:none">hello</span>
</body>
</html>
HTML

my $template_spec = q{<specification><value name="body" id="body"/><value name="none" id="spanning"/></specification>};

my $flute = Template::Flute->new(specification => $template_spec,
                                 template => $template_html,
                                 values => {
                                            body => "body",
                                            none => "hello",
                                           });

my $output = $flute->process();

print "\nOUTPUT:\n", $output, "\n\n";

ok(index($output, q{&& 0 < 1}) >= 0, "&& has NOT been escaped");
ok(index($output, q{0 &lt; 1}) < 0, "< has been NOT escaped");
ok(index($output, q{if ( this.value && ( !request.term || matcher.test(text) ) && 0 < 1 )}) >= 0, "js found verbatim");


my $fixed_html =<< 'HTML';
<div id="body">body</div>
<script>
//<![CDATA[
if ( this.value && ( !request.term || matcher.test(text) ) && 1 > 0 && 0 < 1 )
//]]>
</script>
<div id="test">test</div>
<span id="spanning" style="display:none">test</span>
HTML

$flute = Template::Flute->new(specification => $template_spec,
                              template => $fixed_html,
                              values => {
                                         body => "hello",
                                         none => "hello",
                                        });

$output = $flute->process();

ok((index($output,
         q{if ( this.value && ( !request.term || matcher.test(text) ) && 1 > 0 && 0 < 1 )}) >= 0), "script ok");

diag "\nOUTPUT:\n", $output, "\n\n";

diag "End of T::F tests. Testing Twig internals";

if ($output =~ m/\]\]&gt;/) {
    diag "End of CDATA escaped because of XML::Twig";
}
