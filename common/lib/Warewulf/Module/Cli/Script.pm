#
# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#




package Warewulf::Module::Cli::Script;

use Warewulf::Logger;
use Warewulf::Module::Cli;
use Warewulf::Term;
use Warewulf::DataStore;
use Warewulf::Util;
use Warewulf::Script;
use Getopt::Long;
use File::Basename;
use Text::ParseWords;
use Digest::file qw(digest_file_hex);

our @ISA = ('Warewulf::Module::Cli');

Getopt::Long::Configure ("bundling");

my $entity_type = "script";

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

    $output .= "        Hello script...\n";
    $output .= "           Usage options:\n";
    $output .= "            -i, --import           Import a script into this object\n";
    $output .= "            -e, --export           Export a script to the file system\n";
    $output .= "            -p, --program          Filter script through a program\n";
    $output .= "            -s, --show             Show the contents of the script data\n";
    $output .= "                --DELETE           Delete an entire object\n";

    return($output);
}

sub
complete()
{
    my ($self, $text) = @_;
    my $db = $self->{"DB"};

    return($db->get_lookups("script"));
}

sub
exec()
{
    my $self = shift;
    my $db = $self->{"DB"};
    my $term = Warewulf::Term->new();
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
            my $name = basename($path);
            my $digest = digest_file_hex($path, "MD5");
            $objectSet = $db->get_objects($entity_type, "name", $name);
            my @objList = $objectSet->get_list();
            if (scalar(@objList) == 1) {
                if ($term->interactive()) {
                    print("Are you sure you wish to overwrite '$name'?\n\n");
                    my $yesno = $term->get_input("Yes/No> ", "no", "yes");
                    if ($yesno ne "y" and $yesno ne "yes" ) {
                        print "No import performed\n";
                        return();
                    }
                }
                my $obj = $objList[0];
                $obj->set("checksum", $digest);
                my $script;
                open(SCRIPT, $path);
                $script = <SCRIPT>;
                if ($script ne "#!/bin/sh\n") {
                    &eprint("Only Borne shell scripts are allowed as scripts! ($script)\n");
                    close SCRIPT;
                    return();
                }
                while(my $line = <SCRIPT>) {
                    $script .= $line;
                }
                close SCRIPT;
                $db->set_data($obj->get("id"), $script);
                $db->persist($obj);
                print "Imported $name into existing object\n";
            } elsif (scalar(@objList) == 0) {
                &dprint("Creating new Script Object\n");
                my $script;
                my $obj = Warewulf::Script->new();
                $obj->set("name", $name);
                $obj->set("checksum", digest_file_hex($path, "MD5"));
                &dprint("Persisting new Script Object\n");
                $db->persist($obj);
                open(SCRIPT, $path);
                $script = <SCRIPT>;
                if ($script ne "#!/bin/sh\n") {
                    &eprint("Only Borne shell scripts are allowed as scripts! ($script)\n");
                    close SCRIPT;
                    return();
                }
                while(my $line = <SCRIPT>) {
                    $script .= $line;
                }
                close SCRIPT;
                $db->set_data($obj->get("id"), $script);
                print "Imported $name into a new object\n";
            } else {
                print "Import into one object at a time please!\n";
            }
        }
    } elsif ($opt_program) {
        if ($opt_program) {
            $objectSet = $db->get_objects($entity_type, "name", $ARGV[0]);
            my @objList = $objectSet->get_list();
            if (scalar(@objList) > 1) {
                &eprint("Only specify one object to operate on at a time\n");
                return();
            } elsif (scalar(@objList) == 0) {
                my $obj = Warewulf::Script->new();
                $obj->set("name", $ARGV[0]);
                $db->persist($obj);
                push(@objList, $obj);
            }
            my $rand = &rand_string("16");
            my $tmpfile = "/tmp/wwsh.$rand";
            my $obj = $objList[0];
            my $digest1;
            my $digest2;
            open(TMPFILE, "> $tmpfile");
            print TMPFILE $db->get_data($obj->get("id"));
            close TMPFILE;
            $digest1 = $obj->get("checksum") || "";
            $opt_program =~ s/^"(.+?)"$/$1/;
            if (system("$opt_program $tmpfile") == 0) {
                $digest2 = digest_file_hex($tmpfile, "MD5");
                if ($digest1 ne $digest2) {
                    &nprint("Updated datastore\n");

                    my $script;
                    open(SCRIPT, $tmpfile);
                    $script = <SCRIPT>;
                    if (! $script) {
                        &eprint("Script has no content!\n");
                        close SCRIPT;
                        return();
                    } elsif ($script ne "#!/bin/sh\n") {
                        &eprint("Only Borne shell scripts are allowed as scripts! ($script)\n");
                        close SCRIPT;
                        return();
                    }
                    while(my $line = <SCRIPT>) {
                        $script .= $line;
                    }
                    close SCRIPT;
                    $obj->set("checksum", $digest2);
                    $db->set_data($obj->get("id"), $script);
                    $db->persist($obj);
                } else {
                    &nprint("Not updating datastore\n");
                }
            } else {
                &eprint("Command errored out, not updating datastore\n");
            }
        } else {
            &eprint("Command is undefined\n");
        }

    } elsif ($opt_export) {
        $objectSet = $db->get_objects($entity_type, "name", &expand_bracket(@ARGV));
        my @objList = $objectSet->get_list();

        if (-d $opt_export) {
            foreach my $obj (@objList) {
                my $script = $obj->get("name");
                if (-f "$opt_export/$script" and $term->interactive()) {
                    print("Are you sure you wish to overwrite $opt_export/$script?\n\n");
                    my $yesno = $term->get_input("Yes/No> ", "no", "yes");
                    if ($yesno ne "y" and $yesno ne "yes" ) {
                        print "Skipped export of $opt_export/$script\n";
                        next;
                    }
                }
                open(SCRIPT, "> $opt_export/$script");
                print SCRIPT $db->get_data($obj->get("id"));
                close SCRIPT;
                print "Exported: $opt_export/$script\n";
            }
        } elsif (-f $opt_export) {
            if ($term->interactive()) {
                print("Are you sure you wish to overwrite $opt_export?\n\n");
                my $yesno = $term->get_input("Yes/No> ", "no", "yes");
                if ($yesno ne "y" and $yesno ne "yes" ) {
                    print "No export performed\n";
                    return();
                }
            }
            if (scalar(@objList) == 1) {
                open(SCRIPT, "> $opt_export");
                print SCRIPT $db->get_data($obj->get("id"));
                close SCRIPT;
                print "Exported: $opt_export\n";
            } else {
                &eprint("Can only export 1 script into a file, perhaps export to a directory?\n");
            }
        }
    } else {
        $objectSet = $db->get_objects($entity_type, "name", &expand_bracket(@ARGV));
        my @objList = $objectSet->get_list();
        foreach my $obj (@objList) {
            if ($opt_show) {
                my $data = $db->get_data($obj->get("id"));
                if ($data) {
                    my $name = $obj->get("name");
                    &nprintf("#### %s %s#\n", $name, "#" x (72 - length($name)));
                    print "$data";
                }
            } else {
                print $obj->get("name") ."\n";
            }
        }


    }


    # We are done with ARGV, and it was internally modified, so lets reset
    @ARGV = ();

    return($return_count);
}


1;
