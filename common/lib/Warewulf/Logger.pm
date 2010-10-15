
package Warewulf::Logger;

use Exporter;

use constant INFO => 1;
use constant NOTICE => 2;
use constant DEBUG => 3;

our @ISA = ('Exporter');

our @EXPORT = qw (
    INFO
    NOTICE
    DEBUG
    &get_log_level
    &set_log_level
    &lprint
    &lprintf
);

my $LEVEL = 0;



=head1 NAME

Warewulf::Logger - Log interface

=head1 ABOUT

The Warewulf::Logger package provides an interface for logging and output

=head1 SYNOPSIS

    use Warewulf::Logger;


=item set_log_level(LEVEL)

Set the log level to print at

=cut
sub
set_log_level(@)
{
    my $level = shift;

    if ($level >= INFO and $level <= DEBUG) {
        print "Setting log level to: $level\n";
        $LEVEL = $level;
    } elsif ($level) {
        print STDERR "ERROR: Could not set log level to: $level\n";
    }
}

=item get_log_level()

Return the log level which is set

=cut
sub
get_log_level()
{
    return($LEVEL);
}


=item lprint(LEVEL, $string)

Print a log message

=cut
sub
lprint($$)
{
    my $level = shift;
    my $string = shift;

    if ($LEVEL >= $level) {
        chomp($string);
        print STDERR "$string\n";
    }

}

=item lprintf(LEVEL, $format, @arguments)

Print a log message using printf

=cut
sub
lprintf($$$)
{
    my $level = shift;
    my $format = shift;
    my @args = @_;

    if ($LEVEL >= $level) {
        printf STDERR $format, @args;
    }

}



1;
