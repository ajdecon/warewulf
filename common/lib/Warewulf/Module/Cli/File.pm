#
# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#




package Warewulf::Module::Cli::File;

use Warewulf::Logger;
use Warewulf::Module::Cli;
use Warewulf::Term;
use Warewulf::DataStore;
use Warewulf::Util;
use Warewulf::DSOFactory;
use Getopt::Long;
use File::Basename;
use File::Path;
use Text::ParseWords;
use POSIX;

our @ISA = ('Warewulf::Module::Cli');

my $entity_type = "file";

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
    $h .= "     file [command] [options] [targets]\n";
    $h .= "\n";
    $h .= "SUMMARY:\n";
    $h .= "     This is the base file interface for dealing with Warewulf. It allows you to\n";
    $h .= "     import, export, create and modify files within the Warewulf datastore. Some\n";
    $h .= "     examples of this would be if you wanted to use a specific file as a node\n";
    $h .= "     gets provisioned.\n";
    $h .= "\n";
    $h .= "COMMANDS:\n";
    $h .= "\n";
    $h .= "     import          Import a file into Warewulf\n";
    $h .= "     export          Export the file out of Warewulf\n";
    $h .= "     edit            Edit the file with 'vi' in the datastore directly\n";
    $h .= "     set             Set file attributes/metadata\n";
    $h .= "     show            Show the content of a file\n";
    $h .= "     list            List a summary of imported files\n";
    $h .= "     delete          Remove a node configuration from the data store\n";
    $h .= "     help            Show usage information\n";
    $h .= "\n";
    $h .= "OPTIONS:\n";
    $h .= "\n";
    $h .= "     -l, --lookup    How should we reference this node? (default is name)\n";
    $h .= "     -p, --program   What external program should be used (vi/show)\n";
    $h .= "         --path      Set path attribute for this file\n";
    $h .= "         --mode      Set permission attribute for this file\n";
    $h .= "         --uid       Set the UID of this file\n";
    $h .= "         --gid       Set the GID of this file\n";
    $h .= "         --name      Set the reference name of this file (not path!)\n";
    $h .= "\n";
    $h .= "EXAMPLES:\n";
    $h .= "\n";
    $h .= "     Warewulf> file import /path/to/file/to/import --name=hosts-file\n";
    $h .= "     Warewulf> file import /path/to/file/to/import/with/given-name\n";
    $h .= "     Warewulf> file edit given-name\n";
    $h .= "     Warewulf> file set hosts-file --path=/etc/hosts --mode=0644 --uid=0\n";
    $h .= "     Warewulf> file list\n";
    $h .= "     Warewulf> file delete name123 given-name\n";
    $h .= "\n";

    return($h);
}


sub
summary()
{
    my $output;

    $output .= "Manage files within the Warewulf datastore";

    return($output);
}


sub
complete()
{
    my ($self, $text) = @_;
    my $db = $self->{"DB"};

    return($db->get_lookups($entity_type, "name"));
}

sub
format()
{
    my $data = shift;

    if ($data and length($data) > 0) {
        my ($interpreter) = split(/\n/, $data);

        if ($interpreter =~ /^#!\/.+\/perl\s*/) {
            return("perl");
        } elsif ($interpreter =~ /^#!\/.+\/sh\s*/) {
            return("shell");
        } elsif ($interpreter =~ /^#!\/.+\/bash\s*/) {
            return("bash");
        } elsif ($interpreter =~ /^#!\/.+\/python\s*/) {
            return("python");
        } elsif ($interpreter =~ /^#!\/.+\/t?csh\s*/) {
            return("csh");
        } else {
            return("data");
        }
    }

    return();
}

sub
exec()
{
    my $self = shift;
    my $db = $self->{"DB"};
    my $term = Warewulf::Term->new();
    my $command;
    my $opt_lookup = "name";
    my $opt_name;
    my $opt_program;
    my $opt_path;
    my $opt_mode;
    my $opt_uid;
    my $opt_gid;

    @ARGV = ();
    push(@ARGV, @_);

    Getopt::Long::Configure ("bundling", "nopassthrough");

    GetOptions(
        'n|name=s'      => \$opt_name,
        'p|program=s'   => \$opt_program,
        'l|lookup=s'    => \$opt_lookup,
        'path=s'        => \$opt_path,
        'mode=s'        => \$opt_mode,
        'uid=s'         => \$opt_uid,
        'gid=s'         => \$opt_gid,
    );

    $command = shift(@ARGV);

    if (! $db) {
        &eprint("Database object not avaialble!\n");
        return();
    }

    if (! $command) {
        &eprint("You must provide a command!\n\n");
        print $self->help();
        return();
    } elsif ($command eq "new") {
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

    if ($objSet) {
        $object_count = $objSet->count();
    } else {
        &nprint("No nodes found\n");
        return();
    }


    if (! $command) {
        &eprint("You must provide a command!\n\n");
        print $self->help();
    } elsif ($command eq "import") {
        foreach my $tmp_path (@ARGV) {
            if ($tmp_path =~ /^([a-zA-Z0-9_\-\.\/]+)$/) {
                my $path = $1;
                if (-f $path) {
                    my $name;
                    if ($opt_name) {
                        $name = $opt_name;
                    } else {
                        $name = basename($path);
                    }
                    my $digest = digest_file_hex_md5($path);
                    $objectSet = $db->get_objects($entity_type, $opt_lookup, $name);
                    my @objList = $objectSet->get_list();
                    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size, $atime,$mtime,$ctime,$blksize,$blocks) = stat($path);
                    if (scalar(@objList) == 1) {
                        if ($term->interactive()) {
                            print("Are you sure you wish to overwrite the Warewulf file '$name'?\n\n");
                            my $yesno = lc($term->get_input("Yes/No> ", "no", "yes"));
                            if ($yesno ne "y" and $yesno ne "yes" ) {
                                print "No import performed\n";
                                return();
                            }
                        }
                        my $obj = $objList[0];
                        $obj->set("checksum", $digest);
                        my $binstore = $db->binstore($obj->get("_id"));
                        my $size;
                        my $buffer;
                        open(FILE, $path);
                        while(my $length = sysread(FILE, $buffer, $db->chunk_size())) {
                            &dprint("Chunked $length bytes of $path\n");
                            $binstore->put_chunk($buffer);
                            if (! $size) {
                                $obj->set("format", &format($buffer));
                            }
                            $size += $length;
                        }
                        close FILE;
                        $obj->set("size", $size);
                        $obj->set("uid", $uid);
                        $obj->set("gid", $gid);
                        $obj->set("mode", sprintf("%05o", $mode & 07777));
                        $db->persist($obj);
                        print "Imported $name into existing object\n";
                    } elsif (scalar(@objList) == 0) {
                        &dprint("Creating new File Object\n");
                        my $obj = Warewulf::DSOFactory->new("file");
                        $db->persist($obj);
                        $obj->set($opt_lookup, $name);
                        $obj->set("checksum", digest_file_hex_md5($path));
                        my $binstore = $db->binstore($obj->get("_id"));
                        my $size;
                        my $buffer;
                        &dprint("Persisting new File Object\n");
                        open(FILE, $path);
                        while(my $length = sysread(FILE, $buffer, 15*1024*1024)) {
                            &dprint("Chunked $length bytes of $path\n");
                            $binstore->put_chunk($buffer);
                            if (! $size) {
                                $obj->set("format", &format($buffer));
                            }
                            $size += $length;
                        }
                        close FILE;
                        $obj->set("size", $size);
                        $obj->set("uid", $uid);
                        $obj->set("gid", $gid);
                        $obj->set("mode", sprintf("%05o", $mode & 07777));
                        $obj->set("path", $path);
                        $db->persist($obj);
                        print "Imported $name into a new object\n";
                    } else {
                        print "Import into one object at a time please!\n";
                    }
                } else {
                    &eprint("Could not import '$path' (file not found)\n");
                }
            }
        }
    } elsif ($command eq "edit") {
        my $program;
        if ($opt_program) {
            $program = $opt_program;
        } else {
            $program = "/bin/vi";
        }
        my $name = shift(@ARGV);
        $objectSet = $db->get_objects($entity_type, $opt_lookup, $name);
        my @objList = $objectSet->get_list();
        if (scalar(@objList) > 1) {
            &eprint("Only specify one object to edit at a time\n");
            return();
        } elsif (scalar(@objList) == 0) {
            my $obj = Warewulf::DSOFactory->new("file");
            $obj->set($opt_lookup, $name);
            $db->persist($obj);
            push(@objList, $obj);
        }
        my $obj = $objList[0];
        my $binstore = $db->binstore($obj->get("_id"));
        my $rand = &rand_string("16");
        my $tmpfile = "/tmp/wwsh.$rand";
        my $digest1;
        my $digest2;
        open(TMPFILE, "> $tmpfile");
        while(my $buffer = $binstore->get_chunk()) {
            print TMPFILE $buffer;
        }
        close TMPFILE;
        $digest1 = $obj->get("checksum") || "";
        if ($program =~ /^"?([a-zA-Z0-9_\-\s\.\/]+?)"?$/) {
            if (system("$1 $tmpfile") == 0) {
                $digest2 = digest_file_hex_md5($tmpfile);
                if ($digest1 ne $digest2) {
                    my $binstore = $db->binstore($obj->get("_id"));
                    my $size;
                    my $buffer;
                    open(FILE, $tmpfile);
                    while(my $length = sysread(FILE, $buffer, 15*1024*1024)) {
                        &dprint("Chunked $length bytes of $tmpfile\n");
                        $binstore->put_chunk($buffer);
                        if (! $size) {
                            $obj->set("format", &format($buffer));
                        }
                        $size += $length;
                    }
                    close FILE;
                    $obj->set("checksum", $digest2);
                    $obj->set("size", $size);
                    $obj->set("uid", geteuid);
                    $obj->set("gid", getegid);
                    $obj->set("mode", "0644");
                    $db->persist($obj);
                    &nprint("Updated datastore\n");
                } else {
                    &nprint("Not updating datastore\n");
                }
            } else {
                &iprint("Command errored out, not updating datastore\n");
            }
        } else {
            &eprint("Program name contains illegal characters\n");
        }
        &dprint("Removing temporary file: $tmpfile\n");
        unlink($tmpfile);

    } elsif ($command eq "set") {
        $objectSet = $db->get_objects($entity_type, $opt_lookup, &expand_bracket(@ARGV));
        my @objList = $objectSet->get_list();
        my $persist_bool;

        foreach my $obj (@objList) {
            if (defined($opt_path)) {
                if ($opt_path =~ /^([a-zA-Z0-9\-_\/\.]+)$/) {
                    $obj->set("path", $1);
                    $persist_bool = 1;
                } else {
                    &eprint("Illegal characters in the given PATH\n");
                }
            }
            if (defined($opt_mode)) {
                if ($opt_mode=~ /^(\d\d\d\d)$/) {
                    $obj->set("mode", $1);
                    $persist_bool = 1;
                } else {
                    &eprint("Invalid MODE given (four numeric digits are required)\n");
                }
            }
            if (defined($opt_uid)) {
                if ($opt_uid=~ /^(\d+)$/) {
                    $obj->set("uid", $1);
                    $persist_bool = 1;
                } else {
                    &eprint("Invalid UID given (single numeric digit is required)\n");
                }
            }
            if (defined($opt_gid)) {
                if ($opt_gid=~ /^(\d+)$/) {
                    $obj->set("gid", $1);
                    $persist_bool = 1;
                } else {
                    &eprint("Invalid GID given (single numeric digit is required)\n");
                }
            }

        }


        if ($persist_bool) {
            if ($term->interactive()) {
                print "Are you sure you want to make the following changes to ". scalar($objectSet->get_list()) ." files(s):\n\n";
                if ($opt_path) {
                    print "      PATH = $opt_path\n";
                }
                if ($opt_mode) {
                    print "      MODE = $opt_mode\n";
                }
                if ($opt_uid) {
                    print "       UID = $opt_uid\n";
                }
                if ($opt_gid) {
                    print "       GID = $opt_gid\n";
                }
                print "\n";
                my $yesno = lc($term->get_input("Yes/No> ", "no", "yes"));
                if ($yesno ne "y" and $yesno ne "yes") {
                    &nprint("No update performed\n");
                    return();
                }
            }

            $return_count = $db->persist($objectSet);

            &iprint("Updated $return_count objects\n");
        }



    } elsif ($command eq "export") {
        my $path = pop(@ARGV);
        $objectSet = $db->get_objects($entity_type, $opt_lookup, &expand_bracket(@ARGV));
        my @objList = $objectSet->get_list();

        if ($path =~ /^([a-zA-Z0-9\/\-_\.\s]+)$/) {
            $path = $1;
        } else {
            &eprint("Bad characters in export path\n");
            return();
        }

        if (-d $path) {
            foreach my $obj (@objList) {
                my $file = $obj->get("name");
                my $binstore = $db->binstore($obj->get("_id"));

                if (-f "$path/$file" and $term->interactive()) {
                    print("Are you sure you wish to overwrite $path/$file?\n\n");
                    my $yesno = lc($term->get_input("Yes/No> ", "no", "yes"));
                    if ($yesno ne "y" and $yesno ne "yes" ) {
                        print "Skipped export of $path/$file\n";
                        next;
                    }
                }
                open(FILE, "> $path/$file");
                while(my $buffer = $binstore->get_chunk()) {
                    &dprint("Writing ". length($buffer) ." bytes to buffer\n");
                    print FILE $buffer;
                }
                close FILE;
                print "Exported: $path/$file\n";
            }
        } elsif (-f $path) {
            if ($term->interactive()) {
                print("Are you sure you wish to overwrite $path?\n\n");
                my $yesno = lc($term->get_input("Yes/No> ", "no", "yes"));
                if ($yesno ne "y" and $yesno ne "yes" ) {
                    print "No export performed\n";
                    return();
                }
            }
            if (scalar(@objList) == 1) {
                my $obj = $objList[0];
                my $binstore = $db->binstore($obj->get("_id"));
                open(FILE, "> $path");
                while(my $buffer = $binstore->get_chunk()) {
                    print FILE $buffer;
                }
                close FILE;
                print "Exported: $path\n";
            } else {
                &eprint("Can only export 1 file, perhaps export to a directory?\n");
            }
        } else {
            my $obj = $objList[0];
            my $binstore = $db->binstore($obj->get("_id"));
            if ($path =~ /\/$/) {
                mkpath($path, {error => \my $err});
                if (@$err) {
                    &eprint("Could not create $path\n");
                    return;
                }
                my $name = $obj->get("name");
                $path .= $name;
            }
            open(FILE, "> $path");
            while(my $buffer = $binstore->get_chunk()) {
                print FILE $buffer;
            }
            close FILE;
            print "Exported: $path\n";
        }
    } elsif ($command eq "show") {
        my $program;
        if ($opt_program) {
            $program = $opt_program;
        } else {
            $program = "/bin/more";
        }
        open(PROG, "| $program");
        $objectSet = $db->get_objects($entity_type, $opt_lookup, &expand_bracket(@ARGV));
        my @objList = $objectSet->get_list();
        foreach my $obj (@objList) {
            my $binstore = $db->binstore($obj->get("_id"));
            my $name = $obj->get("name");
            &nprintf("#### %s %s#\n", $name, "#" x (72 - length($name)));
            while(my $buffer = $binstore->get_chunk()) {
                print PROG $buffer;
            }
        }
        close(PROG);

    } elsif ($command eq "list" or $command eq "delete") {
        $objectSet = $db->get_objects($entity_type, $opt_lookup, &expand_bracket(@ARGV));
        my @objList = $objectSet->get_list();
        &nprint("NAME               FORMAT       #NODES    SIZE(K)  FILE PATH\n");
        &nprint("================================================================================\n");
        foreach my $obj (@objList) {
            my $nodeSet = $db->get_objects("node", "fileids", $obj->get("_id"));
            my $node_count = 0;
            if ($nodeSet) {
                $node_count = $nodeSet->count();
            }
            printf("%-18s %-14s %4s %9.1f   %s\n",
                $obj->get("name") || "UNDEF",
                $obj->get("format") || "unknwon",
                $node_count,
                $obj->get("size") ? $obj->get("size")/1024 : "0",
                $obj->get("path") || "");
        }

        if ($command eq "delete") {
            if ($term->interactive()) {
                print("\nAre you sure you wish to make the delete the above file(s)?\n\n");
                my $yesno = lc($term->get_input("Yes/No> ", "no", "yes"));
                if ($yesno ne "y" and $yesno ne "yes" ) {
                    print "No update performed\n";
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
