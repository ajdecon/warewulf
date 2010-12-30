



package Warewulf::Module::Cli::DB;

use Warewulf::Logger;
use Warewulf::Module::Cli;
use Getopt::Long;
use Text::ParseWords;

our @ISA = ('Warewulf::Module::Cli');

Getopt::Long::Configure ("bundling");


sub
new()
{
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};

    bless($self, $class);

    return $self;
}

sub
keyword() {
    my $self = shift;
    my $keyword = shift;

    if ($keyword =~ /^(node|vnfs)$/) {
        return(1);
    }
    return();
}

sub
keywords()
{
    return(qw(node vnfs));
}


sub
exec()
{
    my $self = shift;
    my $opt_type = shift;
    my $opt_new;
    my @opt_set;
    my @opt_add;
    my @opt_del;
    my $opt_obj_delete;
    my $opt_help;
    my $opt_lookup = "name";
    my @opt_print;
    my $db = $self->datastore();

    if (my $first_string = shift) {
        # Sometimes all arguments are passed as a single scalar
        @ARGV = &quotewords('\s+', 1, $first_string);
    }
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
    );

    if (! $db) {
        &eprint("Database object not avaialble!\n");
    }

    if (! $opt_type) {
        &eprint("Error on opt_type=$opt_type\n");
    }

    if (! @opt_print) {
        push(@opt_print, "name");
    } else {
        @opt_print = split(",", join(",", @opt_print));
    }

    if ($opt_new) {

        if ($opt_type) {

            foreach my $string (@ARGV) {
                my $obj;
                $obj = Warewulf::ObjectFactory->new($opt_type);

                $obj->set($opt_lookup, $string);
                foreach my $setstring (@opt_set) {
                    my ($key, $val) = split(/=/, $setstring);
                    $obj->set($key, $val);
                }

                $db->persist($obj);
            }
        } else {
            &eprint("You must provide a type of object to add\n");
        }
    } else {
        my $objectSet;

        $objectSet = $db->get_objects($opt_type, $opt_lookup, &quotewords('\s+', 1, @ARGV));

        my @objList = $objectSet->get_list();

        if (@objList) {

            if (@opt_set) {

                    foreach my $setstring (@opt_set) {

                    if ($setstring =~ /^(.+?)\s*\+=\s*(.+)$/) {
                        my $key = $1;
                        my $val = $2;
                        foreach my $obj (@objList) {
                            &dprint("Set: adding $val to $key\n");
                            $obj->add($key, split(",", $val));
                        }
                        push(@opt_print, $key);
                    } elsif ($setstring =~ /^(.+?)\s*\-=\s*(.+)$/) {
                        my $key = $1;
                        my $val = $2;
                        foreach my $obj (@objList) {
                            &dprint("Set: deleting $val from $key\n");
                            $obj->del($key, split(",", $val));
                        }
                        push(@opt_print, $key);
                    } elsif ($setstring =~ /^(.+?)\s*=\s*(.+)$/) {
                        my $key = $1;
                        my $val = $2;
                        foreach my $obj (@objList) {
                            &dprint("Set: setting $key to $val\n");
                            $obj->set($key, split(",", $val));
                        }
                        push(@opt_print, $key);
                    } else {
                        &eprint("Invalid syntax on set command\n");
                    }
                }
                my $count = $db->persist($objectSet);

                print "Updated $count objects\n";

            } elsif (@opt_add) {

                foreach my $obj (@objList) {
                    foreach my $setstring (@opt_add) {
                        my ($key, $val) = &quotewords('=', 0, $setstring);
                        &dprint("Set: adding $val to $key\n");
                        $obj->add($key, split(",", $val));
                    }
                }
                my $count = $db->persist($objectSet);

                print "Updated $count objects\n";

            } elsif (@opt_del) {

                foreach my $obj (@objList) {
                    foreach my $setstring (@opt_del) {
                        my ($key, $val) = &quotewords('=', 0, $setstring);
                        if ($val) {
                            &dprint("Set: deleting $val from $key\n");
                            $obj->del($key, $val);
                        } else {
                            &dprint("Set: deleting $key\n");
                            $obj->del($key);
                        }
                    }
                }
                my $count = $db->persist($objectSet);

                print "Updated $count objects\n";

            } elsif ($opt_obj_delete) {

                my $count = $db->del_object($objectSet);

                print "Deleted $count objects\n";

            }

            if (@opt_print) {

                if (@opt_print and scalar @opt_print > 1 and $opt_print[0] ne "all") {
                    printf("%-20s " x (scalar @opt_print) ."\n", map {uc($_);}@opt_print);
                }
                foreach my $o ($objectSet->get_list()) {
                    my @values;
                    if (@opt_print and $opt_print[0] eq "all") {
                        my %hash = $o->get_hash();
                        my $id = $o->get("id");
                        foreach my $h (keys %hash) {
                            if(ref($hash{$h}) =~ /^ARRAY/) {
#                                print "$id: $h=\"". join(",", @{$hash{$h}}) ."\"\n";
                                printf("%8s: %-10s = %s\n", $id, $h, join(",", @{$hash{$h}}));
                            } else {
#                                print "$id: $h=\"$hash{$h}\"\n";
                                printf("%8s: %-10s = %s\n", $id, $h, $hash{$h});
                            }
                        }
                    } else {
                        foreach my $g (@opt_print) {
                            if(ref($o->get($g)) =~ /^ARRAY/) {
                                push(@values, join(",", $o->get($g)));
                            } else {
                                push(@values, $o->get($g) || "[undef]");
                            }
                        }
                        printf("%-20s " x (scalar @values) ."\n", @values);
                    }
                }
            }
        } else {
            &nprint("No objects found.\n");
        }
    }

}


1;
