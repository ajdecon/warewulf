
package Warewulf::Node;

use Warewulf::Include;

use Exporter;

our @ISA = ('Exporter');

our @EXPORT = qw (
);

=head1 NAME

Warewulf::Node- Warewulf's node set object interface.

=head1 ABOUT


=head1 SYNOPSIS

    use Warewulf::Node;

    my $obj = Warewulf::Node->new();


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


=item ipaddr()

The ipaddr method will either store or return the IP address for this object
depending if a value/paramater is given.

=cut
sub
ipaddr($$)
{
    my $self = shift;
    my $val = shift;

    if (defined($val)) {
        $self->{"IPADDR"} = $val;
    } elsif (exists($self->{"IPADDR"})) {
        return($self->{"IPADDR"});
    }
    return();
}


=item hostname()

The hostname method will either store or return the hostname for this object
depending if a value/paramater is given.

=cut
sub
hostname($$)
{
    my $self = shift;
    my $val = shift;

    if (defined($val)) {
        $self->{"HOSTNAME"} = $val;
    } elsif (exists($self->{"HOSTNAME"})) {
        return($self->{"HOSTNAME"});
    }
    return();
}


=item hwaddr()

The hwaddr method will either store or return the hardware address for this object
depending if a value/paramater is given.

=cut
sub
hwaddr($$)
{
    my $self = shift;
    my $val = shift;

    if (defined($val)) {
        $self->{"HWADDR"} = $val;
    } elsif (exists($self->{"HWADDR"})) {
        return($self->{"HWADDR"});
    }
    return();
}



=item data()

The data method will either store or return the raw data for this object
depending if a value/paramater is given.

=cut
sub
data($$)
{
    my $self = shift;
    my $val = shift;

    if (defined($val)) {
        $self->{"DATA"} = $val;
    } elsif (exists($self->{"DATA"})) {
        return($self->{"DATA"});
    }
    return();
}



=back

=head1 SEE ALSO

Warewulf::NodeSet

=head1 COPYRIGHT

Warewulf is copyright UC Regents

=cut


1;
