# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#
#
# $Id$
#

package Warewulf::Debug;

use Exporter;

our @ISA = ('Exporter');

our @EXPORT = ('&caller_fixed', '&get_backtrace', '&backtrace');

=head1 NAME

Warewulf::Debug - Debugging functions

=head1 ABOUT

The Warewulf::Debug provides debugging functions

=head1 SYNOPSIS

    use Warewulf::Debug;


=item caller_fixed()

Fixed version of caller() that actually does the right thing.  Returns
the Nth stack frame, not counting itself.

=cut

sub
caller_fixed($)
{
    my $idx = shift || 0;
    my ($pkg, $file, $line, $subroutine);

    $idx++;
    (undef, undef, undef, $subroutine) = caller($idx);
    if (!defined($subroutine)) {
        $subroutine = "MAIN";
    }
    $subroutine =~ s/\w+:://g;
    if ($subroutine =~ /^\w+$/) {
        $subroutine .= "()";
    }
    ($pkg, $file, $line) = caller($idx - 1);
    if ($file && $file =~ /^.*\/([^\/]+)$/) {
        $file = $1;
    }
    return ($pkg || "", $file || "", $line || "", $subroutine);
}

=item get_backtrace()

Generate a stack trace in array form, one caller per line.

=cut

sub
get_backtrace()
{
    my $start = shift || 0;
    my (@trace, @tmp);

    $start++;
    for (my $i = $start; @tmp = caller($i); $i++) {
        my ($file, $line, $subroutine);
        my $idx = $i - $start;

        (undef, $file, $line, $subroutine) = &caller_fixed($i);
        push @trace, sprintf("%s\[%d\] $file:$line | $subroutine\n",  ' ' x $idx, $idx);
    }
    return ((wantarray()) ? (@trace) : (join('', @trace)));
}

=item backtrace()

Throw a backtrace at the current location in the code.

=cut
sub
backtrace()
{
    print STDERR "STACK TRACE:\n";
    print STDERR "------------\n";
    print STDERR &get_backtrace(1), "\n";
}


=head1 SEE ALSO

Warewulf::Logger

=head1 COPYRIGHT

Copyright (c) 2001-2003 Gregory M. Kurtzer

Copyright (c) 2003-2011, The Regents of the University of California,
through Lawrence Berkeley National Laboratory (subject to receipt of any
required approvals from the U.S. Dept. of Energy).  All rights reserved.

=cut

BEGIN {
    #$SIG{"__WARN__"} = sub { if (@_) { &backtrace(); warn @_; } };
    #$SIG{"__DIE__"} = sub { if (@_) { &backtrace(); die @_; } }; 
}

1;
