# Template::Zoom::PDF - Zoom PDF box class
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

package Template::Zoom::PDF::Box;

use strict;
use warnings;

use Data::Dumper;

sub new {
	my ($proto, @args) = @_;
	my ($class, $self);
	my ($elt_class, @p);
	
	$class = ref($proto) || $proto;
	$self = {@args};

	unless ($self->{pdf}) {
		die "Missing PDF object\n";
	}
	
	unless ($self->{elt}) {
		die "Missing Twig element for PDF box\n";
	}

	# Record corresponding GI for box
	$self->{gi} = $self->{elt}->gi();

	# Record corresponding CLASS for box
	$elt_class = $self->{elt}->att('class');

	if (defined $elt_class) {
		$self->{class} = $elt_class;
	}
	else {
		$self->{class} = '';
	}
	
	# Mapping child elements to box objects
	$self->{eltmap} = {};

	# Stack of child elements
	$self->{eltstack} = [];

	# Positions of child elements
	$self->{eltpos} = [];
	
	bless ($self, $class);

	# Create selector map
	@p = (class => $self->{class}, parent => $self->{selector_map});
	
	$self->{selector_map} = $self->{pdf}->{css}->descendant_properties(@p);
		
	unless ($self->{specs}) {
		$self->setup_specs();
	}

	# Determine our window from bounding box
	%{$self->{window}} = %{$self->{bounding}};

	if ($self->{specs}->{props}->{width}) {
#		print "Reducing WINDOW width to GI $self->{gi} CLASS $self->{class} to $self->{specs}->{props}->{width}\n";
		$self->{window}->{max_w} = $self->{specs}->{props}->{width};
	}
	if ($self->{specs}->{props}->{height}) {
#		print "Reducing WINDOW height to GI $self->{gi} CLASS $self->{class} to $self->{specs}->{props}->{height}\n";
		$self->{window}->{max_h} = $self->{specs}->{props}->{height};
	}
	
	return $self;
}

sub calculate {
	my ($self) = @_;
	my ($gi, $class, $text, @parms, $childbox, $dim);

	if ($self->{elt}->is_text()) {
		# simple text box
		$text = $self->{elt}->text();

		# filter text and break into chunks to remove unnecessary whitespace
		$text = $self->{pdf}->text_filter($text);
		
		# break text first
		my @frags;

		while ($text =~ s/^(.*?)\s+//) {
			push (@frags, $1, ' ');
		}

		if (length($text)) {
			push (@frags, $text);
		}
		
		$self->{box} = $self->{pdf}->calculate($self->{elt}, text => \@frags,
											  specs => $self->{specs});

		print "Check width $self->{box}->{width}, height $self->{box}->{height}, $self->{box}->{overflow}->{x} vs $self->{window}->{max_w} for $text\n";
		
		if ($self->{box}->{overflow}->{x}) {
			warn "Uh oh, out of bounds for $text: $self->{box}->{overflow}->{x}\n";
		}
		
		return $self->{box};
	}
	
	for my $child ($self->{elt}->children()) {
		# discard elements we won't use anyway
		next if $self->{gi} eq 'style';
		next if $self->{gi} eq 'head';
		
		unless (exists $self->{eltmap}->{$child}) {
			@parms = (elt => $child, pdf => $self->{pdf},
					  parent => $self);

			if ($child->is_text()) {
				# inheriting specifications of parent
				push (@parms, specs => $self->{specs});
			}
			else {
				push (@parms, selector_map => $self->{selector_map});
			}

			push (@parms, bounding => {%{$self->{window}}});

			$childbox = new Template::Zoom::PDF::Box(@parms);

			$self->{eltmap}->{$child} = $childbox;
			
			push (@{$self->{eltstack}}, $childbox);
		}

		$dim = $self->{eltmap}->{$child}->calculate();
	}

	# processed all childs, now determine my size itself

	my ($max_width, $max_height, $vpos, $hpos, $max_stripe_height, $child) = (0,0,0,0);
	my ($hpos_next, $vpos_next, $stripe_base, $clear_after);

	$stripe_base = 0;
	$clear_after = 0;
	
	for (my $i = 0; $i < @{$self->{eltstack}}; $i++) {
		$child = $self->{eltstack}->[$i];

		if ($hpos > 0 && ! $child->{box}->{clear}->{before}
			&& ! $clear_after) {
			# check if item fits horizontally
			$hpos_next = $hpos + $child->{box}->{width};

			if ($self->{specs}->{props}->{width}
				&& $self->{specs}->{props}->{width} < $hpos_next) {
				# doesn't fit in fixed width of this box
				print "NO HORIZ FIT for GI $child->{gi} CLASS $child->{class}: too wide forH $hpos_next\n";
				$hpos = 0;				
				$hpos_next = 0;
				$max_stripe_height = 0;

			}

			if ($hpos_next > $self->{bounding}->{max_w}) {
				# doesn't fit in bounding box
				print "NO HORIZ FIT for GI $child->{gi} CLASS $child->{class}: H $hpos HN $hpos_next MAX_W  $self->{bounding}->{max_w}\n";
				$hpos = 0;
				$hpos_next = 0;
				$max_stripe_height = 0;

			}
		}
		else {
			$hpos = 0;
			$hpos_next = 0;
			$max_stripe_height = 0;
			print "NO HORIZ FIT for GI $child->{gi} CLASS $child->{class}: A $clear_after\n";
		}

		# keep vertical position
		$vpos_next = $vpos;
		
		if ($hpos_next > 0) {
			print "HORIZ FIT for GI $child->{gi} CLASS $child->{class}\n";

			if ($child->property('float') eq 'right') {
				# push it to the right border
				
				if ($self->property('width')) {
					$max_width = $self->property('width');
				}
				else {
					$max_width = $self->{bounding}->{max_w};
				}

				$hpos = $max_width - $child->{box}->{width};
				$hpos_next = $max_width;
			}
			else {
				# add to current width
				$max_width += $child->{box}->{width};

				# check whether we need to extend the height
				my $height_extend = 0;
			
				if ($child->{box}->{height} > $max_stripe_height) {
					$height_extend = $child->{box}->{height} > $max_stripe_height;
				}

				$max_stripe_height += $height_extend;
				$max_height += $height_extend;
			}
		}
		else {
			if ($child->{box}->{width} > $max_width) {
				$max_width = $child->{box}->{width};
			}

			# add to current height
			$max_height += $child->{box}->{height};

			if ($stripe_base) {
				$vpos_next = $stripe_base;
			}
			$vpos = $stripe_base;
			
			# stripe base moves to max_height
			$stripe_base = $max_height;
			
			# stripe height is simply height of this child
			$max_stripe_height = $child->{box}->{height};

			print "NEW HPOS from GI $child->{gi} CLASS $child->{class}: $child->{box}->{width}\n";
			$hpos_next = $child->{box}->{width};
		}

		$self->{eltpos}->[$i] = {hpos => $hpos, vpos => -$vpos};

		if ($child->{elt}->is_text()) {
			print "POS for TEXT " . $child->{elt}->text() . ": " . Dumper($self->{eltpos}->[$i]);
		}
		else {
			print "POS for GI $child->{gi} CLASS $child->{class}: " . Dumper($self->{eltpos}->[$i]);
		}

		# advance to new relative position
		$hpos = $hpos_next;
		$vpos = $vpos_next;

		$clear_after = $child->{box}->{clear}->{after};
	}

	# add offsets
	$max_width += $self->{specs}->{offset}->{left} + $self->{specs}->{offset}->{right};
	$max_height += $self->{specs}->{offset}->{top} + $self->{specs}->{offset}->{bottom};

	# apply fixed dimensions
	if ($self->{specs}->{props}->{width} > $max_width) {
		$max_width = $self->{specs}->{props}->{width};
	}

	if ($self->{specs}->{props}->{height} > $max_height) {
		$max_height = $self->{specs}->{props}->{height};
	}

	# set up clear properties
	my $clear = {after => 0, before => 0};

	if ($self->{gi} eq 'hr') {
		$clear->{before} = $clear->{after} = 1;
		$max_width ||= $self->{bounding}->{max_w};
	}
	elsif ($self->{gi} eq 'br') {
		$clear->{before} = 1;
	}
	elsif ($self->{gi} =~ /^h\d$/
		   || $self->{gi} eq 'p') {
		$clear->{before} = $clear->{after} = 1;
	}

	$self->{box} = {width => $max_width,
					height => $max_height,
					clear => $clear,
					size => $self->{specs}->{size}};

	print "DIM for GI $self->{gi}, CLASS $self->{class}: " . Dumper($self->{box});
	
	return $self->{box};
}

# property - returns property $name

sub property {
	my ($self, $name) = @_;

	if (exists $self->{specs}->{props}->{$name}) {
		return $self->{specs}->{props}->{$name};
	}
}

sub render {
	my ($self, %parms) = @_;
	my ($child, $pos, $margins);

	print "RENDER for  GI $self->{gi}, CLASS $self->{class}: " . Dumper(\%parms);
	
	# loop through our stack
	for (my $i = 0; $i < @{$self->{eltstack}};  $i++) {
		$child = $self->{eltstack}->[$i];
		$pos = $self->{eltpos}->[$i];
		
		$child->render(hpos => $parms{hpos} + $self->{specs}->{offset}->{left} + $pos->{hpos},
					  vpos => $parms{vpos} - $self->{specs}->{offset}->{top} + $pos->{vpos});
	}
	
	if ($self->{elt}->is_text()) {
		# render text
		my $chunks = $self->{box}->{chunks};

		print "Chunks: " . Dumper($chunks) . "\n";
		
		for (my $i = 0; $i < @$chunks; $i++) {
			$self->{pdf}->textbox($self->{elt}, $chunks->[$i],
								  $self->{specs}, {%parms, vpos => $parms{vpos} - ($i * $self->{specs}->{size})},
								  noborder => 1);
		}
	}
	elsif ($self->{gi} eq 'hr') {
		# rendering horizontal line

		$self->{pdf}->hline($self->{specs}, $parms{hpos},
							$parms{vpos} - $self->{specs}->{offset}->{top},
							$self->{box}->{width}, $self->{specs}->{props}->{height});
	}
	else {
		# render borders
		$self->{pdf}->borders($parms{hpos}, $parms{vpos},
							  $self->{box}->{width},
							  $self->{box}->{height},
							  $self->{specs});
	}
}

sub setup_specs {
	my ($self) = @_;
	my ($inherit);
	
	if ($self->{parent}) {
		$inherit = $self->{parent}->{specs}->{props};
	}
	
	# lookup ourselves in selector map from ancestors
	if ($self->{selector_map}) {
		my (@selectors);
		
		if ($self->{class}) {
			push (@selectors, ".$self->{class}");
		}
		if ($self->{gi}) {
			push (@selectors, $self->{gi});
		}

		for my $key (@selectors) {
			if ($self->{selector_map}->{$key}) {
				$self->{specs} = $self->{pdf}->setup_text_props($self->{elt},
														 $self->{selector_map}->{$key}, $inherit);
			}
		}
	}
			
	$self->{specs} ||= $self->{pdf}->setup_text_props($self->{elt}, undef, $inherit);
	return;
}

1;
