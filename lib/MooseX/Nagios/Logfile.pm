
package MooseX::Nagios::Logfile;

use MooseX::Nagios::ConcreteTypes;
use Moose;

use IO::File;

use Carp;

has 'source' =>
	isa => "Str",
	is => "ro",
	required => 1,
	default => sub {
		require Sys::Hostname;
		&Sys::Hostname::hostname;
	},
	;

has 'filename' =>
	isa => "Str",
	is => "ro",
	;

has 'tail' =>
	isa => "File::Tail",
	is => "ro",
	;

sub parse_logline {
	my $self = shift;
	my $line = shift;

	#print STDERR "read: $line\n";
	my ($time, $type, $info, $fail)
		= $line =~ m{^\[(\d+)\] (?:([\w\s]+): (.*)|(.*))}g;

	if ( $fail ) {
		if ( $fail =~ m{Auto-save.*completed success}) {
			return MooseX::Nagios::IgnorableLogMessage->new
				(source => $self->source,
				 when => $time,
				 message => $fail);
		}
		elsif ( $fail =~ m{Caught (\w+)} ) {
			return MooseX::Nagios::SignalDeath->new
				(source => $self->source,
				 when => $time,
				 signal => $1,
				 message => $fail);
		}
		else {
			return undef;
		}
	}

	if ( $type eq "EXTERNAL COMMAND" ) {
		$info =~ s{^([\w]+);}{} or
			die "failed to strip external command out";
		$type = $1;
		$type =~ s{_}{ }g;
		$type =~ s{\bSVC\b}{SERVICE}g;
	}

	my $class = lc $type;
	$class =~ s{(\w+)\s*}{ucfirst($1)}eg;
	$class = "MooseX::Nagios::$class";

	unless ( eval { $class->does("MooseX::Nagios::LogMessage") } ) {
		die "unknown event type '$type'";
	}

	my @fields = $class->log_info_order;
	# limit the split to the number of expected fields, in case
	# the last one contains a literal ';'
	my @params = split ";", $info, scalar(@fields);

	if ( @fields > @params ) {
		die "Expected ".@fields." fields, saw ".@params;
	}
	my @source;
	(@source) = (source => $self->source)
		unless grep { $_ eq "source" } @fields;

	return $class->new
		(when => $time, @source,
		 map { shift(@fields) => shift(@params) }
		 0..$#fields);

}

has 'fh' =>
	isa => "IO::Handle",
	is => "rw",
	;

sub BUILD {
	my $self = shift;
	if ( $self->filename ) {
		my $handle = IO::File->new($self->filename, "r")
			or croak "Could not open '".$self->filename
				." for reading; $!";
		$self->fh($handle);
	}
}

sub get_message {
	my $self = shift;
	my $line = do {
		if ( $self->tail ) {
			$self->tail->read;
		}
		elsif ( $self->fh ) {
			$self->fh->getline;
		}
	};
	defined($line) or return undef;
	return $self->parse_logline($line) || $line;
}

1;
