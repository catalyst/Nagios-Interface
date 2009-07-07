use inc::Module::Install;

name            ("MooseX-Nagios");
abstract        ("Dig Moose Antlers into Nagios");
author          ("Sam Vilain <samv@cpan.org>");
version_from    ("lib/MooseX/Nagios.pm");
license         ("perl");

requires        ("perl" => 5.008005);
requires        ("Moose" => 0.32);
requires        ("MooseX::Timestamp");
requires        ("Class::Autouse");
requires        ("Scriptalicious");

&WriteAll;
