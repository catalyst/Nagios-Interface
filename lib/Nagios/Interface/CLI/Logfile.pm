
package Nagios::Interface::CLI::Logfile;

use Moose;
use Nagios::Interface::Logfile;
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
		my $logfile = Nagios::Interface::Logfile->new(
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

Nagios::Interface::CLI::Logfile - CLI interface to Logfile module

=head1 SYNOPSIS

 read-nagios-log [ /path/to/nagios.log ]

=head1 DESCRIPTION

This is a program which reads in nagios log files and outputs
interpreted versions of them.  It is currently only really useful for
testing that all logged nagios messages are parsed by the
Nagios::Interface::LogMessage-doing classes in this distribution.

The default path to the nagios log is F</var/log/nagios3/nagios.log>

=head1 SEE ALSO

L<Nagios::Interface>, L<Nagios::Interface::Logfile>,
L<Nagios::Interface::LogMessage>

=cut
