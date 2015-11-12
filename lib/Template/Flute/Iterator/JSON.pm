package Template::Flute::Iterator::JSON;

use strict;
use warnings;

use Moo;
use JSON 'from_json';
use Types::Standard qw/HashRef Str Undef/;
use namespace::clean;
use MooX::StrictConstructor;

extends 'Template::Flute::Iterator';

=head1 NAME

Template::Flute::Iterator::JSON - Iterator class for JSON strings and files

=head1 SYNOPSIS

    $json = q{[
        {"sku": "orange", "image": "orange.jpg"},
        {"sku": "pomelo", "image": "pomelo.jpg"}
    ]};

    $json_iter = Template::Flute::Iterator::JSON->new($json);

    $json_iter->next();

    $json_iter_file = Template::Flute::Iterator::JSON->new(file => 'fruits.json');

=head1 DESCRIPTION

Template::Flute::Iterator::JSON is a subclass of L<Template::Flute::Iterator>.

=head1 ATTRIBUTES

=head2 json

=cut

has json => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

=head2 selector

=cut

has selector => (
    is => 'ro',
    isa => HashRef | Str | Undef,
);

=head2 children

=cut

has children => (
    is => 'ro',
    isa => Str | Undef,
);

=head1 METHODS

=cut

sub BUILDARGS {
	my ($class, @args) = @_;
	my %args;

	if (@args == 1) {
		# single parameter => JSON is passed as string or scalar reference
		if (ref($args[0]) eq 'SCALAR') {
			$args{json} = ${$args[0]};
		}
		else {
			$args{json} = $args[0];
		}
	}
    else {
        %args = @args;

        die "Missing JSON file or string"
          if ( !defined $args{json} && !defined $args{file} );

        if ( my $file = delete $args{file} ) {
            my ( $json_fh, $json_txt );

            # read from JSON file
            unless ( open $json_fh, '<', $file ) {
                die "$0: failed to open JSON file $file: $!\n";
            }

            while (<$json_fh>) {
                $json_txt .= $_;
            }

            close $json_fh;

            $args{json} = $json_txt;
        }
    }
	
	return \%args;
}

=head2 BUILD

Converts L</json> to Perl structure and applies L</selector> and
L</children> if they are defined.

=cut

sub BUILD {
    my $self = shift;

    my $json_struct = from_json( $self->json );

    if (defined $self->selector) {
        if (ref($self->selector) eq 'HASH') {
            my (@k, $key, $value);

            # loop through top level elements and locate selector
            if ((@k = keys %{$self->selector})) {
                $key = $k[0];
                $value = $self->selector->{$key};

                for my $record (@$json_struct) {
                    if (exists $record->{$key} 
                        && $record->{$key} eq $value) {
                        $self->seed($record->{$self->children});
                        return;
                    }
                }
            }

            return;
        }
        elsif ($self->selector eq '*') {
            # find all elements
            $self->seed( $self->_tree( $json_struct, $self->children ) );

#            if ($self->{sort}) {
#                $self->sort($self->{sort}, $self->{unique});
#            }

            return;
        }

        # no matches for selector
        return;
    }
    
    $self->seed($json_struct);
}

sub _tree {
    my ($self, $json_struct, $children) = @_;
    my (@leaves);

    for my $record (@$json_struct) {
        if (exists $record->{$children}) {
            for my $child (@{$record->{$children}}) {
                push (@leaves, $child);
            }
        }
    }

    return \@leaves;
}


=head1 AUTHOR

Stefan Hornburg (Racke), <racke@linuxia.de>

=head1 LICENSE AND COPYRIGHT

Copyright 2011-2015 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
