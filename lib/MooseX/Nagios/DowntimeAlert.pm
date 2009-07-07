package MooseX::Nagios::DowntimeAlert;
use Moose::Role;
use Moose::Util::TypeConstraints;

subtype 'Nagios::DowntimeStarted'
	=> as 'Bool';
coerce 'Nagios::DowntimeStarted'
	=> from 'Str'
	=> via { $_ eq "STARTED" ? 1 : 0 };

has 'started' =>
	isa => 'Nagios::DowntimeStarted',
	is => 'ro',
	required => 1,
	coerce => 1;

1;
