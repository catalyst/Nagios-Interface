package MooseX::Nagios::LogMessage;

use strict;
use warnings;

use Moose::Role;

requires 'log_info_order';

sub output_fields {
	my $self = shift;
	$self->log_info_order;
}

requires 'as_string';
requires 'ok';

has 'host' =>
	isa => 'Str',
	is => 'ro',
	required => 1,
	;

has 'when' =>
	isa => 'TimestampTZ',
	is => 'ro',
	required => 0,
	coerce => 1,
	;

requires 'match';

# As an idea for a simplification, just require classes to return
# which fields make up their 'key'
#
# requires 'match_keys';
#
#has 'keys' =>
#	isa => 'ArrayRef',
#	is => 'rw',
#	required => 1,
#	lazy => 1,
#	default => sub {
#		my $self = shift;
#		[ $self->match_keys ];
#	},
#	;

sub nagios_label {
	my $self = shift;
	my $class = ref $self;
	our %labels;
	$labels{$class} ||= do {
		my $label = $class;
		$DB::single = 1;
		$label =~ s{MooseX::Nagios::}{};
		$label =~ s{([a-z])([A-Z])}{${1}_$2}g;
		$label = uc($label);
		$label =~ s{SERVICE}{SVC}g;
		$label;
	};
}

1;
