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
use Digest::MD5 qw(md5_hex);;

our @ISA = ('Exporter');

our @EXPORT = (
    '&rand_string',
    '&croak',
    '&progname',
    '&expand_bracket',
    '&uid_test',
    '&ellipsis',
    '&digest_file_hex_md5'
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
                        for(my $i=$start; $i<=$end; $i++) {
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

    return(@ret);
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
        return($> == $uid);
    }

    return;
}


=item ellipsis($length, $string, $location)

Trim a string to the desired length adding '...' to show that the original
string is longer then allowed. Location will define where to place the
'...' within the string. Options are start, middle, end (default: middle).

=cut
sub ellipsis($$)
{
    my ($length, $text, $location) = @_;
    my $actual_length = length($text);
    my $ret;

    if ($actual_length > $length) {
        if (! $location or $location eq "middle") {
            my $leader_length = sprintf("%d", ($length-3)/2);
            my $tail_length = $length - 3 - $leader_length;
            $ret = substr($text, 0, $leader_length) ."...". substr($text, -$tail_length);
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

    return($ret);
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


=head1 SEE ALSO

Warewulf

=head1 COPYRIGHT

Copyright (c) 2001-2003 Gregory M. Kurtzer

Copyright (c) 2003-2011, The Regents of the University of California,
through Lawrence Berkeley National Laboratory (subject to receipt of any
required approvals from the U.S. Dept. of Energy).  All rights reserved.

=cut

1;
