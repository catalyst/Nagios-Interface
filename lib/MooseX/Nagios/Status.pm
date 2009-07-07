
package MooseX::Nagios::Status;

=head1 NAME

MooseX::Nagios::Status - parse the Nagios status.dat file

=head1 SYNOPSIS

 use MooseX::Nagios::Status;

 my $status = MooseX::Nagios::Status->new(
         filename => "/var/cache/nagios3/status.dat",
         );

 # set 'block_handler' if you want events for each block
 $status->parse_file;

 # iterate over the blocks in the status file
 for my $blocks ( $status->get_blocks("servicedowntime") ) {
         # these are hashrefs.
 }

=head1 DESCRIPTION

This is a module which provides relatively fast and light-weight
access to the nagios status file.  In reality the memory used by the
module is about 4 times the size of the actual status file on 64-bit
systems due to pointer sizes and memory fragmentation issues.

Currently the interface is very raw; a higher-level interface with
knowledge about what is being parsed will be implemented as
needs/tuits arise (patches/pull requests most welcome!).

=cut

use Moose;
use Carp;
use autodie qw(open);
use MooseX::TimestampTZ;

has 'filename' =>
	isa => "Str",
	is => "rw",
	;

has 'last_mtime' =>
	isa => 'TimestampTZ',
	is => "rw",
	coerce => 1,
	;

# let CoW strings have a chance... always use the same PV for a given
# key
sub cached_key {
	our %key_cache;
	my $x = shift;
	$key_cache{$x} ||= $x;
}

has 'block_handler' =>
	isa => 'CODE',
	is => "rw",
	;

has 'blocks' =>
	isa => 'HashRef[ArrayRef[HashRef]]',
	is => "rw",
	;

sub parse_file {
	my $self = shift;
	my $filename = shift || $self->filename
		or croak "no filename passed to parse_file";

	open my $fh, "<", $filename;
	my $mtime = (stat $fh)[9];
	if ( $mtime and $self->last_mtime and $self->last_mtime == $mtime
	     ) {
		return;
	}

	my $blocks = $self->blocks({});
	my $block_name;
	my $block = {};
	my $block_handler = $self->block_handler;
	my $emit_last_block = sub {
		return unless $block_name;
		$DB::single = 1;
		if ( $block_name eq "info" and $block->{version} !~ m{^3\.}
		     ) {
			die "Refusing to parse status file version "
				.$block->{version};
		}
		$block_handler->($self, $block_name, $block)
			if $block_handler;
		push @{ $blocks->{$block_name}||=[] }, $block;
		$block = {};
		undef($block_name);
	};
	while ( <$fh> ) {
		if ( m{^\s*(#.*)?$} ) {
			next;
		}
		elsif ( my ($new_block_name) = m{^(\w+)\s+\{} ) {
			$emit_last_block->();
			$block_name = $new_block_name;
		}
		elsif ( my ($item_name, $val) = m{^\s+(\w+)=(.*)} ) {
			$block->{cached_key($item_name)} =
				$val;
		}
		elsif ( m{^\s*\}} ) {
			$emit_last_block->();
		}
		else {
			chomp;
			warn "unparsed status line: '$_'";
		}
	}
	$emit_last_block->();
	$self->last_mtime((stat $fh)[9]);
	our%key_cache=();
}

sub get_blocks {
	my $self = shift;
	my $type = shift;
	$self->parse_file unless $self->blocks;
	my $aref = $self->blocks->{$type};
	if ( $aref ) {
		return @$aref;
	}
	else {
		return ();
	}
}

1;
