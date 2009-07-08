use inc::Module::Install;

name            ("Nagios-Interface");
abstract        ("Run-time interaction with Nagios");
author          ("Sam Vilain <samv@cpan.org>");
version_from    ("lib/Nagios/Interface.pm");
license         ("perl");

requires        ("perl" => 5.008005);
requires        ("Moose" => 0.32);
requires        ("MooseX::Timestamp");
requires        ("Class::Autouse");
requires        ("Scriptalicious");

&WriteAll;
