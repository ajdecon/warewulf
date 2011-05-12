#
# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#




package Warewulf::Module::Cli::Provision;

use Warewulf::Logger;
use Warewulf::Module::Cli;
use Warewulf::Term;
use Warewulf::DataStore;
use Warewulf::Util;
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
keyword()
{
    return("provision");
}

sub
help()
{
    my $h;

    $h .= "SUMMARY:\n";
    $h .= "    The provision command is used for setting node provisioning attributes.\n";
    $h .= "\n";
    $h .= "ACTIONS:\n";
    $h .= "\n";
    $h .= "     The first argument MUST be the desired action you wish to take and after\n";
    $h .= "     the action, the order of the options and the targets is not specific.\n";
    $h .= "\n";
    $h .= "         set             Modify existing node provision attributes\n";
    $h .= "         print           Print the node provisioning attributes\n";
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
    $h .= "         --bootstrap     Define the bootstrap image should this node use\n";
    $h .= "         --vnfs          Define the VNFS that this node should use\n";
    $h .= "         --method        What provision method should be used\n";
    $h .= "         --files         Define the files that should be provisioned to this node\n";
    $h .= "         --fileadd       Add a file to be provisioned this node\n";
    $h .= "         --filedel       Remove a file to be provisioned from this node\n";
    $h .= "\n";
    $h .= "EXAMPLES:\n";
    $h .= "\n";
    $h .= "     Warewulf> provision set --lookup=cluster mycluster --vnfs=rhel-6.0\n";
    $h .= "     Warewulf> provision set n000[0-4] --bootstrap=2.6.30-12.x86_64\n";
    $h .= "     Warewulf> provision set --fileadd=ifcfg-eth0 n00[00-99]\n";
    $h .= "     Warewulf> node print --lookup=groups mygroup hello group123\n";
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

    Getopt::Long::Configure ("bundling");

    GetOptions(
        'l|lookup=s'    => \$opt_lookup,
    );

    if (exists($ARGV[1]) and ($ARGV[1] eq "print" or $ARGV[1] eq "new" or $ARGV[1] eq "set")) {
        @ret = $db->get_lookups($entity_type, $opt_lookup);
    } else {
        @ret = ("print", "set");
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
    my $opt_bootstrap;
    my $opt_vnfs;
    my $opt_method;
    my @opt_files;
    my @opt_fileadd;
    my @opt_filedel;
    my $return_count;
    my $objSet;
    my @changes;
    my $command;

    @ARGV = ();
    push(@ARGV, @_);

    GetOptions(
        'l|lookup=s'    => \$opt_lookup,
        'files=s'       => \@opt_files,
        'fileadd=s'     => \@opt_fileadd,
        'filedel=s'     => \@opt_filedel,
        'bootstrap=s'   => \$opt_bootstrap,
        'vnfs=s'        => \$opt_vnfs,
        'method=s'      => \$opt_method,

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

    $objSet = $db->get_objects($opt_type || $entity_type, $opt_lookup, &expand_bracket(@ARGV));

    my $object_count = scalar($objSet->get_list()) || 0;

    if ($object_count == 0 ) {
        &nprint("No nodes found\n");
        return();
    }

    if ($command eq "print") {
        if (scalar(@opt_print) > 0) {
            @opt_print = split(",", join(",", @opt_print));
        } else {
            @opt_print = ("name", "pool", "groups", "hwaddr");
        }
        if (@opt_print and scalar @opt_print > 1 and $opt_print[0] ne ":all") {
            my $string = sprintf("%-17s " x (scalar @opt_print), map {uc($_);} @opt_print);
            &nprint($string ."\n");
            &nprint("=" x length($string) ."\n");
        }
        foreach my $o ($objSet->get_list()) {
            my @values;
            foreach my $h (@opt_print) {
                if (my $val = $o->get($h)) {
                    if(ref($val) =~ /^ARRAY/) {
                        push(@values, join(",", sort @{$val}));
                    } else {
                        push(@values, $val);
                    }
                } else {
                    push(@values, "UNDEF");
                }
            }
            printf("%-17s " x (scalar @values) ."\n", @values);
        }
    } elsif ($command eq "set") {
        &dprint("Entered 'set' codeblock\n");
        my $persist_bool;

        if ($opt_bootstrap) {
            if (uc($opt_bootstrap) eq "UNDEF") {
                foreach my $obj ($objSet->get_list()) {
                    my $name = $obj->get("name") || "UNDEF";
                    $obj->del("bootstrap");
                    &dprint("Deleting bootstrap for node name: $name\n");
                    $persist_bool = 1;
                }
                push(@changes, sprintf("   UNSET: %-20s\n", "BOOTSTRAP"));
            } else {
                foreach my $obj ($objSet->get_list()) {
                    my $name = $obj->get("name") || "UNDEF";
                    $obj->set("bootstrap", $opt_bootstrap);
                    &dprint("Setting bootstrap for node name: $name\n");
                    $persist_bool = 1;
                }
                push(@changes, sprintf("   UNSET: %-20s\n", "BOOTSTRAP"));
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
                push(@changes, sprintf("   UNSET: %-20s\n", "VNFS"));
            } else {
                my $vnfsObj = $db->get_objects("vnfs", "name", $opt_vnfs)->get_object(0);
                if ($vnfsObj and my $vnfsid = $vnfsObj->get("id")) {
                    foreach my $obj ($objSet->get_list()) {
                        my $name = $obj->get("name") || "UNDEF";
                        $obj->set("vnfsid", $vnfsid);
                        &dprint("Setting vnfsid for node name: $name\n");
                        $persist_bool = 1;
                    }
                    push(@changes, sprintf("     SET: %-20s = %s\n", "VNFS", $opt_vnfs));
                } else {
                    &eprint("No VNFS named: $opt_vnfs\n");
                }
            }
        }

        if ($opt_method) {
            if (uc($opt_method) eq "UNDEF") {
                foreach my $obj ($objSet->get_list()) {
                    my $name = $obj->get("name") || "UNDEF";
                    $obj->del("provisionmethod");
                    &dprint("Deleting provisionmethod for node name: $name\n");
                    $persist_bool = 1;
                }
                push(@changes, sprintf("     SET: %-20s = %s\n", "PROVISIONMETHOD", "UNDEF"));
            } else {
                foreach my $obj ($objSet->get_list()) {
                    my $name = $obj->get("name") || "UNDEF";
                    $obj->set("provisionmethod", $opt_pool);
                    &dprint("Setting provisionmethod for node name: $name\n");
                    $persist_bool = 1;
                }
                push(@changes, sprintf("     SET: %-20s = %s\n", "PROVISIONMETHOD", $opt_pool));
            }
        }

        if (@opt_files) {
            foreach my $obj ($objSet->get_list()) {
                my $name = $obj->get("name") || "UNDEF";
                $obj->set("files", split(",", join(",", @opt_files)));
                &dprint("Setting files for node name: $name\n");
                $persist_bool = 1;
            }
            push(@changes, sprintf("     SET: %-20s = %s\n", "FILES", join(",", @opt_files)));
        }

        if (@opt_fileadd) {
            foreach my $opt (@opt_fileadd) {
                &dprint("Adding file $opt to nodes\n");
                foreach my $obj ($objSet->get_list()) {
                    $obj->add("files", split(",", $opt));
                }
                push(@changes, sprintf("     ADD: %-20s = %s\n", "FILES", $opt));
                $persist_bool = 1;
            }
        }
        if (@opt_filedel) {
            foreach my $opt (@opt_filedel) {
                &dprint("Deleting file $opt from nodes\n");
                foreach my $obj ($objSet->get_list()) {
                    $obj->del("files", split(",", $opt));
                }
                push(@changes, sprintf("     DEL: %-20s = %s\n", "FILES", $opt));
                $persist_bool = 1;
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
