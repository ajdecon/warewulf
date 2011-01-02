

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


sub
complete()
{
    my ($self, $keyword) = @_;

    if ($keyword =~ /^debug_level /) {
        return("notice", "info", "debug");
    }

}

sub
help()
{
    my ($self) = @_;
    my $output;

    $output .= "        This will set the default debugging/logging level for this shell. Valid\n";
    $output .= "        options include:\n";
    $output .= "\n";
    $output .= "            notice:     Only show normal usage messages\n";
    $output .= "            info:       Display increased verbosity\n";
    $output .= "            debug:      Debugging output\n";
    $output .= "\n";

    return($output);
}


1;
