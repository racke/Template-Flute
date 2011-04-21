#! perl -T
#

use strict;
use warnings;

use Test::More tests => 1;

use Template::Flute;
use Template::Flute::I18N;

my (%german_map, $i18n, $flute, $output);

%german_map = (Cart=> 'Warenkorb', Price => 'Preis');

sub translate {
	my $text = shift;
	
	return $german_map{$text};
};

$i18n = Template::Flute::I18N->new(\&translate);

$flute = Template::Flute->new(specification => '<specification></specification>',
							  template => '<div>Cart</div><div>Price</div>',
							  i18n => $i18n);

$output = $flute->process();

ok($output =~ m%<div>Warenkorb</div><div>Preis</div>%, $output);
