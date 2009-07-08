
=head1 NAME

Nagios::ConcreteTypes - bundle of real log message types

=head1 DESCRIPTION

This package has all of the 'concrete' message types - these
correspond to the types of Nagios messages that are parsed.

=cut

use strict;
use warnings;
use Nagios::Interface::Alert;
use Nagios::Interface::LogMessage;
use Nagios::Interface::IgnorableMessage;
use Nagios::Interface::Alert::Notification;
use Nagios::Interface::Alert::Host;
use Nagios::Interface::Alert::Service;

=head1 MESSAGES

=head2 HOST ALERT

Logged when a host is seen to go 'up' or 'down'

=cut

package Nagios::Interface::HostAlert;
use Moose;
with 'Nagios::Interface::Alert::Host';

sub log_info_order {
	qw( host up soft count message );
}

sub as_string {
	my $self = shift;
	( "(".( $self->soft ? "soft" : "" )
	  ."#".$self->count.") "
	  ."Host ".$self->host." is "
	  .($self->up ? "up" : "down")
	  .": ".$self->message );
}

=head2 CURRENT HOST STATE

The boring version of the Host Alert that displays the 'current' state
- found at the beginning of nagios log files.

=cut

package Nagios::Interface::CurrentHostState;
use Moose;
extends 'Nagios::Interface::HostAlert';

has '+current' =>
	'default' => 1;


=head2 HOST NOTIFICATION

Some message went out to a notify target about a host alert

=cut

package Nagios::Interface::HostNotification;
use Moose;
with ('Nagios::Interface::Alert::Host', 'Nagios::Interface::Alert::Notification');

sub log_info_order {
	qw( group host up method message );
}

has '+soft' =>
	default => 0;

sub as_string {
	my $self = shift;
	( "[" . ($self->method eq "sms" ? "PAGE" : "email")
	  ." => " .$self->group."] "
	  ."Host ".$self->host." is "
	  .($self->up?"up":"down")
	  .": ".$self->message );
}

=head2 SERVICE ALERT

Logged when a service has a warning logged against it etc

=cut

package Nagios::Interface::ServiceAlert;
use Moose;
with 'Nagios::Interface::Alert::Service';
with 'Nagios::Interface::Alert';

sub log_info_order {
	qw( host service state soft count message );
}

sub as_string {
	my $self = shift;
	( "(".( $self->soft ? "soft" : "" )
	  ."#".$self->count.") "
	  .$self->show_service
	  ." is ".($self->state)
	  .": ".$self->message );
}

=head2 CURRENT SERVICE STATE

Another boring 'current status' version of a notify, of the service state.

=cut

package Nagios::Interface::CurrentServiceState;
use Moose;
extends 'Nagios::Interface::ServiceAlert';

has '+current' =>
	'default' => 1;

=head2 SERVICE NOTIFICATION

Just like the Host Notification, this represents a message that was
sent to a notifcation target.

=cut

package Nagios::Interface::ServiceNotification;
use Moose;
with 'Nagios::Interface::Alert::Service';
with 'Nagios::Interface::Alert::Notification';

has '+soft' =>
	default => 0;

sub log_info_order {
	qw( group host service state method message );
}

sub as_string {
	my $self = shift;
	( "[" . ($self->method eq "sms" ? "PAGE" : "email")
	  ." => " .$self->group."] "
	  .$self->show_service." is "
	  .($self->state)
	  .": ".$self->message );
}

=head2 SCHEDULE FORCED SVC CHECK



=cut

package Nagios::Interface::ScheduleForcedServiceCheck;
use Moose;
with 'Nagios::Interface::Alert', 'Nagios::Interface::Alert::Service';
use MooseX::TimestampTZ qw(epoch);

has '+soft' =>
	required => 0;
has '+state' =>
	required => 0;
has '+message' =>
	required => 0;

has 'checktime' =>
	isa => "TimestampTZ",
	coerce => 1,
	is => "ro",
	required => 1;

sub log_info_order {
	qw(host service checktime);
}

use Scriptalicious qw(time_unit);

sub as_string {
	my $self = shift;
	my $eta = $self->checktime - $self->when;
	("someone forced a".($eta <= 0 ? "n immediate" : "")
	 ." check of ".$self->show_service
	 .($eta > 0 ? " in ".time_unit($eta, 3) : ""));
}

sub match {
	my $self = shift;
	my $other = shift;
	super and $self->checktime == $other->checktime;
}

=head1 MESSAGES RELATING TO DOWNTIME SCHEDULING

Many of these are parsed by first getting rid of the 'EXTERNAL_CMD'
part from the log message and then re-parsing.

=head2 SCHEDULE SVC DOWNTIME

Someone scheduled downtime for a service.

=cut

package Nagios::Interface::ScheduleServiceDowntime;
use Moose;
with 'Nagios::Interface::Alert::Service';
with 'Nagios::Interface::Alert';

has '+soft' =>
	required => 0;
has '+state' =>
	required => 0;
has '+message' =>
	required => 0;

has 'begin' =>
	isa => "TimestampTZ",
	is => "ro",
	required => 1,
	coerce => 1;

has 'end' =>
	isa => "TimestampTZ",
	is => "ro",
	required => 1,
	coerce => 1;

has 'fixed' =>
	isa => "Bool",
	is => "ro",
	default => sub {
		my $self = shift;
		!$self->duration;
	},
	;

has 'flexible' =>
	isa => "Bool",
	is => "ro",
	default => sub {
		my $self = shift;
		!!$self->duration;
	},
	;

has 'duration' =>
	isa => "Int",
	is => "ro",
	;

has 'author' =>
	isa => "Str",
	is => "ro",
	default => \&Nagios::Interface::default_author,
	;

has 'comment' =>
	isa => "Str",
	is => "ro";

sub log_info_order {
	qw(host service begin end fixed flexible duration author comment);
}

sub as_string {
	my $self = shift;
	($self->author." downtimed ".
	 $self->show_service." "
	 .($self->fixed ? "between ".$self->begin." and ".$self->end
	   :"for ".$self->duration." seconds")
	 .", saying: ".$self->comment);
}

sub ok {
	1;
}

=head2 SVC DOWNTIME ALERT

A downtime period for a service has started/finished

=cut

package Nagios::Interface::ServiceDowntimeAlert;
use Moose;
with 'Nagios::Interface::Alert::Service', 'Nagios::Interface::DowntimeAlert';
with 'Nagios::Interface::Alert';

has '+soft' =>
	required => 0;
has '+state' =>
	required => 0;

sub log_info_order {
	qw(host service started message);
}

sub as_string {
	my $self = shift;
	($self->show_service
	 ." is ".($self->started ? "": "no longer ")."in downtime"
	 .($self->message =~ /\S/ ? " (".$self->message.")" : ""));
}

sub ok {
	1;
}

=head2 HOST DOWNTIME ALERT

A downtime period for a host has started/finished

=cut

package Nagios::Interface::HostDowntimeAlert;
use Moose;
with 'Nagios::Interface::Alert', 'Nagios::Interface::Alert::Host', 'Nagios::Interface::DowntimeAlert';

has '+soft' =>
	required => 0;
has '+up' =>
	required => 0;

sub log_info_order {
	qw(host started message);
}

sub as_string {
	my $self = shift;
	($self->host
	 ." is ".($self->started ? "": "no longer ")."in downtime"
	 .($self->message =~ /\S/ ? " (".$self->message.")" : ""));
}

sub ok {
	1;
}

=head1 MESSAGES RELATING TO FLAPPING

=head2 HOST FLAPPING ALERT

=cut

package Nagios::Interface::HostFlappingAlert;
use Moose;
with 'Nagios::Interface::Alert::Flapping', 'Nagios::Interface::Alert::Host';

has '+up' =>
	required => 0,
	;

has '+soft' =>
	required => 0,
	;

sub up {
	my $self = shift;
	!$self->flapping;
}

sub log_info_order {
	qw(host flapping message);
}

sub as_string {
	my $self = shift;
	sprintf( "Host %s has %s flapping %s",
		 $self->host,
		 ($self->flapping? "started" : "stopped"),
		 $self->message,
		 );
}

sub ok {
	my $self = shift;
	!$self->flapping;
}

sub match {
	my $self = shift;
	my $other = shift;
	Nagios::Interface::Alert::Host::match($self, $other);
}

package Nagios::Interface::ServiceFlappingAlert;
use Moose;
with 'Nagios::Interface::Alert::Service', 'Nagios::Interface::Alert::Flapping';

sub log_info_order {
	qw(host service flapping message);  # guessed
}

has '+state' =>
	required => 0,
	;

has '+soft' =>
	required => 0,
	;

sub state {
	my $self = shift;
	$self->flapping ? "CRITICAL" : "OK";
}

sub as_string {
	my $self = shift;
	sprintf( "%s has %s flapping %s",
		 $self->show_service,
		 ($self->flapping? "started" : "stopped"),
		 $self->message,
		 );
}

sub ok {
	my $self = shift;
	!$self->flapping;
}

sub match {
	my $self = shift;
	my $other = shift;
	Nagios::Interface::Alert::Service::match($self, $other);
}

=head1 MESSAGES THAT ARE SPECIALLY CONSTRUCTED

These messages don't fit the regular format, and have exceptions - so
these classes are manually created.

=head2 Nagios::Interface::SignalDeath

When you see a logged message about Nagios dying, create one of these.

=cut

package Nagios::Interface::SignalDeath;
use Moose;
with 'Nagios::Interface::LogMessage';

has 'signal' =>
	is => "ro",
	required => 1;

has 'message' =>
	is => "ro",
	required => 1;

sub log_info_order {
	qw( message );
}

sub as_string {
	my $self = shift;
	"nagios on ".$self->host." died from signal: ".$self->signal;
}

sub match {
	my $self = shift;
	my $other = shift;
	my $am_ok = ($other->can("signal") and
		     $self->signal eq $other->signal);
	Nagios::Alert::DEBUG("match = $am_ok\n");
	$am_ok;
}

sub ok {
	0;
}

sub notify_types {
	"nagios";
}

=head1 BORING MESSAGES

These messages are all considered disinteresting (they use the
Nagios::IgnorableMessage role)

=head2 LOG VERSION

Displaying the log version format ... actually probably we need to
raise an exception if the version is different, so B<FIXME> ;-)

=cut

package Nagios::Interface::LogVersion;
use Moose;
with 'Nagios::Interface::LogMessage', 'Nagios::Interface::IgnorableMessage';

has '+host' =>
	required => 0;

has 'version' =>
	is => "ro",
	default => 0;

sub log_info_order {
	qw( version );
}
sub as_string {
	my $self = shift;
	"Log Version is ".$self->version;
}

sub match {
	my $self = shift;
	my $other = shift;
	$other->can("version") and
		$self->version eq $other->version;
}

=head2 LOG ROTATION

I guess when the log file is turned over this is logged?!

=cut

package Nagios::Interface::LogRotation;
use Moose;
with 'Nagios::Interface::LogMessage', 'Nagios::Interface::IgnorableMessage';
has '+host' =>
	required => 0;

has 'interval' =>
	required => 1;

sub log_info_order {
	qw( interval );
}

sub match {
	my $self = shift;
	my $other = shift;
	$other->can("interval") and
		$self->interval eq $other->interval;
}

sub as_string {

}

=head2 Nagios::Interface::IgnorableLogMessage

This is specially constructed, like the Nagios::Interface::SignalDeath message.
It's currently only used for 'auto save'-type messages

=cut

package Nagios::Interface::IgnorableLogMessage;
use Moose;
with 'Nagios::Interface::LogMessage', 'Nagios::Interface::IgnorableMessage';

has '+host' =>
	required => 0;

has 'message' =>
	is => "ro",
	required => 1;

sub log_info_order {
	qw( message );
}

sub as_string {
	my $self = shift;
	"(ignorable) ".$self->message;
}

sub match {
	my $self = shift;
	my $other = shift;
	$other->can("message") and
		$self->message eq $other->message;
}

1;
