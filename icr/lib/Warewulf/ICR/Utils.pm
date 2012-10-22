# Copyright (c) 2003-2012, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#
# Copyright (c) 2012, Intel Corporation
#
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
#
#    * Redistributions of source code must retain the above copyright notice, 
#      this list of conditions and the following disclaimer.
#    * Redistributions in binary form must reproduce the above copyright 
#      notice, this list of conditions and the following disclaimer in the 
#      documentation and/or other materials provided with the distribution.
#    * Neither the name of Intel Corporation nor the names of its contributors 
#      may be used to endorse or promote products derived from this software 
#      without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.
#
# $Id$
#

package Warewulf::ICR::Utils;

use strict;
use warnings;
use English qw/-no_match_vars/;
use IPC::Open3;
use File::Copy;
use Symbol;

use Warewulf::Logger;

our @ISA = ('Exporter');
our @EXPORT_OK = ( 'run_cmd', 'edit_file_line' );

=head1 NAME

Warewulf::ICR::Utils

=head1 SYNOPSIS

    use Warewulf::ICR::Utils;

=head1 DESCRIPTION

General purpose functions for performing system configurations.

=head1 FUNCTIONS

=over 4

=item  run_cmd($cmd)

Run a command in the system shell. Accept as parameter the command to execute.
Return the standard output and standard error of the command. If the standard 
error is empty it will be undefined. Note that the function must always be
called in array context.

=cut

sub run_cmd {
    my ($cmd) = @ARG;

    # avoid undefined values
    if ( not defined $cmd ) {
        &eprint('Missing command in run_cmd');
        return;
    }
    &dprint("System CMD: $cmd\n");

    # execute command and gather stdout/stderr

    my ( $stdout, $stderr );
    my ( $writer, $reader, $error );

    # create file handles
    $reader = gensym();
    $error  = gensym();

    my $pid = open3( $writer, $reader, $error, $cmd );

    # use select to read from handlers
    my $select = IO::Select->new();
    $select->add( $reader, $error );

    # when handlers are ready for reading, accumulate their output
    while ( my @ready = $select->can_read() ) {
        foreach my $handle (@ready) {
            if ( fileno $handle == fileno $error ) {
                $stderr .= <$error>;
            }
            elsif ( fileno $handle == fileno $reader ) {
                $stdout .= <$reader>;
            }
            $select->remove($handle) if ( eof $handle );
        }
    }

    close $error;
    close $reader;

    waitpid $pid, 0;

    chomp $stdout;
    chomp $stderr;

    &dprint("STDOUT: $stdout\n");
    &dprint("STERR: $stderr\n");

    $stderr = ( $stderr eq q{} ) ? undef : $stderr;
    return ( $stdout, $stderr );
}

=item edit_file_line($file, $item, $match_exp, $data, $add )

Edit the text file $file (absolute path) line matching the pattern $match_exp. 
The new line will start with $item followed by $data. The $match_exp expression
may contain clustering for capturing one sub-string who's usage is controlled by $add.
if $add==1 the new line will be $item $1 $data. If $add==0 the new line will be
$item $data.
Return 0 if no errors found or 1 if cannot open the target file.

=cut

sub edit_file_line {
    my ( $file, $item, $match_exp, $data, $add ) = @ARG;

    my $edited   = 0;
    my $EDIT_FILE;
    if( not( open $EDIT_FILE, "+<", $file ))
    {
        &eprint("Can't open $file: $ERRNO\n");
        return 1;
    }
 
    my @file_lines = <$EDIT_FILE>;
    seek $EDIT_FILE,0,0;
    # if no matching expression was provided, just add the line at the end
    foreach  my $line (@file_lines) {
        if ( $line =~ m/$match_exp/xms ) {

            my $existing_data = $1;

            # append to the content already in the file
            if (    ( defined $add )
                and ( $add =~ m/^1$/xms )
                and ( defined $existing_data ) )
            {
                chomp $existing_data;
#                print $EDIT_FILE_TMP "$item $existing_data $data\n";
                $line = "$item $existing_data $data\n";
                &dprint("Edit file $file with $item $existing_data $data\n");
            }

            # replace the entire line
            else {
#               print $EDIT_FILE_TMP "$item $data\n";
                $line = "$item $data\n";
                &dprint("Edit file $file with $item $data\n");
            }

            $edited = 1;
        }

        print $EDIT_FILE $line;
    }

    # add the line at the end of the file
    if ( not $edited ) {
        print $EDIT_FILE "$item $data\n";
        &dprint("Edit file $file with $item $data\n");
    }

    close $EDIT_FILE;
    @file_lines = ();

    return 0;
}

1;

# vim:filetype=perl:syntax=perl:expandtab:sw=4:ts=4:
