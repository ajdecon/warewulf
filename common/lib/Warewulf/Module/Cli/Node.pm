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
options()
{
    my %hash;

    $hash{"-n, --new"} = "Create a new object with the given name";
    $hash{"-p, --print"} = "Define what fields are printed (':all' is a special tag)";
    $hash{"    --DELETE"} = "Delete an entire object";

    return(%hash);
}

sub
description()
{
    my $output;

    $output .= "Hello from nodes.";

    return($output);
}

sub
summary()
{
    my $output;

    $output .= "Node manipulation commands";

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

    Getopt::Long::Configure ("bundling");

    GetOptions(
        'l|lookup=s'    => \$opt_lookup,
    );

    @ARGV = ();

    return($db->get_lookups($entity_type, $opt_lookup));
}

sub
exec()
{
    my $self = shift;
    my $db = $self->{"DB"};
    my $term = Warewulf::Term->new();
    my $opt_new;
    my $opt_obj_delete;
    my $opt_help;
    my @opt_print;
    my $return_count;

    @ARGV = ();
    push(@ARGV, @_);

    GetOptions(
        'n|new'         => \$opt_new,
        'p|print=s'     => \@opt_print,
        'DELETE'        => \$opt_obj_delete,
        'h|help'        => \$opt_help,
    );

    if (! $db) {
        &eprint("Database object not avaialble!\n");
        return();
    }

    if ($opt_new) {
        foreach my $string (&expand_bracket(@ARGV)) {
            my $obj;
            $obj = Warewulf::DSOFactory->new($entity_type);

            $obj->set("name", $string);

            $db->persist($obj);
        }
    }

    if (@opt_print) {
        if (scalar(@opt_print) > 0) {
            @opt_print = split(",", join(",", @opt_print));
        }
        my $objectSet = $db->get_objects($opt_type || $entity_type, $opt_lookup, &expand_bracket(@ARGV));
        my @objList = $objectSet->get_list();

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
                        push(@values, $o->get($g) || "UNDEF");
                    }
                }
                &nprintf("%-20s " x (scalar @values) ."\n", @values);
            }
        }
    }

    # We are done with ARGV, and it was internally modified, so lets reset
    @ARGV = ();

    return($return_count);
}


1;
