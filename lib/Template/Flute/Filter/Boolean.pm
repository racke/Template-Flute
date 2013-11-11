package Template::Flute::Filter::Boolean;

use strict;
use warnings;

use base 'Template::Flute::Filter';

sub filter {
    my ($self, $value, %args) = @_;
   	if($value and lc($value) ne 'false'){
   		return $value;
   	}
   	else {
   		return undef;
   	}
}
 
1;
