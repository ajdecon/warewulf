
package Warewulf;

use Warewulf::Include;
use Warewulf::Config;

use Exporter;

our @ISA = ('Exporter');

our @EXPORT = qw (
);

=head1 NAME

Warewulf - Object interface to Warewulf

=head1 ABOUT


=head1 SYNOPSIS

    use Warewulf;

    my $obj = Warewulf->new();


=head1 METHODS

=over 12
=cut


=item new([path to config])

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

=back

=head1 SEE ALSO

Warewulf::Info Warewulf::Config

=head1 COPYRIGHT

Warewulf is copyright UC Regents

=cut


1;
