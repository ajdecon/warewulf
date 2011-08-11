# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#
#
# $Id$
#

package Warewulf::Util;

#use Warewulf::Debug;
use Warewulf::Logger;

use Exporter;
use File::Basename;
use Digest::MD5 ('md5_hex');

our @ISA = ('Exporter');

our @EXPORT = (
    '&rand_string',
    '&croak',
    '&progname',
    '&homedir',
    '&expand_bracket',
    '&uid_test',
    '&ellipsis',
    '&digest_file_hex_md5',
    '&is_tainted',
    '&examine_object'
);

=head1 NAME

Warewulf::Util - Various helper functions

=head1 SYNOPSIS

    use Warewulf::Util;

=head1 DESCRIPTION

This module contains various utility functions used throughout the
Warewulf code.

=head1 FUNCTIONS

=over 4

=item rand_string(length)

Generate a random string of a given length

=cut

sub
rand_string($)
{
    my $size;
    my @alphanumeric = ('a'..'z', 'A'..'Z', 0..9);

    if (scalar(@_)) {
        $size = $_[0] - 1;
    } else {
        $size = 7;
    }

    return join('', map { $alphanumeric[rand @alphanumeric] } 0..$size);
}

=item croak()

Die with a backtrace.

=cut

sub
croak()
{
    my ($file, $line, $subroutine, $i);
    my @tmp;

    print "Program has croaked!\n\n";

    &backtrace();

    exit(255);
}

=item progname()

Return the program name of this running instance

=cut

sub
progname()
{
    return basename($0);
}

=item homedir()

Returns the home directory of the current user (real UID) or "." on error.

=cut

sub
homedir()
{
    return (($ENV{'HOME'}) || ($ENV{'LOGDIR'}) || ((getpwuid($<))[7]) || ("."));
}

=item expand_bracket($range1, $range2)

Input a string that contains a bracket range (e.g. [0-20]) and return a list
that has that expanded into a full array. For example, n00[0-19] will return
an array of 20 entries.

=cut

sub
expand_bracket(@)
{
    my @ranges = @_;
    my @ret;

    foreach my $range (@ranges) {
        if ($range =~ /^(.*?)\[([0-9\-\,]+)\](.*?)$/) {
            my $prefix = $1;
            my $range = $2;
            my $suffix = $3;

            foreach my $r (split(",", $range)) {
                if ($r =~ /^([0-9]+)\-([0-9]+)$/) {
                    my $start = $1;
                    my $end = $2;

                    if ($end > $start) {
                        my $len = length($end);

                        for (my $i = $start; $i <= $end; $i++) {
                            push(@ret, sprintf("%s%0.${len}d%s", $prefix, $i, $suffix));
                        }
                    }
                } elsif ($r =~ /^([0-9]+)$/ ) {
                    my $num = $1;
                    my $len = length($num);

                    push(@ret, sprintf("%s%0.${len}d%s", $prefix, $num, $suffix));
                }
            }
        } else {
            push(@ret, $range);
        }

    }

    return @ret;
}

=item uid_test($uid)

Test to see if the current uid meets the passed uid: e.g. &uid_test(0) will
test for the root user (which is always UID zero on a Unix system).

=cut

sub
uid_test()
{
    my ($uid) = @_;

    if (defined($uid)) {
        return ($> == $uid);
    }

    return;
}

=item ellipsis($length, $string, $location)

Trim a string to the desired length adding '...' to show that the original
string is longer then allowed. Location will define where to place the
'...' within the string. Options are start, middle, end (default: middle).

=cut

sub
ellipsis($$)
{
    my ($length, $text, $location) = @_;
    my $actual_length = length($text);
    my $ret;

    if ($actual_length > $length) {
        if (! $location || $location eq "middle") {
            my $leader_length = sprintf("%d", ($length-3)/2);
            my $tail_length = $length - 3 - $leader_length;

            $ret = substr($text, 0, $leader_length) . "..." . substr($text, -$tail_length);
        } elsif ($location eq "end") {
            $ret = substr($text, 0, $length-3);
            $ret .= "...";
        } elsif ($location eq "start") {
            $ret = "...";
            $ret .= substr($text, -$length);
        }
    } else {
        $ret = $text;
    }
    return $ret;
}

=item digest_file_hex_md5($filename)

Return the MD5 checksum of the file specified in $filename

=cut

sub digest_file_hex_md5($)
{
    my ($filename) = @_;
    local *DATA;

    if (open(DATA, $filename)) {
        return md5_hex(join("", <DATA>));
    } else {
        return undef;
    }
}

=item is_tainted($var)

Returns true/false depending on whether or not an item is tainted.

=cut

sub
is_tainted($) {
    # "Borrowed" from the perlsec man page.
    return ! eval { eval("#" . substr($_[0], 0, 0)); 1 };
}

=item examine_object($var, [$buffer, [$indent, [$indent_step]]])

Returns a string representation of a deep examination of the value of
a reference.  Useful for debugging complex data structures and
objects.  Results are appeneded to the contents of $buffer (default
"") and returned.  $indent is the numerical value for the initial
indent level (default 0).  $indent_step determines how many spaces to
indent each subsequent level (default 4).

=cut

sub
examine_object(@)
{
    my ($item, $buffer, $indent, $indent_step) = @_;
    my $tainted;

    # Set default parameters.
    if (!defined($buffer)) {
        $buffer = "";
    }
    if (!defined($indent)) {
        $indent = 0;
    }
    if (!defined($indent_step)) {
        $indent_step = 4;
    }
    if (&is_tainted($item)) {
        $tainted = ' *TAINTED*';
    } else {
        $tainted = '';
    }

    # Figure out what type it is first.
    if (!defined($item)) {
        $buffer .= "UNDEF";
    } elsif (ref($item)) {
        my $type = ref($item);

        if ($type eq "SCALAR") {
            $buffer .= "SCALAR REF $item$tainted {\n" . (' ' x ($indent + $indent_step));
            $buffer = &examine_object(${$item}, $buffer, $indent + $indent_step, $indent_step);
            $buffer .= "\n" . (' ' x $indent) . '}';
        } elsif ($type eq "ARRAY") {
            $buffer .= "ARRAY REF $item$tainted {\n";
            for (my $i = 0; $i < scalar(@{$item}); $i++) {
                $buffer .= (' ' x ($indent + $indent_step)) . "$i:  ";
                $buffer = &examine_object($item->[$i], $buffer, $indent + $indent_step, $indent_step) . "\n";
            }
            $buffer .= (' ' x $indent) . '}';
        } elsif ($type eq "HASH") {
            $buffer .= "HASH REF $item$tainted {\n";
            foreach my $key (sort(keys(%{$item}))) {
                $buffer .= (' ' x ($indent + $indent_step));
                $buffer = &examine_object($key, $buffer, $indent + $indent_step, $indent_step) . " => ";
                $buffer = &examine_object($item->{$key}, $buffer, $indent + $indent_step, $indent_step) . "\n";
            }
            $buffer .= (' ' x $indent) . '}';
        } elsif ($type eq "CODE") {
            $buffer .= "CODE REF $item$tainted";
        } elsif ($type eq "REF") {
            $buffer .= "REF REF $item$tainted {\n" . (' ' x ($indent + $indent_step));
            $buffer = &examine_object(${$item}, $buffer, $indent + $indent_step, $indent_step);
            $buffer .= "\n" . (' ' x $indent) . '}';
        } elsif ($type eq "GLOB") {
            $buffer .= "GLOB REF $item$tainted";
        } elsif ($type eq "LVALUE") {
            $buffer .= "LVALUE REF $item$tainted";
        #} elsif ($type eq "Regexp") {
        } else {
            # Some object type.
            $buffer .= ref($item) . " REF $item$tainted {\n" . (' ' x ($indent + $indent_step));
            if (UNIVERSAL::isa($item, "CODE")) {
                $item = \&{$item};
            } elsif (UNIVERSAL::isa($item, "REF")) {
                $item = \${$item};
            } elsif (UNIVERSAL::isa($item, "HASH")) {
                $item = \%{$item};
            } elsif (UNIVERSAL::isa($item, "ARRAY")) {
                $item = \@{$item};
            } else {
                $item = \"UNKNOWN";  #"
            }
            $buffer = &examine_object($item, $buffer, $indent + $indent_step, $indent_step);
            $buffer .= "\n" . (' ' x $indent) . '}';
        }
    } elsif ($item =~ /^\d+$/) {
        $buffer .= "$item$tainted";
    } else {
        $buffer .= sprintf("\"%s\" (%d)%s", $item, length($item), $tainted);
    }
    return $buffer;
}

=back

=head1 COPYRIGHT

Copyright (c) 2001-2003 Gregory M. Kurtzer

Copyright (c) 2003-2011, The Regents of the University of California,
through Lawrence Berkeley National Laboratory (subject to receipt of any
required approvals from the U.S. Dept. of Energy).  All rights reserved.

=cut

1;
