#
# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#




package Warewulf::Module::Cli::Bootstrap;

use Warewulf::Logger;
use Warewulf::Module::Cli;
use Warewulf::Term;
use Warewulf::DataStore;
use Warewulf::Util;
use Warewulf::DSOFactory;
use Warewulf::Provision::Bootstrap;
use Getopt::Long;
use File::Basename;
use File::Path;
use Text::ParseWords;

our @ISA = ('Warewulf::Module::Cli');

my $entity_type = "bootstrap";

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
    $h .= "     bootstrap [command] [options] [targets]\n";
    $h .= "\n";
    $h .= "SUMMARY:\n";
    $h .= "     This interface allows you to manage your bootstrap images within the Warewulf\n";
    $h .= "     data store.\n";
    $h .= "\n";
    $h .= "COMMANDS:\n";
    $h .= "\n";
    $h .= "     The first argument MUST be the desired action you wish to take and after\n";
    $h .= "     the action, the order of the options and the targets is not specific.\n";
    $h .= "\n";
    $h .= "         import          Import a bootstrap image into Warewulf\n";
    $h .= "         export          Export a bootstrap image to the local file system\n";
    $h .= "         delete          Delete a bootstrap image from Warewulf\n";
    $h .= "         list            Show all of the currently imported bootstrap images\n";
    $h .= "         (re)build       Build (or rebuild) the tftp bootable image on this host\n";
    $h .= "         help            Show usage information\n";
    $h .= "\n";
    $h .= "OPTIONS:\n";
    $h .= "\n";
    $h .= "     -n, --name      When importing a bootstrap use this name instead of the file name\n";
    $h .= "\n";
    $h .= "EXAMPLES:\n";
    $h .= "\n";
    $h .= "     Warewulf> bootstrap import /path/to/name.wwbs --name=bootstrap\n";
    $h .= "     Warewulf> bootstrap export bootstrap1 bootstrap2 /tmp/exported_bootstrap/\n";
    $h .= "     Warewulf> bootstrap list\n";
    $h .= "\n";

    return($h);
}



sub
summary()
{
    my $output;

    $output .= "Manage your bootstrap images";

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

    if (exists($ARGV[1]) and ($ARGV[1] eq "list" or $ARGV[1] eq "export" or $ARGV[1] eq "delete")) {
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

    if (! $command) {
        &eprint("You must provide a command!\n\n");
        print $self->help();
    } elsif ($command eq "import") {
        my $import = shift(@ARGV);
        if ($import and $import =~ /^([a-zA-Z0-9_\-\.\/]+)?$/) {
            my $path = $1;
            if (-f $path) {
                my $name;
                if (defined($opt_name)) {
                    $name = $opt_name;
                } else {
                    $name = basename($path);
                }
                $name =~ s/\.wwbs$//;
                my $digest = digest_file_hex_md5($path);
                $objectSet = $db->get_objects($entity_type, $opt_lookup, $name);
                my @objList = $objectSet->get_list();
                if (scalar(@objList) == 1) {
                    if ($term->interactive()) {
                        print "Are you sure you wish to overwrite the Warewulf Bootstrap Image '$name'?\n\n";
                        my $yesno = lc($term->get_input("Yes/No> ", "no", "yes"));
                        if ($yesno ne "y" and $yesno ne "yes" ) {
                            &nprint("No import performed\n");
                            return();
                        }
                    }
                    my $obj = $objList[0];
                    $obj->set("checksum", $digest);
                    my $binstore = $db->binstore($obj->get("_id"));
                    my $size;
                    my $buffer;
                    open(SCRIPT, $path);
                    while(my $length = sysread(SCRIPT, $buffer, $db->chunk_size())) {
                        &dprint("Chunked $length bytes of $path\n");
                        if (! $binstore->put_chunk($buffer)) {
                            &eprint("Bootstrap import failure!\n");
                            return();
                        }
                        $size += $length;
                    }
                    close SCRIPT;
                    $obj->set("size", $size);
                    $db->persist($obj);
                    &nprint("Imported $name into existing object\n");
                } elsif (scalar(@objList) == 0) {
                    &nprint("Creating new Bootstrap Object: $name\n");
                    my $obj = Warewulf::DSOFactory->new("bootstrap");
                    $db->persist($obj);
                    $obj->set("name", $name);
                    $obj->set("checksum", digest_file_hex_md5($path));
                    my $binstore = $db->binstore($obj->get("_id"));
                    my $size;
                    my $buffer;
                    &dprint("Persisting new Bootstrap Object\n");
                    open(SCRIPT, $path);
                    while(my $length = sysread(SCRIPT, $buffer, $db->chunk_size())) {
                        &dprint("Chunked $length bytes of $path\n");
                        if (! $binstore->put_chunk($buffer)) {
                            $db->del_object($obj);
                            &eprint("Bootstrap import failure!\n");
                            return();
                        }
                        $size += $length;
                    }
                    close SCRIPT;
                    $obj->set("size", $size);
                    $db->persist($obj);
                    &nprint("Imported $name into a new object\n");
                } else {
                    &wprint("Import into one object at a time please!\n");
                }
            } else {
                &eprint("Could not import '$path' (file not found)\n");
            }
        }

    } elsif ($command eq "export") {
        if (scalar(@ARGV) <= 1) {
            &eprint("You must supply a bootstrap name to export, and a local path to export to\n");
            return();
        }
        my $opt_export = pop(@ARGV);
        if ($opt_export =~ /^([a-zA-Z0-9_\-\.\/]+)$/) {
            $opt_export = $1;
        } else {
            &eprint("Illegal characters in export path\n");
            return();
        }
        $objectSet = $db->get_objects($entity_type, $opt_lookup, &expand_bracket(@ARGV));
        my @objList = $objectSet->get_list();

        if (-d $opt_export) {
            foreach my $obj (@objList) {
                my $name = $obj->get("name");
                my $binstore = $db->binstore($obj->get("_id"));

                if ($name !~ /\.wwbs$/) {
                    $name .= ".wwbs";
                }

                if (-f "$opt_export/$name" and $term->interactive()) {
                    print "Are you sure you wish to overwrite $opt_export/$name?\n\n";
                    my $yesno = lc($term->get_input("Yes/No> ", "no", "yes"));
                    if ($yesno ne "y" and $yesno ne "yes" ) {
                        &nprint("Skipped export of $opt_export/$name\n");
                        next;
                    }
                }
                open(SCRIPT, "> $opt_export/$name");
                while(my $buffer = $binstore->get_chunk()) {
                    &dprint("Writing ". length($buffer) ." bytes to buffer\n");
                    print SCRIPT $buffer;
                }
                close SCRIPT;
                &nprint("Exported: $opt_export/$name\n");
            }
        } elsif (-f $opt_export) {
            if (scalar(@objList) == 1) {
                if ($term->interactive()) {
                    print "Are you sure you wish to overwrite $opt_export?\n\n";
                    my $yesno = lc($term->get_input("Yes/No> ", "no", "yes"));
                    if ($yesno ne "y" and $yesno ne "yes" ) {
                        &nprint("No export performed\n");
                        return();
                    }
                }
                my $obj = $objList[0];
                my $binstore = $db->binstore($obj->get("_id"));
                open(SCRIPT, "> $opt_export");
                while(my $buffer = $binstore->get_chunk()) {
                    print SCRIPT $buffer;
                }
                close SCRIPT;
                &nprint("Exported: $opt_export\n");
            } else {
                &eprint("Can only export 1 Bootstrap image into a file, perhaps export to a directory?\n");
            }
        } else {
            my $obj = $objList[0];
            my $binstore = $db->binstore($obj->get("_id"));
            if ($opt_export =~ /\/$/) {
                mkpath($opt_export, {error => \my $err});
                if (@$err) {
                    &eprint("Could not create $opt_export\n");
                    return;
                }
                my $name = $obj->get("name");
                if ($name !~ /\.wwbs$/) {
                    $name .= ".wwbs";
                }
                $opt_export .= $name;
            }
            open(SCRIPT, "> $opt_export");
            while(my $buffer = $binstore->get_chunk()) {
                print SCRIPT $buffer;
            }
            close SCRIPT;
            &nprint("Exported: $opt_export\n");
        }

    } elsif ($command eq "rebuild" or $command eq "build") {
    	my $bootstrapObj = Warewulf::Provision::Bootstrap->new();
        $objectSet = $db->get_objects($entity_type, $opt_lookup, &expand_bracket(@ARGV));
        foreach my $obj ($objectSet->get_list()) {
            $bootstrapObj->build_bootstrap($obj);
        }
    } elsif ($command eq "list" or $command eq "delete") {
        $objectSet = $db->get_objects($entity_type, $opt_lookup, &expand_bracket(@ARGV));
        &nprint("BOOTSTRAP NAME                      SIZE (M)\n");
        foreach my $obj ($objectSet->get_list()) {
            printf("%-35s %-8.1f\n",
                $obj->get("name") || "UNDEF",
                $obj->get("size") ? $obj->get("size")/(1024*1024) : "0"
            );
        }

        if ($command eq "delete") {

            if ($term->interactive()) {
                print "\nAre you sure you wish to delete the above Bootstrap image?\n\n";
                my $yesno = lc($term->get_input("Yes/No> ", "no", "yes"));
                if ($yesno ne "y" and $yesno ne "yes" ) {
                    &nprint("No update performed\n");
                    return();
                }
            }

            my $return_count = $db->del_object($objectSet);

            &nprint("Deleted $return_count objects\n");
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
