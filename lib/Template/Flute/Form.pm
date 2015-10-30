package Template::Flute::Form;

use Moo;
use Types::Standard qw/ArrayRef HashRef InstanceOf/;
use MooX::HandlesVia;

use strict;
use warnings;

with 'Template::Flute::Role::Elements';

=head1 NAME

Template::Flute::Form - Form object for Template::Flute templates.

=head1 ATTRIBUTES

=head2 name

Form name.

=cut

has name => (
    is => 'ro',
);

=head2 action

Form action.

=over

=item writer: set_action

=back

=cut

has action => (
    is => 'ro',
    default => '',
    writer  => 'set_action',
);

after 'set_action' => sub {
    my ( $self, $arg ) = @_;
    $self->elt->set_att( 'action', $arg );
};

=head2 method

Form method.

=over

=item writer: set_method

=back

=cut

has method => (
    is => 'ro',
    default => 'GET',
    writer  => 'set_method',
);

after 'set_method' => sub {
    my ( $self, $arg ) = @_;
    $self->elt->set_att( 'method', $arg );
};

=head2 fields

List of form fields.

=cut

has fields => (
    is => 'ro',
    isa => ArrayRef [ InstanceOf ['Template::Flute::Form::Field'] ],
);

=head2 params

Form parameters

=over

=item writer: params_add

=back

=cut

has params => (
    is => 'ro',
    writer => 'params_add',
);

=head2 inputs

Form inputs.

=over

=item writer: inputs_add

=back

=cut
	
has inputs => (
    is => 'ro',
    isa => HashRef,
    writer => 'inputs_add',
);

after 'inputs_add' => sub {
	$_[0]->valid_input(0);
};

=head2 valid_input

=cut

has valid_input => (
    is => 'rw',
);

=head1 CONSTRUCTOR

=head2 new

Creates Template::Flute::Form object.

=cut

sub BUILDARGS {
    my ($class, @args) = @_;
    my $params = { @args };

    # retrieve values for action and method attributes
    my $action = $params->{elts}->[0]->att('action');

    if (defined $action) {
        $params->{action} = $action;
    }

    my $method = $params->{elts}->[0]->att('method');

    if (defined $method && $method =~ /\S/) {
        $params->{method} = uc($method);
    }

    return $params;
}


=head1 METHODS

=head2 fields_add FIELDS

Add fields from FIELDS to form.

=cut
	
# sub fields_add {
# 	my ($self, $fields) = @_;
# 	my (%field_iters);

# 	for my $field (@$fields) {
# 		if ($field->{iterator}) {
# 			$field_iters{$field->{iterator}} = $field->{name};
# 		}
# 	}

# 	$self->{iterators} = \%field_iters;
# 	$self->{fields} = $fields || [];
# }

=head2 elt

Returns corresponding HTML template element of the form.

=cut
	
sub elt {
	my ($self) = @_;

	return $self->elts->[0];
}

=head2 unused_input PARAMS

Verifies that input parameters are sufficient.
Returns 1 in case of success, 0 otherwise.

=cut	

sub unused_input {
	my ($self, $params) = @_;
	my ($error_count);

	if (! $params && $self->valid_input == 1) {
		return 1;
	}
	
	$error_count = 0;
	$params ||= {};
	
	for my $input (values %{$self->inputs}) {
        my $name = $input->{name};
		if ($input->{required} && ! $params->$name) {
			warn "Missing input for $name.\n";
			$error_count++;
		}
		else {
			$input->{value} = $params->$name;
		}
	}

	if ($error_count) {
		return 0;
	}

	$self->valid_input(1);
	return 1;
}

=head2 iterators

Returns names of all iterators used by the fields for this form.

=cut

sub iterators {
	my ($self) = @_;
    my (%iterators, $name);

    for my $field (@{$self->fields}) {
        if (my $name = $field->iterator) {
            $iterators{$name} = $name;
        }
    }

    return \%iterators;
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
	for my $f (@{$self->fields()}) {
		@elts = @{$f->elts};

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

=head2 query

Returns Perl structure for database query based on
the specification.

=cut

sub query {
	my ($self) = @_;
	my (%query, $found, %cols);

	%query = (tables => [], columns => {}, query => []);
	
	if ($self->{sob}->{table}) {
		push @{$query{tables}}, $self->{sob}->{table};
		$found = 1;
	}

	for (@{$self->{params}}) {
		push @{$query{columns}->{$self->{sob}->{table}}}, $_->{name};
		$cols{$_->{name}} = 1;
		$found = 1;
	}

	# qualifier based on the input
	for (values %{$self->{inputs}}) {
		if ($_->{value}) {
			push @{$query{query}}, $_->{name} => $_->{value};

			# qualifiers need to be present in column specification
			unless (exists $cols{$_->{name}}) {
				push @{$query{columns}->{$self->{sob}->{table}}}, $_->{name};
			}
		}
	}
	
	if ($found) {
		return \%query;
	}
}

=head1 AUTHOR

Stefan Hornburg (Racke), <racke@linuxia.de>

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2015 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
