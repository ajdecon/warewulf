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
use Warewulf::Node;
use Warewulf::DSO::Node;
use Warewulf::Network;
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
    $h .= "         --domain        Define the domain name of nodes that this node is a part of\n";
    $h .= "         --fqdn          Define the FQDN of this node (if this is passed with the\n";
    $h .= "                         --netdev argument it will assign it to the device specified)\n";
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
    $h .= "     Warewulf> node print --lookup=groups mygroup hello group123\n";
    $h .= "\n";

    return ($h);
}

sub
summary()
{
    my $output;

    $output .= "Node manipulation commands";

    return ($output);
}



sub
complete()
{
    my $self = shift;
    my $opt_lookup = "name";
    my $db = $self->{"DB"};
    my @ret;

    if (! $db) {
        return;
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

    if (exists($ARGV[1]) and ($ARGV[1] eq "print" or $ARGV[1] eq "new" or $ARGV[1] eq "set" or $ARGV[1] eq "list")) {
        @ret = $db->get_lookups($entity_type, $opt_lookup);
    } else {
        @ret = ("print", "new", "set", "delete", "list");
    }

    @ARGV = ();

    return (@ret);
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
    my $opt_domain;
    my $opt_fqdn;
    my @opt_print;
    my @opt_groups;
    my @opt_groupadd;
    my @opt_groupdel;
    my $return_count;
    my $objSet;
    my @changes;
    my $command;
    my $object_count = 0;
    my $persist_count = 0;

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
        'fqdn=s'        => \$opt_fqdn,
        'domain=s'      => \$opt_domain,
        'l|lookup=s'    => \$opt_lookup,

    );

    $command = shift(@ARGV);

    if (! $db) {
        &eprint("Database object not avaialble!\n");
        return;
    }

    if (! $command) {
        &eprint("You must provide a command!\n\n");
        print $self->help();
        return;
    } elsif ($command eq "new") {
        $objSet = Warewulf::ObjectSet->new();
        foreach my $string (&expand_bracket(@ARGV)) {
            my $node;
            $node = Warewulf::Node->new();

            $node->nodename($string);

            $objSet->add($node);

            $persist_count++;

            push(@changes, sprintf("     NEW: %-20s = %s\n", "NODE", $string));
        }
    } else {
        if ($opt_lookup eq "hwaddr") {
            $opt_lookup = "_hwaddr";
        } elsif ($opt_lookup eq "id") {
            $opt_lookup = "_id";
        }
        $objSet = $db->get_objects($opt_type || $entity_type, $opt_lookup, &expand_bracket(@ARGV));
    }

    if ($objSet) {
        $object_count = $objSet->count();
    } else {
        &nprint("No nodes found\n");
        return;
    }

    if ($command eq "delete") {
        if (@ARGV) {
            my $question = "Are you sure you want to delete $object_count node(s):\n\n";

            $question .= join("\n", map { sprintf("     DEL: %-20s = %s", "NODE", $_->name()); } $objSet->get_list());
            $question .= "\n";
            if (! $term->yesno($question, 0, 1)) {
                &nprint("No update performed\n");
                return;
            }
            $db->del_object($objSet);
        } else {
            &eprint("Specify the nodes you wish to delete!\n");
        }
    } elsif ($command eq "list") {
        &nprintf("%-19s %-19s %-19s %-19s\n",
            "NAME",
            "GROUPS",
            "IPADDR",
            "HWADDR"
        );
        &nprint("================================================================================\n");
        foreach my $o ($objSet->get_list()) {
            printf("%-19s %-19s %-19s %-19s\n",
                &ellipsis(19, ($o->name() || "UNDEF"), "end"),
                &ellipsis(19, (join(",", $o->groups()) || "UNDEF")),
                join(",", $o->ipaddr_list()),
                join(",", $o->hwaddr_list())
            );
        }
    } elsif ($command eq "print") {
        foreach my $o ($objSet->get_list()) {
            my $nodename = $o->name() || "UNDEF";

            &nprintf("#### %s %s#\n", $nodename, "#" x (72 - length($nodename)));
            printf("%15s: %-16s = %s\n", $nodename, "ID", ($o->id() || "ERROR"));
            printf("%15s: %-16s = %s\n", $nodename, "NAME", join(",", $o->name()));
            printf("%15s: %-16s = %s\n", $nodename, "NODENAME", ($o->nodename() || "UNDEF"));
            printf("%15s: %-16s = %s\n", $nodename, "CLUSTER", ($o->cluster() || "UNDEF"));
            printf("%15s: %-16s = %s\n", $nodename, "DOMAIN", ($o->domain() || "UNDEF"));
            printf("%15s: %-16s = %s\n", $nodename, "GROUPS", join(",", $o->groups()) || "UNDEF");
            foreach my $devname (sort($o->netdevs_list())) {
                printf("%15s: %-16s = %s\n", $nodename, "$devname.HWADDR", $o->hwaddr($devname) || "UNDEF");
                printf("%15s: %-16s = %s\n", $nodename, "$devname.IPADDR", $o->ipaddr($devname) || "UNDEF");
                printf("%15s: %-16s = %s\n", $nodename, "$devname.NETMASK", $o->netmask($devname) || "UNDEF");
                printf("%15s: %-16s = %s\n", $nodename, "$devname.FQDN", $o->fqdn($devname) || "UNDEF");
            }
        }

    } elsif ($command eq "set" or $command eq "new") {
        &dprint("Entered 'set' codeblock\n");

        if ($opt_netdev) {
            if ($opt_netdev =~ /^([a-z]+\d*)$/) {
                $opt_netdev = $1;
            } else {
                &eprint("Option 'netdev' has invalid characters\n");
                return;
            }
        }


        if ($opt_devremove) {
            foreach my $o ($objSet->get_list()) {
                if (! $opt_netdev) {
                    my @devs = $o->netdevs_list();
                    if (scalar(@devs) == 1) {
                        $opt_netdev = shift(@devs);
                    }
                }
                $o->netdel($opt_netdev);
                $persist_count++;
            }
            push(@changes, sprintf("     DEL: %-20s\n", $opt_netdev));
        } else {
            if ($opt_hwaddr) {
                if ($opt_hwaddr =~ /^((?:[0-9a-f]{2}:){5}[0-9a-f]{2})$/) {
                    my $show_changes;
                    foreach my $o ($objSet->get_list()) {
                        my $nodename = $o->name();
                        if (! $opt_netdev) {
                            my @devs = $o->netdevs_list();
                            if (scalar(@devs) == 1) {
                                $opt_netdev = shift(@devs);
                            } else {
                                &eprint("Option --hwaddr requires the --netdev option for: $nodename\n");
                                next;
                            }
                        }
                        $o->hwaddr($opt_netdev, $1);
                        $persist_count++;
                        $show_changes = 1;
                    }
                    if ($show_changes) {
                        push(@changes, sprintf("     SET: %-20s = %s\n", "$opt_netdev.HWADDR", $opt_hwaddr));
                    }
                } else {
                    &eprint("Option 'hwaddr' has invalid characters\n");
                }
            }
            if ($opt_ipaddr) {
                if ($opt_ipaddr =~ /^(\d+\.\d+\.\d+\.\d+)$/) {
                    my $ip_serialized = Warewulf::Network->ip_serialize($1);
                    my $show_changes;
                    foreach my $o ($objSet->get_list()) {
                        my $nodename = $o->name();
                        if (! $opt_netdev) {
                            my @devs = $o->netdevs_list();
                            if (scalar(@devs) == 1) {
                                $opt_netdev = shift(@devs);
                            } else {
                                &eprint("Option --ipaddr requires the --netdev option for: $nodename\n");
                                next;
                            }
                        }
                        $o->ipaddr($opt_netdev, Warewulf::Network->ip_unserialize($ip_serialized));
                        $ip_serialized++;
                        $persist_count++;
                        $show_changes = 1;
                    }
                    if ($show_changes) {
                        push(@changes, sprintf("     SET: %-20s = %s\n", "$opt_netdev.IPADDR", $opt_ipaddr));
                    }
                } else {
                    &eprint("Option 'ipaddr' has invalid characters\n");
                }
            }
            if ($opt_netmask) {
                if ($opt_netmask =~ /^(\d+\.\d+\.\d+\.\d+)$/) {
                    my $show_changes;
                    foreach my $o ($objSet->get_list()) {
                        my $nodename = $o->name();
                        if (! $opt_netdev) {
                            my @devs = $o->netdevs_list();
                            if (scalar(@devs) == 1) {
                                $opt_netdev = shift(@devs);
                            } else {
                                &eprint("Option --netmask requires the --netdev option for: $nodename\n");
                                next;
                            }
                        }
                        $o->netmask($opt_netdev, $1);
                        $persist_count++;
                        $show_changes = 1;
                    }
                    if ($show_changes) {
                        push(@changes, sprintf("     SET: %-20s = %s\n", "$opt_netdev.NETMASK", $opt_netmask));
                    }
                } else {
                    &eprint("Option 'netmask' has invalid characters\n");
                }
            }
            if ($opt_fqdn) {
                if ($opt_fqdn =~ /^([a-zA-Z0-9\-_\.]+)$/) {
                    my $show_changes;
                    foreach my $o ($objSet->get_list()) {
                        my $nodename = $o->name();
                        if (! $opt_netdev) {
                            my @devs = $o->netdevs_list();
                            if (scalar(@devs) == 1) {
                                $opt_netdev = shift(@devs);
                            } else {
                                &eprint("Option --fqdn requires the --netdev option for: $nodename\n");
                                next;
                            }
                        }
                        $o->fqdn($opt_netdev, $opt_fqdn);
                        $persist_count++;
                        $show_changes = 1;
                    }
                    if ($show_changes) {
                        push(@changes, sprintf("     SET: %-20s = %s\n", "$opt_netdev.FQDN", $opt_fqdn));
                    }
                } else {
                    &eprint("Option 'fqdn' has invalid characters\n");
                }
            }
        }

        if ($opt_name) {
            if (uc($opt_name) eq "UNDEF") {
                &eprint("You must define the name you wish to reference the node as!\n");
            } elsif ($opt_name =~ /^([a-zA-Z0-9\.\-_]+)$/) {
                $opt_name = $1;
                foreach my $obj ($objSet->get_list()) {
                    my $nodename = $obj->get("name") || "UNDEF";
                    $obj->nodename($opt_name);
                    &dprint("Setting new name for node $nodename: $opt_name\n");
                    $persist_count++;
                }
                push(@changes, sprintf("     SET: %-20s = %s\n", "NAME", $opt_name));
            } else {
                &eprint("Option 'name' has invalid characters\n");
            }
        }

        if ($opt_cluster) {
            if (uc($opt_cluster) eq "UNDEF") {
                $opt_cluster = undef;
                foreach my $obj ($objSet->get_list()) {
                    my $nodename = $obj->get("name") || "UNDEF";
                    $obj->cluster($opt_cluster);
                    &dprint("Undefining cluster name for node $nodename\n");
                    $persist_count++;
                }
                push(@changes, sprintf("   UNDEF: %-20s\n", "CLUSTER"));
            } elsif ($opt_cluster =~ /^([a-zA-Z0-9\.\-_]+)$/) {
                $opt_cluster = $1;
                foreach my $obj ($objSet->get_list()) {
                    my $nodename = $obj->get("name") || "UNDEF";
                    $obj->cluster($opt_cluster);
                    &dprint("Setting cluster name for node $nodename: $opt_cluster\n");
                    $persist_count++;
                }
                push(@changes, sprintf("     SET: %-20s = %s\n", "CLUSTER", $opt_cluster));
            } else {
                &eprint("Option 'cluster' has invalid characters\n");
            }
        }

        if ($opt_domain) {
            if (uc($opt_domain) eq "UNDEF") {
                $opt_domain = undef;
                foreach my $obj ($objSet->get_list()) {
                    my $nodename = $obj->get("name") || "UNDEF";
                    $obj->domain($opt_domain);
                    &dprint("Undefining domain name for node $nodename\n");
                    $persist_count++;
                }
                push(@changes, sprintf("   UNDEF: %-20s\n", "CLUSTER"));
            } elsif ($opt_domain =~ /^([a-zA-Z0-9\.\-_]+)$/) {
                $opt_domain = $1;
                foreach my $obj ($objSet->get_list()) {
                    my $nodename = $obj->get("name") || "UNDEF";
                    $obj->domain($opt_domain);
                    &dprint("Setting domain name for node $nodename: $opt_domain\n");
                    $persist_count++;
                }
                push(@changes, sprintf("     SET: %-20s = %s\n", "DOMAIN", $opt_domain));
            } else {
                &eprint("Option 'domain' has invalid characters\n");
            }
        }

        if ($opt_fqdn) {
            if ($opt_fqdn =~ /^([a-zA-Z0-9\.\-_]+)$/) {
                $opt_fqdn = $1;
                foreach my $obj ($objSet->get_list()) {
                    my $nodename = $obj->get("name") || "UNDEF";

                    $obj->fqdn($opt_fqdn);
                    &dprint("Setting FQDN for node $nodename: $opt_fqdn\n");
                    $persist_count++;
                }
                push(@changes, sprintf("     SET: %-20s = %s\n", "FQDN", $opt_fqdn));
            } else {
                &eprint("Option 'fqdn' has invalid characters\n");
            }
        }

        if (@opt_groups) {
            foreach my $obj ($objSet->get_list()) {
                my $nodename = $obj->get("name") || "UNDEF";

                $obj->groups(split(",", join(",", @opt_groups)));
                &dprint("Setting groups for node name: $nodename\n");
                $persist_count++;
            }
            push(@changes, sprintf("     SET: %-20s = %s\n", "GROUPS", join(",", @opt_groups)));
        }

        if (@opt_groupadd) {
            foreach my $obj ($objSet->get_list()) {
                my $nodename = $obj->get("name") || "UNDEF";

                $obj->groupadd(split(",", join(",", @opt_groupadd)));
                &dprint("Setting groups for node name: $nodename\n");
                $persist_count++;
            }
            push(@changes, sprintf("     ADD: %-20s = %s\n", "GROUPS", join(",", @opt_groupadd)));
        }

        if (@opt_groupdel) {
            foreach my $obj ($objSet->get_list()) {
                my $nodename = $obj->get("name") || "UNDEF";

                $obj->groupdel(split(",", join(",", @opt_groupdel)));
                &dprint("Setting groups for node name: $nodename\n");
                $persist_count++;
            }
            push(@changes, sprintf("     DEL: %-20s = %s\n", "GROUPS", join(",", @opt_groupdel)));
        }

        if ($persist_count > 0 or $command eq "new") {
            if ($term->interactive()) {
                my $node_count = $objSet->count();
                my $question;

                $question = sprintf("Are you sure you want to make the following %d change(s) to %d node(s):\n\n",
                                    $persist_count, $node_count);
                $question .= join('', @changes) . "\n";
                if (! $term->yesno($question)) {
                    &nprint("No update performed\n");
                    return;
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

    return $return_count;
}


1;
