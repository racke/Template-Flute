package Template::Flute::Form;

use strict;
use warnings;
use Scalar::Util qw/blessed/;

=head1 NAME

Template::Flute::Form - Form object for Template::Flute templates.

=head1 CONSTRUCTOR

=head2 new

Creates Template::Flute::Form object.

=cut

# Constructor
sub new {
	my ($class, $sob, $static) = @_;
	my ($self);
	
	$self = {sob => $sob, static => $static, valid_input => undef};

    # retrieve values for action and method attributes
    my $action = $self->{sob}->{elts}->[0]->att('action');

    if (defined $action) {
        $self->{action} = $action;
    }
    else {
        $self->{action} = '';
    }

    my $method = $self->{sob}->{elts}->[0]->att('method');

    if (defined $method && $method =~ /\S/) {
        $self->{method} = uc($method);
    }
    else {
        $self->{method} = 'GET';
    }

	bless $self, $class;
}

=head1 METHODS

=head2 params_add PARAMS

Add parameters from PARAMS to form.

=cut
	
sub params_add {
	my ($self, $params) = @_;

	$self->{params} = $params || [];
}

=head2 fields_add FIELDS

Add fields from FIELDS to form.

=cut
	
sub fields_add {
	my ($self, $fields) = @_;
	my (%field_iters);

	for my $field (@$fields) {
		if ($field->{iterator}) {
			$field_iters{$field->{iterator}} = $field->{name};
		}
	}

	$self->{iterators} = \%field_iters;
	$self->{fields} = $fields || [];
}

=head2 inputs_add INPUTS

Add inputs from INPUTS to form.

=cut
	
sub inputs_add {
	my ($self, $inputs) = @_;

	if (ref($inputs) eq 'HASH') {
		$self->{inputs} = $inputs;
		$self->{valid_input} = 0;
	}
}

=head2 name

Returns name of the form.

=cut

sub name {
	my ($self) = @_;

	return $self->{sob}->{name};
}

=head2 elt

Returns corresponding HTML template element of the form.

=cut
	
sub elt {
	my ($self) = @_;

	return $self->{sob}->{elts}->[0];
}

=head2 fields

Returns form fields.

=cut

sub fields {
	my ($self) = @_;

	return $self->{fields};
}

=head2 params

Returns form parameters.

=cut
	
sub params {
	my ($self) = @_;

	return $self->{params};
}

=head2 inputs

Returns form inputs.

=cut
	
sub inputs {
	my ($self) = @_;

	return $self->{inputs};
}

=head2 input PARAMS

Verifies that input parameters are sufficient.
Returns 1 in case of success, 0 otherwise.

=cut	

sub input {
	my ($self, $params) = @_;
	my ($error_count);

	if (! $params && $self->{valid_input} == 1) {
		return 1;
	}
	
	$error_count = 0;
	$params ||= {};
	
	for my $input (values %{$self->{inputs}}) {
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

	$self->{valid_input} = 1;
	return 1;
}

=head2 iterators

Returns names of all iterators used by the fields for this form.

=cut

sub iterators {
	my ($self) = @_;

	return keys(%{$self->{iterators}});
}

=head2 action

Returns current form action.

=cut

sub action {
	my ($self) = @_;

	return $self->{action};
}

=head2 set_action ACTION

Sets from action to ACTION.

=cut

sub set_action {
	my ($self, $action) = @_;

	$self->{sob}->{elts}->[0]->set_att('action', $action);
	$self->{action} = $action;
}

=head2 method

Returns current form method, e.g. GET or POST.

=cut

sub method {
    my ($self) = @_;

    return $self->{method};
};

=head2 set_method METHOD

Sets form method to METHOD, e.g. GET or POST.

=cut

sub set_method {
	my ($self, $method) = @_;

	$self->{sob}->{elts}->[0]->set_att('method', $method);
	$self->{method} = $method;
}

=head2 fill PARAMS

Fills form with parameters from hash reference PARAMS.

=head2 is_filled

Return true if you called fill on the form.

=cut


# fill - fills form fields

sub _set_filled {
    my $self = shift;
    $self->{_form_is_filled} = 1;
}

sub is_filled {
    my $self = shift;
    return $self->{_form_is_filled};
}

sub fill {
	my ($self, $href) = @_;
	my ($f, @elts, $value, $zref, $type);
    $self->_set_filled;
    if (blessed($href) and $href->isa('Hash::MultiValue')) {
        $href = $href->mixed;
    }
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

Copyright 2010-2021 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
