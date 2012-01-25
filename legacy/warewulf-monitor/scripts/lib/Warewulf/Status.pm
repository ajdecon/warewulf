#
# Copyright (c) 2001-2003 Gregory M. Kurtzer
# 
# Copyright (c) 2003-2012, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#

my $debug = ();
#$debug = 1;

package Warewulf::Status;
use Exporter;
use Socket;
use IO::Socket;
@ISA = ('Exporter');

@EXPORT = qw (
   &node_status
);


sub node_status {
   my ( $host, $port, $timeout, @NULL ) = @_;
   my ( %nodes, %nodecfg, @s, $entry, $value, $nodename, $sock );

   unless ( $host ) {
      $host = 'localhost';
   }
   unless ( $port ) {
      $port = '9873';
   }
   unless ( $timeout ) {
      $timeout = '5';
   }

   my $sock = new IO::Socket::INET ( PeerAddr => $host,
                                     PeerPort => $port,
                                     Proto    => 'tcp',
                                     Timeout  => $timeout,
                                   );
   unless ( $sock ) {
      warn "Could not connect to $host:$port!\n";
   }

   foreach ( keys %nodecfg ) {
      $nodes{$_}{NODESTATUS} = 'DOWN';
      $nodes{$_}{LASTCONTACT} = 'never';
   }

   while (<$sock>) {
      chomp;
      ( $entry, $value ) = split (/=/, $_ );
      next unless ( defined $entry and defined $value );
      if ( $entry eq 'CLUSTER' ) {
         $cluster = "$value";
         next;
      } 
      if ( $entry eq 'NODE' ) {
         if ( $cluster ) {
            $keyname = "$cluster:$value";
            $nodes{$keyname}{CLUSTERNAME} = $cluster;
            $nodes{$keyname}{CLUSTERNODENAME} = "$value.$cluster";
         } else {
            $keyname = "$value";
            $nodes{$keyname}{CLUSTERNODENAME} = $value;
         }
         $nodes{$keyname}{NODENAME} = $value;
         next;
      }
      if ( $keyname ) {
         $nodes{$keyname}{$entry} = $value;
      }
   }
   return(%nodes);
}



1;
