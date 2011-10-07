#
# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#




package Warewulf::Module::Cli::Ipmi;

use Warewulf::Logger;
use Warewulf::Module::Cli;
use Warewulf::Term;
use Warewulf::DataStore;
use Warewulf::Util;
use Warewulf::Network;
use Warewulf::ParallelCmd;
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
keyword()
{
    return("ipmi");
}

sub
help()
{
    my $h;

    $h .= "USAGE:\n";
    $h .= "     ipmi [command] [options] [targets]\n";
    $h .= "\n";
    $h .= "SUMMARY:\n";
    $h .= "    The ipmi command is used for setting node ipmi configuration attributes.\n";
    $h .= "\n";
    $h .= "COMMANDS:\n";
    $h .= "\n";
    $h .= "     The first argument MUST be the desired action you wish to take and after\n";
    $h .= "     the action, the order of the options and the targets is not specific.\n";
    $h .= "\n";
    $h .= "         set             Modify an existing node configuration\n";
    $h .= "         list            List a summary of the node(s) ipmi configuration\n";
    $h .= "         print           Print the full node(s) ipmi configuration\n";
    $h .= "         poweron         Power on the list of nodes\n";
    $h .= "         poweroff        Power off the list of nodes\n";
    $h .= "         powercycle      Power cycle the list of nodes\n";
    $h .= "         powerstatus     Print the power status of the nodes\n";
    $h .= "         help            Show usage information\n";
    $h .= "\n";
    $h .= "TARGETS:\n";
    $h .= "\n";
    $h .= "     The target is the specification for the node you wish to act on. All targets\n";
    $h .= "     can be bracket expanded as follows:\n";
    $h .= "\n";
    $h .= "         n00[0-99]       inclusively all nodes from n0000 to n0099\n";
    $h .= "         n00[00,10-99]   n0000 and inclusively all nodes from n0010 to n0099\n";
    $h .= "\n";
    $h .= "OPTIONS:\n";
    $h .= "\n";
    $h .= "     -l, --lookup        How should we reference this node? (default is name)\n";
    $h .= "         --ipaddr        The IPMI accessible IP address for this node. If multiple\n";
    $h .= "                         nodes are given, this IP address will be incremented for\n";
    $h .= "                         each node given\n";
    $h .= "         --netmask       The netmask defined for this node\n";
    $h .= "         --username      Define the IPMI username for this node\n";
    $h .= "         --password      Define the IPMI password for this node\n";
    $h .= "         --autoconfig    Automatically try and configure this node's IPMI settings\n";
    $h .= "                         on boot (if no password is set for the node, one will be\n";
    $h .= "                         randomly generated)\n";
    $h .= "         --noautoconfig  Remove the autoconfig flag so the node doesn't get configured\n";
    $h .= "                         automatically\n";
    $h .= "\n";
    $h .= "EXAMPLES:\n";
    $h .= "\n";
    $h .= "     Warewulf> ipmi set n000[0-4] --ipaddr=10.100.0.1 --netmask=255.255.255.0\n";
    $h .= "\n";

    return($h);
}

sub
summary()
{
    my $output;

    $output .= "Node IPMI configuration";

    return($output);
}


sub
complete()
{
    my $self = shift;
    my $db = $self->{"DB"};
    my $opt_lookup = "name";
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

    if (exists($ARGV[1])) {
        @ret = $db->get_lookups($entity_type, $opt_lookup);
    } else {
        @ret = ("list", "set", "print", "help", "poweron", "poweroff");
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
    my $opt_ipaddr;
    my $opt_netmask;
    my $opt_username;
    my $opt_password;
    my $opt_autoconfig;
    my $opt_noautoconfig;
    my $return_count;
    my $objSet;
    my @changes;
    my $command;
    my $persist_bool;
    my $object_count;

    @ARGV = ();
    push(@ARGV, @_);

    Getopt::Long::Configure ("bundling", "nopassthrough");

    GetOptions(
        'ipaddr=s'      => \$opt_ipaddr,
        'netmask=s'     => \$opt_netmask,
        'username=s'    => \$opt_username,
        'password=s'    => \$opt_password,
        'autoconfig'    => \$opt_autoconfig,
        'noautoconfig'  => \$opt_noautoconfig,
        'l|lookup=s'    => \$opt_lookup,
    );

    $command = shift(@ARGV);

    if (! $db) {
        &eprint("Database object not avaialble!\n");
        return();
    }

    $objSet = $db->get_objects("node", $opt_lookup, &expand_bracket(@ARGV));
    $object_count = $objSet->count();

    if ($object_count eq 0) {
        &nprint("No nodes found\n");
        return();
    }


    if (! $command) {
        &eprint("You must provide a command!\n\n");
        print $self->help();
    } elsif ($command eq "set") {
        if ($opt_ipaddr) {
            if (uc($opt_ipaddr) eq "UNDEF") {
                foreach my $obj ($objSet->get_list()) {
                    my $name = $obj->get("name") || "UNDEF";
                    $obj->del("ipmi_ipaddr");
                    &dprint("Deleting IPMI IP address for node name: $name\n");
                    $persist_bool = 1;
                }
                push(@changes, sprintf("   UNSET: %-20s\n", "IPMI_IPADDR"));
            } else {
                my $n = Warewulf::Network->new();
                my $ip_serialized = $n->ip_serialize($opt_ipaddr);
                foreach my $obj ($objSet->get_list()) {
                    my $name = $obj->get("name") || "UNDEF";
                    my $ip = $n->ip_unserialize($ip_serialized);
                    $obj->set("ipmi_ipaddr", $ip);
                    &dprint("Setting IPMI IP address for node name: $name\n");
                    $persist_bool = 1;
                    push(@changes, sprintf("     SET: %-20s = %s\n", "IPMI_IPADDR($name)", $ip));
                    $ip_serialized ++;
                }
            }
        }
        if ($opt_netmask) {
            if (uc($opt_netmask) eq "UNDEF") {
                foreach my $obj ($objSet->get_list()) {
                    my $name = $obj->get("name") || "UNDEF";
                    $obj->del("ipmi_netmask");
                    &dprint("Deleting IPMI netmask for node name: $name\n");
                    $persist_bool = 1;
                }
                push(@changes, sprintf("   UNSET: %-20s\n", "IPMI_NETMASK"));
            } else {
                foreach my $obj ($objSet->get_list()) {
                    my $name = $obj->get("name") || "UNDEF";
                    $obj->set("ipmi_netmask", $opt_netmask);
                    &dprint("Setting IPMI netmask for node name: $name\n");
                    $persist_bool = 1;
                }
                push(@changes, sprintf("     SET: %-20s = %s\n", "IPMI_NETMASK", $opt_netmask));
            }
        }
        if ($opt_username) {
            if (uc($opt_username) eq "UNDEF") {
                foreach my $obj ($objSet->get_list()) {
                    my $name = $obj->get("name") || "UNDEF";
                    $obj->del("ipmi_username");
                    &dprint("Deleting IPMI username for node name: $name\n");
                    $persist_bool = 1;
                }
                push(@changes, sprintf("   UNSET: %-20s\n", "IPMI_USERNAME"));
            } else {
                foreach my $obj ($objSet->get_list()) {
                    my $name = $obj->get("name") || "UNDEF";
                    $obj->set("ipmi_username", $opt_username);
                    &dprint("Setting IPMI username for node name: $name\n");
                    $persist_bool = 1;
                }
                push(@changes, sprintf("     SET: %-20s = %s\n", "IPMI_USERNAME", $opt_username));
            }
        }
        if ($opt_password) {
            if (uc($opt_password) eq "UNDEF") {
                foreach my $obj ($objSet->get_list()) {
                    my $name = $obj->get("name") || "UNDEF";
                    $obj->del("ipmi_password");
                    &dprint("Deleting IPMI password for node name: $name\n");
                    $persist_bool = 1;
                }
                push(@changes, sprintf("   UNSET: %-20s\n", "IPMI_PASSWORD"));
            } else {
                foreach my $obj ($objSet->get_list()) {
                    my $name = $obj->get("name") || "UNDEF";
                    $obj->set("ipmi_password", $opt_password);
                    &dprint("Setting IPMI password for node name: $name\n");
                    $persist_bool = 1;
                }
                push(@changes, sprintf("     SET: %-20s = %s\n", "IPMI_PASSWORD", $opt_password));
            }
        }

        if ($opt_autoconfig) {
            foreach my $obj ($objSet->get_list()) {
                my $name = $obj->get("name") || "UNDEF";
                $obj->set("ipmi_autoconfig", "1");
                &dprint("Setting the IPMI auto configure tag for node name: $name\n");
                if (! $obj->get("ipmi_username")) {
                    $obj->set("ipmi_username", "wwadmin");
                }
                if (! $obj->get("ipmi_password")) {
                    $obj->set("ipmi_password", &rand_string("8"));
                }
                $persist_bool = 1;
            }
            push(@changes, sprintf("     SET: %-20s\n", "IPMI_AUTOCONFIG"));
        }
        if ($opt_noautoconfig) {
            foreach my $obj ($objSet->get_list()) {
                my $name = $obj->get("name") || "UNDEF";
                $obj->del("ipmi_autoconfig");
                &dprint("Deleting the IPMI auto configure tag for node name: $name\n");
                $persist_bool = 1;
            }
            push(@changes, sprintf("   UNSET: %-20s\n", "IPMI_AUTOCONFIGURE"));
        }

        if ($persist_bool) {
            if ($command ne "new" and $term->interactive()) {
                print "Are you sure you want to make the following changes to ". $object_count ." node(s):\n\n";
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

    } elsif ($command eq "poweron") {
        my $pcmd = Warewulf::ParallelCmd->new();
        $pcmd->fanout(4);
        foreach my $o ($objSet->get_list()) {
            my $name = $o->get("name") || "UNDEF";
            if (my ($cluster) = $o->get("cluster")) {
               $name .= ".$cluster";
            }
            if (my $ipaddr = $o->get("ipmi_ipaddr") and my $username = $o->get("ipmi_username") and my $password = $o->get("ipmi_password")) {
                &dprint("Sending IPMI command to $name: chassis power on\n");
                $pcmd->queue("echo -n '$name: '; ipmitool -I lan -U $username -P $password -H $ipaddr chassis power on");
            } else {
                &iprint("Skipping poweron for unconfigured node $name\n");
            }
        }
        $pcmd->run();
    } elsif ($command eq "powercycle") {
        my $pcmd = Warewulf::ParallelCmd->new();
        $pcmd->fanout(4);
        foreach my $o ($objSet->get_list()) {
            my $name = $o->get("name") || "UNDEF";
            if (my ($cluster) = $o->get("cluster")) {
               $name .= ".$cluster";
            }
            if (my $ipaddr = $o->get("ipmi_ipaddr") and my $username = $o->get("ipmi_username") and my $password = $o->get("ipmi_password")) {
                &dprint("Sending IPMI command to $name: chassis power cycle\n");
                $pcmd->queue("echo -n '$name: '; ipmitool -I lan -U $username -P $password -H $ipaddr chassis power cycle");
            } else {
                &iprint("Skipping powercycle for unconfigured node $name\n");
            }
        }
        $pcmd->run();
    } elsif ($command eq "poweroff") {
        my $pcmd = Warewulf::ParallelCmd->new();
        foreach my $o ($objSet->get_list()) {
            my $name = $o->get("name") || "UNDEF";
            if (my ($cluster) = $o->get("cluster")) {
               $name .= ".$cluster";
            }
            if (my $ipaddr = $o->get("ipmi_ipaddr") and my $username = $o->get("ipmi_username") and my $password = $o->get("ipmi_password")) {
                &dprint("Sending IPMI command to $name: chassis power off\n");
                $pcmd->queue("echo -n '$name: '; ipmitool -I lan -U $username -P $password -H $ipaddr chassis power off");
            } else {
                &iprint("Skipping poweroff for unconfigured node $name\n");
            }
        }
        $pcmd->run();
    } elsif ($command eq "powerstatus") {
        my $pcmd = Warewulf::ParallelCmd->new();
        foreach my $o ($objSet->get_list()) {
            my $name = $o->get("name") || "UNDEF";
            if (my ($cluster) = $o->get("cluster")) {
               $name .= ".$cluster";
            }
            if (my $ipaddr = $o->get("ipmi_ipaddr") and my $username = $o->get("ipmi_username") and my $password = $o->get("ipmi_password")) {
                &dprint("Sending IPMI command to $name: chassis power status\n");
                $pcmd->queue("echo -n '$name: '; ipmitool -I lan -U $username -P $password -H $ipaddr chassis power status");
            } else {
                &iprint("Skipping powerstatus for unconfigured node $name\n");
            }
        }
        $pcmd->run();
    } elsif ($command eq "print") {
        foreach my $o ($objSet->get_list()) {
            my $name = $o->get("name") || "UNDEF";
            if (my ($cluster) = $o->get("cluster")) {
               $name .= ".$cluster";
            }
            &nprintf("#### %s %s#\n", $name, "#" x (72 - length($name)));
            printf("%15s: %-16s = %s\n", $name, "IPMI_IPADDR", $o->get("ipmi_ipaddr") || "UNDEF");
            printf("%15s: %-16s = %s\n", $name, "IPMI_NETMASK", $o->get("ipmi_netmask") || "UNDEF");
            printf("%15s: %-16s = %s\n", $name, "IPMI_USERNAME", $o->get("ipmi_username") || "UNDEF");
            printf("%15s: %-16s = %s\n", $name, "IPMI_PASSWORD", $o->get("ipmi_password") || "UNDEF");
            printf("%15s: %-16s = %s\n", $name, "IPMI_AUTOCONFIG", $o->get("ipmi_autoconfig") || "UNDEF");
        }

    } elsif ($command eq "list") {
        &nprintf("%-19s %-4s    %-14s %-14s\n", "NAME(.CLUSTER)", "AUTO", "IPMI_IPADDR", "IPMI_NETMASK");
        &nprint("================================================================================\n");
        foreach my $o ($objSet->get_list()) {
            my $name = $o->get("name") || "UNDEF";
            if (my ($cluster) = $o->get("cluster")) {
               $name .= ".$cluster";
            }
            printf("%-19s %-4s    %-14s %-14s\n",
                &ellipsis(19, $name, "end"),
                ($o->get("ipmi_autoconfig") ? "yes" : "no"),
                $o->get("ipmi_ipaddr") || "UNDEF",
                $o->get("ipmi_netmask") || "UNDEF"
            );
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
