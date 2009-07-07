package MooseX::Nagios::HostAlert;
use Moose;
with 'MooseX::Nagios::Alert::Host';

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

1;
