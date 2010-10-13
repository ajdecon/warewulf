
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
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = ();

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
    my $self = shift;
    my $nodeobj = shift;

    if (defined($nodeobj)) {
        my $hostname = $nodeobj->hostname();
        my $ipaddr = $nodeobj->ipaddr();
        my $hwaddr = $nodeobj->hwaddr();
        if ($hostname) {
            push(@{$self->{"BY_HOSTNAME"}{"$hostname"}}, $nodeobj);
        }
        if ($ipaddr) {
            push(@{$self->{"BY_IPADDR"}{"$ipaddr"}}, $nodeobj);
        }
        if ($hwaddr) {
            push(@{$self->{"BY_HWADDR"}{"$hwaddr"}}, $nodeobj);
        }
    }

    return();
}


=item get($searchby)

Return the relevant node object(s) by searching for the given searchby
criteria. Valid search credentials are hostname, IP address, and HW
address if these were stored in the original object ***WHEN THE OBJECT
WAS INITIALLY ADDED TO THIS NODESET***.

The return value will be either a list or a scalar depending on how you
request the data.

=cut
sub
get($$)
{
    my $self = shift;
    my $val = shift;
    my @return;

    if (exists($self->{"BY_HOSTNAME"}{"$val"})) {
        push(@return, @{$self->{"BY_HOSTNAME"}{"$val"}});
    } elsif (exists($self->{"BY_IPADDR"}{"$val"})) {
        push(@return, @{$self->{"BY_IPADDR"}{"$val"}});
    } elsif (exists($self->{"BY_HWADDR"}{"$val"})) {
        push(@return, @{$self->{"BY_HWADDR"}{"$val"}});
    }

    if (@return) {
        return(wantarray ? @return : $return[0]);
    } else {
        return();
    }
}




=back

=head1 SEE ALSO

Warewulf::Node

=head1 COPYRIGHT

Warewulf is copyright UC Regents

=cut


1;
