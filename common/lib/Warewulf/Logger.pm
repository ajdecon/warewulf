
package Warewulf::Logger;

use Warewulf::Daemon;
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

    chomp($string);
    if (&daemon_check()) {
        # Test log file
        open(LOG, ">> /tmp/test.log");
        print LOG "$string\n";
        close LOG;
    } elsif ($LEVEL >= $level) {
        if ($LEVEL == DEBUG) {
            (undef, undef, undef, $s) = caller(1);
            if (!defined($s)) {
                $s = "MAIN";
            }
            (undef, $f, $l) = caller(0);
                $f =~ s/^.*\/([^\/]+)$/$1/;
            $s =~ s/\w+:://g;
            $s .= "()" if ($s =~ /^\w+$/);
            $f = "" if (!defined($f));
            $l = "" if (!defined($l));
            $s = "" if (!defined($s));
            print STDERR "[$f/$l/$s]: ";
        }
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

    if (&daemon_check()) {
        # Test log file
        open(LOG, ">> /tmp/test.log");
        printf LOG $format, @args;
        close LOG;
    } elsif ($LEVEL >= $level) {
        if ($LEVEL == DEBUG) {
            (undef, undef, undef, $s) = caller(1);
            if (!defined($s)) {
                $s = "MAIN";
            }
            (undef, $f, $l) = caller(0);
                $f =~ s/^.*\/([^\/]+)$/$1/;
            $s =~ s/\w+:://g;
            $s .= "()" if ($s =~ /^\w+$/);
            $f = "" if (!defined($f));
            $l = "" if (!defined($l));
            $s = "" if (!defined($s));
            print STDERR "[$f/$l/$s]: ";
        }
        printf STDERR $format, @args;
    }

}



1;
