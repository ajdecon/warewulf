#
# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#




package Warewulf::Module::Cli::Vnfs;

use Warewulf::Logger;
use Warewulf::Module::Cli;
use Warewulf::Term;
use Warewulf::DataStore;
use Warewulf::Util;
use Getopt::Long;
use File::Basename;
use File::Path;
use Text::ParseWords;

our @ISA = ('Warewulf::Module::Cli');

my $entity_type = "vnfs";

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
    $h .= "     vnfs [command] [options] [targets]\n";
    $h .= "\n";
    $h .= "SUMMARY:\n";
    $h .= "     This interface allows you to manage your VNFS images within the Warewulf\n";
    $h .= "     data store.\n";
    $h .= "\n";
    $h .= "COMMANDS:\n";
    $h .= "\n";
    $h .= "     The first argument MUST be the desired action you wish to take and after\n";
    $h .= "     the action, the order of the options and the targets is not specific.\n";
    $h .= "\n";
    $h .= "         import          Import a VNFS image into Warewulf\n";
    $h .= "         export          Export a VNFS image to the local file system\n";
    $h .= "         delete          Delete a VNFS image from Warewulf\n";
    $h .= "         list            Show all of the currently imported VNFS images\n";
    $h .= "         help            Show usage information\n";
    $h .= "\n";
    $h .= "TARGETS:\n";
    $h .= "\n";
    $h .= "     The target is the specification for the VNFS you wish to operate on.\n";
    $h .= "\n";
    $h .= "OPTIONS:\n";
    $h .= "\n";
    $h .= "     -n, --name      When importing a VNFS use this name instead of the file name\n";
    $h .= "\n";
    $h .= "EXAMPLES:\n";
    $h .= "\n";
    $h .= "     Warewulf> vnfs import /path/to/name.vnfs --name=vnfs1\n";
    $h .= "     Warewulf> vnfs export vnfs1 vnfs2 /tmp/exported_vnfs/\n";
    $h .= "     Warewulf> vnfs list\n";
    $h .= "\n";

    return($h);
}



sub
summary()
{
    my $output;

    $output .= "Manage your VNFS images";

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

    if (exists($ARGV[1]) and ($ARGV[1] eq "print" or $ARGV[1] eq "export" or $ARGV[1] eq "delete")) {
        @ret = $db->get_lookups($entity_type, $opt_lookup);
    } else {
        @ret = ("list", "import", "export", "delete");
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
    my $opt_name;
    my $command;

    @ARGV = ();
    push(@ARGV, @_);

    Getopt::Long::Configure ("bundling", "nopassthrough");

    GetOptions(
        'n|name=s'      => \$opt_name,
        'l|lookup=s'    => \$opt_lookup,
    );

    $command = shift(@ARGV);

    if (! $db) {
        &eprint("Database object not avaialble!\n");
        return();
    }

    if ($command) {
        if ($command eq "export") {
            if (scalar(@ARGV) >= 2) {
                my $path = pop(@ARGV);
                my $objSet = $db->get_objects("vnfs", $opt_lookup, &expand_bracket(@ARGV));
                if ($objSet->count() eq 0) {
                    &nprint("Vnfs(s) not found\n");
                    return();
                }

                if ($path =~ /^([a-zA-Z0-9\.\-_\/]+?)\/?$/) {
                    $path = $1;
                } else {
                    &eprint("Destination path contains illegal characters: $path\n");
                }

                if ($objSet->count() == 1) {
                    my $obj = $objSet->get_object(0);
                    my $name = $obj->name();
                    if (-f $path) {
                        if ($term->interactive()) {
                            &wprint("Do you wish to overwrite this file: $path?");
                            my $yesno = lc($term->get_input("Yes/No> ", "no", "yes"));
                            if ($yesno ne "y" and $yesno ne "yes") {
                                &nprint("Not exporting '$name'\n");
                                return();
                            }
                        }

                        &iprint("Exporting single file object to defined file: $path\n");
                        $obj->file_export($path);
                    } elsif (-d $path) {
                        if (-f "$path/$name") {
                            if ($term->interactive()) {
                                &wprint("Do you wish to overwrite this file: $path/$name?");
                                my $yesno = lc($term->get_input("Yes/No> ", "no", "yes"));
                                if ($yesno ne "y" and $yesno ne "yes") {
                                    &nprint("Not exporting '$name'\n");
                                    return();
                                }
                            }
                        }
                        &iprint("Exporting single file object to defined directory path: $path/$name\n");
                        $obj->file_export("$path/$name");
                    } else {
                        my $dirname = dirname($path);
                        if (-d $dirname) {
                            &iprint("Exporting single file object to extrapolated directory path: $path/$name\n");
                            $obj->file_export($path);
                        } else {
                            &eprint("Can not export to non-existant directory: $path\n");
                        }
                    }
                } elsif ($objSet->count() > 1) {
                    if (-d $path) {
                        foreach my $obj ($objSet->get_list()) {
                            my $name = $obj->name();
                            if (-f "$path/$name") {
                                if ($term->interactive()) {
                                    &wprint("Do you wish to overwrite this file: $path/$name?");
                                    my $yesno = lc($term->get_input("Yes/No> ", "no", "yes"));
                                    if ($yesno ne "y" and $yesno ne "yes") {
                                        &nprint("Not exporting '$name'\n");
                                        next;
                                    }
                                }
                            }
                            &iprint("Exporting multiple file objects to defined directory path: $path/$name\n");
                            $obj->file_export("$path/$name");
                        }
                    } else {
                        &eprint("Can not export to non-existant directory: $path\n");
                    }
                }
            } else {
                &eprint("USAGE: file export [file name sources...] [destination]\n");
            }
        } elsif ($command eq "import") {
            foreach my $o (@opt_origin) {
                if (!scalar(grep { $_ eq $o} @ARGV)) {
                    push(@ARGV, @opt_origin);
                }
            }
            foreach my $path (@ARGV) {
                if ($path =~ /^([a-zA-Z0-9\-_\.\/]+)$/) {
                    $path = $1;
                    if (-f $path) {
                        my $name;
                        my $objSet;
                        my $obj;
                        if ($opt_name) {
                            $name = $opt_name;
                        } else {
                            $name = basename($path);
                        }
                        $objSet = $db->get_objects("file", $opt_lookup, $name);

                        if ($objSet->count() > 0) {
                            $obj = $objSet->get_object(0);
                            if ($term->interactive()) {
                                my $name = $obj->name() || "UNDEF";
                                &wprint("Do you wish to overwrite '$name' in the Warewulf datastore?");
                                my $yesno = lc($term->get_input("Yes/No> ", "no", "yes"));
                                if ($yesno ne "y" and $yesno ne "yes") {
                                    &nprint("Not exporting '$name'\n");
                                    return();
                                }
                            }
                        } else {
                            &dprint("Creating a new Warewulf file object\n");
                            $obj = Warewulf::File->new();
                            $obj->name($name);
                            &dprint("Persisting the new Warewulf file object with name: $name\n");
                            $db->persist($obj);
                        }

                        $obj->file_import($path);

                    } else {
                        &eprint("File not Found: $path\n");
                    }
                } else {
                    &eprint("File contains illegal characters: $path\n");
                }
            }
        } else {
            $objSet = $db->get_objects($opt_type || $entity_type, $opt_lookup, &expand_bracket(@ARGV));
            if ($command eq "delete") {
                my $object_count = $objSet->count();
                if ($term->interactive()) {
                    print "Are you sure you want to delete $object_count files(s):\n\n";
                    foreach my $o ($objSet->get_list()) {
                        printf("     DEL: %-20s = %s\n", "FILE", $o->name());
                    }
                    print "\n";
                    my $yesno = lc($term->get_input("Yes/No> ", "no", "yes"));
                    if ($yesno ne "y" and $yesno ne "yes") {
                        &nprint("No update performed\n");
                        return();
                    }
                }
                $db->del_object($objSet);
            } elsif ($command eq "print") {
                &nprint("VNFS NAME                 SIZE (M)\n");
                foreach my $obj ($objSet->get_list()) {
                    printf("%-25s %-8.1f\n",
                        $obj->get("name") || "UNDEF",
                        $obj->get("size") ? $obj->get("size")/(1024*1024) : "0"
                    );
                }
            } else {
                &eprint("Invalid command: $command\n");
            }
        }
    } else {
        &eprint("You must provide a command!\n\n");
        print $self->help();
        return();

    }

    # We are done with ARGV, and it was internally modified, so lets reset
    @ARGV = ();

    return;
}


1;
