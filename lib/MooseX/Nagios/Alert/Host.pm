
package MooseX::Nagios::Alert::Host;

use Moose::Util::TypeConstraints;
use Moose::Role;
with 'MooseX::Nagios::Alert';

subtype 'Nagios::HostState'
	=> as 'Bool';
coerce 'Nagios::HostState'
	=> from 'Str'
	=> via { $_ eq "UP" ? 1 : 0 };

has 'up' =>
	isa => "Nagios::HostState",
	is => "ro",
	coerce => 1;

sub ok {
	my $self = shift;
	$self->up;
}

1;
