# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#
#
# $Id: Pxelinux.pm 50 2010-11-02 01:15:57Z gmk $
#

package Warewulf::Event::NewNode;

use Warewulf::Logger;
use Warewulf::Event;
use Warewulf::EventHandler;
use Warewulf::Config;

my $event = Warewulf::EventHandler->new();

sub
default_config()
{
    my @objects = @_;
    my $config = Warewulf::Config->new("node-defaults.conf");

    my %hash = $config->get_hash();

    foreach my $obj (@objects) {
        foreach my $key (keys %hash) {
            if ($obj->get($key)) {
                &dprint("Not overriding previously set value for $key\n");
            } else {
                &dprint("Setting node attribute: $key = $hash{$key}\n");
                $obj->set($key, $hash{$key});
            }
        }
    }

}


$event->register("node.new", \&default_config);

1;
