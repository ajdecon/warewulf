

package Warewulf::Module::Cli::Debug_Level;

use Warewulf::Logger;

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
    my $self = shift;
    my $keyword = shift;
    my $debug_level = uc(shift);

    if ($debug_level) {
        &nprint("Setting debug level to: $debug_level\n");
        &set_log_level($debug_level);
    }
}



1;
