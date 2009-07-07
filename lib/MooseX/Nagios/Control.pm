
package MooseX::Nagios::Control;

use Moose;
use IO::File;

has 'filename' =>
	isa => "Str",
	is => "ro",
	;

has 'fh' =>
	isa => "IO::Handle",
	is => "rw",
	lazy => 1,
	required => 1,
	default => sub {
		my $self = shift;
		die "no filename passed to MooseX::Nagios::Control object"
			unless $self->filename;
		IO::File->new($self->filename, "w");
	},
	;

use MooseX::TimestampTZ qw(epoch);

sub issue {
	my $self = shift;
	my $object = shift;

	my $entry_time = time;
	my @fields = $object->output_fields;
	my @data;
	for my $field ( @fields ) {
		$DB::single = 1;
		my $m_a = $object->meta->find_attribute_by_name($field);
		if ( $m_a and (my $t_c = $m_a->type_constraint) ) {
			if ( $t_c->is_a_type_of("TimestampTZ") ) {
				# these are output as ints
				push @data, epoch $object->$field;
			}
			else {
				push @data, $object->$field;
			}
		}
		else {
			push @data, $object->$field;
		}
	}

	my $logline = "[$entry_time] ".join(
		";",
		$object->nagios_label,
		(map { defined($_) ? $_ : "" } @data),
		);

	print { $self->fh } $logline, "\n";
	$self->fh->flush();
	return $entry_time;
}

1;
