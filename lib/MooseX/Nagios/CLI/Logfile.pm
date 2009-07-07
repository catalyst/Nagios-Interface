
package MooseX::Nagios::CLI::Logfile;

use Moose;
use MooseX::Nagios::Logfile;
use IO::Handle;

with 'MooseX::Getopt';

has 'path' =>
	is => "rw",
	isa => "Str",
	default => '/var/log/nagios3/nagios.log',
	;

sub run {
	my $self = shift;

	my @filenames = @{ $self->extra_argv };
	if ( !@filenames ) {
		@filenames = $self->path;
	}

	for my $file ( @filenames ) {
		my $logfile = MooseX::Nagios::Logfile->new(
			($file eq "-"
			 ? (fh => IO::Handle->new_from_fd(fileno(STDIN), "r"))
			 : (filename => $file)
			 ),
			);
		while ( my $message = $logfile->get_message ) {
			print $message->as_string, "\n";
		}
	}
}

1;

__END__

=head1 NAME

MooseX::Nagios::CLI::Logfile - CLI interface to Logfile module

=head1 SYNOPSIS

 read-nagios-log [ /path/to/nagios.log ]

=head1 DESCRIPTION

This is a program which reads in nagios log files and outputs
interpreted versions of them.  It is currently only really useful for
testing that all logged nagios messages are parsed by the
MooseX::Nagios::LogMessage-doing classes in this distribution.

The default path to the nagios log is F</var/log/nagios3/nagios.log>

=head1 SEE ALSO

L<MooseX::Nagios>, L<MooseX::Nagios::Logfile>,
L<MooseX::Nagios::LogMessage>

=cut
