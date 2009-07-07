
package MooseX::Nagios::IgnorableLogMessage;
use Moose;
with 'MooseX::Nagios::LogMessage', 'MooseX::Nagios::IgnorableMessage';

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
