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
use Warewulf::DSOFactory;
use Getopt::Long;
use File::Basename;
use Text::ParseWords;
use Digest::file qw(digest_file_hex);

our @ISA = ('Warewulf::Module::Cli');

Getopt::Long::Configure ("bundling");

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

    $h .= "SUMMARY:\n";
    $h .= "     This interface allows you to manage your VNFS images within the Warewulf\n";
    $h .= "     data store.\n";
    $h .= "\n";
    $h .= "COMMANDS:\n";
    $h .= "\n";
    $h .= "     import          Import a VNFS image into Warewulf\n";
    $h .= "     export          Export a VNFS image to the local file system\n";
    $h .= "     delete          Delete a VNFS image from Warewulf\n";
    $h .= "     print           Show all of the currently imported VNFS images\n";
    $h .= "\n";
    $h .= "\n";
    $h .= "OPTIONS:\n";
    $h .= "\n";
    $h .= "     -n, --name      When importing a VNFS use this name instead of the file name\n";
    $h .= "\n";
    $h .= "EXAMPLES:\n";
    $h .= "\n";
    $h .= "     Warewulf> vnfs import /path/to/name.vnfs --name=vnfs1\n";
    $h .= "     Warewulf> vnfs print\n";
    $h .= "\n";

    return($h);
}



sub
summary()
{
    my $output;

    $output .= "Manage your VNFS images.";

    return($output);
}


sub
complete()
{
    my ($self, $text) = @_;
    my $db = $self->{"DB"};

    return($db->get_lookups("vnfs"));
}

sub
exec()
{
    my $self = shift;
    my $db = $self->{"DB"};
    my $term = Warewulf::Term->new();
    my $opt_name;
    my $command;

    @ARGV = ();
    push(@ARGV, @_);

    GetOptions(
        'n|name=s'      => \$opt_name,
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

    if ($command eq "import") {
        my $import = shift(@ARGV);
        if ($import and $import =~ /^([a-zA-Z0-9_\-\.\/]+)$/) {
            my $path = $1;
            if (-f $path) {
                my $name;
                if (defined($opt_name)) {
                    $name = $opt_name;
                } else {
                    $name = basename($path);
                }
                my $digest = digest_file_hex($path, "MD5");
                $objectSet = $db->get_objects($entity_type, "name", $name);
                my @objList = $objectSet->get_list();
                if (scalar(@objList) == 1) {
                    if ($term->interactive()) {
                        print "Are you sure you wish to overwrite the Warewulf Vnfs Image '$name'?\n\n";
                        my $yesno = lc($term->get_input("Yes/No> ", "no", "yes"));
                        if ($yesno ne "y" and $yesno ne "yes" ) {
                            &nprint("No import performed\n");
                            return();
                        }
                    }
                    my $obj = $objList[0];
                    $obj->set("checksum", $digest);
                    my $binstore = $db->binstore($obj->get("id"));
                    my $size;
                    my $buffer;
                    open(SCRIPT, $path);
                    while(my $length = sysread(SCRIPT, $buffer, $db->chunk_size())) {
                        &dprint("Chunked $length bytes of $path\n");
                        if (! $binstore->put_chunk($buffer)) {
                            &eprint("VNFS import failure!\n");
                            return();
                        }
                        $size += $length;
                    }
                    close SCRIPT;
                    $obj->set("size", $size);
                    $db->persist($obj);
                    &nprint("Imported $name into existing object\n");
                } elsif (scalar(@objList) == 0) {
                    &nprint("Creating new Vnfs Object: $name\n");
                    my $obj = Warewulf::DSOFactory->new("vnfs");
                    $db->persist($obj);
                    $obj->set("name", $name);
                    $obj->set("checksum", digest_file_hex($path, "MD5"));
                    my $binstore = $db->binstore($obj->get("id"));
                    my $size;
                    my $buffer;
                    &dprint("Persisting new Vnfs Object\n");
                    open(SCRIPT, $path);
                    while(my $length = sysread(SCRIPT, $buffer, $db->chunk_size())) {
                        &dprint("Chunked $length bytes of $path\n");
                        if (! $binstore->put_chunk($buffer)) {
                            $db->del_object($obj);
                            &eprint("VNFS import failure!\n");
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
        $objectSet = $db->get_objects($entity_type, "name", &expand_bracket(@ARGV));
        my @objList = $objectSet->get_list();

        if (-d $opt_export) {
            foreach my $obj (@objList) {
                my $name = $obj->get("name");
                my $binstore = $db->binstore($obj->get("id"));

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
            if ($term->interactive()) {
                print "Are you sure you wish to overwrite $opt_export?\n\n";
                my $yesno = lc($term->get_input("Yes/No> ", "no", "yes"));
                if ($yesno ne "y" and $yesno ne "yes" ) {
                    &nprint("No export performed\n");
                    return();
                }
            }
            if (scalar(@objList) == 1) {
                my $obj = $objList[0];
                my $binstore = $db->binstore($obj->get("id"));
                open(SCRIPT, "> $opt_export");
                while(my $buffer = $binstore->get_chunk()) {
                    print SCRIPT $buffer;
                }
                close SCRIPT;
                &nprint("Exported: $opt_export\n");
            } else {
                &eprint("Can only export 1 Vnfs image into a file, perhaps export to a directory?\n");
            }
        } else {
            my $obj = $objList[0];
            my $binstore = $db->binstore($obj->get("id"));
            my $dirname = dirname($opt_export);
            open(SCRIPT, "> $opt_export");
            while(my $buffer = $binstore->get_chunk()) {
                print SCRIPT $buffer;
            }
            close SCRIPT;
            &nprint("Exported: $opt_export\n");
        }

    } elsif ($command eq "print" or $command eq "delete") {
        $objectSet = $db->get_objects($entity_type, "name", &expand_bracket(@ARGV));
        my @objList = $objectSet->get_list();
        &nprint("#NODES    SIZE (M)    VNFS NAME\n");
        foreach my $obj (@objList) {
            my @nodeObjects = $db->get_objects("node", "vnfsid", $obj->get("id"))->get_list();
            printf("%-5s     %-8.1f    %s\n",
                scalar(@nodeObjects),
                $obj->get("size") ? $obj->get("size")/(1024*1024) : "0",
                $obj->get("name") || "UNDEF");
        }

        if ($command eq "delete") {

            if ($term->interactive()) {
                print "\nAre you sure you wish to make the delete the above Vnfs image?\n\n";
                my $yesno = lc($term->get_input("Yes/No> ", "no", "yes"));
                if ($yesno ne "y" and $yesno ne "yes" ) {
                    &nprint("No update performed\n");
                    return();
                }
            }

            my $return_count = $db->del_object($objectSet);

            &nprint("Deleted $return_count objects\n");
        }
    }


    # We are done with ARGV, and it was internally modified, so lets reset
    @ARGV = ();

    return($return_count);
}


1;
