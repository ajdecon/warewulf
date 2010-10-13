
package Warewulf::Debug;

use Exporter;

our @ISA = ('Exporter');

our @EXPORT = qw (
    &dprint
);

=head1 NAME

Warewulf::Debug - Debugging functions

=head1 ABOUT

The Warewulf::Debug provides debugging functions

=head1 SYNOPSIS

    use Warewulf::Debug;


=item dprint(level, "message")

Print a debugging message of a particular numeric level. This requires the
scalar $debug to be declared with "our" in the main script to operate.

=cut
sub
dprint(@)
{
    my $level = shift;
    my @message = @_ ;

    if ( @message and $main::debug ) {

        if ( $level <= $main::debug ) {
            printf STDERR @message;
        }

    }

    return();
}





1;
