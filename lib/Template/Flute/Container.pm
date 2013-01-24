package Template::Flute::Container;

use strict;
use warnings;

=head1 NAME

Template::Flute::Container - Container object for Template::Flute templates.

=head1 CONSTRUCTOR

=head2 new

Creates Template::Flute::Container object.

=cut

use Template::Flute::Expression;

# Constructor
sub new {
	my ($class, $sob, $spec, $name) = @_;
	my ($self);
	
	$class = shift;
	
	$self = {sob => $sob};

	bless $self;
	
	return $self;
}

=head1 METHODS

=head2 name

Returns name of the container.

=cut

sub name {
	my ($self) = @_;

	return $self->{sob}->{name};
}

=head2 set_values

Passes current values to this container.

=cut
	
sub set_values {
	my ($self, $values) = @_;

	$self->{values} = $values;
}

=head2 elts

Returns corresponding HTML template elements for this container.

=cut

sub elts {
	my ($self) = @_;

	return $self->{sob}->{elts};
}

=head2 visible

Determines whether the container is visible. Possible return values are 1 (visible),
0 (hidden) or undef if the specification for the container misses a value attribute.

=cut
	
# visible
sub visible {
	my ($self) = @_;
	my ($key, $ret);
	
	if ($key = $self->{sob}->{value}) {
	    # check whether this is an expression or a simple value
	    if ($key =~ /^\w[0-9\w_-]*$/) {
		if (exists $self->{values}) {
			if ($self->{values}->{$key}) {
				return 1;
			}
			return 0;
		}

		return undef;
	    }
	    else {
		$self->{_expr_parser} ||= Template::Flute::Expression->new($key);
		$ret = $self->{_expr_parser}->evaluate($self->{values});

		if ($ret) {
		    return 1;
		}

		return 0;
	    }
	}

	# container is visible if no value is specified
	return 1;
}

=head1 AUTHOR

Stefan Hornburg (Racke), <racke@linuxia.de>

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2013 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
	
1;
