package Template::Zoom::Iterator;

use strict;
use warnings;

=head1 NAME

Template::Zoom::Iterator - Generic iterator class for Template::Zoom

=head1 SYNOPSIS

$cart = [{isbn => '978-0-2016-1622-4', title => 'The Pragmatic Programmer',
          quantity => 1},
         {isbn => '978-1-4302-1833-3',
          title => 'Pro Git', quantity => 1},
 		];

$iter = new Template::Zoom::Iterator($cart);

while ($record = $iter->next()) {
	print "Title: " . $record->title();
}

=head1 CONSTRUCTOR

=head2 new


=cut

# Constructor
sub new {
	my ($proto, @args) = @_;
	my ($class, $self);
	
	$class = ref($proto) || $proto;

	if (ref($args[0]) eq 'ARRAY') {
		$self = {DATA => $args[0], INDEX => 0};
	}
	else {
		$self = {DATA => \@args};
	}

	$self->{INDEX} = 0;
	$self->{COUNT} = scalar(@{$self->{DATA}});
	
	bless $self, $class;
}

=head1 METHODS

=head2 next

Returns next record or undef.

=cut

sub next {
	my ($self) = @_;


	if ($self->{INDEX} <= $self->{COUNT}) {
		return $self->{DATA}->[$self->{INDEX}++];
	}
	
	return;
};

=head2 count

Returns number of elements.

=cut
	
sub count {
	my ($self) = @_;

	return $self->{COUNT};
}

=head2 reset

Resets iterator.

=cut

# Reset method - rewind index of iterator
sub reset {
	my ($self) = @_;

	$self->{INDEX} = 0;

	return $self;
}

=head1 AUTHOR

Stefan Hornburg (Racke), <racke@linuxia.de>

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2011 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
