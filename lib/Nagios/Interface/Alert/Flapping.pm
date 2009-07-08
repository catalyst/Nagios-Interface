
package Nagios::Interface::Alert::Flapping;

use Moose::Role;
use Moose::Util::TypeConstraints;
with 'Nagios::Interface::Alert';

# 'FAIL' means Socket timeout
subtype 'Nagios::FlapState'
	=> as 'Bool';
coerce 'Nagios::FlapState'
	=> from 'Str'
	=> via { $_ eq "STARTED" ? 1 : 0 };

has 'flapping' =>
	isa => 'Nagios::FlapState',
	required => 1,
	coerce => 1,
	is => 'ro',
	;

1;
