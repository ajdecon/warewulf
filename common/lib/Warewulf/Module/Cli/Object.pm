#
# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#




package Warewulf::Module::Cli::Object;

use Warewulf::Logger;
use Warewulf::Module::Cli;
use Warewulf::Term;
use Warewulf::DataStore;
use Warewulf::Util;
use Getopt::Long;
use Text::ParseWords;

our @ISA = ('Warewulf::Module::Cli');

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
    $h .= "     The object command provides an interface for generically manipulating all\n";
    $h .= "     object types within the Warewulf datastore.\n";
    $h .= "\n";
    $h .= "OPTIONS:\n";
    $h .= "\n";
    $h .= "     -l, --lookup    How should we reference this node? (default is name)\n";
    $h .= "     -t, --type      By what type of object should we be limited\n";
    $h .= "     -p, --print     Define what fields are printed (':all' is a special tag)\n";
    $h .= "     -s, --set       Set a given attribute\n";
    $h .= "     -a, --add       Add an attribute to an existing key (otherwise create the key)\n";
    $h .= "     -d, --del       Delete an attribute from a key\n";
    $h .= "         --DELETE    Delete an entire object\n";
    $h .= "\n";
    $h .= "EXAMPLES:\n";
    $h .= "\n";
    $h .= "     Warewulf> object -p id,name,type\n";
    $h .= "\n";

    return($h);
}


sub
summary()
{
    my $output;

    $output .= "Generically manipulate all Warewulf datastore entries";

    return($output);
}


sub
complete()
{
    my $self = shift;
    my $opt_lookup = "name";
    my $db = $self->{"DB"};
    my $opt_type;
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
        't|type=s'      => \$opt_type,
    );

    @ARGV = ();

    return($db->get_lookups($opt_type, $opt_lookup));
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
    push(@ARGV, &quotewords('\s+', 1, @_));

    Getopt::Long::Configure ("bundling", "nopassthrough");

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
    } elsif (scalar(@opt_print) > 0) {
        @opt_print = split(",", join(",", @opt_print));
    } else {
        @opt_print = ("name", "_type");
    }

    if ($opt_new) {
        if ($opt_type) {
            &dprint("Creating a new object of type: $opt_type\n");
            if (@ARGV) {
                foreach my $string (&expand_bracket(@ARGV)) {
                    &dprint("New object known by: $opt_lookup=$string\n");
                    my $obj = Warewulf::DSOFactory->new($opt_type);

                    if ($obj) {
                        $obj->set($opt_lookup, $string);
                        foreach my $setstring (@opt_set) {
                            my ($key, $val) = split(/=/, $setstring);
                            $obj->set($key, $val);
                        }

                        $db->persist($obj);
                        &nprint("Created new '$opt_type' object ($opt_lookup=$string)\n");
                    } else {
                        &eprint("Could not create an object of type: $opt_type\n");
                    }
                }
            } else {
                &dprint("Creating a blank object\n");
                my $obj = Warewulf::DSOFactory->new($opt_type);
                if ($obj) {
                    $db->persist($obj);
                    &nprint("Created new blank '$opt_type' object\n");
                }
            }
        } else {
            &eprint("What type of object would you like to create? (use the --type option)\n");
        }
    } else {

        my $objectSet = $db->get_objects($opt_type, $opt_lookup, &expand_bracket(@ARGV));

        my @objList = $objectSet->get_list();

        if (@objList) {
            if (@opt_print) {

                if (@opt_print and scalar @opt_print > 1 and $opt_print[0] ne ":all") {
                    my $string = sprintf("%-26s " x (scalar @opt_print), map {uc($_);} @opt_print);
                    &nprint($string ."\n");
                    &nprint("=" x length($string) ."\n");
                }

                foreach my $o ($objectSet->get_list()) {
                    if (@opt_print and $opt_print[0] eq ":all") {
                        my %hash = $o->get_hash();
                        my $id = $o->get("_id");
                        my $name = $o->get("name");
                        &nprintf("#### %s %s#\n", $name, "#" x (72 - length($name)));
                        foreach my $h (keys %hash) {
                            if(ref($hash{$h}) =~ /^ARRAY/) {
                                my @scalars;
                                foreach my $e (@{$hash{$h}}) {
                                    if (ref($e) =~ /^Warewulf::DSO::([a-zA-Z0-9\-_]+)/) {
                                        my $type = lc($1);
                                        my @s;
                                        foreach my $l ($e->lookups()) {
                                            if (my $string = $e->get($l)) {
                                                push(@s, $l ."=". $string);
                                            }
                                        }
                                        push(@scalars, $type ."(". join(",", @s) .")");
                                    } else {
                                        push(@scalars, $e);
                                    }
                                }
                                if (scalar(@scalars) > 0) {
                                    if ($h =~ /^_/) {
                                        &iprintf("%8s: %-10s = %s\n", $id, $h, join(",", sort @scalars));
                                    } else {
                                        printf("%8s: %-10s = %s\n", $id, $h, join(",", sort @scalars));
                                    }
                                }
                            } else {
                                if (ref($e) =~ /^Warewulf::DSO::([a-zA-Z0-9\-_]+)/) {
                                    my @scalars;
                                    my $type = lc($1);
                                    my @s;
                                    foreach my $l ($e->lookups()) {
                                        if (my $string = $e->get($l)) {
                                            push(@s, $l ."=". $string);
                                        }
                                    }
                                    if ($h =~ /^_/) {
                                        &iprintf("%8s: %-10s = %s\n", $id, $h, $type ."(". join(",", @s) .")");
                                    } else {
                                        printf("%8s: %-10s = %s\n", $id, $h, $type ."(". join(",", @s) .")");
                                    }
                                } else {
                                    if ($h =~ /^_/) {
                                        &iprintf("%8s: %-10s = %s\n", $id, $h, $hash{$h});
                                    } else {
                                        printf("%8s: %-10s = %s\n", $id, $h, $hash{$h});
                                    }
                                }
                            }
                        }
                    } else {
                        my @values;
                        foreach my $h (@opt_print) {
                            if (my $val = $o->get($h)) {
                                if(ref($val) =~ /^ARRAY/) {
                                    my @scalars;
                                    foreach my $e (@{$val}) {
                                        if (ref($e) =~ /^Warewulf::DSO::([a-zA-Z0-9\-_]+)/) {
                                            my $type = lc($1);
                                            my @s;
                                            foreach my $l ($e->lookups()) {
                                                if (my $string = $e->get($l)) {
                                                    push(@s, $l ."=". $string);
                                                }
                                            }
                                            push(@scalars, $type ."(". join(",", @s) .")");
                                        } else {
                                            push(@scalars, $e);
                                        }
                                    }
                                    if (scalar(@scalars) > 0) {
                                        push(@values, join(",", sort @scalars));
                                    } else {
                                        push(@values, "UNDEF");
                                    }
                                } else {
                                    if (ref($e) =~ /^Warewulf::DSO::([a-zA-Z0-9\-_]+)/) {
                                        my @scalars;
                                        my $type = lc($1);
                                        my @s;
                                        foreach my $l ($e->lookups()) {
                                            if (my $string = $e->get($l)) {
                                                push(@s, $l ."=". $string);
                                            }
                                        }
                                        push(@values, $type ."(". join(",", @s) .")");
                                    } else {
                                        push(@values, $val);
                                    }
                                }
                            } else {
                                push(@values, "UNDEF");
                            }
                        }
                        printf("%-26s " x (scalar @values) ."\n", @values);
                    }
                }
            }

            if ($opt_obj_delete) {
    
                if ($term->interactive()) {
                    print "\nAre you sure you wish to delete the above objects?\n\n";
                    my $yesno = lc($term->get_input("Yes/No> ", "no", "yes"));
                    if ($yesno ne "y" and $yesno ne "yes") {
                        &nprint("No update performed\n");
                        return();
                    }
                } else {
                    &nprint("Deleting the above objects\n");
                }

                $return_count = $db->del_object($objectSet);

                &nprint("Deleted $return_count objects\n");

            } elsif ((scalar @opt_set) > 0 or (scalar @opt_del) > 0 or (scalar @opt_add) > 0) {

                my $persist_bool;

                if (scalar(@objList) eq 1) {
                    print "\nAre you sure you wish to make the following changes to 1 object?\n\n";
                } else {
                    print "\nAre you sure you wish to make the following changes to ". scalar(@objList) ." objects?\n\n";
                }
                foreach my $setstring (@opt_set) {
                    my ($key, @vals) = &quotewords('=', 1, $setstring);
                    printf(" set: %15s = %s\n", $key, join("=", @vals));
                }
                foreach my $setstring (@opt_add) {
                    my ($key, @vals) = &quotewords('=', 1, $setstring);
                    foreach my $val (&quotewords(',', 0, join("=", @vals))) {
                        printf(" add: %15s = %s\n", $key, $val);
                    }
                }
                foreach my $setstring (@opt_del) {
                    my ($key, @vals) = &quotewords('=', 1, $setstring);
                    if (@vals) {
                        foreach my $val (&quotewords(',', 0, join("=", @vals))) {
                            printf(" delete: %12s = %s\n", $key, $val);
                        }
                    } else {
                        printf(" undefine: %10s = [ALL]\n", $key);
                    }
                }

                if ($term->interactive()) {
                    my $yesno;
                    do {
                        $yesno = lc($term->get_input("Yes/No> ", "no", "yes"));
                    } while (! $yesno);

                    if ($yesno ne "y" and $yesno ne "yes" ) {
                        &nprint("No update performed\n");
                        return();
                    }
                } else {
                    print "Yes/No> (running non-interactively, defaulting to yes)\n";
                }

                if (@opt_set) {
                    foreach my $setstring (@opt_set) {
                        my ($key, @vals) = &quotewords('=', 1, $setstring);
                        if ($key =~ /^_/) {
                            &eprint("Can not manipulate private object key\n");
                        } else {
                            &dprint("Set: setting $key to ". join("=", @vals) ."\n");
                            foreach my $obj (@objList) {
                                $obj->set($key, &quotewords(',', 0, join("=", @vals)));
                            }
                            $persist_bool = 1;
                        }
                    }
                }

                if (@opt_add) {
                    foreach my $setstring (@opt_add) {
                        my ($key, @vals) = &quotewords('=', 1, $setstring);
                        if ($key =~ /^_/) {
                            &eprint("Can not manipulate private object key\n");
                        } else {
                            foreach my $val (&quotewords(',', 0, join("=", @vals))) {
                                &dprint("Set: adding $key to $val\n");
                                foreach my $obj (@objList) {
                                    $obj->add($key, split(",", $val));
                                }
                                $persist_bool = 1;
                            }
                        }
                    }

                }

                if (@opt_del) {
                    foreach my $setstring (@opt_del) {
                        my ($key, @vals) = &quotewords('=', 1, $setstring);
                        if ($key =~ /^_/) {
                            &eprint("Can not manipulate private object key\n");
                        } else {
                            if ($key and @vals) {
                                foreach my $val (&quotewords(',', 0, join("=", @vals))) {
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
