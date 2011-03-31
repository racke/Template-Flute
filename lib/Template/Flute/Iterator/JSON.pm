package Template::Flute::Iterator::JSON;

use strict;
use warnings;

use JSON;

use base 'Template::Flute::Iterator';

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

=head1 CONSTRUCTOR

=head2 new

Creates an Template::Flute::Iterator::JSON object from a JSON string.

The JSON string can be either passed as such or as scalar reference.

=cut

sub new {
	my ($class, @args) = @_;
	my ($json, $json_struct, $self, $key, $value);

	$self = {};
	
	bless ($self, $class);

	if (@args == 1) {
		# single parameter => JSON is passed as string or scalar reference
		if (ref($args[0]) eq 'SCALAR') {
			$json = ${$args[0]};
		}
		else {
			$json = $args[0];
		}

		$json_struct = from_json($json);
		$self->seed($json_struct);
		
		return $self;
	}
	
	while (@args) {
		$key = shift(@args);
		$value = shift(@args);
		
		$self->{$key} = $value;
	}

	if ($self->{file}) {
		$json_struct = $self->_parse_json_from_file($self->{file});
		$self->seed($json_struct);
	}
	else {
		die "Missing JSON file.";
	}
	
	return $self;
}

sub _parse_json_from_file {
	my ($self, $file) = @_;
	my ($json_fh, $json_struct, $json_txt);
	
	# read from JSON file
	unless (open $json_fh, '<', $file) {
		die "$0: failed to open JSON file $file: $!\n";
	}

	while (<$json_fh>) {
		$json_txt .= $_;
	}

	close $json_fh;

	# parse JSON
	$json_struct = from_json($json_txt);

	return $json_struct;
}

=head1 AUTHOR

Stefan Hornburg (Racke), <racke@linuxia.de>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
