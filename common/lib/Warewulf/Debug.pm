
package Warewulf::Debug;

use Exporter;

our @ISA = ('Exporter');

our @EXPORT = qw (
    &dprint
    &backtrace
);

=head1 NAME

Warewulf::Debug - Debugging functions

=head1 ABOUT

The Warewulf::Debug provides debugging functions

=head1 SYNOPSIS

    use Warewulf::Debug;


=item backtrace()

Throw a backtrace at the current location in the code.

=cut
sub
backtrace()
{
    my $file             = ();
    my $line             = ();
    my $subroutine       = ();
    my $i                = ();
    my @tmp              = ();

    print STDERR "STACK TRACE:\n";
    print STDERR "------------\n";
    for ($i = 0; @tmp = caller($i); $i++) {
        $subroutine = $tmp[3];
        (undef, $file, $line) = caller($i);
        $file =~ s/^.*\/([^\/]+)$/$1/;
        print STDERR '      ', ' ' x $i, "$subroutine() called at $file:$line\n";
    }
    print STDERR "\n";
}





1;
