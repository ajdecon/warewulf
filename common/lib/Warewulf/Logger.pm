
package Warewulf::Logger;

use Warewulf::Daemon;
use Exporter;

my $WWLOG_CRITICAL = 0;
my $WWLOG_ERROR = 1;
my $WWLOG_WARNING = 2;
my $WWLOG_NOTICE = 3;
my $WWLOG_INFO = 4;
my $WWLOG_DEBUG = 5;

our @ISA = ('Exporter');

our @EXPORT = ('&get_log_level', '&set_log_level', '&cprint',
               '&cprintf', '&eprint', '&eprintf', '&wprint',
               '&wprintf', '&nprint', '&nprintf', '&iprint',
               '&iprintf', '&dprint', '&dprintf');

our @EXPORTOK = ('$WWLOG_CRITICAL', '$WWLOG_ERROR', '$WWLOG_WARNING',
                 '$WWLOG_NOTICE', '$WWLOG_INFO', '$WWLOG_DEBUG',
                 '&lprint', '&lprintf');

my $LEVEL = 0;

my $LOGFILE = undef;

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
set_log_level($)
{
    my ($level) = @_;

    if (uc($level) eq "CRITICAL") {
        $level = $WWLOG_CRITICAL;
    } elsif (uc($level) eq "ERROR") {
        $level = $WWLOG_ERROR;
    } elsif (uc($level) eq "WARNING") {
        $level = $WWLOG_WARNING;
    } elsif (uc($level) eq "NOTICE") {
        $level = $WWLOG_NOTICE;
    } elsif (uc($level) eq "INFO") {
        $level = $WWLOG_INFO;
    } elsif (uc($level) eq "DEBUG") {
        $level = $WWLOG_DEBUG;
    } else {
        $level = int($level);
    }
    if ($level >= $WWLOG_CRITICAL && $level <= $WWLOG_DEBUG) {
        $LEVEL = $level;
    }
    return $LEVEL;
}

=item get_log_level()

Return the log level which is set

=cut
sub
get_log_level()
{
    return $LEVEL;
}

=item leader(LEVEL)

Generate leader for log file.

=cut
sub
leader($)
{
    my ($level) = @_;

    if (!defined($LOGFILE)) {
        if (&daemon_check()) {
            # Test log file
            open($LOGFILE, ">> /tmp/test.log");
        } else {
            open($LOGFILE, ">&STDERR");
        }
    }
    if ($level == $WWLOG_DEBUG) {
        my $depth = 1;

        (undef, undef, undef, $s) = caller($depth + 1);
        if ($s && $s =~ /^Warewulf::Logger::.printf?$/) {
            $depth++;
            (undef, undef, undef, $s) = caller($depth + 1);
        }
        if (!defined($s)) {
            $s = "MAIN";
        }
        ($f, undef, $l) = caller($depth);
        $s =~ s/\w+:://g;
        $s .= "()" if ($s =~ /^\w+$/);
        $f = "" if (!defined($f));
        $l = "" if (!defined($l));
        $s = "" if (!defined($s));
        return sprintf("%-40s", "[$f->$s/$l]:  ");
    } elsif ($level == $WWLOG_CRITICAL) {
        return "CRITICAL:  ";
    } elsif ($level == $WWLOG_ERROR) {
        return "ERROR:  ";
    } elsif ($level == $WWLOG_WARNING) {
        return "WARNING:  ";
    }
    return "";
}

=item lprint(LEVEL, $string)

Log a message at a given log level.

=cut
sub
lprint
{
    my ($level, $string) = @_;

    if ($level > $LEVEL) {
        return;
    }
    chomp($string);
    $string = &leader($level) . $string;
    print $LOGFILE "$string\n";
}

=item lprintf(LEVEL, $format, @arguments)

Log a message at a given log level (with format).

=cut
sub
lprintf
{
    my $level = shift;
    my $format = shift;
    my @args = @_;

    if ($level > $LEVEL) {
        return;
    }
    $format = &leader($level) . $format;
    printf $LOGFILE $format, @args;
}

=item cprint($string)

Log a message at the CRITICAL log level (without format).

=item cprintf($format, ...)

Log a message at the CRITICAL log level (with format).

=cut
sub cprint {return lprint($WWLOG_CRITICAL, @_);}
sub cprintf {return lprintf($WWLOG_CRITICAL, @_);}

=item eprint($string)

Log a message at the ERROR log level (without format).

=item eprintf($format, ...)

Log a message at the ERROR log level (with format).

=cut
sub eprint {return lprint($WWLOG_ERROR, @_);}
sub eprintf {return lprintf($WWLOG_ERROR, @_);}

=item wprint($string)

Log a message at the WARNING log level (without format).

=item wprintf($format, ...)

Log a message at the WARNING log level (with format).

=cut
sub wprint {return lprint($WWLOG_WARNING, @_);}
sub wprintf {return lprintf($WWLOG_WARNING, @_);}

=item nprint($string)

Log a message at the NOTICE log level (without format).

=item nprintf($format, ...)

Log a message at the NOTICE log level (with format).

=cut
sub nprint {return lprint($WWLOG_NOTICE, @_);}
sub nprintf {return lprintf($WWLOG_NOTICE, @_);}

=item iprint($string)

Log a message at the INFO log level (without format).

=item iprintf($format, ...)

Log a message at the INFO log level (with format).

=cut
sub iprint {return lprint($WWLOG_INFO, @_);}
sub iprintf {return lprintf($WWLOG_INFO, @_);}

=item dprint($string)

Log a message at the DEBUG log level (without format).

=item dprintf($format, ...)

Log a message at the DEBUG log level (with format).

=cut
sub dprint {return lprint($WWLOG_DEBUG, @_);}
sub dprintf {return lprintf($WWLOG_DEBUG, @_);}



1;
