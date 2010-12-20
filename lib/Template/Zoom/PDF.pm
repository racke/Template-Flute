# Template::Zoom::PDF - Zoom PDF output engine
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

package Template::Zoom::PDF;

use strict;
use warnings;

use Data::Dumper;

use PDF::API2;
use PDF::Table;

use Template::Zoom::HTML::Table;
use Template::Zoom::Style::CSS;

use Template::Zoom::PDF::Import;
use Template::Zoom::PDF::Box;

# defaults
use constant FONT_FAMILY => 'Helvetica';
use constant FONT_SIZE => '12';

sub new {
	my ($proto, @args) = @_;
	my ($class, $self);

	$class = ref($proto) || $proto;
	$self = {@args};

	if ($self->{template}) {
		$self->{xml} = $self->{template}->root();
		$self->{css} = new Template::Zoom::Style::CSS(template => $self->{template});
	}

	bless ($self, $class);
}

sub process {
	my ($self, $file) = @_;
	my ($pdf, $font, $table);

	$self->{cur_page} = 1;
	
	$pdf = new PDF::API2(-file => $file);
	$table = new PDF::Table;

	$self->{pdf} = $pdf;
#	$self->{page} = $page;
	$self->{pdftable} = $table;
	

# Page definitions in mm
# --------------------------------------------------
# Paper size 160x297 mm
my $page_width    = 160; # Custom width in mm
my $page_height   = 297; # A4 height in mm

my $margin_left   =  10;
my $margin_right  =  10;
my $margin_top    =   2;
my $margin_bottom =   5;

my $spacer_bnr_inv		=   5;
my $invoice_banner_height	=   8;
my $invoice_address_height	=  20;

my $totals_height		=  15;

my $notes_height	= 10;
my $promo_height	= 10;
my $vat_coc_height	=  3;
my $footer_height	=  3;

	$self->{margin_left} = $margin_left;
	$self->{margin_right} = $margin_right;
	$self->{page_width} = $page_width;
	
	$self->{border_left} = to_points($margin_left);
	$self->{border_right} = to_points($page_width - $margin_right);

	$self->{border_top} = to_points($page_height - $margin_top);
	$self->{border_bottom} = to_points($margin_bottom);

	$self->{vpos_next} = $self->{border_top};
	
	$self->{hpos} = $self->{border_left};
	$self->{y} = $self->{page_height} = to_points($page_height - $margin_top);

	if ($self->{verbose}) {
		print "Starting page at X $self->{hpos} Y $self->{y}.\n";
		print "Borders are T $self->{border_top} R $self->{border_right} B $self->{border_bottom} L $self->{border_left}.\n\n";
	}

	$pdf->mediabox( to_points($page_width), to_points($page_height) );

	my %h = $pdf->info(
        'Producer'     => "Template::Zoom",
	);

	if ($self->{import}) {
		my ($obj, $ret, %import_parms);

		if (ref($self->{import})) {
			%import_parms = %{$self->{import}};
		}
		else {
			%import_parms = (file => $self->{import});
		}

		$import_parms{pdf} = $self->{pdf};
		
		$obj = new Template::Zoom::PDF::Import;
		
		unless ($ret = $obj->import(%import_parms)) {
			die "Failed to import file $self->{import}.\n";
		}

		if ($self->{verbose} || 1) {
			print "Imported PDF $self->{import}: $ret->{pages} pages.\n\n";
		}

		$self->{page} = $ret->{cur_page};
#		$pdf->saveas();
#		return;
	}

	# Open first page
	$self->{page} ||= $pdf->page($self->{cur_page});

	$pdf->preferences(
					  -fullscreen => 0,
					  -singlepage => 1,
					  -afterfullscreenoutlines => 1,
					  -firstpage => [ $self->{page} , -fit => 0],
					  -displaytitle => 1,
					  -fitwindow => 0,
					  -centerwindow => 1,
					  -printscalingnone => 1,
	);
	
	# retrieve default settings for font etc from CSS
	my $css_defaults = $self->{css}->properties(tag => 'body');

	# set font
	if ($css_defaults->{font}->{family}) {
		$self->{fontfamily} = $css_defaults->{font}->{family};
	}
	else {
		$self->{fontfamily} = FONT_FAMILY;
	}

	if ($css_defaults->{font}->{size}) {
		$self->{fontsize} = to_points($css_defaults->{font}->{size});
	}
	else {
		$self->{fontsize} = FONT_SIZE;
	}

	if ($css_defaults->{font}->{weight}) {
		$self->{fontweight} = $css_defaults->{font}->{weight};
	}
	else {
		$self->{fontweight} = '';
	}

	if ($self->{fontweight}) {
		$font = $self->{pdf}->corefont("$self->{fontfamily},$self->{fontweight}",
									   -encoding => 'latin1');
	}
	else {
		$font = $self->{pdf}->corefont($self->{fontfamily},-encoding => 'latin1');
	}
	
	$self->{page}->text->font($font, $self->{fontsize});

	# move to starting point
	$self->{page}->text->translate($self->{border_left}, $self->{border_top});
									
	# now walk HTML document and add appropriate parts
	my ($root_box, @root_parms);

	@root_parms = (pdf => $self,
				   elt => $self->{xml},
				   bounding => {vpos => $self->{border_top},
								hpos => $self->{border_left},
								max_w => $self->{border_right} - $self->{border_left},
								max_h => $self->{border_top} - $self->{border_bottom}});

	$root_box = new Template::Zoom::PDF::Box(@root_parms);

	$root_box->calculate();
	$root_box->render(vpos => $self->{border_top},
					  hpos => $self->{border_left});
	
#	$self->walk_template($self->{xml});
	
	$pdf->saveas();
	
	return;
}

# converts widths to points, default unit is mm
sub to_points {
	my $width = shift;
	my ($unit, $points);

	return 0 unless defined $width;

	if ($width =~ s/^(\d+(\.\d+)?)(in|px|pt|cm|mm)?$/$1/) {
		$unit = $3 || 'mm';
	}
	else {
		warn "Invalid width $width\n";
		return;
	}

	if ($unit eq 'in') {
		# 72 points per inch
		$points = 72 * $width;
	}
	elsif ($unit eq 'cm') {
		$points = 72 * $width / 2.54;
	}
	elsif ($unit eq 'mm') {
		$points = 72 * $width / 25.4;
	}
	elsif ($unit eq 'pt') {
		$points = $width;
	}
	elsif ($unit eq 'px') {
		$points = $width;
	}

	return sprintf("%.0f", $points);
}

sub content_width {
	my ($self) = @_;
	my ($width);
	
	$width = $self->{page_width} - $self->{margin_left} - $self->{margin_right};

	return to_points($width);
}

sub text_filter {
	my ($self, $text) = @_;

	# fall back to empty string
	unless (defined $text) {
		return '';
	}

	# replace newlines with blanks
	$text =~ s/\n/ /gs;

	# remove leading/trailing whitespace
	$text =~ s/^\s+//;
	$text =~ s/\s+$//;

	return $text;
}

sub setup_text_props {
	my ($self, $elt, $selector, $inherit) = @_;
	my ($props, %borders, %padding, %margins, %offset, $fontsize, $fontfamily,
		$fontweight, $txeng);

	my $class = $elt->att('class') || '';
	my $gi = $elt->gi();

	$selector ||= '';
	
	# get properties from CSS
	$props = $self->{css}->properties(class => $elt->att('class'),
									  tag => $elt->gi(),
									  selector => $selector,
									  inherit => $inherit,
									 );
			
	$txeng = $self->{page}->text;

	if ($props->{font}->{size} && $props->{font}->{size} =~ s/^(\d+)(pt)?$/$1/) {
		$fontsize =  $props->{font}->{size};
	}
	else {
		$fontsize = $self->{fontsize};
	}

	if ($props->{font}->{family}) {
		$fontfamily = $props->{font}->{family};
	}
	else {
		$fontfamily = $self->{fontfamily};
	}

	if ($props->{font}->{weight}) {
		$fontweight = $props->{font}->{weight};
	}
	else {
		$fontweight = $self->{fontweight};
	}
	
	if ($fontweight) {
		$self->{font} = $self->{pdf}->corefont("$fontfamily,$fontweight",-encoding => 'latin1' );
	}
	else {
		$self->{font} = $self->{pdf}->corefont($fontfamily,-encoding => 'latin1' );
	}

	$txeng->font($self->{font}, $fontsize);

	if ($gi eq 'hr') {
		unless (keys %{$props->{margin}}) {
			# default margins for horizontal rule
			my $margin;

			$margin = 0.5 * $fontsize;

			$props->{margin} = {top => $margin,
								bottom => $margin};
		}
	}
				
	# offsets from border, padding etc.
	for my $s (qw/top right bottom left/) {
		$borders{$s} = to_points($props->{border}->{$s}->{width});
		$margins{$s} = to_points($props->{margin}->{$s});
		$padding{$s} = to_points($props->{padding}->{$s});

		$offset{$s} += $margins{$s} + $borders{$s} + $padding{$s};
	}

	# height and width
	$props->{width} = to_points($props->{width});
	$props->{height} = to_points($props->{height});
	
	return {font => $self->{font}, size => $fontsize, offset => \%offset,
			borders => \%borders, margins => \%margins, padding => \%padding, props => $props,
			# for debugging
			class => $class, selector => $selector
		   };
}

sub calculate {
	my ($self, $elt, %parms) = @_;
	my ($text, $chunk_width, $text_width, $max_width, $height, $specs, $txeng,
		$overflow_x, $overflow_y, $clear_before, $clear_after, @chunks, $buf);
	
	$txeng = $self->{page}->text();
	$max_width = 0;
	$height = 0;
	$overflow_x = $overflow_y = 0;
	$clear_before = $clear_after = 0;
	
	if (ref($parms{text}) eq 'ARRAY') {
		if ($parms{specs}) {
			$specs = $parms{specs};
		}
		else {
			$specs = $self->setup_text_props($elt);
		}
		
		$height = $specs->{size};

		$buf = '';
		$text_width = 0;
		
		for my $text (@{$parms{text}}) {
			if ($text eq "\n") {
				push (@chunks, $buf . $text);
				$buf = '';
				$text_width = 0;
				
				$height += $specs->{size};
			}
			elsif ($text =~ /\S/) {
				$chunk_width = $txeng->advancewidth($text, font => $specs->{font},
												   fontsize => $specs->{size});

				print "TW for $text and $specs->{props}->{width} $specs->{size}: $text_width\n";
			}
			else {
				# whitespace
				$chunk_width = $txeng->advancewidth("\x20", font => $specs->{font},
												   fontsize => $specs->{size});
				$buf .= $text;
			}

			if ($specs->{props}->{width}
				&& $text_width + $chunk_width > $specs->{props}->{width}) {
				print "Line break by long text: $buf + $text\n";

				push (@chunks, $buf . $text);
				$buf = '';
				$text_width = 0;
			}
			else {
				$buf .= $text;
			}

			$text_width += $chunk_width;
			
			if ($text_width > $max_width) {
				$max_width = $text_width;
			}
		}

		if ($buf) {
			push (@chunks, $buf);
		}
	}

	if ($parms{clear} || $specs->{props}->{clear} eq 'both') {
		$clear_before = $clear_after = 1;
	}
	elsif ($specs->{props}->{clear} eq 'left') {
		$clear_before = 1;		
	}
	elsif ($specs->{props}->{clear} eq 'right') {
		$clear_after = 1;
	}
	
	print "Before offset: MW $max_width H $height S $specs->{size}, ", Dumper($specs->{offset}) . "\n";
	
#	print "PW $specs->{props}->{width}, PH $specs->{props}->{height}, MW $max_width H $height\n";

	# line height
	if (exists $specs->{props}->{line_height}) {
		if ($height > 0) {
			$height = to_points($specs->{props}->{line_height});
		}
	}
	
	# adjust to fixed width
	if ($specs->{props}->{width}) {
		if ($specs->{props}->{width} < $max_width) {
			$overflow_x = $max_width - $specs->{props}->{width};
			$max_width = $specs->{props}->{width};
		}
		else {
			$max_width = $specs->{props}->{width};
		}
	}

	# adjust to fixed height
	if ($specs->{props}->{height}) {
		if ($specs->{props}->{height} < $height) {
			$overflow_y = $height - $specs->{props}->{height};
			$height = $specs->{props}->{height};
		}
		else {
			$height = $specs->{props}->{height};
		}
	}
	
	return {width => $max_width, height => $height, size => $specs->{size},
			clear => {before => $clear_before, after => $clear_after},
			overflow => {x => $overflow_x, y => $overflow_y},
			chunks => \@chunks,
		   };
}

sub check_out_of_bounds {
	my ($self, $pos, $dim) = @_;

	if ($pos->{hpos} == $self->{border_right}) {
		# we are on the left border, so even if the box is out
		# of bounds, we have no better idea :-)
		return;
	}
	
#	print "COB pos: " . Dumper($pos) . "COB dim: " . Dumper($dim);
#	print "NEXT: $self->{vpos_next}.\n";

	if ($pos->{hpos} + $dim->{width} > $self->{border_right}) {
		return {hpos => $self->{border_left}, vpos => $self->{vpos_next}};
	}
	
	return;
}

sub textbox {
	my ($self, $elt, $boxtext, $boxprops, $box, %atts) = @_;
	my ($width_last, $y_top, $y_last, $left_over, $text_width, $text_height, $box_height);
	my (@tb_parms, %parms, $txeng, %offset, %borders, %padding, $props,
		$paragraph, $specs);

	if ($boxprops) {
		$specs = $boxprops;
	}
	else {
		# get specifications from CSS
		$specs = $self->setup_text_props($elt);
	}

	unless ($specs->{borders}) {
		delete $specs->{font};
		print "Elt: ", $elt->sprint(), "\n";
		print "Specs for textbox: " . Dumper($specs) . "\n";
	}
	
	$props = $specs->{props};
	%borders = %{$specs->{borders}};
	%offset = %{$specs->{offset}};
	%padding = %{$specs->{padding}};

	if ($box) {
		print "Set from box: " . Dumper($box) . " for size $specs->{size}\n";
		$self->{hpos} = $box->{hpos};
		$self->{y} = $box->{vpos};
	}

	$txeng = $self->{page}->text;
	$txeng->font($specs->{font}, $specs->{size});
	
#print "Starting pos: X $self->{hpos} Y $self->{y}\n";
	$txeng->translate($self->{hpos}, $self->{y});
	
	# determine resulting horizontal position
	$text_width = $txeng->advancewidth($boxtext);
#print "Hpos after: " . $text_width . "\n";

	# now draw the background for text box
	if ($props->{background}->{color}) {
#		print "Background for text box: $props->{background}->{color}\n";
		$self->rect($self->{hpos}, $self->{y},
					$self->{hpos} + $text_width, $self->{y} - $padding{top} - $specs->{size} - $padding{bottom},
					$props->{background}->{color});
	}

	# colors
	if ($props->{color}) {
		$txeng->fillcolor($props->{color});		
	}
	
	%parms = (x => $self->{hpos},
			  y => $self->{y} - $padding{top} - $specs->{size},
			  w => to_points($self->{page_width} - $self->{margin_left} - $self->{margin_right}),
			  h => to_points(100),
			  lead => $specs->{size},
#			  align => $props->{text}->{align} || 'left',
			  align => 'left',
			 );
		
	@tb_parms = ($txeng,  $boxtext, %parms);

print "Add textbox (class " . ($elt->att('class') || "''") . ") with content $boxtext at $parms{y} x $parms{x}, border $offset{top}\n";

	if (length($boxtext) && $boxtext =~ /\S/) {
		($width_last, $y_last, $left_over) = $self->{pdftable}->text_block(@tb_parms);

		unless (defined $width_last) {
			warn qq{Bad text block parameters for "$boxtext" (CL } . ($elt->att('class') || $elt->parent()->att('class')) . "): " . Dumper(\%parms);
		}
	}
	else {
		$y_last = $parms{y};
	}

#print "Results: W $width_last Y $y_last LO $left_over\n";

	$txeng->fill();

	my $gfx = $self->{page}->gfx();
	
	if ($width_last && $width_last < $text_width) {
		# Adjusting result
#		print "Adjusting hpos from $text_width to $width_last.\n";
		if ($width_last) {
			$text_width = $width_last + $self->{border_left};
		}
	}
		
	# move position downwards
	if ($y_last != $parms{y}) {
		$text_height = $self->{y} - $y_last;
	}
	else {
		$text_height = $specs->{size};
	}

	$box_height = $offset{top} + $text_height + $offset{bottom};

	if ($self->{y} - $box_height < $self->{vpos_next}) {
		$self->{vpos_next} = $self->{y} - $box_height;
#		print "VPOS_NEXT is $self->{vpos_next} = $self->{y} - $box_height.\n";
	}
	
	# move position downwards
#	$self->{y} -= $offset{bottom};

	# move horizontal position
	$self->{hpos} += $text_width;

	return {height => $box_height, width => $text_width };
#print "Current pos: " . $self->{y} . ' x ' . $self->{hpos} . "\n\n";
}

# draw horizontal line according to specs
sub hline {
	my ($self, $specs, $hpos, $vpos, $length, $width) = @_;
	my ($gfx);

	$gfx = $self->{page}->gfx;

	# set line color
	$gfx->strokecolor($specs->{props}->{color});

	# set line width
	$gfx->linewidth($width || 1);
	
	# starting point
	$gfx->move($hpos, $vpos);

	$gfx->line($hpos + $length, $vpos);
	
	# draw line
	$gfx->stroke();

	return;
}

# draw borders according to specs
sub borders {
	my ($self, $x_left, $y_top, $width, $height, $specs) = @_;
	my ($gfx);
	
	$gfx = $self->{page}->gfx;
	
	if ($specs->{borders}->{top}) {
		$gfx->strokecolor($specs->{props}->{border}->{top}->{color});
		$gfx->linewidth($specs->{borders}->{top});
		$gfx->move($x_left, $y_top);
		$gfx->line($x_left + $width, $y_top);
		$gfx->stroke();
	}

	if ($specs->{borders}->{left}) {
		$gfx->strokecolor($specs->{props}->{border}->{left}->{color});
		$gfx->linewidth($specs->{borders}->{left});
		$gfx->move($x_left, $y_top);
		$gfx->line($x_left, $y_top - $height);
		$gfx->stroke();
	}
	
	if ($specs->{borders}->{bottom}) {
		$gfx->strokecolor($specs->{props}->{border}->{bottom}->{color});
		$gfx->linewidth($specs->{borders}->{bottom});
		$gfx->move($x_left, $y_top - $height + $specs->{borders}->{bottom});
		$gfx->line($x_left + $width, $y_top - $height + $specs->{borders}->{bottom});
		$gfx->stroke();
	}

	if ($specs->{borders}->{right}) {
		$gfx->strokecolor($specs->{props}->{border}->{right}->{color});
		$gfx->linewidth($specs->{borders}->{right});
		$gfx->move($x_left + $width, $y_top);
		$gfx->line($x_left + $width, $y_top - $height);
		$gfx->stroke();
	}
}

# primitives
sub rect {
	my ($self, $x_left, $y_top, $x_right, $y_bottom, $color) = @_;
	my ($gfx);

	$gfx = $self->{page}->gfx;

	if ($color) {
		$gfx->fillcolor($color);
	}

	$gfx->rectxy($x_left, $y_top, $x_right, $y_bottom);

	if ($color) {
		$gfx->fill();
	}
}

1;
