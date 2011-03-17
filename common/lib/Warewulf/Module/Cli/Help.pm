

package Warewulf::Module::Cli::Help;

use Warewulf::Logger;
use Warewulf::ModuleLoader;

our @ISA = ('Warewulf::Module::Cli');


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
complete()
{
    my $modules = Warewulf::ModuleLoader->new("Cli");
    my @ret;

    foreach my $mod ($modules->list()) {
        push(@ret, $mod->keyword());
    }

    return(@ret);
}

sub
exec()
{
    my ($self, $target) = @_;
    my $modules = Warewulf::ModuleLoader->new("Cli");
    my %keywords;
    my $summary;

    if ($target) {
        my %usage;
        my $printed;
        my $options_printed;
        my $examples_printed;
        &dprint("Gathering help topics for: $target\n");
        foreach my $mod (sort $modules->list($target)) {
            my $ref = ref($mod);
            &dprint("Calling on module: $mod\n");
            if ($mod->can("description")) {
                &iprint("$ref:\n");
                my $description = $mod->description();
                chomp($description);
                &dprint("Calling $mod->description()\n");
                print $description ."\n\n";
                $printed = 1;
            } elsif ($mod->can("help")) {
                &iprint("$ref:\n");
                my $help = $mod->help();
                chomp($help);
                &dprint("Calling $mod->help()\n");
                print $help ."\n\n";
                $printed = 1;
            }
        }
        foreach my $mod (sort $modules->list($target)) {
            &dprint("Calling on module: $mod\n");
            if ($mod->can("options")) {
                if (! $options_printed) {
                    print "OPTIONS:\n";
                    $options_printed = 1;
                }
                my $ref = ref($mod);
                &iprint("  ($ref)\n");
                &dprint("Calling $mod->options()\n");
                my %tmp = $mod->options();
                foreach my $key (sort keys %tmp) {
                    printf("  %-17s %s\n", $key, $tmp{$key});
                }
                $printed = 1;
            }
        }
        foreach my $mod (sort $modules->list($target)) {
            &dprint("Calling on module: $mod\n");
            if ($mod->can("examples")) {
                if (! $examples_printed) {
                    print "\nEXAMPLES:\n";
                    $examples_printed = 1;
                }
                &dprint("Calling $mod->example()\n");
                foreach my $example ($mod->examples()) {
                    chomp $example;
                    print "  Warewulf> $example\n";
                    $printed = 1;
                }
            }
        }
        if ($printed) {
            print "\n";
        } else {
            print "This module has no help methods defined\n";
        }
    } else {
        my $last_keyword = "";
        print "Warewulf command line shell interface\n";
        print "\n";
        print "Welcome to the Warewulf shell interface. This application allows you\n";
        print "to interface to the Warewulf backend database, modules, and interfaces\n";
        print "via a single shell interface.\n";
        print "\n";

        foreach my $mod (sort $modules->list()) {
            if ($mod->can("summary")) {
                if ($mod->summary()) {
                    my $keyword = $mod->keyword();
                    if ($keyword eq $last_keyword) {
                        printf "  %-17s", "";
                    } else {
                        printf "  %-17s", $mod->keyword();
                        $last_keyword = $keyword;
                    }
                    print $mod->summary();
                }
                print "\n";
            }
        }
        print "\n";
    }
}


1;
