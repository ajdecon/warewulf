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
use Warewulf::DSO::Netdev;
use Warewulf::DSO::Node;
use Getopt::Long;
use Text::ParseWords;

our @ISA = ('Warewulf::Module::Cli');

Getopt::Long::Configure ("bundling");

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
options()
{
    my %hash;

    $hash{"-n, --new"} = "Create a new object with the given name";
    $hash{"-p, --print"} = "Define what fields are printed (':all' is a special tag)";
    $hash{"    --DELETE"} = "Delete an entire object";

    return(%hash);
}

sub
description()
{
    my $output;

    $output .= "Hello from nodes.";

    return($output);
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

    Getopt::Long::Configure ("bundling");

    GetOptions(
        'l|lookup=s'    => \$opt_lookup,
    );

    if (exists($ARGV[1]) and ($ARGV[1] eq "print" or $ARGV[1] eq "create" or $ARGV[1] eq "edit")) {
        @ret = $db->get_lookups($entity_type, $opt_lookup);
    } else {
        @ret = ("print", "create", "edit", "delete");
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
    my $opt_new;
    my $opt_obj_delete;
    my $opt_help;
    my $opt_hwaddr;
    my $opt_ipaddr;
    my $opt_netmask;
    my $opt_netdev;
    my $opt_devremove;
    my $opt_bootstrap;
    my $opt_vnfs;
    my $opt_cluster;
    my @opt_set;
    my @opt_add;
    my @opt_del;
    my @opt_print;
    my @opt_groupadd;
    my @opt_groupdel;
    my $return_count;
    my $objSet;
    my @changes;
    my $command;

    @ARGV = ();
    push(@ARGV, @_);

    GetOptions(
        'n|new'         => \$opt_new,
        'p|print=s'     => \@opt_print,
        's|set=s'       => \@opt_set,
        'a|add=s'       => \@opt_add,
        'd|del=s'       => \@opt_del,
        'groupadd=s'    => \@opt_groupadd,
        'groupdel=s'    => \@opt_groupdel,
        'DELETE'        => \$opt_obj_delete,
        'h|help'        => \$opt_help,
        'netdev=s'      => \$opt_netdev,
        'remove'        => \$opt_devremove,
        'hwaddr=s'      => \$opt_hwaddr,
        'ipaddr=s'      => \$opt_ipaddr,
        'netmask=s'     => \$opt_netmask,
        'cluster=s'     => \$opt_cluster,
        'b|bootstrap=s' => \$opt_bootstrap,
        'v|vnfs=s'      => \$opt_vnfs,
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

    if ($command eq "create") {
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

    my $object_count = scalar($objSet->get_list()) || 0;

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
    } elsif ($command eq "print") {
        my @list;
        foreach my $o ($objSet->get_list()) {
            my $limit;
            if ($opt_cluster and $o->get("cluster") eq $opt_cluster) {
                push(@list, $o);
                $limit = 1;
            }
            if ($opt_vnfs and $o->get("vnfs") eq $opt_vnfs) {
                push(@list, $o);
                $limit = 1;
            }
            if (! $limit) {
                push(@list, $o);
            }
        }
        if (@opt_print) {
            @opt_print = split(",", join(",", @opt_print));

            if (scalar(@opt_print) > 1) {
                my $string = sprintf("%-20s " x (scalar @opt_print), map {uc($_);} @opt_print);
                &nprint($string ."\n");
                &nprint("=" x length($string) ."\n");
            }

            foreach my $o (@list) {
                my @values;
                foreach my $g (@opt_print) {
                    if(ref($o->get($g)) =~ /^ARRAY/) {
                        push(@values, join(",", sort $o->get($g)));
                    } else {
                        push(@values, $o->get($g) || "UNDEF");
                    }
                }
                printf("%-20s " x (scalar @values) ."\n", @values);
            }
        } else {
            &nprintf("%-10s %-10s %-15s %-10s %-10s %s\n",
                "NAME",
                "CLUSTER",
                "GROUPS",
                "VNFS",
                "BOOTSTRAP",
                "NETDEVS"
            );
            &nprintf("=" x 92 ."\n");
            foreach my $o (@list) {
                my ($name) = $o->get("name") || "UNDEF";
                my ($cluster) = $o->get("cluster") || "UNDEF";
                my ($bootstrap) = $o->get("bootstrap") || "UNDEF";
                my $groups = join(",", sort $o->get("groups")) || "UNDEF";
                my $vnfs = "UNDEF";
                my @netdevs;
                if (my $vnfsid = $o->get("vnfsid")) {
                    my $vnfsObj = $db->get_objects("vnfs", "id", $o->get("vnfsid"))->get_object(0);
                    $vnfs = $vnfsObj->get("name") || "UNDEF";
                }
                foreach my $n ($o->get("netdevs")) {
                    if (ref($n) =~ /^Warewulf::DSO::/) {
                        my $name = $n->get("name") || "unknown";
                        my $ipaddr = $n->get("ipaddr") || "UNDEF";
                        my $netmask = $n->get("netmask");
                        my $hwaddr = $n->get("hwaddr");
                        if ($netmask) {
                            $netmask = "/$netmask";
                        } else {
                            $netmask = "";
                        }
                        if ($hwaddr) {
                            $hwaddr = "($hwaddr)";
                        } else {
                            $hwaddr = "";
                        }
                        push(@netdevs, "$name$hwaddr:$ipaddr$netmask");
                    }
                }
                printf("%-10s %-10s %-15s %-10s %-10s %s\n",
                    $name,
                    $cluster,
                    $groups,
                    $vnfs,
                    $bootstrap,
                    join(",", @netdevs)
                );
            }
        }

        return();



        if (scalar(@opt_print) > 0) {
            @opt_print = split(",", join(",", @opt_print));
        } else {
            @opt_print = ("name", "cluster", "group", "vnfs", "bootstrap");
        }
        if (@opt_print and scalar @opt_print > 1 and $opt_print[0] ne ":all") {
            my $string = sprintf("%-20s " x (scalar @opt_print), map {uc($_);} @opt_print);
            &nprint($string ."\n");
            &nprint("=" x length($string) ."\n");
        }
        foreach my $o ($objSet->get_list()) {
            my @values;
            if (@opt_print and $opt_print[0] eq ":all") {
                my %hash = $o->get_hash();
                my $id = $o->get("id");
                my $name = $o->get("name");
                &nprintf("#### %s %s#\n", $name, "#" x (72 - length($name)));
                foreach my $h (keys %hash) {
                    if(ref($hash{$h}) =~ /^ARRAY/) {
                        my @scalars;
                        foreach my $e (@{$hash{$h}}) {
                            if (ref($e) =~ /^Warewulf::DSO::([a-zA-Z0-9\-_]+)/) {
                                push(@scalars, lc($1) ."(". ($e->get("name") || "undef") .")");
                            } else {
                                push(@scalars, $e);
                            }
                        }
                        if (scalar(@scalars) > 0) {
                            printf("%8s: %-10s = %s\n", $id, $h, join(",", sort @scalars));
                        }
                    } else {
                        if (ref($e) =~ /^Warewulf::DSO::([a-zA-Z0-9\-_]+)/) {
                            printf("%8s: %-10s = %s\n", $id, $h, lc($1) ."(". ($e->get("name") || "undef") .")");
                        } else {
                            printf("%8s: %-10s = %s\n", $id, $h, $hash{$h});
                        }
                    }
                }
            } else {
                foreach my $g (@opt_print) {
                    if(ref($o->get($g)) =~ /^ARRAY/) {
                        push(@values, join(",", sort $o->get($g)));
                    } else {
                        push(@values, $o->get($g) || "UNDEF");
                    }
                }
                printf("%-20s " x (scalar @values) ."\n", @values);
            }
        }
    } elsif ($command eq "set" or $command eq "edit" or $command eq "create") {
        &dprint("Entered 'set' loop\n");
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
                        $netobject = Warewulf::DSO::Netdev->new();
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
                push(@changes, sprintf("   %10s = %s\n", $opt_netdev, "REMOVE"));
            } else {
                if ($opt_ipaddr) {
                    push(@changes, sprintf("   %10s = %s\n", "$opt_netdev.IPADDR", $opt_ipaddr));
                }
                if ($opt_netmask) {
                    push(@changes, sprintf("   %10s = %s\n", "$opt_netdev.NETMASK", $opt_netmask));
                }
                if ($opt_hwaddr) {
                    push(@changes, sprintf("   %10s = %s\n", "$opt_netdev.HWADDR", $opt_hwaddr));
                }
            }
        }

        if ($opt_bootstrap) {
            if (uc($opt_bootstrap) eq "UNDEF") {
                foreach my $obj ($objSet->get_list()) {
                    my $name = $obj->get("name") || "UNDEF";
                    $obj->del("bootstrap");
                    &dprint("Deleting bootstrap for node name: $name\n");
                    $persist_bool = 1;
                }
                push(@changes, sprintf("   %10s = %s\n", "BOOTSTRAP", "UNDEF"));
            } else {
                foreach my $obj ($objSet->get_list()) {
                    my $name = $obj->get("name") || "UNDEF";
                    $obj->set("bootstrap", $opt_bootstrap);
                    &dprint("Setting bootstrap for node name: $name\n");
                    $persist_bool = 1;
                }
                push(@changes, sprintf("   %10s = %s\n", "BOOTSTRAP", $opt_bootstrap));
            }
        }

        if ($opt_vnfs) {
            if (uc($opt_vnfs) eq "UNDEF") {
                foreach my $obj ($objSet->get_list()) {
                    my $name = $obj->get("name") || "UNDEF";
                    $obj->del("vnfsid");
                    &dprint("Deleting vnfsid for node name: $name\n");
                    $persist_bool = 1;
                }
                push(@changes, sprintf("   %10s = %s\n", "VNFS", "UNDEF"));
            } else {
                my $vnfsObj = $db->get_objects("vnfs", "name", $opt_vnfs)->get_object(0);
                if (my $vnfsid = $vnfsObj->get("id")) {
                    foreach my $obj ($objSet->get_list()) {
                        my $name = $obj->get("name") || "UNDEF";
                        $obj->set("vnfsid", $vnfsid);
                        &dprint("Setting vnfsid for node name: $name\n");
                        $persist_bool = 1;
                    }
                    push(@changes, sprintf("   %10s = %s\n", "VNFS", $opt_vnfs));
                } else {
                    &eprint("No VNFS named: $opt_vnfs\n");
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
                push(@changes, sprintf("   %10s = %s\n", "CLUSTER", "UNDEF"));
            } else {
                foreach my $obj ($objSet->get_list()) {
                    my $name = $obj->get("name") || "UNDEF";
                    $obj->set("cluster", $opt_cluster);
                    &dprint("Setting clusterfor node name: $name\n");
                    $persist_bool = 1;
                }
                push(@changes, sprintf("   %10s = %s\n", "CLUSTER", $opt_cluster));
            }
        }

        if (@opt_groupadd) {
            foreach my $opt (@opt_groupadd) {
                &dprint("Adding group $opt to nodes\n");
                foreach my $obj ($objSet->get_list()) {
                    $obj->add("groups", split(",", $opt));
                }
                push(@changes, sprintf("   %10s += %s\n", "GROUP", $opt));
                $persist_bool = 1;
            }
        }
        if (@opt_groupdel) {
            foreach my $opt (@opt_groupdel) {
                &dprint("Deleting group $opt from nodes\n");
                foreach my $obj ($objSet->get_list()) {
                    $obj->del("groups", split(",", $opt));
                }
                push(@changes, sprintf("   %10s -= %s\n", "GROUP", $opt));
                $persist_bool = 1;
            }
        }


        if (@opt_set) {
            foreach my $setstring (@opt_set) {
                my ($key, @vals) = &quotewords('=', 1, $setstring);
                &dprint("Set: setting $key to ". join("=", @vals) ."\n");
                foreach my $obj ($objSet->get_list()) {
                    $obj->set($key, &quotewords(',', 0, join("=", @vals)));
                }
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
                    }
                } elsif ($key) {
                    &dprint("Set: deleting $key\n");
                    foreach my $obj ($objSet->get_list()) {
                        $obj->del($key);
                    }
                    $persist_bool = 1;
                }
            }
        }

        if ($persist_bool) {
            if ($command ne "create" and $term->interactive()) {
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
