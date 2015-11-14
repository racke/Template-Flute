package Template::Flute::Specification::Node;

use Moo;
use MooX::HandlesVia;
use Types::Standard qw/ArrayRef InstanceOf/;

use namespace::clean;
use MooX::StrictConstructor;

# points to parent node
has parent => (
    is => 'ro',
    isa => InstanceOf ['Template::Flute::Specification::Node'],
    weak_ref => 1,
);

# list of children
has children => (
    is => 'ro',
    isa => ArrayRef [ InstanceOf ['Template::Flute::Specification::Node'] ],
    default => sub {[]},
    handles_via => 'Array',
    handles => {
        child_add => 'push',
    }
);

sub add_child {
    my $self = shift;
    my $child = Template::Flute::Specification::Node->new(
        parent => $self,
    );

    return $child;
}

1;
