
package Nagios::Interface::Alert;

use Moose::Role;

use Moose::Util::TypeConstraints;
use MooseX::TimestampTZ;

with 'Nagios::Interface::LogMessage';

has 'message' =>
	isa => 'Str',
	is => 'rw',
	required => 1;

# some messages say how close they are to being hard
has 'count' =>
	isa => 'Int',
	is => 'ro';

subtype 'Nagios::Interface::SoftAlert'
	=> as 'Bool';
coerce 'Nagios::Interface::SoftAlert'
	=> from 'Str'
	=> via { $_ eq "SOFT" ? 1 : 0 };

has 'soft' =>
	isa => 'Nagios::Interface::SoftAlert',
	is => 'rw',
	required => 1,
	coerce => 1;

has 'current' =>
	isa => 'Bool',
	is => 'ro',
	required => 1,
	default => 0;

sub match {
	my $self = shift;
	my $other = shift;
	my $ok = ($other->can("host") and
		  $self->host eq $other->host);
	##DEBUG("match = $ok\n");
	$ok;
}

requires 'ok';

1;
