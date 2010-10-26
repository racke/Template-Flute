# Template::Zoom::Iterator::Base - Template::Zoom Rose iterator class
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

package Template::Zoom::Iterator::Rose;

use strict;
use warnings;

use Rose::DB::Object::QueryBuilder qw(build_select);

# Constructor
sub new {
	my ($class, @args) = @_;
	my ($self);
	
	$class = shift;
	$self = {@args};
	bless $self, $class;
}

# Build method
sub build {
	my ($self) = @_;
	my ($dbref, $sql, $bind);

	$dbref = $self->{query};
	$dbref->{dbh} = $self->{dbh};
	$dbref->{query_is_sql} = 1;

	# prepare database query
	($sql, $bind) = build_select(%$dbref);

	$self->{sql} = $sql;
	$self->{bind} = $bind;
	
	return 1;
}

# Run method - executes database query
sub run {
	my ($self) = @_;
	my ($sth);
	
	$sth = $self->{dbh}->prepare($self->{sql});
	$sth->execute(@{$self->{bind}});
	$self->{results}->{sth} = $sth;

	return 1;
}

# Next method - return next element or undef
sub next {
	my ($self) = @_;

	unless ($self->{results}) {
		$self->run();
	}

	return $self->{results}->{sth}->fetchrow_hashref();
};

1;
