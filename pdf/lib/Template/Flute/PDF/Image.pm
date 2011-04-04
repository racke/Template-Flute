package Template::Flute::PDF::Image;

use strict;
use warnings;

use File::Basename;
use File::Spec;
use File::Temp qw(tempfile);
use Image::Size;
use Image::Magick;

# map of supported image types
my %types = (JPG => 'jpeg',
			 TIF => 'tiff',
#			'pnm',
			 PNG => 'png',
			 GIF => 'gif',
			);

=head1 NAME

Template::Flute::PDF::Image - PDF image class

=head1 SYNOPSIS

  new Template::Flute::PDF::Image(file => $file,
                                 pdf => $self->{pdf});

=head1 CONSTRUCTOR

=head2 new

Create Template::Flute::PDF::Image object with the following parameters:

=over 4

=item file

Image file (required).

=item pdf

Template::Flute::PDF object (required).

=back

=cut

sub new {
	my ($proto, @args) = @_;
	my ($class, $self, @ret, $img_dir, $template_file, $template_dir);

	$class = ref($proto) || $proto;
	$self = {@args};

	unless ($self->{file}) {
		die "Missing file name for image object.\n";
	}

	bless ($self, $class);

	$img_dir = dirname($self->{file});

	if ($img_dir eq '.') {
		# check whether HTML template is located in another directory
		$template_dir = dirname($self->{pdf}->template()->file());

		if ($template_dir ne '.') {
			if ($self->{pdf}->{html_base}) {
				$self->{file} = File::Spec->catfile($self->{pdf}->{html_base},
													basename($self->{file}));
			}
			else {
				$self->{file} = File::Spec->catfile($template_dir,
													basename($self->{file}));
			}
		}
	}
	
	# determine width, height, file type
	@ret = imgsize($self->{file});

	if (exists $types{$ret[2]}) {
		$self->{width} = $ret[0];
		$self->{height} = $ret[1];
		$self->{type} = $types{$ret[2]};
	}
	else {
		$self->convert();
	}
	
	return $self;
}

=head1 FUNCTIONS

=head2 info

Returns image information, see L<Image::Size>.

=cut

sub info {
	my ($filename) = @_;
	my (@ret);

	@ret = imgsize($filename);

	unless (defined $ret[0]) {
		# error reading the image
		return;
	}

	return @ret;
}

=head2 width

Returns image width.

=cut

sub width {
	my $self = shift;

	return $self->{width};
}

=head2 height

Returns image height.

=cut

sub height {
	my $self = shift;

	return $self->{height};
}

=head2 convert FORMAT

Converts image to FORMAT. This is necessary as PDF::API2 does support
only a limited range of formats.

=cut	
	
sub convert {
	my ($self, $format) = @_;
	my ($magick, $msg, $tmph, $tmpfile);

	$format ||= 'png';
	
	$self->{original_file} = $self->{file};

	# create temporary file
	($tmph, $tmpfile) = tempfile('temzooXXXXXX', SUFFIX => ".$format");
	
	$magick = new Image::Magick;

	if ($msg = $magick->Read($self->{file})) {
		die "Failed to read picture from $self->{file}: $msg\n";
	}

	if ($msg = $magick->Write(file => $tmph, magick => $format)) {
		die "Failed to write picture to $tmpfile: $msg\n";
	}
	
	$self->{file} = $tmpfile;
	$self->{type} = $format;

	($self->{width}, $self->{height}) = $magick->Get('width', 'height');
	
	return 1;
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
