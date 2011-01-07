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
    my $opt_obj_delete;

    @ARGV = ();
    push(@ARGV, @_);

    GetOptions(
        'i|import=s'    => \$opt_import,
        'e|export=s'    => \$opt_export,
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
                print "Imported $name into existing object\n";
            } elsif (scalar(@objList) == 0) {
                &dprint("Creating new Script Object\n");
                my $script;
                my $obj = Warewulf::Script->new();
                $obj->set("name", $name);
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
            print $obj->get("name") ."\n";
        }


    }


    # We are done with ARGV, and it was internally modified, so lets reset
    @ARGV = ();

    return($return_count);
}


1;
