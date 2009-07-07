
package MooseX::Nagios::Alert::Notification;

use Moose::Util::TypeConstraints;
use Moose::Role;
with 'MooseX::Nagios::Alert';

enum 'Nagios::NotifyMethod' => qw[email sms];
coerce 'Nagios::NotifyMethod'
	=> from 'Str'
	=> via { s{.*notify-by-}{}; $_ };

has 'method' =>
	isa => 'Nagios::NotifyMethod',
	is => 'rw',
	coerce => 1,
	;

has 'group' =>
	isa => 'Str',
	is => 'rw';

1;
