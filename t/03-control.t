#!/usr/bin/env perl

use Test::More no_plan;

use strict;
use warnings;
use FindBin qw($Bin);

BEGIN {
	use_ok("MooseX::Nagios::Control");
}
use MooseX::Nagios::ConcreteTypes;

my $test_control_file = "$Bin/test_control.cmd";
unlink($test_control_file);
open my $control_fh, "+>$test_control_file"
	or die $!;

my $control = MooseX::Nagios::Control->new(
	filename => $test_control_file,
	);

my $begin = time;
my $end   = $begin + 15*60;

my $svc_downtime = MooseX::Nagios::ScheduleServiceDowntime->new(
	host  => "frodo",
	service => "Visibility",
	begin => $begin,
	end   => $begin + 15 * 60,
	author => "dummy",
	comment => "here's a comment",
	);

my $entry_time = $control->issue($svc_downtime);
ok($entry_time, "Got an entry time back");

my $written = <$control_fh>;
like($written, qr/\[$entry_time\] SCHEDULE_SVC_DOWNTIME;frodo;Visibility;$begin;$end;1;;;dummy;here's a comment/,
   "Wrote a command to the nagios control file");
