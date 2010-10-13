
package Warewulf::NodeSet;

use Warewulf::Include;

use Exporter;

our @ISA = ('Exporter');

our @EXPORT = qw (
);

=head1 NAME

Warewulf::NodeSet - Warewulf's node set object interface.

=head1 ABOUT


=head1 SYNOPSIS

    use Warewulf::NodeSet;

    my $obj = Warewulf::NodeSet->new();


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
    my $proto               = shift;
    my $class               = ref($proto) || $proto;
    my $self                = ();

    %{$self} = ();

    bless($self, $class);

    return($self);
}

=item add($nodeobj)

The add method will add a node object into the nodeset object.

=cut
sub
add($$)
{
    my $self                = shift;
    my $nodeobj             = shift;

    if ( defined($nodeobj) ) {
        my $hostname = $nodeobj->hostname();
        my $ipaddr = $nodeobj->ipaddr();
        $self->{"BY_HOSTNAME"}{"$hostname"} = $nodeobj;
        $self->{"BY_IPADDR"}{"$ipaddr"} = $nodeobj;
    }

    return();
}






=back

=head1 SEE ALSO

Warewulf::Node

=head1 COPYRIGHT

Warewulf is copyright UC Regents

=cut


1;
