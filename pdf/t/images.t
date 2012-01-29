#! perl -T

use strict;
use warnings;

use Template::Flute;
use Template::Flute::PDF;

use CAM::PDF;

use Test::More tests => 2;

my ($spec, $html, $flute, $flute_pdf, $pdf, $cam);

$html = q{<img src="t/files/sample.jpg">};

$spec = q{<specification></specification>};

$flute = Template::Flute->new(template => $html,
			      specification => $spec,
    );

$flute->process();

$flute_pdf = Template::Flute::PDF->new(template => $flute->template());

$pdf = $flute_pdf->process();

$cam = CAM::PDF->new($pdf);

# check whether we got a valid PHP file
isa_ok($cam, 'CAM::PDF');

# locate images
my ($ctree, $gs, @nodes);

$ctree = $cam->getPageContentTree(1);
$gs = $ctree->findImages();
@nodes = @{$gs->{images}};

ok(scalar(@nodes) == 1);
