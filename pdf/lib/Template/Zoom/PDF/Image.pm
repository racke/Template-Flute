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

use Image::Size;

# map of supported image types
my %types = (JPG => 'jpeg',
			 TIF => 'tiff',
#			'pnm',
			 PNG => 'png',
			 GIF => 'gif',
			);

sub new {
	my ($proto, @args) = @_;
	my ($class, $self, @ret);

	$class = ref($proto) || $proto;
	$self = {@args};

	unless ($self->{file}) {
		die "Missing file name for image object.\n";
	}

	# determine width, height, file type
	@ret = imgsize($self->{file});

	if (exists $types{$ret[2]}) {
		$self->{type} = $types{$ret[2]};
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

1;
