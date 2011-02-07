#
# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#




package Warewulf::Module::Cli::Node;

use Warewulf::Logger;
use Warewulf::Module::Cli;
use Warewulf::Term;
use Warewulf::DataStore;
use Warewulf::Util;
use Getopt::Long;
use Text::ParseWords;

our @ISA = ('Warewulf::Module::Cli');

Getopt::Long::Configure ("bundling");

my $entity_type = "node";

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

    $output .= "        Hello nodes...\n";
    $output .= "           Usage options:\n";
    $output .= "            -l, --lookup           Lookup objects using a given string type (default: name)\n";
    $output .= "            -n, --new              Create a new object with the given name\n";
    $output .= "            -p, --print            Define what fields are printed (':all' is a special tag)\n";
    $output .= "            -s, --set              Set a given attribute (e.g. -s key=value)\n";
    $output .= "            -a, --add              Add an attribute to a key (-a key=value2)\n";
    $output .= "            -d, --del              Delete an attribute from a key (-d key=value)\n";
    $output .= "                --DELETE           Delete an entire object\n";

    return($output);
}

sub
complete()
{
    my ($self, $text) = @_;
    my $opt_lookup = "name";
    my $db = $self->{"DB"};
    my $opt_null;
    my @ret;

    if (! $db) {
        return();
    }

    foreach (&quotewords('\s+', 0, $text)) {
        if ($_) {
            push(@ARGV, $_);
        }
    }

    GetOptions(
        'l|lookup=s'    => \$opt_lookup,
    );

    if ($opt_lookup) {
        my $objectSet = $db->get_objects($entity_type);

        my @objList = $objectSet->get_list();

        foreach my $o (@objList) {
            my $string = $o->get($opt_lookup);
            if ($string) {
                if (ref($string) =~ /^ARRAY/) {
                    push(@ret, @{$string});
                } else {
                    push(@ret, $string);
                }
            }
        }
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
    my $opt_new;
    my $opt_type;
    my @opt_set;
    my @opt_add;
    my @opt_del;
    my $opt_obj_delete;
    my $opt_help;
    my @opt_print;
    my $return_count;

    @ARGV = ();
    push(@ARGV, @_);

    GetOptions(
        'n|new'         => \$opt_new,
        'p|print=s'     => \@opt_print,
        's|set=s'       => \@opt_set,
        'a|add=s'       => \@opt_add,
        'd|del=s'       => \@opt_del,
        'l|lookup=s'    => \$opt_lookup,
        'DELETE'        => \$opt_obj_delete,
        'h|help'        => \$opt_help,
        't|type=s'      => \$opt_type,
    );

    if (! $db) {
        &eprint("Database object not avaialble!\n");
        return();
    }

    if ((scalar @opt_set) > 0 or (scalar @opt_del) > 0 or (scalar @opt_add) > 0) {
        if ($term->interactive()) {
            my %modifiers;
            my @mod_print;
            @opt_print = ("name");
            foreach my $setstring (@opt_set, @opt_add, @opt_del) {
                if ($setstring =~ /^([^=]+)/) {
                    if (!exists($modifiers{"$1"})) {
                        push(@mod_print, $1);
                        $modifiers{"$1"} = 1;
                    }
                }
            }
            push(@opt_print, @mod_print);
        }
    } elsif (scalar(@opt_print) > 0) {
        @opt_print = split(",", join(",", @opt_print));
    } else {
        @opt_print = ("name");
    }

    if ($opt_new) {
        foreach my $string (@ARGV) {
            my $obj;
            $obj = Warewulf::DSOFactory->new($entity_type);

            $obj->set($opt_lookup, $string);
            foreach my $setstring (@opt_set) {
                my ($key, $val) = split(/=/, $setstring);
                $obj->set($key, $val);
            }

            $db->persist($obj);
        }
    } else {
        my $objectSet = $db->get_objects($opt_type || $entity_type, $opt_lookup, &expand_bracket(@ARGV));

        my @objList = $objectSet->get_list();

        if (@objList) {
            if (@opt_print) {

                if (@opt_print and scalar @opt_print > 1 and $opt_print[0] ne ":all") {
                    &nprintf("%-20s " x (scalar @opt_print) ."\n", map {uc($_);}@opt_print);
                }
                foreach my $o ($objectSet->get_list()) {
                    my @values;
                    if (@opt_print and $opt_print[0] eq ":all") {
                        my %hash = $o->get_hash();
                        my $id = $o->get("id");
                        my $name = $o->get("name");
                        &nprintf("#### %s %s#\n", $name, "#" x (72 - length($name)));
                        foreach my $h (keys %hash) {
                            if(ref($hash{$h}) =~ /^ARRAY/) {
                                &nprintf("%8s: %-10s = %s\n", $id, $h, join(",", sort @{$hash{$h}}));
                            } else {
                                &nprintf("%8s: %-10s = %s\n", $id, $h, $hash{$h});
                            }
                        }
                    } else {
                        foreach my $g (@opt_print) {
                            if(ref($o->get($g)) =~ /^ARRAY/) {
                                push(@values, join(",", sort $o->get($g)));
                            } else {
                                push(@values, $o->get($g) || "NULL");
                            }
                        }
                        &nprintf("%-20s " x (scalar @values) ."\n", @values);
                    }
                }
            }

            if ($opt_obj_delete) {

                if ($term->interactive()) {
                    print("\nAre you sure you wish to delete the above nodes?\n\n");
                    my $yesno = $term->get_input("Yes/No> ", "no", "yes");
                    if ($yesno ne "y" and $yesno ne "yes" ) {
                        print "No update performed\n";
                        return();
                    }
                }

                $return_count = $db->del_object($objectSet);

                &nprint("Deleted $return_count objects\n");

            } elsif ((scalar @opt_set) > 0 or (scalar @opt_del) > 0 or (scalar @opt_add) > 0) {

                my $persist_bool;

                if ($term->interactive()) {
                    if (scalar(@objList) eq 1) {
                        print("\nAre you sure you wish to make the following changes to 1 node?\n\n");
                    } else {
                        print("\nAre you sure you wish to make the following changes to ". scalar(@objList) ." nodes?\n\n");
                    }
                    foreach my $setstring (@opt_set) {
                        my ($key, $vals) = &quotewords('=', 1, $setstring);
                        printf(" set: %15s = %s\n", $key, $vals);
                    }
                    foreach my $setstring (@opt_add) {
                        my ($key, $vals) = &quotewords('=', 1, $setstring);
                        foreach my $val (&quotewords(',', 0, $vals)) {
                            printf(" add: %15s = %s\n", $key, $val);
                        }
                    }
                    foreach my $setstring (@opt_del) {
                        my ($key, $vals) = &quotewords('=', 1, $setstring);
                        if ($vals) {
                            foreach my $val (&quotewords(',', 0, $vals)) {
                                printf(" delete: %12s = %s\n", $key, $val);
                            }
                        } else {
                            printf(" undefine: %10s = [ALL]\n", $key);
                        }
                    }

                    my $yesno = $term->get_input("Yes/No> ", "no", "yes");

                    if ($yesno ne "y" and $yesno ne "yes" ) {
                        print "No update performed\n";
                        return();
                    }
                }

                if (@opt_set) {

                    foreach my $setstring (@opt_set) {
                        my ($key, $vals) = &quotewords('=', 1, $setstring);
                        &dprint("Set: setting $key to $vals\n");
                        foreach my $obj (@objList) {
                            $obj->set($key, &quotewords(',', 0, $vals));
                        }
                        $persist_bool = 1;
                    }
                }
                if (@opt_add) {

                    foreach my $setstring (@opt_add) {
                        my ($key, $vals) = &quotewords('=', 1, $setstring);
                        foreach my $val (&quotewords(',', 0, $vals)) {
                            &dprint("Set: adding $key to $val\n");
                            foreach my $obj (@objList) {
                                $obj->add($key, split(",", $val));
                            }
                            $persist_bool = 1;
                        }
                    }

                }
                if (@opt_del) {

                    foreach my $setstring (@opt_del) {
                        my ($key, $vals) = &quotewords('=', 1, $setstring);
                        if ($key and $vals) {
                            foreach my $val (&quotewords(',', 0, $vals)) {
                                &dprint("Set: deleting $val from $key\n");
                                foreach my $obj (@objList) {
                                    $obj->del($key, split(",", $val));
                                }
                                $persist_bool = 1;
                            }
                        } elsif ($key) {
                            &dprint("Set: deleting $key\n");
                            foreach my $obj (@objList) {
                                $obj->del($key);
                            }
                            $persist_bool = 1;
                        }
                    }

                }

                if ($persist_bool) {
                    $return_count = $db->persist($objectSet);

                    &iprint("Updated $return_count objects\n");
                }

            }

        } else {
            &wprint("No objects found.\n");
        }
    }

    # We are done with ARGV, and it was internally modified, so lets reset
    @ARGV = ();

    return($return_count);
}


1;
