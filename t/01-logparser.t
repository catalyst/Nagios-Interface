#!/usr/bin/perl

use Test::More no_plan;

use strict;
use warnings;

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

