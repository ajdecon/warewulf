# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#
#
# $Id$
#

package Warewulf::Logger;

use IO::Handle;
use IO::File;
use IO::Pipe;
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

sub init_log_targets();
sub resolve_log_level(@);
sub leader($);

my $LEVEL = 0;
my $LOGFILE = undef;
my @TARGETS;

=head1 NAME

Warewulf::Logger - Log interface

=head1 ABOUT

The Warewulf::Logger package provides an interface for logging and output

=head1 SYNOPSIS

    use Warewulf::Logger;

=item get_log_level()

Returns the current (numeric) log level.

=cut

sub
get_log_level()
{
    return $LEVEL;
}

=item set_log_level(LEVEL)

Set the minimum log level at which to print/log messages.  LEVEL may
be any of the following string or numeric values: CRITICAL (0), ERROR
(1), WARNING (2), NOTICE (3), INFO (4), or DEBUG (5).

=cut

sub
set_log_level($)
{
    my ($level) = @_;

    $level = &resolve_log_level($level);
    if (defined($level)) {
        $LEVEL = $level;
    }
    return $LEVEL;
}

=item add_log_target(TARGET, LEVEL, [ LEVEL ... ])

Add a logging target (IO::Handle, filehandle, filename, string to be
passed to open(), code reference, or the special target "SYSLOG") to
one or more logging levels.  The range operator may be used to supply
a range of levels.  "ALL" specifies all log levels.

Returns the number of log levels to which the specified target was
successfully appended or "undef" on error.

=cut

sub
add_log_target()
{
    my $target = shift;
    my @levels = @_;

    @levels = &resolve_log_level(@levels);
    if (!scalar(@levels)) {
        return undef;
    }

    # Figure out what the target is and handle it accordingly.
    if (! $target) {
        # FIXME:  What to do here?
    } elsif (ref($target)) {
        # We support objects or code references here.
        if ((ref($target) eq "CODE") || (ref($target) eq "SCALAR") || (ref($target) eq "ARRAY")) {
            # Do nothing.  We'll have to handle these specially, but they're supported.
        } elsif ((ref($target) eq "IO") || (ref($target) eq "GLOB")) {
            $target = IO::Handle->new_from_fd(fileno($target), "w");
            if (! $target) {
                return undef;
            }
        } else {
            my $is_obj;

            # Better be an object that inherits from IO::Handle!
            $is_obj = eval { no warnings ('all'); $target->isa("IO::Handle"); };
            if ($@) {
                $is_obj = 0;
            }
            if (! $is_obj) {
                return undef;
            }
        }
    } else {
        if (-w $target) {
            $target = ">>$target";
        }
        $target = IO::File->new($target);
        if (! $target) {
            return undef;
        }
    }

    foreach my $level (@levels) {
        push @{$TARGETS[$level]}, $target;
    }
    return scalar(@levels);
}

=item clear_log_target(LEVEL, [ LEVEL ... ])

Removes ALL currently assigned targets for the specified log level(s).

Returns the number of log levels successfully cleared.

=cut

sub
clear_log_target()
{
    my @levels = @_;

    @levels = &resolve_log_level(@levels);
    foreach my $level (@levels) {
        $TARGETS[$level] = [];
    }
    return scalar(@levels);
}

=item set_log_target(TARGET, LEVEL, [ LEVEL ... ])

Same as add_log_target() except that existing targets are removed.

=cut

sub
set_log_target()
{
    my $target = shift;

    &clear_log_target(@_);
    return &add_log_target($target, @_);
}

=item lprint(LEVEL, $string)

Log a message at a given log (i.e., severity/verbosity) level.

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

Log a message at a given log (i.e., severity/verbosity) level (with
format).

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


=head1 SEE ALSO

Warewulf, Warewulf::Debug

=head1 COPYRIGHT

Copyright (c) 2001-2003 Gregory M. Kurtzer

Copyright (c) 2003-2011, The Regents of the University of California,
through Lawrence Berkeley National Laboratory (subject to receipt of any
required approvals from the U.S. Dept. of Energy).  All rights reserved.

=cut

# Initialize the defaults for logging targets
sub
init_log_targets()
{
    my ($so, $se);

    if (&daemon_check()) {
        $so = $se = IO::File->new("/tmp/test.log", "a", 0600);
    } else {
        $so = IO::Handle->new_from_fd(fileno(STDOUT), "w");
        $se = IO::Handle->new_from_fd(fileno(STDERR), "w");
    }
    @TARGETS = (
        [ $se ],  # CRITICAL
        [ $se ],  # ERROR
        [ $se ],  # WARNING
        [ $so ],  # NOTICE
        [ $so ],  # INFO
        [ $se ]   # DEBUG
    );        
}

# Convert one or more user-supplied log levels to their numeric equivalents.
sub
resolve_log_level(@)
{
    my @levels = @_;
    my @ret;

    foreach my $level (@levels) {
        if (length($level) > 1) {
            $level = uc($level);
            if ($level eq "CRITICAL") {
                push @ret, $WWLOG_CRITICAL;
            } elsif ($level eq "ERROR") {
                push @ret, $WWLOG_ERROR;
            } elsif ($level eq "WARNING") {
                push @ret, $WWLOG_WARNING;
            } elsif ($level eq "NOTICE") {
                push @ret, $WWLOG_NOTICE;
            } elsif ($level eq "INFO") {
                push @ret, $WWLOG_INFO;
            } elsif ($level eq "DEBUG") {
                push @ret, $WWLOG_DEBUG;
            } elsif ($level eq "ALL") {
                push @ret, $WWLOG_CRITICAL .. $WWLOG_DEBUG;
            }
        } else {
            $level = int($level);
            if ($level >= $WWLOG_CRITICAL && $level <= $WWLOG_DEBUG) {
                push @ret, $level;
            }
        }
    }
    if (!scalar(@ret)) {
        return ((wantarray()) ? () : (undef));
    }
    return ((wantarray()) ? (@ret) : ($ret[0]));
}

# Return prefix for log file message based on its severity.
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
    if (!scalar(@TARGETS)) {
        &init_log_targets();
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

1;
