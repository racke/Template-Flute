package Template::Flute::Form;

use strict;
use warnings;
use Template::Flute::Types qw/ArrayRef Bool HashRef InstanceOf Str/;
use Moo;
use namespace::clean;

=head1 NAME

Template::Flute::Form - Form object for Template::Flute templates.

=head1 CONSTRUCTOR

=head2 new

Creates Template::Flute::Form object.

Arguments:

=over

=item sob

=item static

=back

=cut

has action => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    writer  => 'set_action',
    default => sub { $_[0]->elt->att('action') || '' },
    trigger => sub { $_[0]->elt->set_att( 'action', $_[1] ) },
);

has elt => (
    is      => 'ro',
    isa     => InstanceOf ['XML::Twig::Elt'],
    lazy    => 1,
    default => sub { $_[0]->sob->{elts}->[0] },
);

has fields => (
    is      => 'ro',
    isa     => ArrayRef,
    writer  => 'fields_add',
    default => sub { [] },
    trigger => sub {
        my ( $self, $fields ) = @_;
        for my $field (@$fields) {
            if ( $field->{iterator} ) {
                $self->iterators->{ $field->{iterator} } = $field->{name};
            }
        }
    },
);

has is_filled => (
    is     => 'ro',
    isa    => Bool,
    writer => '_set_is_filled',
);

has inputs => (
    is      => 'ro',
    isa     => HashRef,
    trigger => sub { $_[0]->_set_valid_input(0) },
    writer  => 'inputs_add',
);

has iterators => (
    is      => 'ro',
    isa     => HashRef,
    default => sub { +{} },
);

has method => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    writer  => 'set_method',
    default => sub {
        my $method = $_[0]->elt->att('method');
        return defined($method) && $method =~ /\S/ ? uc($method) : 'GET';
    },
    trigger => sub { $_[0]->elt->set_att( 'method', $_[1] ) },
);

has name => (
    is => 'ro',
    isa => Str,
    lazy => 1,
    default => sub { $_[0]->sob->{name} },
);

has params => (
    is      => 'ro',
    isa     => ArrayRef,
    default => sub { [] },
    coerce  => sub { defined $_[0] ? $_[0] : [] },
    writer  => 'params_add',
);

has sob => (
    is       => 'ro',
    isa      => HashRef,
    required => 1,
);

has static => (
    is       => 'ro',
    required => 1,
);

has _valid_input => (
    is       => 'ro',
    isa      => Bool,
    default  => undef,
    init_arg => undef,
    writer   => '_set_valid_input',
);

# FIXME: (SysPete 29/4/16) Keep old api for now.
sub BUILDARGS {
    my ( $class, $sob, $static ) = @_;

    return { sob => $sob, static => $static };
}

=head1 METHODS

=head2 params_add PARAMS

Add parameters from PARAMS to form.

=head2 fields_add FIELDS

Add fields from FIELDS to form.

=head2 inputs_add INPUTS

Add inputs from INPUTS to form.

=head2 name

Returns name of the form.

=head2 elt

Returns corresponding HTML template element of the form.

=head2 fields

Returns form fields.

=head2 params

Returns form parameters.

=head2 inputs

Returns form inputs.

=head2 input PARAMS

Verifies that input parameters are sufficient.
Returns 1 in case of success, 0 otherwise.

=cut	

sub input {
	my ($self, $params) = @_;
	my ($error_count);

    if ( !$params && $self->_valid_input ) {
        return 1;
    }
	
	$error_count = 0;
	$params ||= {};
	
	for my $input (values %{$self->inputs}) {
		if ($input->{required} && ! $params->{$input->{name}}) {
			warn "Missing input for $input->{name}.\n";
			$error_count++;
		}
		else {
			$input->{value} = $params->{$input->{name}};
		}
	}

	if ($error_count) {
		return 0;
	}

    $self->_set_valid_input(1);
	return 1;
}

=head2 iterators

Returns names of all iterators used by the fields for this form.

=head2 action

Returns current form action.

=head2 set_action ACTION

Sets from action to ACTION.

=head2 method

Returns current form method, e.g. GET or POST.

=head2 set_method METHOD

Sets form method to METHOD, e.g. GET or POST.

=head2 fill PARAMS

Fills form with parameters from hash reference PARAMS.

=head2 is_filled

Return true if you called fill on the form.

=cut

sub _set_filled {
    my $self = shift;
    $self->_set_is_filled(1);
}

sub fill {
	my ($self, $href) = @_;
	my ($f, @elts, $value, $zref, $type);
    $self->_set_filled;
	for my $f (@{$self->fields()}) {
		@elts = @{$f->{elts}};

		if (exists $href->{$f->{name}}
			&& defined $href->{$f->{name}}) {
			$value = $href->{$f->{name}};
		}
		else {
			$value = '';
		}
		
		if (@elts == 1) {
			$zref = $elts[0]->{"flute_$f->{name}"};
			$type = $elts[0]->att('type') || '';
			
			if ($zref->{rep_sub}) {
				# call subroutine to handle this element
				$zref->{rep_sub}->($elts[0], $value);
			}
			elsif ($elts[0]->gi() eq 'textarea') {
				$elts[0]->set_text($value);
			}
			elsif ($elts[0]->gi() eq 'input') {
				if ($type eq 'submit') {
					# don't override button text
				}
				elsif ($type eq 'checkbox') {
                    my $att_value = $elts[0]->att('value');

					if (defined $att_value && $value eq $att_value) {
						$elts[0]->set_att('checked', 'checked');
					}
					else {
						$elts[0]->del_att('checked');
					}
				}
				else {
					$elts[0]->set_att('value', $value);
				}
			}
		}
		elsif (@elts > 1) {
			# handle radio buttons
			for my $elt (@elts) {
				if ($elt->gi() eq 'input') {
					if ($elt->att('type') eq 'radio') {
						if ($value eq $elt->att('value')) {
							$elt->set_att('checked', 'checked');
						}
					}
					elsif ($elt->att('type') eq 'checkbox') {
						if (ref($value) eq 'ARRAY') {
							if (grep {$_ eq $elt->att('value')}
								@$value) {
								$elt->set_att('checked', 'checked');
							}
							else {
								$elt->del_att('checked');
							}
						}
						elsif ($value eq $elt->att('value')) {
							$elt->set_att('checked', 'checked');
						}
						else {
							$elt->del_att('checked');
						}
					}
					else {
						$elt->del_att('checked');
					}
				}
			}
		}
	}
}

=head1 AUTHOR

Stefan Hornburg (Racke), <racke@linuxia.de>

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2016 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
