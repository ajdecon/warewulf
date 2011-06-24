#
# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#




package Warewulf::Module::Cli::Node;

use Warewulf::Logger;
use Warewulf::Module::Cli;
use Warewulf::Term;
use Warewulf::DataStore;
use Warewulf::Util;
use Getopt::Long;
use Text::ParseWords;

our @ISA = ('Warewulf::Module::Cli');

my $entity_type = "node";

sub
new()
{
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};

    bless($self, $class);

    $self->init();

    return $self;
}

sub
init()
{
    my ($self) = @_;

    $self->{"DB"} = Warewulf::DataStore->new();
}


sub
help()
{
    my $h;

    $h .= "USAGE:\n";
    $h .= "     node [command] [options] [targets]\n";
    $h .= "\n";
    $h .= "SUMMARY:\n";
    $h .= "    The node command is used for editing the node configurations.\n";
    $h .= "\n";
    $h .= "COMMANDS:\n";
    $h .= "\n";
    $h .= "     The first argument MUST be the desired action you wish to take and after\n";
    $h .= "     the action, the order of the options and the targets is not specific.\n";
    $h .= "\n";
    $h .= "         new             Create a new node configuration defined by the 'target'\n";
    $h .= "         set             Modify an existing node configuration\n";
    $h .= "         list            List a summary of nodes\n";
    $h .= "         print           Print the node configuration\n";
    $h .= "         delete          Remove a node configuration from the data store\n";
    $h .= "         help            Show usage information\n";
    $h .= "\n";
    $h .= "TARGETS:\n";
    $h .= "\n";
    $h .= "     The target is the specification for the node you wish to act on. By default\n";
    $h .= "     the specification is the node's name and this can be changed by setting the\n";
    $h .= "     --lookup option to something else (e.g. 'hwaddr' or 'groups').\n";
    $h .= "\n";
    $h .= "     All targets can be bracket expanded as follows:\n";
    $h .= "\n";
    $h .= "         n00[0-99]       inclusively all nodes from n0000 to n0099\n";
    $h .= "         n00[00,10-99]   n0000 and inclusively all nodes from n0010 to n0099\n";
    $h .= "\n";
    $h .= "OPTIONS:\n";
    $h .= "\n";
    $h .= "     -l, --lookup        How should we reference this node? (default is name)\n";
    $h .= "         --groups        Define the list of groups this node should be part of\n";
    $h .= "         --groupadd      Associate a group to this node\n";
    $h .= "         --groupdel      Remove a group association from this node\n";
    $h .= "         --netdev        Define a network device to set for this node\n";
    $h .= "         --ipaddr        Set an IP address for the given network device\n";
    $h .= "         --netmask       Set a subnet mask for the given network device\n";
    $h .= "         --hwaddr        Set the device's hardware/MAC address\n";
    $h .= "         --netdel        Remove a network device from the system\n";
    $h .= "         --cluster       Define the cluster of nodes that this node is a part of\n";
    $h .= "         --name          Rename this node\n";
    $h .= "\n";
    $h .= "EXAMPLES:\n";
    $h .= "\n";
    $h .= "     Warewulf> node new n0000 --netdev=eth0 --hwaddr=xx:xx:xx:xx:xx:xx\n";
    $h .= "     Warewulf> node set n0000 --netdev=eth0 --ipaddr=10.0.0.10\n";
    $h .= "     Warewulf> node set n0000 --netdev=eth0 --netmask=255.255.255.0\n";
    $h .= "     Warewulf> node set --groupadd=mygroup,hello,bye --cluster=mycluster n0000\n";
    $h .= "     Warewulf> node set --groupdel=bye --set=vnfs=sl6.vnfs\n";
    $h .= "     Warewulf> node set xx:xx:xx:xx:xx:xx --lookup=hwaddr\n";
    $h .= "     Warewulf> node print --lookup=groups --print=id,name,groups mygroup hello group123\n";
    $h .= "\n";

    return($h);
}

sub
summary()
{
    my $output;

    $output .= "Node manipulation commands";

    return($output);
}



sub
complete()
{
    my $self = shift;
    my $opt_lookup = "name";
    my $db = $self->{"DB"};
    my @ret;

    if (! $db) {
        return();
    }

    @ARGV = ();

    foreach (&quotewords('\s+', 0, @_)) {
        if (defined($_)) {
            push(@ARGV, $_);
        }
    }

    Getopt::Long::Configure ("bundling", "passthrough");

    GetOptions(
        'l|lookup=s'    => \$opt_lookup,
    );

    if (exists($ARGV[1]) and ($ARGV[1] eq "print" or $ARGV[1] eq "new" or $ARGV[1] eq "set")) {
        @ret = $db->get_lookups($entity_type, $opt_lookup);
    } else {
        @ret = ("print", "new", "set", "delete");
    }

    @ARGV = ();

    return(@ret);
}

sub
exec()
{
    my $self = shift;
    my $db = $self->{"DB"};
    my $term = Warewulf::Term->new();
    my $opt_lookup = "name";
    my $opt_hwaddr;
    my $opt_ipaddr;
    my $opt_netmask;
    my $opt_netdev;
    my $opt_devremove;
    my $opt_cluster;
    my $opt_name;
    my @opt_print;
    my @opt_groups;
    my @opt_groupadd;
    my @opt_groupdel;
    my $return_count;
    my $objSet;
    my @changes;
    my $command;
    my $object_count = 0;

    @ARGV = ();
    push(@ARGV, @_);

    Getopt::Long::Configure ("bundling", "nopassthrough");

    GetOptions(
        'groups=s'      => \@opt_groups,
        'groupadd=s'    => \@opt_groupadd,
        'groupdel=s'    => \@opt_groupdel,
        'netdev=s'      => \$opt_netdev,
        'netdel'        => \$opt_devremove,
        'hwaddr=s'      => \$opt_hwaddr,
        'ipaddr=s'      => \$opt_ipaddr,
        'netmask=s'     => \$opt_netmask,
        'cluster=s'     => \$opt_cluster,
        'name=s'        => \$opt_name,
        'l|lookup=s'    => \$opt_lookup,

    );

    $command = shift(@ARGV);

    if (! $db) {
        &eprint("Database object not avaialble!\n");
        return();
    }

    if (! $command) {
        &eprint("You must provide a command!\n\n");
        print $self->help();
        return();
    } elsif ($command eq "new") {
        $objSet = Warewulf::ObjectSet->new();
        foreach my $string (&expand_bracket(@ARGV)) {
            my $obj;
            $obj = Warewulf::DSOFactory->new($entity_type);

            $obj->set($opt_lookup, $string);

            $objSet->add($obj);
        }
        $db->persist($objSet);
    } else {
        $objSet = $db->get_objects($opt_type || $entity_type, $opt_lookup, &expand_bracket(@ARGV));
    }

    if ($objSet) {
        $object_count = $objSet->count();
    } else {
        &nprint("No nodes found\n");
        return();
    }

    if ($command eq "delete") {
        if ($term->interactive()) {
            print "Are you sure you want to delete $object_count node(s):\n\n";
            my $yesno = lc($term->get_input("Yes/No> ", "no", "yes"));
            if ($yesno ne "y" and $yesno ne "yes") {
                &nprint("No update performed\n");
                return();
            }
        }
        $db->del_object($objSet);
    } elsif ($command eq "list") {
        &nprintf("%-19s %-19s %-19s %-19s\n",
            "NAME",
            "CLUSTER",
            "GROUPS",
            "HWADDR"
        );
        &nprint("================================================================================\n");
        foreach my $o ($objSet->get_list()) {
            printf("%-19s %-19s %-19s %-19s\n",
                &ellipsis(19, ($o->get("name") || "UNDEF"), "end"),
                &ellipsis(19, ($o->get("cluster") || "UNDEF")),
                &ellipsis(19, (join(",", $o->get("groups")) || "UNDEF")),
                join(",", $o->get("_hwaddr")) || "UNDEF"
            );
        }
    } elsif ($command eq "print") {
        foreach my $o ($objSet->get_list()) {
            my $name = $o->get("name") || "UNDEF";
            if (my ($cluster) = $o->get("cluster")) {
                $name .= ".$cluster";
            }
            &nprintf("#### %s %s#\n", $name, "#" x (72 - length($name)));
            printf("%15s: %-16s = %s\n", $name, "ID", ($o->get("_id") || "ERROR"));
            printf("%15s: %-16s = %s\n", $name, "NAME", ($o->get("name") || "UNDEF"));
            printf("%15s: %-16s = %s\n", $name, "CLUSTER", ($o->get("cluster") || "UNDEF"));
            printf("%15s: %-16s = %s\n", $name, "GROUPS", join(",", $o->get("groups")));
            foreach my $n ($o->get("netdevs")) {
                if ( my $device = $n->get("name")) {
                    printf("%15s: %-16s = %s\n", $name, "HWADDR($device)", $n->get("hwaddr"));
                    if (my $ipaddr = $n->get("ipaddr")) {
                        printf("%15s: %-16s = %s\n", $name, "IPADDR($device)", $ipaddr);
                    }
                    if (my $netmask = $n->get("netmask")) {
                        printf("%15s: %-16s = %s\n", $name, "NETMASK($device)", $netmask);
                    }
                    if (my $fqdn = $n->get("fqdn")) {
                        printf("%15s: %-16s = %s\n", $name, "FQDN($device)", $fqdn);
                    }
                }
            }
        }

    } elsif ($command eq "set" or $command eq "new") {
        &dprint("Entered 'set' codeblock\n");
        my $persist_count = 0;

        if ($opt_ipaddr or $opt_hwaddr or $opt_netmask or $opt_fqdn or $opt_devremove) {
            if ($opt_ipaddr) {
                if ($opt_ipaddr =~ /^(\d+\.\d+\.\d+\.\d+)$/) {
                    $opt_ipaddr = $1;
                } else {
                    &eprint("Bad format for IP address!\n");
                    $opt_ipaddr = undef;
                }
            }
            if ($opt_netmask) {
                if ($opt_netmask =~ /^(\d+\.\d+\.\d+\.\d+)$/) {
                    $opt_netmask = $1;
                } else {
                    &eprint("Bad format for netmask address!\n");
                    $opt_netmask = undef;
                }
            }
            if ($opt_fqdn) {
                if ($opt_fqdn =~ /^([a-zA-Z0-9\-_\.]+)$/) {
                    $opt_fqdn = $1;
                } else {
                    &eprint("Illegal characters in FQDN format!\n");
                    $opt_fqdn = undef;
                }
            }
            if ($opt_hwaddr) {
                if ($opt_hwaddr =~ /^((?:[0-9a-f]{2}:){5}[0-9a-f]{2})$/) {
                    $opt_hwaddr = $1;
                } else {
                    &eprint("Bad format for HW address!\n");
                    $opt_hwaddr = undef;
                }
            }
            foreach my $obj ($objSet->get_list()) {
                my $name = $obj->get("name") || "UNDEF";
                my $netobj;
                if ($opt_netdev) {
                    foreach my $nobj ($obj->get("netdevs")) {
                        if ($nobj->get("name") eq $opt_netdev) {
                            &dprint("Using existing netdev object: $nobj\n");
                            $netobj = $nobj;
                            last;
                        }
                    }
                    if (! $netobj) {
                        &dprint("Creating a new netdev object\n");
                        $netobj = Warewulf::DSOFactory->new("netdev");
                        $netobj->set("name", $opt_netdev);
                        $obj->add("netdevs", $netobj);
                    }
                }
                if (! $netobj) {
                    my @netobjs = $obj->get("netdevs");
                    if (scalar(@netobjs) == 1) {
                        $netobj = shift(@netobjs);
                        $opt_netdev = $netobj->get("name");
                    } else {
                        &eprint("Could not set network configuration for node '$name' (include --netdev!)\n");
                        next;
                    }
                }
                if ($opt_hwaddr) {
                    $opt_hwaddr = lc($opt_hwaddr);
                    my $old_hwaddr = $netobj->get("hwaddr");
                    $netobj->set("hwaddr", $opt_hwaddr);
                    if ($old_hwaddr and $old_hwaddr ne $opt_hwaddr) {
                        $obj->del("_hwaddr", $old_hwaddr);
                    }
                    $obj->add("_hwaddr", $opt_hwaddr);
                    $persist_count++;
                }
                if ($opt_ipaddr) {
                    $netobj->set("ipaddr", $opt_ipaddr);
                    $persist_count++;
                }
                if ($opt_netmask) {
                    $netobj->set("netmask", $opt_netmask);
                    $persist_count++;
                }
                if ($opt_fqdn) {
                    $netobj->set("fqdn", $opt_fqdn);
                    $persist_count++;
                }
                if ($opt_devremove) {
                    $obj->del("_hwaddr", $netobj->get("hwaddr"));
                    $obj->del("netdevs", $netobj);
                    $persist_count++;
                }
            }
            if ($opt_ipaddr) {
                push(@changes, sprintf("     SET: %-20s = %s\n", "$opt_netdev.IPADDR", $opt_ipaddr));
            }
            if ($opt_netmask) {
                push(@changes, sprintf("     SET: %-20s = %s\n", "$opt_netdev.NETMASK", $opt_netmask));
            }
            if ($opt_hwaddr) {
                push(@changes, sprintf("     SET: %-20s = %s\n", "$opt_netdev.HWADDR", $opt_hwaddr));
            }
            if ($opt_fqdn) {
                push(@changes, sprintf("     SET: %-20s = %s\n", "$opt_netdev.FQDN", $opt_fqdn));
            }
            if ($opt_devremove) {
                push(@changes, sprintf("     SET: %-20s = %s\n", $opt_netdev, "REMOVE"));
            }
        }

        if ($opt_cluster) {
            if (uc($opt_cluster) eq "UNDEF") {
                foreach my $obj ($objSet->get_list()) {
                    my $name = $obj->get("name") || "UNDEF";
                    $obj->del("cluster");
                    &dprint("Deleting cluster for node name: $name\n");
                    $persist_count++;
                }
                push(@changes, sprintf("     SET: %-20s = %s\n", "CLUSTER", "UNDEF"));
            } else {
                foreach my $obj ($objSet->get_list()) {
                    my $name = $obj->get("name") || "UNDEF";
                    $obj->set("cluster", $opt_cluster);
                    &dprint("Setting cluster for node name: $name\n");
                    $persist_count++;
                }
                push(@changes, sprintf("     SET: %-20s = %s\n", "CLUSTER", $opt_cluster));
            }
        }

        if ($opt_name) {
            if (uc($opt_name) eq "UNDEF") {
                &eprint("You must define the name you wish to reference the node as!\n");
            } else {
                foreach my $obj ($objSet->get_list()) {
                    my $name = $obj->get("name") || "UNDEF";
                    $obj->set("name", $opt_name);
                    &dprint("Setting name for node name: $name\n");
                    $persist_count++;
                }
                push(@changes, sprintf("     SET: %-20s = %s\n", "NAME", $opt_name));
            }
        }

        if (@opt_groups) {
            foreach my $obj ($objSet->get_list()) {
                my $name = $obj->get("name") || "UNDEF";
                $obj->set("groups", split(",", join(",", @opt_groups)));
                &dprint("Setting groups for node name: $name\n");
                $persist_count++;
            }
            push(@changes, sprintf("     SET: %-20s = %s\n", "GROUPS", join(",", @opt_groups)));
        }

        if (@opt_groupadd) {
            foreach my $opt (@opt_groupadd) {
                &dprint("Adding group $opt to nodes\n");
                foreach my $obj ($objSet->get_list()) {
                    $obj->add("groups", split(",", $opt));
                }
                push(@changes, sprintf("     ADD: %-20s = %s\n", "GROUPS", $opt));
                $persist_count++;
            }
        }
        if (@opt_groupdel) {
            foreach my $opt (@opt_groupdel) {
                &dprint("Deleting group $opt from nodes\n");
                foreach my $obj ($objSet->get_list()) {
                    $obj->del("groups", split(",", $opt));
                }
                push(@changes, sprintf("     DEL: %-20s = %s\n", "GROUPS", $opt));
                $persist_count++;
            }
        }

        if ($persist_count > 0) {
            if ($command ne "new" and $term->interactive()) {
                print "Are you sure you want to make the following $persist_count changes to node(s):\n\n";
                foreach my $change (@changes) {
                    print $change;
                }
                print "\n";
                my $yesno = lc($term->get_input("Yes/No> ", "no", "yes"));
                if ($yesno ne "y" and $yesno ne "yes") {
                    &nprint("No update performed\n");
                    return();
                }
            }

            $return_count = $db->persist($objSet);

            &iprint("Updated $return_count objects\n");
        }

    } elsif ($command eq "help") {
        print $self->help();

    } else {
        &eprint("Unknown command: $command\n\n");
        print $self->help();
    }

    # We are done with ARGV, and it was internally modified, so lets reset
    @ARGV = ();

    return($return_count);
}


1;
