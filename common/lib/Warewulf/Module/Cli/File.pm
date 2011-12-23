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
use Warewulf::File;
use Warewulf::DSO::File;
use Getopt::Long;
use File::Basename;
use File::Path;
use Text::ParseWords;
use Digest::MD5 qw(md5_hex);
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

    return $self;
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
    $h .= "     print           Print all file attributes\n";
    $h .= "     (re)sync        Sync the data of a file object with its orgin(s)\n";
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
    $h .= "         --origin    Define where this file comes from (used with sync)\n";
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
    my $db = Warewulf::DataStore->new();

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
    my $db = Warewulf::DataStore->new();
    my $term = Warewulf::Term->new();
    my $command;
    my $opt_lookup = "name";
    my $opt_name;
    my $opt_program;
    my $opt_path;
    my $opt_mode;
    my $opt_uid;
    my $opt_gid;
    my @opt_origin;

    @ARGV = ();
    push(@ARGV, @_);

    Getopt::Long::Configure ("bundling", "nopassthrough");

    GetOptions(
        'n|name=s'      => \$opt_name,
        'p|program=s'   => \$opt_program,
        'l|lookup=s'    => \$opt_lookup,
        'o|origin=s'    => \@opt_origin,
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

    if ($command) {
        if ($command eq "delete") {
            if (@ARGV) {
                my $objSet = $db->get_objects("file", $opt_lookup, &expand_bracket(@ARGV));
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
            } else {
                &eprint("Specify the files you wish to delete!\n");
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
            my $objSet;
            if ($command eq "new") {
                $objSet = Warewulf::ObjectSet->new();
                foreach my $string (&expand_bracket(@ARGV)) {
                    my $obj;
                    $obj = Warewulf::DSO::File->new();

                    $obj->set($opt_lookup, $string);

                    $objSet->add($obj);

                    $persist_count++;

                    push(@changes, sprintf("     NEW: %-20s = %s\n", "FILE", $string));
                }
                $db->persist($objSet);
            } else {
                $objSet = $db->get_objects($opt_type || $entity_type, $opt_lookup, &expand_bracket(@ARGV));
            }


            if ($command eq "edit") {
                my $program;
                if ($opt_program) {
                    $program = $opt_program;
                } else {
                    $program = "/bin/vi";
                }

                if ($objSet->count() eq 0) {
                    my $name;
                    if ($opt_name) {
                        $name = $opt_name;
                    } else {
                        $name = shift(@ARGV);
                    }
                    &dprint("Creating a new Warewulf file object\n");
                    $obj = Warewulf::File->new();
                    $obj->name($name);
                    &dprint("Persisting the new Warewulf file object with name: $name\n");
                    $db->persist($obj);
                    $objSet->add($obj);
                }

                foreach my $obj ($objSet->get_list()) {
                    my $rand = &rand_string("16");
                    my $tmpfile = "/tmp/wwsh.$rand";

                    $obj->file_export($tmpfile);

                    if ($program =~ /^"?([a-zA-Z0-9_\-\s\.\/\'\/\"]+?)"?$/) {
                        &dprint("Running command: $1 $tmpfile\n");
                        if (system("$1 $tmpfile") == 0) {
                            if ($obj->checksum() ne digest_file_hex_md5($tmpfile)) {
                                $obj->file_import($tmpfile);
                            } else {
                                &nprint("Not updating datastore\n");
                            }
                        } else {
                            &iprint("Command errored out, not updating datastore\n");
                        }
                    } else {
                        &eprint("Program name contains illegal characters: $program\n");
                    }

                    unlink($tmpfile);
                }

            } elsif ($command eq "export") {
                if ($objSet) {
                    $object_count = $objSet->count();
                } else {
                    &nprint("File(s) not found\n");
                    return();
                }
                
                foreach my $obj ($objSet->get_list) {
                    my $name = $obj->name();
                    my $path = getcwd();
                    if (-f $name) {
                        if ($term->interactive()) {
                            &wprint("Do you wish to overwrite this file: $path/$name?");
                            my $yesno = lc($term->get_input("Yes/No> ", "no", "yes"));
                            if ($yesno ne "y" and $yesno ne "yes") {
                                &nprint("Not exporting '$name'\n");
                                return();
                            }
                        }
                    }
                    $obj->file_export("$path/$name");
                }

            } elsif ($command eq "set" or $command eq "new") {
                my $persist_count = 0;
                my @changes;
                if ($objSet) {
                    $object_count = $objSet->count();
                } else {
                    &nprint("File(s) not found\n");
                    return();
                }

                if (defined($opt_path)) {
                    if ($opt_path =~ /^([a-zA-Z0-9\-_\/\.]+)$/) {
                        my $path = $1;
                        foreach my $obj ($objSet->get_list()) {
                            $obj->path($path);
                            $persist_count++;
                        }
                        push(@changes, sprintf("     SET: %-20s = %s\n", "PATH", $path));
                    }
                }
                if (defined($opt_mode)) {
                    if ($opt_mode =~ /^(\d\d\d\d)$/) {
                        my $mode = $1;
                        foreach my $obj ($objSet->get_list()) {
                            $obj->mode($mode);
                            $persist_count++;
                        }
                        push(@changes, sprintf("     SET: %-20s = %s\n", "MODE", $mode));
                    }
                }
                if (defined($opt_uid)) {
                    if ($opt_uid =~ /^(\d+)$/) {
                        my $uid = $1;
                        foreach my $obj ($objSet->get_list()) {
                            $obj->uid($uid);
                            $persist_count++;
                        }
                        push(@changes, sprintf("     SET: %-20s = %s\n", "UID", $uid));
                    }
                }
                if (defined($opt_gid)) {
                    if ($opt_gid =~ /^(\d+)$/) {
                        my $gid = $1;
                        foreach my $obj ($objSet->get_list()) {
                            $obj->gid($gid);
                            $persist_count++;
                        }
                        push(@changes, sprintf("     SET: %-20s = %s\n", "GID", $gid));
                    }
                }
                if (@opt_origin) {
                    my @origins;
                    foreach my $origin (split(",", join(",", @opt_origin))) {
                        if ($origin =~ /^(\/[a-zA-Z0-9\-_\.\/]+)$/) {
                            push(@origins, $1);
                            $persist_count++;
                        } else {
                            &eprint("Invalid origin path given: $origin\n");
                        }
                    }
                    if (@origins) {
                        foreach my $obj ($objSet->get_list()) {
                            $obj->origin(@origins);
                        }
                        push(@changes, sprintf("     SET: %-20s = %s\n", "ORIGIN", join(",", @origins)));
                    }
                }


                if ($persist_count > 0) {
                    if ($term->interactive()) {
                        my $file_count = $objSet->count();
                        print "Are you sure you want to make the following $persist_count actions(s) to $file_count file(s):\n\n";
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
                foreach my $obj ($objSet->get_list()) {
                    my $name = $obj->get("name") || "UNDEF";
                    &nprintf("#### %s %s#\n", $name, "#" x (72 - length($name)));
                    printf("%15s: %-16s = %s\n", $name, "ID", ($obj->id() || "ERROR"));
                    printf("%15s: %-16s = %s\n", $name, "NAME", ($obj->name() || "UNDEF"));
                    printf("%15s: %-16s = %s\n", $name, "PATH", ($obj->path() || "UNDEF"));
#                    printf("%15s: %-16s = %s\n", $name, "FORMAT", ($obj->format() || "UNDEF"));
                    printf("%15s: %-16s = %s\n", $name, "CHECKSUM", ($obj->checksum() || "UNDEF"));
                    printf("%15s: %-16s = %s\n", $name, "SIZE", ($obj->size() || "UNDEF"));
                    printf("%15s: %-16s = %s\n", $name, "MODE", ($obj->mode() || "UNDEF"));
                    printf("%15s: %-16s = %s\n", $name, "UID", ($obj->uid() || "UNDEF"));
                    printf("%15s: %-16s = %s\n", $name, "GID", ($obj->gid() || "UNDEF"));
                    printf("%15s: %-16s = %s\n", $name, "ORIGIN", (join(",", ($obj->origin())) || "UNDEF"));
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
}



#    } elsif ($command eq "show") {
#        my $program;
#        if ($opt_program) {
#            $program = $opt_program;
#        } else {
#            $program = "/bin/more";
#        }
#        open(PROG, "| $program");
#        $objectSet = $db->get_objects($entity_type, $opt_lookup, &expand_bracket(@ARGV));
#        my @objList = $objectSet->get_list();
#        foreach my $obj (@objList) {
#            my $binstore = $db->binstore($obj->get("_id"));
#            my $name = $obj->get("name");
#            &nprintf("#### %s %s#\n", $name, "#" x (72 - length($name)));
#            while(my $buffer = $binstore->get_chunk()) {
#                print PROG $buffer;
#            }
#        }
#        close(PROG);
#
#    } elsif ($command eq "sync" or $command eq "resync") {
#        foreach my $o ($objSet->get_list()) {
#            my @origins = $o->get("origin");
#            if (@origins) {
#                my $data;
#                foreach my $origin (@origins) {
#                    if ($origin =~ /^(\/[a-zA-Z0-9\-_\/\.]+)$/) {
#                        my $path = $1;
#                        open(FILE, $path);
#                        while(my $line = <FILE>) {
#                            $data .= $line;
#                        }
#                        close(FILE);
#                    }
#                }
#                my $binstore = $db->binstore($o->get("_id"));
#                my $total_len = length($data);
#                my $cur_len = 0;
#                my $start = 0;
#                while($total_len > $cur_len) {
#                    my $buffer = substr($data, $start, $db->chunk_size());
#                    $binstore->put_chunk($buffer);
#                    $start += $db->chunk_size();
#                    $cur_len += length($buffer);
#                    &dprint("Chunked $cur_len of $total_len\n");
#                }
#
#                $o->set("checksum", md5_hex($data));
#                $o->set("size", $total_len);
#            }
#        }
#
#        $db->persist($objSet);
#
#    } elsif ($command eq "print") {
#        foreach my $o ($objSet->get_list()) {
#            my $name = $o->get("name");
#            &nprintf("#### %s %s#\n", $name, "#" x (72 - length($name)));
#            printf("%15s: %-16s = %s\n", $name, "ID", ($o->get("_id") || "ERROR"));
#            printf("%15s: %-16s = %s\n", $name, "NAME", ($o->get("name") || "UNDEF"));
#            printf("%15s: %-16s = %s\n", $name, "PATH", ($o->get("path") || "UNDEF"));
#            printf("%15s: %-16s = %s\n", $name, "FORMAT", ($o->get("format") || "UNDEF"));
#            printf("%15s: %-16s = %s\n", $name, "CHECKSUM", ($o->get("checksum") || "UNDEF"));
#            printf("%15s: %-16s = %s\n", $name, "SIZE", (defined $o->get("size") ? $o->get("size") : "UNDEF"));
#            printf("%15s: %-16s = %s\n", $name, "MODE", (defined $o->get("mode") ? $o->get("mode") : "UNDEF"));
#            printf("%15s: %-16s = %s\n", $name, "UID", (defined $o->get("uid") ? $o->get("uid") : "UNDEF"));
#            printf("%15s: %-16s = %s\n", $name, "GID", (defined $o->get("gid") ? $o->get("gid") : "UNDEF"));
#            printf("%15s: %-16s = %s\n", $name, "ORIGIN", (join(",", ($o->get("origin"))) || "UNDEF"));
#        }
#    } elsif ($command eq "list" or $command eq "delete") {
#        $objectSet = $db->get_objects($entity_type, $opt_lookup, &expand_bracket(@ARGV));
#        my @objList = $objectSet->get_list();
#        &nprint("NAME               FORMAT       #NODES    SIZE(K)  FILE PATH\n");
#        &nprint("================================================================================\n");
#        foreach my $obj (@objList) {
#            my $nodeSet = $db->get_objects("node", "fileids", $obj->get("_id"));
#            my $node_count = 0;
#            if ($nodeSet) {
#                $node_count = $nodeSet->count();
#            }
#            printf("%-18s %-14s %4s %9.1f   %s\n",
#                $obj->get("name") || "UNDEF",
#                $obj->get("format") || "unknwon",
#                $node_count,
#                $obj->get("size") ? $obj->get("size")/1024 : "0",
#                $obj->get("path") || "");
#        }
#
#        if ($command eq "delete") {
#            if ($term->interactive()) {
#                print("\nAre you sure you wish to make the delete the above file(s)?\n\n");
#                my $yesno = lc($term->get_input("Yes/No> ", "no", "yes"));
#                if ($yesno ne "y" and $yesno ne "yes" ) {
#                    print "No update performed\n";
#                    return();
#                }
#            }
#
#            my $return_count = $db->del_object($objectSet);
#
#            &nprint("Deleted $return_count objects\n");
#        }
#
#    } elsif ($command eq "help") {
#        print $self->help();
#
#    } else {
#        &eprint("Unknown command: $command\n\n");
#        print $self->help();
#    }
#
#
#    # We are done with ARGV, and it was internally modified, so lets reset
#    @ARGV = ();
#
#    return($return_count);
#}


1;
