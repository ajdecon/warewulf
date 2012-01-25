#
# Copyright (c) 2001-2003 Gregory M. Kurtzer
# 
# Copyright (c) 2003-2012, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#


my $debug = ();
#$debug = 1;

package Warewulf::Util;
use Warewulf::Config;
use Socket;
use File::Basename;
use Exporter;
@ISA = ('Exporter');

@EXPORT = qw (
   &generate_random_string
   &users_filter
);

sub generate_random_string {
    my $size = shift;
    my @alphanumeric = ('a'..'z', 'A'..'Z', 0..9);
    my $randstring = join '', map $alphanumeric[rand @alphanumeric], 0..$size;
    return $randstring;
}

sub users_filter {
# PARAMS: Array of all node names
# RETURN: Array of nodes that the user wants to view
# DESC:   Looks for the users enviornment variable for '$NODES' and then checks
#         to see if it is a node list (\W delim) or a file of defined nodes
#         that the user wants to view.

   my @nodes = @_;
   my @return;
   if ( $ENV{NODES} ) {
      if ( -f "$ENV{NODES}" ) {
         open(NODES, "< $ENV{NODES}");
         while ($match=<NODES>) {
            chomp $match;
            $match =~ s/#.*$//;
            $match =~ s/\s+$//;
            next unless $match;
            $match =~ s/\*/.*/g;
            $match =~ s/\+/\\+/g;
            push(@return, grep(/$match/, @nodes));
         }
      } elsif ( $ENV{NODES} =~ /^\/.+$/ ) {
         # ignore node files that don't exist
         push(@return, @nodes);
      } else {
         foreach $match ( split(/,/, $ENV{NODES}) ) {
            $match =~ s/\*/.*/g;
            $match =~ s/\+/\\+/g;
            push(@return, grep(/$match/, @nodes));
         }
      }
   } else {
      push(@return, @nodes);
   }

   return(@return);
}


1;
