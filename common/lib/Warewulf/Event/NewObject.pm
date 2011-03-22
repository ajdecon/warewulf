# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#
#
# $Id: Pxelinux.pm 50 2010-11-02 01:15:57Z gmk $
#

package Warewulf::Event::NewObject;

use Warewulf::Logger;
use Warewulf::Event;
use Warewulf::EventHandler;
use Warewulf::Config;
use Warewulf::DataStore;

my $event = Warewulf::EventHandler->new();

sub
default_config()
{
    my @objects = @_;
    my $db = Warewulf::DataStore->new();

    &iprint("Building default configuration for new object(s)\n");

    foreach my $obj (@objects) {
        my $type = $obj->type();
        my $def_object = $db->get_objects($type, "name", "DEFAULT")->get_object(0);
        if ($def_object) {
            my %hash = $def_object->get_hash();
            foreach my $key (keys %hash) {
                if (! $obj->get($key)) {
                    $obj->set($key, $hash{"$key"});
                }
            }
        }
    }

}


$event->register("*.new", \&default_config);

1;
