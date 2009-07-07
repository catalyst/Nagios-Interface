
package MooseX::Nagios::Alert::Service;

use Moose::Role;
use Moose::Util::TypeConstraints;

# 'FAIL' means Socket timeout
enum 'Nagios::ServiceState' => qw[OK WARNING CRITICAL FAIL UNKNOWN];

has 'service' =>
	isa => 'Str',
	is => 'ro';

has 'state' =>
	isa => 'Nagios::ServiceState',
	required => 1,
	is => 'ro';

sub match {
	my $self = shift;
	my $other = shift;
	my $super_ok = MooseX::Nagios::Alert::match($self, $other);
	my $am_ok = ( $other->can("service") and
		      $self->service eq $other->service);
	Nagios::Alert::DEBUG("match = $am_ok (super = $super_ok)\n");
	return $super_ok and $am_ok;
};

sub ok {
	my $self = shift;
	$self->state eq "OK";
}

sub show_service {
	my $self = shift;
	$self->service ." on ". $self->host;
}

sub clean_message {
	my $self = shift;
	my $message = $self->message;
	my $state = $self->state;
	if ( $state and $message =~ s{^$state: }{} ) {
		$self->message($message);
	};
}

sub BUILD {
	my $self = shift;
	$self->clean_message;
}

1;
