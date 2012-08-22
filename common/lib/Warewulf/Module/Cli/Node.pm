#
# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#




package Warewulf::Module::Cli::Node;

use Warewulf::Config;
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
    my $config_defaults = Warewulf::Config->new("defaults/node.conf");
    my $netdev = $config_defaults->get("netdev") || "UNDEF";

    $h .= "USAGE:\n";
    $h .= "     node <command> [options] [targets]\n";
    $h .= "\n";
    $h .= "SUMMARY:\n";
    $h .= "     The node command is used for viewing and manipulating node objects.\n";
    $h .= "\n";
    $h .= "COMMANDS:\n";
    $h .= "         new             Create a new node configuration\n";
    $h .= "         set             Modify an existing node configuration\n";
    $h .= "         list            List a summary of nodes\n";
    $h .= "         print           Print the node configuration\n";
    $h .= "         delete          Remove a node configuration from the data store\n";
    $h .= "         help            Show usage information\n";
    $h .= "\n";
    $h .= "TARGETS:\n";
    $h .= "     The target(s) specify which node(s) will be affected by the chosen\n";
    $h .= "     action(s).  By default, node(s) will be identified by their name(s).\n";
    $h .= "     Use the --lookup option to specify another property (e.g., \"hwaddr\"\n";
    $h .= "     or \"groups\").\n";
    $h .= "\n";
    $h .= "     All targets can be bracket expanded as follows:\n";
    $h .= "\n";
    $h .= "         n00[0-99]       All nodes from n0000 through n0099 (inclusive)\n";
    $h .= "         n00[00,10-99]   n0000 and all nodes from n0010 through n0099\n";
    $h .= "\n";
    $h .= "OPTIONS:\n";
    $h .= "     -l, --lookup        Identify nodes by specified property (default: \"name\")\n";
    $h .= "     -g, --groups        Specify all groups to which this node belongs\n";
    $h .= "         --groupadd      Add node to specified group(s)\n";
    $h .= "         --groupdel      Remove node from specified group(s)\n";
    $h .= "     -D, --netdev        Specify network device to add or modify (defaults: $netdev)\n";
    $h .= "         --netdel        Remove specified netdev from node\n";
    $h .= "     -I, --ipaddr        Set IP address of given netdev\n";
    $h .= "     -M, --netmask       Set subnet mask of given netdev\n";
    $h .= "     -N, --network       Set network address of netdev\n";
    $h .= "     -G, --gateway       Set gateway of given netdev\n";
    $h .= "     -H, --hwaddr        Set hardware/MAC address\n";
    $h .= "     -f, --fqdn          Set FQDN of given netdev\n";
    $h .= "     -c, --cluster       Specify cluster name for this node\n";
    $h .= "     -d, --domain        Specify domain name for this node\n";
    $h .= "     -n, --name          Specify new name for this node\n";
    $h .= "\n";
    $h .= "EXAMPLES:\n";
    $h .= "     Warewulf> node new n0000 --netdev=eth0 --hwaddr=xx:xx:xx:xx:xx:xx\n";
    $h .= "     Warewulf> node set n0000 -D eth0 -I 10.0.0.10 -G 10.0.0.1\n";
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
    my $config_defaults = Warewulf::Config->new("defaults/node.conf");
    my $opt_netdev = $config_defaults->get("netdev");
    my $opt_lookup = "name";
    my $opt_hwaddr;
    my $opt_ipaddr;
    my $opt_netmask;
    my $opt_network;
    my $opt_gateway;
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
        'g|groups=s'    => \@opt_groups,
        'groupadd=s'    => \@opt_groupadd,
        'groupdel=s'    => \@opt_groupdel,
        'D|netdev=s'    => \$opt_netdev,
        'netdel'        => \$opt_devremove,
        'H|hwaddr=s'    => \$opt_hwaddr,
        'I|ipaddr=s'    => \$opt_ipaddr,
        'N|network=s'   => \$opt_network,
        'G|gateway=s'   => \$opt_gateway,
        'M|netmask=s'   => \$opt_netmask,
        'c|cluster=s'   => \$opt_cluster,
        'n|name=s'      => \$opt_name,
        'f|fqdn=s'      => \$opt_fqdn,
        'd|domain=s'    => \$opt_domain,
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

            if ($string =~ /^([a-zA-Z0-9\-_]+)$/) {
                my $nodename = $1;
                $node = Warewulf::Node->new();
                $node->nodename($nodename);
                $objSet->add($node);
                $persist_count++;
                push(@changes, sprintf("%8s: %-20s = %s\n", "NEW", "NODE", $nodename));
            } else {
                &eprint("Nodename '$string' contains invalid characters\n");                
            }
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
    }
    if (! $objSet || ($object_count == 0)) {
        &nprint("No nodes found\n");
        return;
    }

    if ($command eq "delete") {
        my @changes;

        @changes = map { sprintf("%8s: %s %s", "DEL", "NODE", $_->name()); } $objSet->get_list();
        if ($self->confirm_changes($term, $object_count, "node(s)", @changes)) {
            $return_count = $db->del_object($objSet);
            &nprint("Deleted $return_count nodes.\n");
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
                printf("%15s: %-16s = %s\n", $nodename, "$devname.NETWORK", $o->network($devname) || "UNDEF");
                printf("%15s: %-16s = %s\n", $nodename, "$devname.GATEWAY", $o->gateway($devname) || "UNDEF");
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
            push(@changes, sprintf("%8s: %-20s\n", "DEL", $opt_netdev));
        } else {
            if ($opt_hwaddr) {
                $opt_hwaddr = lc($opt_hwaddr);
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
                                return;
                            }
                        }
                        $o->hwaddr($opt_netdev, $1);
                        $persist_count++;
                        $show_changes = 1;
                    }
                    if ($show_changes) {
                        push(@changes, sprintf("%8s: %-20s = %s\n", "SET", "$opt_netdev.HWADDR", $opt_hwaddr));
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
                                return;
                            }
                        }
                        $o->ipaddr($opt_netdev, Warewulf::Network->ip_unserialize($ip_serialized));
                        $ip_serialized++;
                        $persist_count++;
                        $show_changes = 1;
                    }
                    if ($show_changes) {
                        push(@changes, sprintf("%8s: %-20s = %s\n", "SET", "$opt_netdev.IPADDR", $opt_ipaddr));
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
                                return;
                            }
                        }
                        $o->netmask($opt_netdev, $1);
                        $persist_count++;
                        $show_changes = 1;
                    }
                    if ($show_changes) {
                        push(@changes, sprintf("%8s: %-20s = %s\n", "SET", "$opt_netdev.NETMASK", $opt_netmask));
                    }
                } else {
                    &eprint("Option 'netmask' has invalid characters\n");
                }
            }



            if ($opt_network) {
                if ($opt_network =~ /^(\d+\.\d+\.\d+\.\d+)$/) {
                    my $show_changes;
                    foreach my $o ($objSet->get_list()) {
                        my $nodename = $o->name();
                        if (! $opt_netdev) {
                            my @devs = $o->netdevs_list();
                            if (scalar(@devs) == 1) {
                                $opt_netdev = shift(@devs);
                            } else {
                                &eprint("Option --network requires the --netdev option for: $nodename\n");
                                return;
                            }
                        }
                        $o->network($opt_netdev, $1);
                        $persist_count++;
                        $show_changes = 1;
                    }
                    if ($show_changes) {
                        push(@changes, sprintf("%8s: %-20s = %s\n", "SET", "$opt_netdev.NETWORK", $opt_network));
                    }
                } else {
                    &eprint("Option 'network' has invalid characters\n");
                }
            }
            if ($opt_gateway) {
                if ($opt_gateway =~ /^(\d+\.\d+\.\d+\.\d+)$/) {
                    my $show_changes;
                    foreach my $o ($objSet->get_list()) {
                        my $nodename = $o->name();
                        if (! $opt_netdev) {
                            my @devs = $o->netdevs_list();
                            if (scalar(@devs) == 1) {
                                $opt_netdev = shift(@devs);
                            } else {
                                &eprint("Option --gateway requires the --netdev option for: $nodename\n");
                                return;
                            }
                        }
                        $o->gateway($opt_netdev, $1);
                        $persist_count++;
                        $show_changes = 1;
                    }
                    if ($show_changes) {
                        push(@changes, sprintf("%8s: %-20s = %s\n", "SET", "$opt_netdev.GATEWAY", $opt_gateway));
                    }
                } else {
                    &eprint("Option 'gateway' has invalid characters\n");
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
                                return;
                            }
                        }
                        $o->fqdn($opt_netdev, $opt_fqdn);
                        $persist_count++;
                        $show_changes = 1;
                    }
                    if ($show_changes) {
                        push(@changes, sprintf("%8s: %-20s = %s\n", "SET", "$opt_netdev.FQDN", $opt_fqdn));
                    }
                } else {
                    &eprint("Option 'fqdn' has invalid characters\n");
                }
            }
        }

        if ($opt_name) {
            if (uc($opt_name) eq "UNDEF") {
                &eprint("You must define the name you wish to reference the node as!\n");
            } elsif ($opt_name =~ /^([a-zA-Z0-9\-_]+)$/) {
                $opt_name = $1;
                foreach my $obj ($objSet->get_list()) {
                    my $nodename = $obj->get("name") || "UNDEF";
                    $obj->nodename($opt_name);
                    &dprint("Setting new name for node $nodename: $opt_name\n");
                    $persist_count++;
                }
                push(@changes, sprintf("%8s: %-20s = %s\n", "SET", "NAME", $opt_name));
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
                push(@changes, sprintf("%8s: %-20s\n", "UNDEF", "CLUSTER"));
            } elsif ($opt_cluster =~ /^([a-zA-Z0-9\.\-_]+)$/) {
                $opt_cluster = $1;
                foreach my $obj ($objSet->get_list()) {
                    my $nodename = $obj->get("name") || "UNDEF";
                    $obj->cluster($opt_cluster);
                    &dprint("Setting cluster name for node $nodename: $opt_cluster\n");
                    $persist_count++;
                }
                push(@changes, sprintf("%8s: %-20s = %s\n", "SET", "CLUSTER", $opt_cluster));
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
                push(@changes, sprintf("%8s: %-20s\n", "UNDEF", "DOMAIN"));
            } elsif ($opt_domain =~ /^([a-zA-Z0-9\.\-_]+)$/) {
                $opt_domain = $1;
                foreach my $obj ($objSet->get_list()) {
                    my $nodename = $obj->get("name") || "UNDEF";
                    $obj->domain($opt_domain);
                    &dprint("Setting domain name for node $nodename: $opt_domain\n");
                    $persist_count++;
                }
                push(@changes, sprintf("%8s: %-20s = %s\n", "SET", "DOMAIN", $opt_domain));
            } else {
                &eprint("Option 'domain' has invalid characters\n");
            }
        }

        if (@opt_groups) {
            foreach my $obj ($objSet->get_list()) {
                my $nodename = $obj->get("name") || "UNDEF";

                $obj->groups(split(",", join(",", @opt_groups)));
                &dprint("Setting groups for node name: $nodename\n");
                $persist_count++;
            }
            push(@changes, sprintf("%8s: %-20s = %s\n", "SET", "GROUPS", join(",", @opt_groups)));
        }

        if (@opt_groupadd) {
            foreach my $obj ($objSet->get_list()) {
                my $nodename = $obj->get("name") || "UNDEF";

                $obj->groupadd(split(",", join(",", @opt_groupadd)));
                &dprint("Setting groups for node name: $nodename\n");
                $persist_count++;
            }
            push(@changes, sprintf("%8s: %-20s = %s\n", "ADD", "GROUPS", join(",", @opt_groupadd)));
        }

        if (@opt_groupdel) {
            foreach my $obj ($objSet->get_list()) {
                my $nodename = $obj->get("name") || "UNDEF";

                $obj->groupdel(split(",", join(",", @opt_groupdel)));
                &dprint("Setting groups for node name: $nodename\n");
                $persist_count++;
            }
            push(@changes, sprintf("%8s: %-20s = %s\n", "DEL", "GROUPS", join(",", @opt_groupdel)));
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
