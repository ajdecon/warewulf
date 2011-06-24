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

    $h .= "USAGE:\n";
    $h .= "     provision [command] [options] [targets]\n";
    $h .= "\n";
    $h .= "SUMMARY:\n";
    $h .= "    The provision command is used for setting node provisioning attributes.\n";
    $h .= "\n";
    $h .= "COMMANDS:\n";
    $h .= "\n";
    $h .= "     The first argument MUST be the desired action you wish to take and after\n";
    $h .= "     the action, the order of the options and the targets is not specific.\n";
    $h .= "\n";
    $h .= "         set             Modify an existing node configuration\n";
    $h .= "         list            List a summary of the node(s) configuration\n";
    $h .= "         status          Print the node(s) provisioning status\n";
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
    $h .= "         --bootstrap     Define the bootstrap image should this node use\n";
    $h .= "         --master        What master(s) should respond to this node?\n";
    $h .= "         --vnfs          Define the VNFS that this node should use\n";
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
    $h .= "     Warewulf> provision list n00[00-99]\n";
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

    if (exists($ARGV[1]) and ($ARGV[1] eq "print" or $ARGV[1] eq "set" or $ARGV[1] eq "status")) {
        @ret = $db->get_lookups($entity_type, $opt_lookup);
    } else {
        @ret = ("list", "set", "status");
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
    my @opt_master;
    my @opt_files;
    my @opt_fileadd;
    my @opt_filedel;
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
        'files=s'       => \@opt_files,
        'fileadd=s'     => \@opt_fileadd,
        'filedel=s'     => \@opt_filedel,
        'master=s'      => \@opt_master,
        'bootstrap=s'   => \$opt_bootstrap,
        'vnfs=s'        => \$opt_vnfs,
        'l|lookup=s'    => \$opt_lookup,
    );

    $command = shift(@ARGV);

    if (! $db) {
        &eprint("Database object not avaialble!\n");
        return();
    }

    $objSet = $db->get_objects("node", $opt_lookup, &expand_bracket(@ARGV));

    if ($objSet) {
        $object_count = $objSet->count();
    } else {
        &nprint("No nodes found\n");
        return();
    }


    if (! $command) {
        &eprint("You must provide a command!\n\n");
        print $self->help();
    } elsif ($command eq "set") {
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
                my $bootstrapObj = $db->get_objects("bootstrap", "name", $opt_bootstrap)->get_object(0);
                if ($bootstrapObj and my $bootstrapid = $bootstrapObj->get("_id")) {
                    foreach my $obj ($objSet->get_list()) {
                        my $name = $obj->get("name") || "UNDEF";
                        $obj->set("bootstrapid", $bootstrapid);
                        &dprint("Setting bootstrapid for node name: $name\n");
                        $persist_bool = 1;
                    }
                    push(@changes, sprintf("     SET: %-20s = %s\n", "BOOTSTRAP", $opt_bootstrap));
                } else {
                    &eprint("No bootstrap named: $opt_vnfs\n");
                }
            }
        }

        if (@opt_master) {
            if (exists($opt_master[0]) and $opt_master[0] eq "UNDEF") {
                foreach my $obj ($objSet->get_list()) {
                    my $name = $obj->get("name") || "UNDEF";
                    $obj->del("master");
                    &dprint("Deleting master entries for node name: $name\n");
                    $persist_bool = 1;
                }
                push(@changes, sprintf("   UNSET: %-20s\n", "MASTER"));
            } else {
                my @set_masters;
                foreach my $master (split(",", join(",", @opt_master))) {
                    if ($master =~ /^(\d+\.\d+\.\d+\.\d+)$/) {
                        push(@set_masters, $1);
                        push(@changes, sprintf("     SET: %-20s = %s\n", "MASTER", $1));
                    } else {
                        &eprint("Bad format for IP address: $master\n");
                    }
                }
                foreach my $obj ($objSet->get_list()) {
                    my $name = $obj->get("name") || "UNDEF";
                    $obj->set("master", @set_masters);
                    &dprint("Setting master for node name: $name\n");
                    $persist_bool = 1;
                }
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
                if ($vnfsObj and my $vnfsid = $vnfsObj->get("_id")) {
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

        if (@opt_files) {
            my @file_ids;
            my @file_names;
            foreach my $filename (split(",", join(",", @opt_files))) {
                &dprint("Building file ID's for: $filename\n");
                my @objList = $db->get_objects("file", "name", $filename)->get_list();
                if (@objList) {
                    foreach my $fileObj ($db->get_objects("file", "name", $filename)->get_list()) {
                        if ($fileObj->get("_id")) {
                            &dprint("Found ID for $filename: ". $fileObj->get("_id") ."\n");
                            push(@file_names, $fileObj->get("name"));
                            push(@file_ids, $fileObj->get("_id"));
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
                        if ($fileObj->get("_id")) {
                            &dprint("Found ID for $filename: ". $fileObj->get("_id") ."\n");
                            push(@file_names, $fileObj->get("name"));
                            push(@file_ids, $fileObj->get("_id"));
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
                        if ($fileObj->get("_id")) {
                            &dprint("Found ID for $filename: ". $fileObj->get("_id") ."\n");
                            push(@file_names, $fileObj->get("name"));
                            push(@file_ids, $fileObj->get("_id"));
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
    } elsif ($command eq "status") {
        &nprintf("%-15s %12s %15s  %s\n", "NAME", "LAST CONTACT", "STATUS", "MESSAGE");
        my $time = time();
        foreach my $o ($objSet->get_list()) {
            my $lastcontact = $o->get("_provisiontime");
            if ($lastcontact and $lastcontact =~ /^\d+$/) {
                $lastcontact = $time - $lastcontact;
            } else {
                $lastcontact = "unknown";
            }
            printf("%-15s %12s %15s  %s\n",
                $o->get("name") || "UNDEF",
                $lastcontact,
                $o->get("_provisionstatus") || "",
                $o->get("_provisionlog") || ""
            );
        }

    } elsif ($command eq "print") {
        foreach my $o ($objSet->get_list()) {
            my @files;
            my $vnfs = "UNDEF";
            my $bootstrap = "UNDEF";
            my $name = $o->get("NAME") || "UNDEF";
            if ($o->get("fileids")) {
                $fileObjSet = $db->get_objects("file", "_id", $o->get("fileids"));
            }
            if ($fileObjSet) {
                foreach my $f ($fileObjSet->get_list()) {
                    push(@files, $f->get("name"));
                }
            } else {
                push(@files, "UNDEF");
            }
            if (my $vnfsid = $o->get("vnfsid")) {
                my $vnfsObj = $db->get_objects("vnfs", "_id", $vnfsid)->get_object(0);
                if ($vnfsObj) {
                    $vnfs = $vnfsObj->get("name");
                }
            }
            if (my $bootstrapid = $o->get("bootstrapid")) {
                my $bootstrapObj = $db->get_objects("bootstrap", "_id", $bootstrapid)->get_object(0);
                if ($bootstrapObj) {
                    $bootstrap = $bootstrapObj->get("name");
                }
            }
            &nprintf("#### %s %s#\n", $name, "#" x (72 - length($name)));
            printf("%12s: %-10s = %s\n", $name, "BOOTSTRAP", $bootstrap);
            printf("%12s: %-10s = %s\n", $name, "VNFS", $vnfs);
            printf("%12s: %-10s = %s\n", $name, "FILES", join(",", @files));
            if ($o->get("master")) {
                printf("%12s: %-10s = %s\n", $name, "MASTER", join(",", $o->get("master")));
            }
            if ($o->get("filesystems")) {
                printf("%12s: %-10s = %s\n", $name, "FILESYSTEMS", join(",", $o->get("filesystems")));
            }
            if ($o->get("diskformat")) {
                printf("%12s: %-10s = %s\n", $name, "DISKFORMAT", join(",", $o->get("diskformat")));
            }
            if ($o->get("diskpartition")) {
                printf("%12s: %-10s = %s\n", $name, "DISKPARTITION", join(",", $o->get("diskpartition")));
            }
        }

    } elsif ($command eq "list") {
        &nprintf("%-15s %-15s %-20s %-15s %-15s\n", "NAME", "MASTER", "BOOTSTRAP", "VNFS", "FILES");
        &nprint("================================================================================================\n");
        foreach my $o ($objSet->get_list()) {
            my $fileObjSet;
            my @files;
            my $vnfs = "UNDEF";
            my $bootstrap = "UNDEF";
            my $mater = "UNDEF";
            if ($o->get("fileids")) {
                $fileObjSet = $db->get_objects("file", "_id", $o->get("fileids"));
            }
            if ($fileObjSet) {
                foreach my $f ($fileObjSet->get_list()) {
                    push(@files, $f->get("name"));
                }
            } else {
                push(@files, "UNDEF");
            }
            if (my $vnfsid = $o->get("vnfsid")) {
                my $vnfsObj = $db->get_objects("vnfs", "_id", $vnfsid)->get_object(0);
                if ($vnfsObj) {
                    $vnfs = $vnfsObj->get("name");
                }
            }
            if (my $bootstrapid = $o->get("bootstrapid")) {
                my $bootstrapObj = $db->get_objects("bootstrap", "_id", $bootstrapid)->get_object(0);
                if ($bootstrapObj) {
                    $bootstrap = $bootstrapObj->get("name");
                }
            }
            $master = $o->get("master");
            printf("%-15s %-15s %-20s %-15s %-15s\n",
                $o->get("name") || "UNDEF",
                &ellipsis(15, $master),
                &ellipsis(20, $bootstrap),
                &ellipsis(15, $vnfs),
                join(",", @files)
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
