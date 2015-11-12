package Template::Flute::Container;

use Moo;
use base 'Template::Flute';
use Types::Standard qw/ArrayRef HashRef InstanceOf Object Str Undef/;
use Template::Flute::Expression;

use namespace::clean;
use MooX::StrictConstructor;

our %expression_cache;

=head1 NAME

Template::Flute::Container - Container object for Template::Flute templates.

=head1 ATTRIBUTES

=head2 elts

corresponding HTML template elements for this container.

=cut

has elts => (
    is      => 'ro',
    isa     => ArrayRef,
    default => sub { [] },
);

=head2 expression_parser

Possibly an instance of L<Template::Flute::Expression>.

=over

=item predicate: has_expression_parser

=item writer set_expression_parser

=back

=cut

has expression_parser => (
    is        => 'ro',
    isa       => InstanceOf ['Template::Flute::Expression'],
    writer    => 'set_expression_parser',
    predicate => 1,
);

=head2 list

Name of list this container belongs to or undef for top level containers.

=cut

has list => (
    is  => 'ro',
    isa => Str | Undef,
);

=head2 name

container name

=cut

has name => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

=head2 spec

L<Template::Flute::Specification> object.

=cut

#FIXME: perhaps this attr is not needed

has spec => (
    is       => 'ro',
    isa      => InstanceOf ['Template::Flute::Specification'],
    weak_ref => 1,
);

=head2 value

Value we check against to decide whether to display container.

=cut

has value => (
    is => 'ro',
    isa => Str,
);

=head2 values

=over

=item predicate: has_values

=item writer: set_values

=back

=cut

has values => (
    is        => 'ro',
    isa       => HashRef | Object,
    predicate => 1,
    writer    => 'set_values',
);

=head1 METHODS

=head2 visible

Determines whether the container is visible. Possible return values are 1 (visible),
0 (hidden) or undef if the specification for the container misses a value attribute.

=cut
	
# visible
sub visible {
	my ($self) = @_;
	my ($key, $ret);
	
	if ($key = $self->value) {
	    # check whether this is an expression or a simple value
	    if ($key =~ /^\w[0-9\w_-]*$/) {
            # value holds method
            return $self->values->$key
                if $self->_is_record_object($self->values) && $self->values->can($key); 
    		if ($self->has_values) {
    			if ($self->values->{$key}) {
    				return 1;
    			}
    			return 0;
    		}

    		return undef;
	    }
	    else {
            if ( !$self->has_expression_parser ) {
                # check the cache
                if (! exists $expression_cache{$key}) {
                    $expression_cache{$key} = Template::Flute::Expression->new($key);
                }

                $self->set_expression_parser( $expression_cache{$key} );
            }
       		$ret = $self->expression_parser->evaluate($self->values);

		if ($ret) {
		    return 1;
		}

		return 0;
	    }
	}

	# container is visible if no value is specified
	return 1;
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
