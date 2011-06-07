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

    $h .= "SUMMARY:\n";
    $h .= "    The node command is used for editing the node configurations.\n";
    $h .= "\n";
    $h .= "ACTIONS:\n";
    $h .= "\n";
    $h .= "     The first argument MUST be the desired action you wish to take and after\n";
    $h .= "     the action, the order of the options and the targets is not specific.\n";
    $h .= "\n";
    $h .= "         new             Create a new node configuration defined by the 'target'\n";
    $h .= "         set             Modify an existing node configuration\n";
    $h .= "         list            List a summary of nodes\n";
    $h .= "         print           Print the node configuration\n";
    $h .= "         delete          Remove a node configuration from the data store\n";
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
    $h .= "     -p, --print         Define what fields are printed (':all' prints all)\n";
    $h .= "     -s, --set           Set an arbituary key=value(s) pair\n";
    $h .= "     -a, --add           Add a value to an arbituary key\n";
    $h .= "     -d, --del           Delete a value from an arbituary key, or the entire key\n";
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
    my @opt_set;
    my @opt_add;
    my @opt_del;
    my @opt_print;
    my @opt_groups;
    my @opt_groupadd;
    my @opt_groupdel;
    my $return_count;
    my $objSet;
    my @changes;
    my $command;

    @ARGV = ();
    push(@ARGV, @_);

    Getopt::Long::Configure ("bundling", "nopassthrough");

    GetOptions(
        'p|print=s'     => \@opt_print,
        's|set=s'       => \@opt_set,
        'a|add=s'       => \@opt_add,
        'd|del=s'       => \@opt_del,
        'groups=s'      => \@opt_groups,
        'groupadd=s'    => \@opt_groupadd,
        'groupdel=s'    => \@opt_groupdel,
        'netdev=s'      => \$opt_netdev,
        'remove'        => \$opt_devremove,
        'hwaddr=s'      => \$opt_hwaddr,
        'ipaddr=s'      => \$opt_ipaddr,
        'netmask=s'     => \$opt_netmask,
        'cluster=s'     => \$opt_cluster,
        'name=s'        => \$opt_name,
        'l|lookup=s'    => \$opt_lookup,

    );

    if (scalar(@ARGV) > 0) {
        $command = shift(@ARGV);
        &dprint("Running command: $command\n");
    } else {
        &dprint("Returning with nothing to do\n");
        return();
    }

    if (! $db) {
        &eprint("Database object not avaialble!\n");
        return();
    }

    if ($command eq "new") {
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

    my $object_count = $objSet->count();

    if ($object_count == 0 ) {
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
                $o->get("name") || "UNDEF",
                $o->get("cluster") || "UNDEF",
                join(",", $o->get("groups")) || "UNDEF",
                join(",", $o->get("hwaddr")) || "UNDEF"
            );
        }
    } elsif ($command eq "print") {
        if (scalar(@opt_print) > 0) {
            @opt_print = split(",", join(",", @opt_print));
        } else {
            @opt_print = (":all");
        }
        if (@opt_print and scalar @opt_print > 1 and $opt_print[0] ne ":all") {
            my $string = sprintf("%-17s " x (scalar @opt_print), map {uc($_);} @opt_print);
            &nprint($string ."\n");
            &nprint("=" x length($string) ."\n");
        }
        foreach my $o ($objSet->get_list()) {
            if (@opt_print and $opt_print[0] eq ":all") {
                my %hash = $o->get_hash();
                my $name = $o->get("name");
                &nprintf("#### %s %s#\n", $name, "#" x (72 - length($name)));
                foreach my $h (keys %hash) {
                    if(ref($hash{$h}) =~ /^ARRAY/) {
                        my @scalars;
                        foreach my $e (@{$hash{$h}}) {
                            if (ref($e) =~ /^Warewulf::DSO::([a-zA-Z0-9\-_]+)/) {
                                my $type = lc($1);
                                my @s;
                                foreach my $l ($e->lookups()) {
                                    if (my $string = $e->get($l)) {
                                        push(@s, $l ."=". $string);
                                    }
                                }
                                push(@scalars, $type ."(". join(",", @s) .")");
                            } else {
                                push(@scalars, $e);
                            }
                        }
                        if (scalar(@scalars) > 0) {
                            printf("%12s: %-10s = %s\n", $name, $h, join(",", sort @scalars));
                        } else {
                            push(@values, "UNDEF");
                        }
                    } else {
                        if (ref($e) =~ /^Warewulf::DSO::([a-zA-Z0-9\-_]+)/) {
                            my @scalars;
                            my $type = lc($1);
                            my @s;
                            foreach my $l ($e->lookups()) {
                                if (my $string = $e->get($l)) {
                                    push(@s, $l ."=". $string);
                                }
                            }
                            printf("%12s: %-10s = %s\n", $name, $h, $type ."(". join(",", @s) .")");
                        } else {
                            printf("%12s: %-10s = %s\n", $name, $h, $hash{$h});
                        }
                    }
                }
            } else {
                my @values;
                foreach my $h (@opt_print) {
                    if (my $val = $o->get($h)) {
                        if(ref($val) =~ /^ARRAY/) {
                            my @scalars;
                            foreach my $e (@{$val}) {
                                if (ref($e) =~ /^Warewulf::DSO::([a-zA-Z0-9\-_]+)/) {
                                    my $type = lc($1);
                                    my @s;
                                    foreach my $l ($e->lookups()) {
                                        if (my $string = $e->get($l)) {
                                            push(@s, $l ."=". $string);
                                        }
                                    }
                                    push(@scalars, $type ."(". join(",", @s) .")");
                                } else {
                                    push(@scalars, $e);
                                }
                            }
                            if (scalar(@scalars) > 0) {
                                push(@values, join(",", sort @scalars));
                            } else {
                                push(@values, "UNDEF");
                            }
                        } else {
                            if (ref($e) =~ /^Warewulf::DSO::([a-zA-Z0-9\-_]+)/) {
                                my @scalars;
                                my $type = lc($1);
                                my @s;
                                foreach my $l ($e->lookups()) {
                                    if (my $string = $e->get($l)) {
                                        push(@s, $l ."=". $string);
                                    }
                                }
                                push(@values, $type ."(". join(",", @s) .")");
                            } else {
                                push(@values, $val);
                            }
                        }
                    } else {
                        push(@values, "UNDEF");
                    }
                }
                printf("%-17s " x (scalar @values) ."\n", @values);
            }
        }
    } elsif ($command eq "set" or $command eq "new") {
        &dprint("Entered 'set' codeblock\n");
        my $persist_bool;

        if ($opt_netdev) {
            &dprint("Working on network device: $opt_netdev\n");
            foreach my $obj ($objSet->get_list()) {
                my $netobject;
                &dprint("looking for an existing network device name: $opt_netdev\n");
                foreach my $nobj ($obj->get("netdevs")) {
                    &dprint("testing match for: ". $nobj->get("name") ."\n");
                    if ($nobj->get("name") eq $opt_netdev) {
                        &dprint("Using existing netdev object: $nobj\n");
                        $netobject = $nobj;
                        last;
                    }
                }
                if ($opt_devremove) {
                    if ($netobject) {
                        $obj->del("hwaddr", $netobject->get("hwaddr"));
                        $obj->del("netdevs", $netobject);
                        $persist_bool = 1;
                    } else {
                        &wprint("No device named '$opt_netdev' found\n");
                    }
                } else {
                    if (! $netobject) {
                        &dprint("Creating new netdev object\n");
                        $netobject = Warewulf::DSOFactory->new("netdev");
                        $netobject->set("name", $opt_netdev);
                        $obj->add("netdevs", $netobject);
                    }
                    if ($opt_ipaddr) {
                        $netobject->set("ipaddr", $opt_ipaddr);
                        $persist_bool = 1;
                    }
                    if ($opt_netmask) {
                        $netobject->set("netmask", $opt_netmask);
                        $persist_bool = 1;
                    }
                    if ($opt_hwaddr) {
                        $netobject->set("hwaddr", $opt_hwaddr);
                        $obj->add("hwaddr", $opt_hwaddr);
                        $persist_bool = 1;
                    }
                }
            }

            if ($opt_devremove) {
                push(@changes, sprintf("     SET: %-20s = %s\n", $opt_netdev, "REMOVE"));
            } else {
                if ($opt_ipaddr) {
                    push(@changes, sprintf("     SET: %-20s = %s\n", "$opt_netdev.IPADDR", $opt_ipaddr));
                }
                if ($opt_netmask) {
                    push(@changes, sprintf("     SET: %-20s = %s\n", "$opt_netdev.NETMASK", $opt_netmask));
                }
                if ($opt_hwaddr) {
                    push(@changes, sprintf("     SET: %-20s = %s\n", "$opt_netdev.HWADDR", $opt_hwaddr));
                }
            }
        }

        if ($opt_cluster) {
            if (uc($opt_cluster) eq "UNDEF") {
                foreach my $obj ($objSet->get_list()) {
                    my $name = $obj->get("name") || "UNDEF";
                    $obj->del("cluster");
                    &dprint("Deleting cluster for node name: $name\n");
                    $persist_bool = 1;
                }
                push(@changes, sprintf("     SET: %-20s = %s\n", "CLUSTER", "UNDEF"));
            } else {
                foreach my $obj ($objSet->get_list()) {
                    my $name = $obj->get("name") || "UNDEF";
                    $obj->set("cluster", $opt_cluster);
                    &dprint("Setting cluster for node name: $name\n");
                    $persist_bool = 1;
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
                    $persist_bool = 1;
                }
                push(@changes, sprintf("     SET: %-20s = %s\n", "NAME", $opt_name));
            }
        }

        if (@opt_groups) {
            foreach my $obj ($objSet->get_list()) {
                my $name = $obj->get("name") || "UNDEF";
                $obj->set("groups", split(",", join(",", @opt_groups)));
                &dprint("Setting groups for node name: $name\n");
                $persist_bool = 1;
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
                $persist_bool = 1;
            }
        }
        if (@opt_groupdel) {
            foreach my $opt (@opt_groupdel) {
                &dprint("Deleting group $opt from nodes\n");
                foreach my $obj ($objSet->get_list()) {
                    $obj->del("groups", split(",", $opt));
                }
                push(@changes, sprintf("     DEL: %-20s = %s\n", "GROUPS", $opt));
                $persist_bool = 1;
            }
        }

        if (@opt_set) {
            foreach my $setstring (@opt_set) {
                my ($key, @vals) = &quotewords('=', 1, $setstring);
                &dprint("Set: setting $key to ". join("=", @vals) ."\n");
                foreach my $obj ($objSet->get_list()) {
                    #$obj->set($key, &quotewords(',', 0, join("=", @vals)));
                    $obj->set($key, &quotewords(',', 0, @vals));
                }
                push(@changes, sprintf("     SET: %-20s = %s\n", $key, join(",", @vals)));
                $persist_bool = 1;
            }
        }
        if (@opt_add) {
            foreach my $setstring (@opt_add) {
                my ($key, @vals) = &quotewords('=', 1, $setstring);
                foreach my $val (&quotewords(',', 0, join("=", @vals))) {
                    &dprint("Set: adding $key to $val\n");
                    foreach my $obj ($objSet->get_list()) {
                        $obj->add($key, split(",", $val));
                    }
                    push(@changes, sprintf("     ADD: %-20s = %s\n", $key, $opt));
                    $persist_bool = 1;
                }
            }

        }
        if (@opt_del) {
            foreach my $setstring (@opt_del) {
                my ($key, @vals) = &quotewords('=', 1, $setstring);
                if ($key and @vals) {
                    foreach my $val (&quotewords(',', 0, join("=", @vals))) {
                        &dprint("Set: deleting $val from $key\n");
                        foreach my $obj ($objSet->get_list()) {
                            $obj->del($key, split(",", $val));
                        }
                        $persist_bool = 1;
                        push(@changes, sprintf("     DEL: %-20s = %s\n", $key, $opt));
                    }
                } elsif ($key) {
                    &dprint("Set: deleting $key\n");
                    foreach my $obj ($objSet->get_list()) {
                        $obj->del($key);
                    }
                    $persist_bool = 1;
                    push(@changes, sprintf("   UNSET: %-20s\n", $key));
                }
            }
        }

        if ($persist_bool) {
            if ($command ne "new" and $term->interactive()) {
                print "Are you sure you want to make the following changes to ". scalar($objSet->get_list()) ." node(s):\n\n";
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


    } else {
        &eprint("Unknown command: $command\n");
        return;
    }

    # We are done with ARGV, and it was internally modified, so lets reset
    @ARGV = ();

    return($return_count);
}


1;
