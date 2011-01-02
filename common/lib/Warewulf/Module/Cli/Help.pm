

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
    my ($self, $keyword, $target) = @_;
    my $modules = Warewulf::ModuleLoader->new("Cli");
    my %keywords;
    my $summary;

    foreach my $mod (sort $modules->list()) {
        my $module_name = ref($mod);
        foreach my $key ($mod->keywords) {
            if ($mod->help($key)) {
                $keywords{"$key"}{"$module_name"} = $mod->help($key);
            }
        }
    }

    if ($target) {
        if (exists($keywords{"$target"})) {
            foreach my $module_name (sort keys %{$keywords{"$target"}}) {
                if (exists($keywords{"$target"}{"$module_name"})) {
                    &iprint("   $module_name\n");
                    &nprint($keywords{"$target"}{"$module_name"});
                }
            }
        }
    } else {
        $summary .= "Warewulf command line shell interface\n";
        $summary .= "\n";
        $summary .= "   Welcome to the Warewulf shell interface. This application allows you\n";
        $summary .= "   to interface to the Warewulf backend database, modules, and interfaces\n";
        $summary .= "   via a single shell interface.\n";
        $summary .= "\n";
        print $summary;

        foreach my $key (sort keys %keywords) {
            print "   $key\n";
            foreach my $module_name (sort keys %{$keywords{"$key"}}) {
                if (exists($keywords{"$key"}{"$module_name"})) {
                    &iprint("     $module_name\n");
                    &nprint($keywords{"$key"}{"$module_name"});
                }
            }
        }
    }
}


1;
