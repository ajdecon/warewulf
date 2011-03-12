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
use Warewulf::DSO::File;
use Getopt::Long;
use File::Basename;
use Text::ParseWords;
use Digest::file qw(digest_file_hex);
use POSIX;

our @ISA = ('Warewulf::Module::Cli');

Getopt::Long::Configure ("bundling");

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
    my ($self, $keyword) = @_;
    my $output;

    $output .= "           Usage options:\n";
    $output .= "            -i, --import           Import a file into this object\n";
    $output .= "            -e, --export           Export a file to the file system\n";
    $output .= "            -l, --lookup           Lookup by field (default: name)\n";
    $output .= "            -p, --program          Filter file through a program\n";
    $output .= "            -s, --show             Show the contents of the file data\n";
    $output .= "                --DELETE           Delete an entire object\n";

    return($output);
}

sub
complete()
{
    my ($self, $text) = @_;
    my $db = $self->{"DB"};

    return($db->get_lookups($entity_type));
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
    my $opt_lookup = "name";
    my $opt_import;
    my $opt_export;
    my $opt_show;
    my $opt_program;
    my $opt_obj_delete;

    @ARGV = ();
    push(@ARGV, @_);

    GetOptions(
        'i|import=s'    => \$opt_import,
        'e|export=s'    => \$opt_export,
        'p|program=s'   => \$opt_program,
        'l|lookup=s'    => \$opt_lookup,
        's|show'        => \$opt_show,
        'DELETE'        => \$opt_obj_delete,
    );

    if (! $db) {
        &eprint("Database object not avaialble!\n");
        return();
    }

    if ($opt_import and $opt_import =~ /^([a-zA-Z0-9_\-\.\/]+)$/) {
        my $path = $1;
        if (-f $path) {
            my $name;
            if (exists($ARGV[0])) {
                $name = $ARGV[0];
            } else {
                $name = basename($path);
            }
            my $digest = digest_file_hex($path, "MD5");
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
                my $binstore = $db->binstore($obj->get("id"));
                my $size;
                my $buffer;
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
                $obj->set("mode", $mode & 07777);
                $db->persist($obj);
                print "Imported $name into existing object\n";
            } elsif (scalar(@objList) == 0) {
                &dprint("Creating new File Object\n");
                my $obj = Warewulf::DSO::File->new();
                $db->persist($obj);
                $obj->set($opt_lookup, $name);
                $obj->set("checksum", digest_file_hex($path, "MD5"));
                my $binstore = $db->binstore($obj->get("id"));
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
                $obj->set("uid", geteuid);
                $obj->set("gid", getegid);
                $obj->set("path", $path);
                $obj->set("mode", "0644");
                $db->persist($obj);
                print "Imported $name into a new object\n";
            } else {
                print "Import into one object at a time please!\n";
            }
        } else {
            &eprint("Could not import '$path' (file not found)\n");
        }
    } elsif ($opt_program) {
        if ($opt_program) {
            $objectSet = $db->get_objects($entity_type, $opt_lookup, $ARGV[0]);
            my @objList = $objectSet->get_list();
            if (scalar(@objList) > 1) {
                &eprint("Only specify one object to operate on at a time\n");
                return();
            } elsif (scalar(@objList) == 0) {
                my $obj = Warewulf::DSO::File->new();
                $obj->set($opt_lookup, $ARGV[0]);
                $db->persist($obj);
                push(@objList, $obj);
            }
            my $obj = $objList[0];
            my $binstore = $db->binstore($obj->get("id"));
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
            if ($opt_program =~ /^"?([a-zA-Z0-9_\-\s\.]+?)"?$/) {
                if (system("$1 $tmpfile") == 0) {
                    $digest2 = digest_file_hex($tmpfile, "MD5");
                    if ($digest1 ne $digest2) {
                        my $binstore = $db->binstore($obj->get("id"));
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
        } else {
            &eprint("Command is undefined\n");
        }

    } elsif ($opt_export) {
        $objectSet = $db->get_objects($entity_type, $opt_lookup, &expand_bracket(@ARGV));
        my @objList = $objectSet->get_list();

        if ($opt_export =~ /^([a-zA-Z0-9\/\-_\.\s]+)$/) {
            $opt_export = $1;
        } else {
            &eprint("Bad characters in export path\n");
            return();
        }

        if (-d $opt_export) {
            foreach my $obj (@objList) {
                my $file = $obj->get("name");
                my $binstore = $db->binstore($obj->get("id"));

                if (-f "$opt_export/$file" and $term->interactive()) {
                    print("Are you sure you wish to overwrite $opt_export/$file?\n\n");
                    my $yesno = lc($term->get_input("Yes/No> ", "no", "yes"));
                    if ($yesno ne "y" and $yesno ne "yes" ) {
                        print "Skipped export of $opt_export/$file\n";
                        next;
                    }
                }
                open(FILE, "> $opt_export/$file");
                while(my $buffer = $binstore->get_chunk()) {
                    &dprint("Writing ". length($buffer) ." bytes to buffer\n");
                    print FILE $buffer;
                }
                close FILE;
                print "Exported: $opt_export/$file\n";
            }
        } elsif (-f $opt_export) {
            if ($term->interactive()) {
                print("Are you sure you wish to overwrite $opt_export?\n\n");
                my $yesno = lc($term->get_input("Yes/No> ", "no", "yes"));
                if ($yesno ne "y" and $yesno ne "yes" ) {
                    print "No export performed\n";
                    return();
                }
            }
            if (scalar(@objList) == 1) {
                my $obj = $objList[0];
                my $binstore = $db->binstore($obj->get("id"));
                open(FILE, "> $opt_export");
                while(my $buffer = $binstore->get_chunk()) {
                    print FILE $buffer;
                }
                close FILE;
                print "Exported: $opt_export\n";
            } else {
                &eprint("Can only export 1 file, perhaps export to a directory?\n");
            }
        } else {
            my $obj = $objList[0];
            my $binstore = $db->binstore($obj->get("id"));
            my $dirname = dirname($opt_export);
            open(FILE, "> $opt_export");
            while(my $buffer = $binstore->get_chunk()) {
                print FILE $buffer;
            }
            close FILE;
            print "Exported: $opt_export\n";
        }
    } elsif ($opt_show) {
        $objectSet = $db->get_objects($entity_type, $opt_lookup, &expand_bracket(@ARGV));
        my @objList = $objectSet->get_list();
        foreach my $obj (@objList) {
            my $binstore = $db->binstore($obj->get("id"));
            my $name = $obj->get("name");
            &nprintf("#### %s %s#\n", $name, "#" x (72 - length($name)));
            while(my $buffer = $binstore->get_chunk()) {
                print $buffer;
            }
        }

    } else {
        $objectSet = $db->get_objects($entity_type, $opt_lookup, &expand_bracket(@ARGV));
        my @objList = $objectSet->get_list();
        print "File Name          Format       #Nodes    Size(K)  File Path\n";
        foreach my $obj (@objList) {
            my @nodeObjects = $db->get_objects("node", undef, $obj->get("name"))->get_list();
            printf("%-18s %-14s %4s %9.1f   %s\n",
                $obj->get("format") || "unknwon",
                scalar(@nodeObjects),
                $obj->get("size") ? $obj->get("size")/1024 : "0",
                $obj->get("name") || "NULL",
                $obj->get("path") || "");
        }

        if ($opt_obj_delete) {

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

    }


    # We are done with ARGV, and it was internally modified, so lets reset
    @ARGV = ();

    return($return_count);
}


1;
