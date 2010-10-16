
package Warewulf::Util;

use Warewulf::Debug;
use Warewulf::Logger;

use Exporter;
use File::Basename;

our @ISA = ('Exporter');

our @EXPORT = qw (
    &rand_string
    &croak
    &progname
);

=head1 NAME

Warewulf::Util- Various helper functions

=head1 ABOUT

The Warewulf::Util provides some additional helper functions

=head1 SYNOPSIS

    use Warewulf::Util;


=item rand_string(length)

Generate a random string of a given length

=cut
sub
rand_string($)
{
   my $size             = (shift || "8" ) - 1;
   my @alphanumeric     = ('a'..'z', 'A'..'Z', 0..9);
   my $randstring       = join '', map $alphanumeric[rand @alphanumeric], 0..$size;

   return $randstring;
}



=item croak()

Die with a backtrace

=cut
sub
croak()
{
    my $file             = ();
    my $line             = ();
    my $subroutine       = ();
    my $i                = ();
    my @tmp              = ();

    print "Program has croaked!\n\n";

    if (get_log_level() == DEBUG) {
        print STDERR "STACK TRACE:\n";
        print STDERR "------------\n";
        for ($i = 1; @tmp = caller($i); $i++) {
            $subroutine = $tmp[3];
            (undef, $file, $line) = caller($i);
            $file =~ s/^.*\/([^\/]+)$/$1/;
            print STDERR '      ', ' ' x $i, "$subroutine() called at $file:$line\n";
        }
        print STDERR "\n";
    }

    exit(255);
}


=item progname()

Return the program name of this running instance

=cut
sub
progname()
{
    return(basename($0));
}


1;
