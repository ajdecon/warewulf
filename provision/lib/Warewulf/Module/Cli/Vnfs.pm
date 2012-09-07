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
use Warewulf::Vnfs;
use Warewulf::DSO::Vnfs;
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
    $h .= "     vnfs <command> [options] [targets]\n";
    $h .= "\n";
    $h .= "SUMMARY:\n";
    $h .= "     This interface allows you to manage your VNFS images within the Warewulf\n";
    $h .= "     data store.\n";
    $h .= "\n";
    $h .= "COMMANDS:\n";
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
    $h .= "     -n, --name          When importing a VNFS use this name instead of the file name\n";
    $h .= "\n";
    $h .= "EXAMPLES:\n";
    $h .= "\n";
    $h .= "     Warewulf> vnfs import /path/to/name.vnfs --name=vnfs1\n";
    $h .= "     Warewulf> vnfs export vnfs1 vnfs2 /tmp/exported_vnfs/\n";
    $h .= "     Warewulf> vnfs list\n";
    $h .= "\n";

    return $h;
}



sub
summary()
{
    my $output;

    $output .= "Manage your VNFS images";

    return $output;
}


sub
complete()
{
    my $self = shift;
    my $opt_lookup = "name";
    my $db = $self->{"DB"};
    my @ret;

    if (! $db) {
        return undef;
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

    return @ret;

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
    my $return_count = 0;

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
        return undef;
    }

    if ($command) {
        if ($command eq "help") {
            print $self->help();
            return 1;
        } elsif ($command eq "export") {
            if (scalar(@ARGV) eq 2) {
                my $vnfs = shift(@ARGV);
                my $vnfs_path = shift(@ARGV);

                if ($vnfs_path =~ /^([a-zA-Z0-9_\-\.\/]+)\/?$/) {
                    $vnfs_path = $1;
                    my $vnfs_object = $db->get_objects("vnfs", $opt_lookup, $vnfs)->get_object(0);
                    my $vnfs_name = $vnfs_object->name();

                    if (-d $vnfs_path) {
                        $vnfs_path = "$vnfs_path/$vnfs_name.vnfs";
                    } else {
                        my $dirname = dirname($vnfs_path);
                        if (! -d $dirname) {
                            &eprint("Parent directory $dirname does not exist!\n");
                            return undef;
                        }
                    }

                    if (-f $vnfs_path) {
                        if ($term->interactive()) {
                            &wprint("Do you wish to overwrite this file: $vnfs_path?\n");
                            my $yesno = lc($term->get_input("Yes/No> ", "no", "yes"));
                            if ($yesno ne "y" and $yesno ne "yes") {
                                &nprint("Not exporting '$vnfs_name'\n");
                                return undef;
                            }
                        }
                    }

                    $vnfs_object->vnfs_export($vnfs_path);

                    $return_count ++;

                } else {
                    &eprint("Destination path contains illegal characters: $vnfs_path\n");
                    return undef;
                }
            } else {
                &eprint("USAGE: vnfs export [vnfs name] [destination]\n");
                return undef;
            }
        } elsif ($command eq "import") {
            if (scalar(@ARGV) >= 1) {
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
                                $name =~ s/\.vnfs$//;
                            }
                            $objSet = $db->get_objects("vnfs", $opt_lookup, $name);

                            if ($objSet->count() > 0) {
                                $obj = $objSet->get_object(0);
                                if ($term->interactive()) {
                                    my $name = $obj->name() || "UNDEF";
                                    &wprint("Do you wish to overwrite '$name' in the Warewulf data store?\n");
                                    my $yesno = lc($term->get_input("Yes/No> ", "no", "yes"));
                                    if ($yesno ne "y" and $yesno ne "yes") {
                                        &nprint("Not importing '$name'\n");
                                        return undef;
                                    }
                                }
                            } else {
                                &dprint("Creating a new Warewulf VNFS object\n");
                                $obj = Warewulf::Vnfs->new();
                                $obj->name($name);
                                &dprint("Persisting the new Warewulf VNFS object with name: $name\n");
                                $db->persist($obj);
                            }

                            $obj->vnfs_import($path);

                            $return_count ++;

                        } else {
                            &eprint("VNFS not Found: $path\n");
                            return undef;
                        }
                    } else {
                        &eprint("VNFS contains illegal characters: $path\n");
                        return undef;
                    }
                }
            } else {
                &eprint("USAGE: vnfs import [vnfs path]\n");
                return undef;
            }
        } else {
            $objSet = $db->get_objects($opt_type || $entity_type, $opt_lookup, &expand_bracket(@ARGV));

            if ($objSet->count() == 0) {
                &eprint("No VNFS images found\n");
                return undef;
            }
            if ($command eq "delete") {
                my $object_count = $objSet->count();
                if ($term->interactive()) {
                    print "Are you sure you want to delete $object_count VNFS images(s):\n\n";
                    foreach my $o ($objSet->get_list()) {
                        printf("     DEL: %-20s = %s\n", "VNFS", $o->name());
                    }
                    print "\n";
                    my $yesno = lc($term->get_input("Yes/No> ", "no", "yes"));
                    if ($yesno ne "y" and $yesno ne "yes") {
                        &nprint("No update performed\n");
                        return undef;
                    }
                }
                $return_count = $db->del_object($objSet);
            } elsif ($command eq "list" or $command eq "print") {
                &nprint("VNFS NAME                 SIZE (M)\n");
                foreach my $obj ($objSet->get_list()) {
                    printf("%-25s %-8.1f\n",
                        $obj->get("name") || "UNDEF",
                        $obj->get("size") ? $obj->get("size")/(1024*1024) : "0"
                    );
                    $return_count ++;
                }
            } else {
                &eprint("Invalid command: $command\n");
                return undef;
            }
        }
    } else {
        &eprint("You must provide a command!\n\n");
        print $self->help();
        return undef;

    }

    # We are done with ARGV, and it was internally modified, so lets reset
    @ARGV = ();

    return $return_count;
}


1;
