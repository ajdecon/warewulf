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
    $h .= "         set             Modify an existing node configuration\n";
    $h .= "         print           Print the node(s) configuration\n";
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
    $h .= "         --bootstrap     Define the bootstrap image should this node use\n";
    $h .= "         --vnfs          Define the VNFS that this node should use\n";
    $h .= "         --method        What provision method should be used\n";
    $h .= "         --files         Define the files that should be provisioned to this node\n";
    $h .= "         --fileadd       Add a file to be provisioned this node\n";
    $h .= "         --filedel       Remove a file to be provisioned from this node\n";
    $h .= "\n";
    $h .= "EXAMPLES:\n";
    $h .= "\n";
    $h .= "     Warewulf> provision set n000[0-4] --bootstrap=2.6.30-12.x86_64\n";
    $h .= "     Warewulf> provision set n00[00-99] --fileadd=ifcfg-eth0\n";
    $h .= "     Warewulf> provision set -l cluster mycluster --vnfs=rhel-6.0\n";
    $h .= "     Warewulf> provision set -l group mygroup hello group123\n";
    $h .= "     Warewulf> provision print n00[00-99]\n";
    $h .= "\n";

    return($h);
}

sub
summary()
{
    my $output;

    $output .= "Node provision manipulation commands";

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

    if (exists($ARGV[1]) and ($ARGV[1] eq "print" or $ARGV[1] eq "set")) {
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
    my $persist_bool;

    @ARGV = ();
    push(@ARGV, @_);

    Getopt::Long::Configure ("bundling", "nopassthrough");

    GetOptions(
        'files=s'       => \@opt_files,
        'fileadd=s'     => \@opt_fileadd,
        'filedel=s'     => \@opt_filedel,
        'bootstrap=s'   => \$opt_bootstrap,
        'vnfs=s'        => \$opt_vnfs,
        'method=s'      => \$opt_method,
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

    $objSet = $db->get_objects("node", $opt_lookup, &expand_bracket(@ARGV));

    my $object_count = $objSet->count();

    if ($object_count == 0 ) {
        &nprint("No nodes found\n");
        return();
    }


    if ($command eq "set") {
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
                push(@changes, sprintf("     SET: %-20s\n", "BOOTSTRAP"));
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
                    $obj->set("provisionmethod", $opt_method);
                    &dprint("Setting provisionmethod for node name: $name\n");
                    $persist_bool = 1;
                }
                push(@changes, sprintf("     SET: %-20s = %s\n", "PROVISIONMETHOD", $opt_method));
            }
        }

        if (@opt_files) {
            my @file_ids;
            my @file_names;
            foreach my $filename (split(",", join(",", @opt_files))) {
                &dprint("Building file ID's for: $filename\n");
                my @objList = $db->get_objects("file", "name", $filename)->get_list();
                if (@objList) {
                    foreach my $fileObj ($db->get_objects("file", "name", $filename)->get_list()) {
                        if ($fileObj->get("id")) {
                            &dprint("Found ID for $filename: ". $fileObj->get("id") ."\n");
                            push(@file_names, $fileObj->get("name"));
                            push(@file_ids, $fileObj->get("id"));
                        } else {
                            &eprint("No file ID found for: $filename\n");
                        }
                    }
                } else {
                    &eprint("No file found for name: $filename\n");
                }
            }
            if (@file_ids) {
                foreach my $obj ($objSet->get_list()) {
                    my $name = $obj->get("name") || "UNDEF";
                    $obj->set("fileids", @file_ids);
                    &dprint("Setting file IDs for node name: $name\n");
                    $persist_bool = 1;
                }
                push(@changes, sprintf("     SET: %-20s = %s\n", "FILES", join(",", @file_names)));
            }
        }

        if (@opt_fileadd) {
            my @file_ids;
            my @file_names;
            foreach my $filename (split(",", join(",", @opt_fileadd))) {
                &dprint("Building file ID's for: $filename\n");
                my @objList = $db->get_objects("file", "name", $filename)->get_list();
                if (@objList) {
                    foreach my $fileObj ($db->get_objects("file", "name", $filename)->get_list()) {
                        if ($fileObj->get("id")) {
                            &dprint("Found ID for $filename: ". $fileObj->get("id") ."\n");
                            push(@file_names, $fileObj->get("name"));
                            push(@file_ids, $fileObj->get("id"));
                        } else {
                            &eprint("No file ID found for: $filename\n");
                        }
                    }
                } else {
                    &eprint("No file found for name: $filename\n");
                }
            }
            if (@file_ids) {
                foreach my $obj ($objSet->get_list()) {
                    my $name = $obj->get("name") || "UNDEF";
                    $obj->add("fileids", @file_ids);
                    &dprint("Setting file IDs for node name: $name\n");
                    $persist_bool = 1;
                }
                push(@changes, sprintf("     ADD: %-20s = %s\n", "FILES", join(",", @file_names)));
            }
        }

        if (@opt_filedel) {
            my @file_ids;
            my @file_names;
            foreach my $filename (split(",", join(",", @opt_filedel))) {
                &dprint("Building file ID's for: $filename\n");
                my @objList = $db->get_objects("file", "name", $filename)->get_list();
                if (@objList) {
                    foreach my $fileObj ($db->get_objects("file", "name", $filename)->get_list()) {
                        if ($fileObj->get("id")) {
                            &dprint("Found ID for $filename: ". $fileObj->get("id") ."\n");
                            push(@file_names, $fileObj->get("name"));
                            push(@file_ids, $fileObj->get("id"));
                        } else {
                            &eprint("No file ID found for: $filename\n");
                        }
                    }
                } else {
                    &eprint("No file found for name: $filename\n");
                }
            }
            if (@file_ids) {
                foreach my $obj ($objSet->get_list()) {
                    my $name = $obj->get("name") || "UNDEF";
                    $obj->del("fileids", @file_ids);
                    &dprint("Setting file IDs for node name: $name\n");
                    $persist_bool = 1;
                }
                push(@changes, sprintf("     DEL: %-20s = %s\n", "FILES", join(",", @file_names)));
            }
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
    } elsif ($command eq "print") {
        &nprintf("%-15s %-28s %-15s %-15s\n", "NAME", "BOOTSTRAP", "VNFS", "FILES");
        foreach my $o ($objSet->get_list()) {
            my $fileObjSet;
            my @files;
            if ($o->get("fileids")) {
                $fileObjSet = $db->get_objects("file", "id", $o->get("fileids"));
            }
            if ($fileObjSet) {
                foreach my $f ($fileObjSet->get_list()) {
                    push(@files, $f->get("name"));
                }
            } else {
                push(@files, "UNDEF");
            }
            my $vnfs = "UNDEF";
            if (my $vnfsid = $o->get("vnfsid")) {
                my $vnfsObj = $db->get_objects("vnfs", "id", $vnfsid)->get_object(0);
                if ($vnfsObj) {
                    $vnfs = $vnfsObj->get("name");
                }
            }
            printf("%-15s %-28s %-15s %-15s\n",
                $o->get("name") || "UNDEF",
                $o->get("bootstrap") || "UNDEF",
                $vnfs,
                join(",", @files)
            );
        }
    }

    # We are done with ARGV, and it was internally modified, so lets reset
    @ARGV = ();

    return($return_count);
}


1;
