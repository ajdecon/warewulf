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
    $h .= "     (re)sync        Sync the data of a file object with its source(s)\n";
    $h .= "     delete          Remove a node configuration from the data store\n";
    $h .= "     help            Show usage information\n";
    $h .= "\n";
    $h .= "OPTIONS:\n";
    $h .= "\n";
    $h .= "     -l, --lookup    How should we reference this node? (default is name)\n";
    $h .= "     -p, --program   What external program should be used (vi/show)\n";
    $h .= "         --path      Set destination path attribute for this file\n";
    $h .= "         --origin    Set origin path attribute (use 'UNDEF' to delete)\n";
    $h .= "         --mode      Set permission attribute for this file\n";
    $h .= "         --uid       Set the UID of this file\n";
    $h .= "         --gid       Set the GID of this file\n";
    $h .= "         --name      Set the reference name of this file (not path!)\n";
    $h .= "         --interpreter Set the interpreter name to parse this file\n";
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
    my $self = shift;
    my $db = Warewulf::DataStore->new();
    my @ret;


    @ARGV = ();

    foreach (&quotewords('\s+', 0, @_)) {
        if (defined($_)) {
            push(@ARGV, $_);
        }
    }

    if (exists($ARGV[1]) and ($ARGV[1] eq "print" or $ARGV[1] eq "new" or $ARGV[1] eq "set" or $ARGV[1] eq "list" or $ARGV[1] eq "edit" or $ARGV[1] eq "delete")) {
        @ret = $db->get_lookups($entity_type, "name");
    } else {
        @ret = ("print", "edit", "new", "set", "delete", "list");
    }

    @ARGV = ();

    return @ret;
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
    my $opt_interpreter;
    my @opt_origin;

    @ARGV = ();
    push(@ARGV, @_);

    Getopt::Long::Configure ("bundling", "nopassthrough");

    GetOptions(
        'n|name=s'      => \$opt_name,
        'p|program=s'   => \$opt_program,
        'l|lookup=s'    => \$opt_lookup,
        'origin=s'      => \@opt_origin,
        'source=s'      => \@opt_origin,
        'path=s'        => \$opt_path,
        'dest=s'        => \$opt_path,
        'mode=s'        => \$opt_mode,
        'uid=s'         => \$opt_uid,
        'gid=s'         => \$opt_gid,
        'interpreter=s' => \$opt_interpreter,
    );

    $command = shift(@ARGV);

    if (! $db) {
        &eprint("Database object not avaialble!\n");
        return();
    }

    if ($command) {
        # Import and export commands are done seperately because they take a
        # slightly different argument syntax.
        if ($command eq "export") {
            if (scalar(@ARGV) >= 2) {
                my $path = pop(@ARGV);
                my $objSet = $db->get_objects("file", $opt_lookup, &expand_bracket(@ARGV));
                if ($objSet->count() eq 0) {
                    &nprint("File(s) not found\n");
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
                        my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($path);
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
                        $obj->mode($mode & 0777);
                        $obj->uid($uid);
                        $obj->gid($gid);
                        $obj->path($path);
                        $obj->origin($path);

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

            } elsif ($command eq "edit") {
                my $program;
                if ($opt_program) {
                    if ($opt_program =~ /^"?([a-zA-Z0-9_\-\s\.\/\'\/\"]+?)"?$/) {
                        $program = $1;
                    } else {
                        &eprint("Program name contains illegal characters: $program\n");
                        return();
                    }
                } else {
                    $program = "/bin/vi";
                }

                if ($objSet->count() eq 0) {
                    my $rand = &rand_string("16");
                    my $tmpfile = "/tmp/wwsh.$rand";
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

                if ($objSet->count() eq 1) {
                    my $obj = $objSet->get_object(0);
                    my $rand = &rand_string("16");
                    my $tmpfile = "/tmp/wwsh.$rand";

                    $obj->file_export($tmpfile);

                    &dprint("Running command: $program $tmpfile\n");
                    if (system("$program $tmpfile") == 0) {
                        if ((! $obj->checksum() or !$obj->size()) or $obj->checksum() ne digest_file_hex_md5($tmpfile)) {
                            $obj->file_import($tmpfile);
                            unlink($tmpfile);
                        } else {
                            &nprint("Not updating datastore\n");
                        }
                    } else {
                        &iprint("Command errored out, not updating datastore\n");
                    }

                } else {
                    &eprint("Edit only one file object at a time\n");
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

                if (defined($opt_interpreter)) {
                    if (uc($opt_interpreter) eq "UNDEF") {
                        foreach my $obj ($objSet->get_list()) {
                            $obj->interpreter(undef);
                            $persist_count++;
                        }
                        push(@changes, sprintf("   UNDEF: %-20s\n", "INTREPRETER"));
                    } elsif ($opt_interpreter =~ /^([a-zA-Z0-9\-_\/\.]+)$/) {
                        my $interpreter = $1;
                        foreach my $obj ($objSet->get_list()) {
                            $obj->interpreter($interpreter);
                            $persist_count++;
                        }
                        push(@changes, sprintf("     SET: %-20s = %s\n", "INTREPRETER", $interpreter));
                    } else {
                        &eprint("Interpreter contains illegal characters\n");
                    }
                }
                if (defined($opt_path)) {
                    if (uc($opt_path) eq "UNDEF") {
                        foreach my $obj ($objSet->get_list()) {
                            $obj->path(undef);
                            $persist_count++;
                        }
                        push(@changes, sprintf("   UNDEF: %-20s\n", "PATH"));
                    } elsif ($opt_path =~ /^([a-zA-Z0-9\-_\/\.]+)$/) {
                        my $path = $1;
                        foreach my $obj ($objSet->get_list()) {
                            $obj->path($path);
                            $persist_count++;
                        }
                        push(@changes, sprintf("     SET: %-20s = %s\n", "PATH", $path));
                    } else {
                        &eprint("Destination path contains illegal characters\n");
                    }
                }
                if (defined($opt_mode)) {
                    if (uc($opt_mode) eq "UNDEF") {
                        foreach my $obj ($objSet->get_list()) {
                            $obj->mode(undef);
                            $persist_count++;
                        }
                        push(@changes, sprintf("   UNDEF: %-20s\n", "MODE"));
                    } elsif ($opt_mode =~ /^([0-7]{3,4})$/) {
                        my $mode = $1;
                        foreach my $obj ($objSet->get_list()) {
                            $obj->mode(oct($mode));
                            $persist_count++;
                        }
                        push(@changes, sprintf("     SET: %-20s = %s\n", "MODE", $mode));
                    } else {
                        &eprint("Mode should in octal format\n");
                    }
                }
                if (defined($opt_uid)) {
                    if (uc($opt_uid) eq "UNDEF") {
                        foreach my $obj ($objSet->get_list()) {
                            $obj->uid(undef);
                            $persist_count++;
                        }
                        push(@changes, sprintf("   UNDEF: %-20s\n", "UID"));
                    } elsif ($opt_uid =~ /^(\d+)$/) {
                        my $uid = $1;
                        foreach my $obj ($objSet->get_list()) {
                            $obj->uid($uid);
                            $persist_count++;
                        }
                        push(@changes, sprintf("     SET: %-20s = %s\n", "UID", $uid));
                    } else {
                        &eprint("UID should be in numeric form\n");
                    }
                }
                if (defined($opt_gid)) {
                    if (uc($opt_gid) eq "UNDEF") {
                        foreach my $obj ($objSet->get_list()) {
                            $obj->gid(undef);
                            $persist_count++;
                        }
                        push(@changes, sprintf("   UNDEF: %-20s\n", "GID"));
                    } elsif ($opt_gid =~ /^(\d+)$/) {
                        my $gid = $1;
                        foreach my $obj ($objSet->get_list()) {
                            $obj->gid($gid);
                            $persist_count++;
                        }
                        push(@changes, sprintf("     SET: %-20s = %s\n", "GID", $gid));
                    } else {
                        &eprint("UID should be in numeric form\n");
                    }
                }
                if (@opt_origin) {
                    if (uc($opt_origin[0]) eq "UNDEF") {
                        foreach my $obj ($objSet->get_list()) {
                            $obj->origin(undef);
                            $persist_count++;
                        }
                        push(@changes, sprintf("   UNDEF: %-20s\n", "ORIGIN"));
                    } else {
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

            } elsif ($command eq "show") {
                my $program;
                if ($opt_program) {
                    if ($opt_program =~ /^"?([a-zA-Z0-9_\-\s\.\/\'\/\"]+?)"?$/) {
                        $program = $1;
                    } else {
                        &eprint("Program name contains illegal characters: $program\n");
                        return();
                    }
                } else {
                    $program = "/bin/cat";
                }

                foreach my $obj ($objSet->get_list()) {
                    my $rand = &rand_string("16");
                    my $tmpfile = "/tmp/wwsh.$rand";

                    $obj->file_export($tmpfile);

                    if (system("$program $tmpfile") == 0) {
                        unlink($tmpfile);
                    } else {
                        &eprint("Program failed: $program $tmpfile\n");
                    }

                }

            } elsif ($command eq "sync" or $command eq "resync") {
                foreach my $obj ($objSet->get_list()) {
                    $obj->sync();
                }
            } elsif ($command eq "list" or $command eq "ls") {
                #&nprint("NAME               FORMAT       SIZE(K)  FILE PATH\n");
                #&nprint("================================================================================\n");
                &iprintf("%-16s  %10s %s %-16s %9s %s\n",
                    "NAME", "PERMS", "O", "USER GROUP", "SIZE", "DEST");
                foreach my $obj ($objSet->get_list()) {
                    my $perms = "-";
                    foreach my $m (split(//, substr(sprintf("%04o", $obj->mode()), -3))) {
                        if ($m eq 7) {
                            $perms .= "rwx";
                        } elsif ($m eq 6) {
                            $perms .= "rw-";
                        } elsif ($m eq 5) {
                            $perms .= "r-x";
                        } elsif ($m eq 4) {
                            $perms .= "r--";
                        } elsif ($m eq 3) {
                            $perms .= "-wx";
                        } elsif ($m eq 2) {
                            $perms .= "-w-";
                        } elsif ($m eq 1) {
                            $perms .= "--x";
                        } else {
                            $perms .= "---";
                        }
                    }
                    my $user_group = getpwuid($obj->uid() || "0") ." ". getgrgid($obj->gid() || "0");
                    my @o = $obj->origin();
                    printf("%-16s: %10s %d %-16s %9d %s\n",
                        $obj->name(),
                        $perms || "UNDEF",
                        scalar @o,
                        $user_group,
                        $obj->size() || "0",
                        $obj->path() || "",
                    );
                }
            } elsif ($command eq "print") {
                foreach my $obj ($objSet->get_list()) {
                    my $name = $obj->get("name") || "UNDEF";
                    &nprintf("#### %s %s#\n", $name, "#" x (72 - length($name)));
                    printf("%-16s: %-16s = %s\n", $name, "ID", ($obj->id() || "ERROR"));
                    printf("%-16s: %-16s = %s\n", $name, "NAME", ($obj->name() || "UNDEF"));
                    printf("%-16s: %-16s = %s\n", $name, "PATH", ($obj->path() || "UNDEF"));
                    printf("%-16s: %-16s = %s\n", $name, "ORIGIN", (join(",", ($obj->origin())) || "UNDEF"));
                    printf("%-16s: %-16s = %s\n", $name, "FORMAT", ($obj->format() || "UNDEF"));
                    printf("%-16s: %-16s = %s\n", $name, "CHECKSUM", ($obj->checksum() || "UNDEF"));
                    printf("%-16s: %-16s = %s\n", $name, "INTERPRETER", ($obj->interpreter() || "UNDEF"));
                    printf("%-16s: %-16s = %s\n", $name, "SIZE", ($obj->size() || "0"));
                    printf("%-16s: %-16s = %s\n", $name, "MODE", (sprintf("%04o", $obj->mode()) || "UNDEF"));
                    printf("%-16s: %-16s = %s\n", $name, "UID", $obj->uid());
                    printf("%-16s: %-16s = %s\n", $name, "GID", $obj->gid());
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




1;
