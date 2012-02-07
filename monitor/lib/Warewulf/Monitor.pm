# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#
#

package Warewulf::Monitor;

use Warewulf::Object;
use Warewulf::ObjectSet;
use Warewulf::Logger;
use JSON::XS;

@ISA = ('Warewulf::Object');

=head1 NAME

Warewulf::Monitor - Put something useful here

=head1 ABOUT

Blah blah blah

=head1 SYNOPSIS

    use Warewulf::Monitor;

    my $monitor = Warewulf::Monitor->new();
    my $ObjectSet = $monitor->query();

    foreach my $node_object ( $ObjectSet->get_list()) {
        printf("%-20s CPU: %s\n", $node_object->get("name"), $node_object->get("cpu_util"));
    }



=head1 METHODS

=over 12

=cut



=item new()

The new constructor will create the object that references configuration the
stores.

=cut

sub
new($$)
{
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = ();

    $self = $class->SUPER::new();
    bless($self, $class);

    return $self->init(@_);
}


sub
init()
{
	my ($self, @args) = @_;

	return $self;
}

sub
persist_socket()
{
	my ($self, $bool) = @_;

	if ($bool) {
		$self->set("persist_socket", "1");
	}

	return;
}


sub
query()
{
	my ($self, $query) = @_;
	my $json = JSON::XS->new();
	my $ObjectSet = Warewulf::ObjectSet->new();

	# Build Socket conditionally if ! exists
	if (! $self->get("socket")) {
		# Make socket connection
		$self->set("socket", "");
	}

	my %decoded_json = decode_json($data);
	foreach my $node (keys %decoded_json) {
		my $tmpObject = Warewulf::Object->new();
		foreach my $entry (keys %{$decoded_json{$node}}) {
			$tmpObject->set($entry, $decoded_json{"$node"}{"$entry"});
			&dprint("Set entry for node: $node ($entry....)\n");
		}
		$ObjectSet->add($tmpObject);
	}

	if (! $self->get("persist_socket")) {
		# tear down socket
	}

	return $ObjectSet;
}

sub
update_node_entry()
{
	# will send post to monitor

}




=back

=head1 SEE ALSO

Warewulf::Object

=head1 COPYRIGHT

Copyright (c) 2001-2003 Gregory M. Kurtzer

Copyright (c) 2003-2011, The Regents of the University of California,
through Lawrence Berkeley National Laboratory (subject to receipt of any
required approvals from the U.S. Dept. of Energy).  All rights reserved.

=cut










# This happens in client code
&set_log_level("DEBUG");

&dprint("This comes from Warewulf Logger\n");



my $monitor = Warewulf::Monitor->new();

my $ObjectSet = $monitor->query();

foreach my $node_object ( $ObjectSet->get_list()) {
	printf("%-20s CPU: %s\n", $node_object->get("name"), $node_object->get("cpu_util"));
}


1;
