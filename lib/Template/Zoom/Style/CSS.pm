# Template::Zoom::Style::CSS - Template::Zoom CSS parser
#
# Copyright (C) 2010 Stefan Hornburg (Racke) <racke@linuxia.de>.
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

package Template::Zoom::Style::CSS;

use strict;
use warnings;

use CSS::Tiny;

# names for the sides of a box, as in border-top, border-right, ...
use constant SIDE_NAMES => qw/top right bottom left/;

sub new {
	my ($proto, @args) = @_;
	my ($class, $self);

	$class = ref($proto) || $proto;
	$self = {@args};

	bless ($self, $class);

	if ($self->{template}) {
		$self->{css} = $self->initialize();
	}

	return $self;
}

sub initialize {
	my ($self) = @_;
	my (@ret, $css);

	# create CSS::Tiny object
	$css = new CSS::Tiny;

	# search for inline stylesheets
	@ret = $self->{template}->root()->get_xpath(qq{//style});
	
	for (@ret) {
		unless ($css->read_string($_->text())) {
			die "Failed to parse inline CSS: " . $css->errstr() . "\n";
		}
	}
	
	return $css;
}

sub properties {
	my ($self, %parms) = @_;
	my (@classes, @tags, %props);

	# defaults
	$props{color} = 'black';

	if (defined $parms{class} && $parms{class} =~ /\S/) {
		@classes = split(/\s+/, $parms{class});

		for my $class (@classes) {
			$self->build_properties(\%props, ".$class");
		}
	}

	if (defined $parms{tag} && $parms{tag} =~ /\S/) {
		@tags = split(/\s+/, $parms{tag});
			
		for my $tag (@tags) {
			$self->build_properties(\%props, $tag);

			if ($parms{tag} eq 'strong'
				&& ! exists $props{font}->{weight}) {
				$props{font}->{weight} = 'bold';
			}
		}
	}

	if (defined $parms{selector} && $parms{selector} =~ /\S/) {
		$self->build_properties(\%props, $parms{selector});
	}
	
	return \%props;
}

sub descendant_properties {
	my ($self, %parms) = @_;
	my (@classes, @selectors, $regex, $sel, @tags, %selmap);

	if (ref($parms{parent}) eq 'HASH') {
		%selmap = %{$parms{parent}};
	}
	
	if (defined $parms{class} && $parms{class} =~ /\S/) {
		@classes = split(/\s+/, $parms{class});

		for my $class (@classes) {
			$regex = qr{^.$class\s+};
			@selectors = $self->grep_properties($regex);

			for (@selectors) {
				$sel = substr($_, length($class) + 2);
				$selmap{$sel} = $_;
			}
		}
	}
	elsif (defined $parms{tag} && $parms{tag} =~ /\S/) {
		@tags = split(/\s+/, $parms{tag});
			
		for my $tag (@tags) {
			$regex = qr{^$tag\s+};
			@selectors = $self->grep_properties($regex);
			
			for (@selectors) {
				$sel = substr($_, length($tag) + 1);
				$selmap{$sel} = $_;
			}
		}
	}
	
	return \%selmap;
}

sub grep_properties {
	my ($self, $sel_regex) = @_;
	my (@selectors);

	@selectors = grep {/$sel_regex/} keys %{$self->{css}};

	return @selectors;
}

sub build_properties {
	my ($self, $propref, $sel) = @_;
	my ($props_css, $sides);
	my (@specs, $value);
	
	$props_css = $self->{css}->{$sel};

	# background: all possible values in arbitrary order
	# attachment,color,image,position,repeat

	if ($value = $props_css->{background}) {
		@specs = split(/\s+/, $value);

		for (@specs) {
			# attachment
			if (/^(fixed|scroll)$/) {
				$propref->{background}->{attachment} = $1;
				next;
			}
			# color (switch later to one of Graphics::ColorNames modules)
			if (/^(\#[0-9a-f]{3,6})$/) {
				$propref->{background}->{color} = $1;
				next;
			}

		}
	}

	for (qw/attachment color image position repeat/) {
		if ($value = $props_css->{"background-$_"}) {
			$propref->{background}->{$_} = $value;
		}
	}
	
	# border
	if ($value = $props_css->{border}) {
		my ($width, $style, $color) = split(/\s+/, $value);
	
		$propref->{border}->{all} = {width => $width,
			style => $style,
			color => $color};
	}
	
	# border-width, border-style, border-color
	for my $p (qw/width style color/) {
		if ($value = $props_css->{"border-$p"}) {
			$sides = $self->by_sides($value);

			$propref->{border}->{all}->{$p} = $sides->{all};
			
			for (SIDE_NAMES) {
				$propref->{border}->{$_}->{$p} = $sides->{$_} || $sides->{all};
			}
		}
	}
	
	# border sides		
	for my $s (qw/top bottom left right/) {
		if ($value = $props_css->{"border-$s"}) {
			my ($width, $style, $color) = split(/\s+/, $value);

			$propref->{border}->{$s} = {width => $width,
				style => $style,
				color => $color};
		}
		else {
			for my $p (qw/width style color/) {
				$propref->{border}->{$s}->{$p} ||=  $propref->{border}->{all}->{$p};
			}
		}

		for my $p (qw/width style color/) {
			if ($value = $props_css->{"border-$s-$p"}) {
				$propref->{border}->{$s}->{$p} = $value;
			}
		}
	}

	# clear
	if ($props_css->{clear}) {
		$propref->{clear} = $props_css->{clear};
	}
	else {
		$propref->{clear} = 'none';
	}
	
	# color
	if ($props_css->{color}) {
		$propref->{color} = $props_css->{color};
	}

	# float
	if ($props_css->{float}) {
		$propref->{float} = $props_css->{float};
	}
	else {
		$propref->{float} = 'none';
	}
	
	# font
	if ($props_css->{'font-size'}) {
		$propref->{font}->{size} = $props_css->{'font-size'};
	}
	if ($props_css->{'font-family'}) {
		$propref->{font}->{family} = $props_css->{'font-family'};
	}
	if ($props_css->{'font-weight'}) {
		$propref->{font}->{weight} = $props_css->{'font-weight'};
	}

	# height
	if ($props_css->{'height'}) {
		$propref->{height} = $props_css->{height};
	}

	# line-height
	if ($props_css->{'line-height'}) {
		$propref->{'line_height'} = $props_css->{'line-height'};
	}
	
	# margin
	if ($props_css->{'margin'}) {
		$sides = $self->by_sides($props_css->{'margin'});

		for (SIDE_NAMES) {
			$propref->{margin}->{$_} = $sides->{$_} || $sides->{all};
		}
	}

	# margin sides
	for (SIDE_NAMES) {
		if (exists $props_css->{"margin-$_"}
			&& $props_css->{"margin-$_"} =~ /\S/) {
			$propref->{margin}->{$_} = $props_css->{"margin-$_"};
		}
	}
	
	# padding
	if ($props_css->{'padding'}) {
		$sides = $self->by_sides($props_css->{'padding'});

		for (SIDE_NAMES) {
			$propref->{padding}->{$_} = $sides->{$_} || $sides->{all};
		}
	}

	# padding sides
	for (SIDE_NAMES) {
		if (exists $props_css->{"padding-$_"}
			&& $props_css->{"padding-$_"} =~ /\S/) {
			$propref->{padding}->{$_} = $props_css->{"padding-$_"};
		}
	}

	# text
	if ($props_css->{'text-align'}) {
		$propref->{text}->{align} = $props_css->{'text-align'};
	}

	# width
	if ($props_css->{'width'}) {
		$propref->{width} = $props_css->{width};
	}
	
	return $propref;
}

# helper functions

sub by_sides {
	my ($self, $value) = @_;
	my (@specs, %sides);

	@specs = split(/\s+/, $value);

	if (@specs == 1) {
		# all sides		
		$sides{all} = $specs[0];
	} elsif (@specs == 2) {
		# top/bottom, left/right
		$sides{top} = $sides{bottom} = $specs[0];
		$sides{left} = $sides{right} = $specs[1];
	} elsif (@specs == 3) {
		# top, left/right, bottom
		$sides{top} = $specs[0];
		$sides{left} = $sides{right} = $specs[1];
		$sides{bottom} = $specs[2];
	} elsif (@specs == 4) {
		# top, right, bottom, left
		$sides{top} = $specs[0];
		$sides{right} = $specs[1];
		$sides{bottom} = $specs[2];
		$sides{left} = $specs[3];
	}

	return \%sides;

}

1;

