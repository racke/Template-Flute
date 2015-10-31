package Template::Flute::Increment;

use Moo;
use Types::Standard qw/Int/;

=head1 NAME

Template::Flute::Increment - Increment class for Template::Flute

=head1 SYNOPSIS

    $increment = new Template::Flute::Increment(start => 4, step => 2);
    $increment->increment;  # 6

=head1 ACCESSORS

=head2 start

Start value for the increment. Defaults to 1.

=cut

has start => (
    is => 'ro',
    isa => Int,
    default => 1,
);

=head2 step

Value added to the increment with each call of the increment method.
Defaults to 1.

=cut

has step => (
    is      => 'ro',
    isa     => Int,
    default => 1,
);

=head2 value

current value of the increment.

=over

=item writer: update_value

=back

=cut

has value => (
    is     => 'lazy',
    isa    => Int,
    writer => 'update_value',
);

sub _build_value {
    return $_[0]->start;
}

sub BUILDARGS {
    my $class = shift;
    my %args;
    if ( @_ % 2 ) {
        %args = %{ $_[0] };
    }
    else {
        %args = @_;
    }
    # backwards compatibility with pre-Moo class which had iterator as
    # attribute and method
    if ( defined $args{iterator} && !defined $args{step} ) {
        $args{step} = $args{iterator};
    }
    return \%args;
}

=head1 METHODS

=head2 increment

Adds L</step> to L</value> of increment.

=cut

sub increment {
	my $self = shift;
	$self->update_value( $self->value + $self->step );
}

=head1 AUTHOR

Stefan Hornburg (Racke), <racke@linuxia.de>

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2015 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
