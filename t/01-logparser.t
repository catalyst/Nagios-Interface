#!/usr/bin/perl

use Test::More no_plan;

use strict;
use warnings;
use IO::Handle;

BEGIN {
	use_ok("MooseX::Nagios::Logfile");
}

my $parser = MooseX::Nagios::Logfile->new(source => $0);

ok( $parser, "MooseX::Nagios::Logfile->new" );
can_ok($parser, "parse_logline");

my $event = $parser->parse_logline(<<LOG);
[1212101036] SERVICE NOTIFICATION: sysadmin-sms;frodo;Test: HTTP on port 80;OK;notify-by-sms;HTTP OK HTTP/1.1 200 OK - 964 bytes in 0.430 seconds
LOG

isa_ok($event, "MooseX::Nagios::ServiceNotification", "parsed OK!");
like($event->when, qr/2008-05/, "Extracted time OK");
is($event->method, "sms", "extracted notification method OK");
like($event->message, qr/200 OK/, "got message out");
is($event->state, "OK", "ok");
is($event->host, "frodo", "host");
is($event->group, "sysadmin-sms", "group");

$event = $parser->parse_logline(<<LOG);
[1213143666] SERVICE ALERT: samwise;Staging: Backend State;OK;SOFT;2;OK - Backend status is untrusted
LOG
isa_ok($event, "MooseX::Nagios::ServiceAlert", "parsed OK!");
is($event->soft, 1, "converted SOFT to 1");

while ( my $line = <DATA> ) {
	$event = $parser->parse_logline($line);
	pass("Parsed a $event OK");
}
if ( $@ ) {
	diag("Last failure: $@");
}
ok(eof(DATA), "Parsed all events successfully");

__END__
[1246881600] LOG ROTATION: DAILY
[1246881600] LOG VERSION: 2.0
[1246881600] CURRENT HOST STATE: shire-router;UP;HARD;1;PING OK - Packet loss = 0%, RTA = 17.18 ms
[1246881600] CURRENT HOST STATE: frodo;UP;HARD;1;
[1246881600] CURRENT SERVICE STATE: shire-router;Interface Status: Cisco Border Router;OK;HARD;1;FastEthernet0/1:UP, Serial0/2/0:UP, Serial0/2/0.1:UP, Vlan1:UP, FastEthernet0/3/3:UP, Tunnel2:UP, Tunnel1:UP:7 UP: OK
[1246881602] SERVICE ALERT: frodo;Load Average;OK;SOFT;2;OK - load average: 4.00, 4.28, 3.90
[1246881852] Auto-save of retention data completed successfully.
[1246912992] HOST ALERT: bilbo;DOWN;SOFT;1;WARNING: ANY query not answered
[1246932412] HOST FLAPPING ALERT: frodo;STARTED; Host appears to have started flapping (20.9% change > 20.0% threshold)
