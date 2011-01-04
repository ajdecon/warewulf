

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
exec()
{
    my ($self, $target) = @_;
    my $modules = Warewulf::ModuleLoader->new("Cli");
    my %keywords;
    my $summary;

    $summary .= "Warewulf command line shell interface\n";
    $summary .= "\n";
    $summary .= "   Welcome to the Warewulf shell interface. This application allows you\n";
    $summary .= "   to interface to the Warewulf backend database, modules, and interfaces\n";
    $summary .= "   via a single shell interface.\n";
    $summary .= "\n";
    print $summary;

    foreach my $mod (sort $modules->list($target)) {
        if ($mod->can("help")) {
            print "  ". $mod->keyword() ."\n";
            print $mod->help();
        }
    }
}


1;
