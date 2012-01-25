#
# Copyright (c) 2001-2003 Gregory M. Kurtzer
# 
# Copyright (c) 2003-2012, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#



my $debug = ();
#$debug = 1;

package Warewulf::Config;
use File::Basename;
use Warewulf::Util;
use Socket;
use Exporter;
@ISA = ('Exporter');

@EXPORT = qw(
   &read_conf
   &client_config
);


sub read_conf {
   my ($file, @NULL) = @_;
   my ( %ret );
   open(CONF, "$file");
   while(<CONF>) {
      chomp;
      $_ =~ s/#.*$//g;
      $_ =~ s/^\s+//g;
      $_ =~ s/\s+$//g;
      $_ =~ s/\s*=\s*/=/g;
      if ( $_ =~ /^([a-zA-Z0-9_\s]+)=(.)(.*)(.)$/) {
         $key = $1;
         if ( $ret{"$key"} ) {
            $ret{"$key"} .= " ";
         }
         if ( ( $2 eq '"' and $4 eq '"') or ( $2 eq '\'' and $4 eq '\'') ){
            $ret{"$key"} .= "$3";
         } elsif ( $2 eq '"' or $2 eq '\'' ) {
            $open_quote = '1';
            $ret{"$key"} .= "$3$4";
         } else {
            $ret{"$key"} .= "$2$3$4";
         }
      } elsif ( $open_quote ) {
         if ( $_ =~ /^(.+)(.)$/ ) {
            if ( $2 eq '"' ) {
               $ret{"$key"} .= " $1 ";
               $open_quote = ();
            } else {
               $ret{"$key"} .= " $1$2 ";
            }
         }
      }
   }
   close CONF;
   return %ret;
}

sub client_config {
   my %return = &read_conf("/etc/warewulf-legacy/client.conf");
   return(%return);
}



1;
