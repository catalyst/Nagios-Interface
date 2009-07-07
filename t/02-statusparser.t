#!/usr/bin/env perl

use Test::More no_plan;

use strict;
use warnings;
use FindBin qw($Bin);

BEGIN {
	use_ok("MooseX::Nagios::Status");
}

my $test_file = "$Bin/status.dat";

my $parser = MooseX::Nagios::Status->new(
	filename => $test_file,
	);

my %old_mem;
my $file_size = (stat $test_file)[7];
if ( -t STDOUT and $^O eq "linux" ) {
	%old_mem = map { m{Vm(\w+):\s+(\d+) kB} }
		`cat /proc/$$/status`;
}

eval { $parser->parse_file };
ok( !$@, "parsed file without dying" )
	or diag("\$\@ was: ".$@);

# display how much bigger the process got from reading the status
# file.
if ( -t STDOUT and $^O eq "linux" ) {
	my %new_mem = map { m{Vm(\w+):\s+(\d+) kB} }
		`cat /proc/$$/status`;

	my @growth = map {
		($old_mem{$_} < $new_mem{$_} ?
			 ("$_: ".($new_mem{$_} - $old_mem{$_})." kB")
				 : ())
	} sort keys %new_mem;

	diag("status file size: ".($file_size>>10)."kB");
	diag("process growth after reading status file: ".join(", ", @growth));
}

my @hosts = $parser->get_blocks("hoststatus");
is(@hosts, 4, "got back 4 hoststatus blocks");
is_deeply(
	[ map { $_->{host_name} } @hosts ],
	[ qw(shire-router bilbo samwise frodo) ],
	"parsed hoststatus OK",
	);
