use strict;
use warnings;
use Test::More;
use Template::Flute;
use utf8;
binmode STDOUT, ":encoding(utf-8)";

use XML::Twig;

if ($XML::Twig::VERSION > 3.39) {
    plan skip_all => "WARNING! Your XML::Twig version probably contains a bug when parsing entities!. Skipping test";
}
else {
    plan tests => 3;
}

my $layout_html = << 'EOF';
<html>
<head>
<title>Test</title>
</head>
<body>
<div id="content">
This is the default page.
</div>
<div id="test">&nbsp;</div>
</body>
</html>
EOF

my $layout_spec = q{<specification><value name="content" id="content" op="hook"/></specification>};
my $template_html = << 'EOF';
<html>
	<head>
	<title>Test</title>
	</head>
	<div id="body">body</div>
	<div id="test">&nbsp; v&amp;r</div>
	<span id="spanning" style="display:none">&nbps;</span>
</html>
EOF
my $template_spec = q{<specification><value name="body" id="body"/><value name="none" id="spanning"/></specification>};

my $flute = Template::Flute->new(specification => $template_spec,
                                 template => $template_html,
                                 values => {
                                            body => "v&r",
                                            none => "hello",
                                           });

my $out = $flute->process();

my $expected = q{<html><div id="body">v&amp;r</div><div id="test">  v&amp;r</div><span id="spanning" style="display:none">hello</span></html>};
ok((index($out, $expected) >= 0),
  "body rendered");

my $layout = Template::Flute->new(specification => $layout_spec,
                                  template => $layout_html,
                                  values => {content => $out});

my $final = $layout->process;
ok ((index($final, $expected) >= 0), "the layout contains the body");
ok ((index($final, q{<div id="test"> </div>}) >= 0), "the layout has the decoded &nbsp;");
