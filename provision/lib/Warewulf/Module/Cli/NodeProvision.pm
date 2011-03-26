#
# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#




package Warewulf::Module::Cli::NodeProvision;

use Warewulf::Logger;
use Warewulf::Module::Cli;
use Warewulf::Term;
use Warewulf::DataStore;
use Warewulf::Util;
use Warewulf::DSO::Node;
use Getopt::Long;

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
keyword()
{
    return("node");
}


sub
options()
{
    my %hash;

    $hash{"-b, --bootstrap"} = "Bootstrap image to be used";
    $hash{"-v, --vnfs"} = "VNFS image that this node should use for booting";
    $hash{"-h, --hwaddr"} = "What is the hardware (MAC) addresses for this node";
    $hash{"-i, --ipaddr"} = "Define the IP address that this node should use";
    $hash{"-k, --kernelargs"} = "What kernel arguments should be used for booting";
    $hash{"-f, --files"} = "Comma delim list of WW file names that this node should use";
    $hash{"-d, --debug"} = "Debug level during provision";
    $hash{"-p, --provision"} = "Provision mechanism to use (default is 'tmpfs')";

    return(%hash);
}

sub
description()
{
    my $output;

    $output .= "Add features to the node object relevent for provisioning.";

    return($output);
}

sub
summary()
{
    my $output;

    $output .= "Features for node provisioning.";

    return($output);
}



sub
complete()
{
    my ($self, $text) = @_;
    my $db = $self->{"DB"};

    return();
}

sub
exec()
{
    my $self = shift;
    my $db = $self->{"DB"};
    my $term = Warewulf::Term->new();
    my $opt_bootstrap;
    my $opt_vnfs;
    my $opt_lookup = "name";

    @ARGV = ();
    push(@ARGV, @_);

    GetOptions(
        'b|bootstrap=s' => \$opt_bootstrap,
        'v|vnfs=s'      => \$opt_vnfs,
        'l|lookup=s'    => \$opt_lookup,
    );

    if (! $db) {
        &eprint("Database object not avaialble!\n");
        return();
    }

    $objectSet = $db->get_objects($entity_type, $opt_lookup, &expand_bracket(@ARGV));
    my @objList = $objectSet->get_list();

    if (@objList) {
        my $persist_bool;
        my @changes;
        if ($opt_bootstrap) {
            foreach my $obj (@objList) {
                my $name = $obj->get("name") || "UNDEF";
                $obj->set("bootstrap", $opt_bootstrap);
                &dprint("Setting bootstrap for node name: $name\n");
                $persist_bool = 1;
            }
            push(@changes, sprintf("   %10s = %s\n", "BOOTSTRAP", $opt_bootstrap));
        }
        if ($opt_vnfs) {
            foreach my $obj (@objList) {
                my $name = $obj->get("name") || "UNDEF";
                $obj->set("vnfs", $opt_vnfs);
                &dprint("Setting vnfs for node name: $name\n");
                $persist_bool = 1;
            }
            push(@changes, sprintf("   %10s = %s\n", "VNFS", $opt_vnfs));
        }
        if ($persist_bool) {
            &nprint("\n");
            &nprint("Making the following changes to ". scalar(@objList) ." node(s):\n\n");
            foreach my $change (@changes) {
                &nprint($change);
            }
            $db->persist(@objList);
            &nprint("\n");
        }
    }

    # We are done with ARGV, and it was internally modified, so lets reset
    @ARGV = ();

    return($return_count);
}


1;
