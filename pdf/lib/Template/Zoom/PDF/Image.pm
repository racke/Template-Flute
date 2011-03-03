# Template::Zoom::PDF::Image - Image object for Zoom PDF output engine
#
# Copyright (C) 2011 Stefan Hornburg (Racke) <racke@linuxia.de>.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public
# License along with this program; if not, write to the Free
# Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA 02110-1301, USA.

package Template::Zoom::PDF::Image;

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
			$self->{file} = File::Spec->catfile($template_dir,
												basename($self->{file}));
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

sub width {
	my $self = shift;

	return $self->{width};
}

sub height {
	my $self = shift;

	return $self->{height};
}

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

1;
