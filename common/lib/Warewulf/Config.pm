
package Warewulf::Config;

use Warewulf::Include;
use Warewulf::Debug;
use Warewulf::Logger;
use Warewulf::Util;
use Text::ParseWords;

use Exporter;

our @ISA = ('Exporter');

our @EXPORT = qw (
);

=head1 NAME

Warewulf::Config - Object interface to configuration paramaters

=head1 ABOUT

The Warewulf::Config class allows one to access configuration paramaters
with as an object interface.

=head1 SYNOPSIS

    use Warewulf::Config;

    my $obj = Warewulf::Config->new();

    foreach my $entry ( $obj->get("config entry name") ) {
        print "->$entry<-\n";
    }

=head1 FORMAT

The configuration file format utilizes key value pairs seperated by an
equal ('=') sign. There maybe multiple key value pairs as well as comma
delimated value entries.

Line continuations are allowed as long as the previous line entry ends
with a backslash.

    key value = entry one, entry two, "entry two,a"
    key value = entry three, \
    entry four

Will yield the following values:

    entry one
    entry two
    entry two,a
    entry three
    entry four


=head1 METHODS

=over 12
=cut


=item new([path to config])

The new constructor will create the object that references configuration the
stores. You can pass a list of configuration files that will be included in
the object if desired.

Some configuration files will automatically be included in the following
order:

    /etc/warewulf/[program name].conf
    /etc/warewulf/main.conf

(assumg that warewulf was built with --sysconfdir=/etc/)

=cut
sub
new($$)
{
    my $proto               = shift;
    my @files               = @_;
    my $class               = ref($proto) || $proto;
    my $self                = ();
    my $main_config         = $Warewulf::Include::path{"SYSCONFDIR"} . "/warewulf/main.conf";
    my $progname_config     = $Warewulf::Include::path{"SYSCONFDIR"} . "/warewulf/" . $Warewulf::Include::info{"PROGNAME"} . ".conf";

    %{$self} = ();

    # Load up default configuration files
    if ( ! grep($_ eq $main_config, @{$self->{"FILE"}}) ) {
        push(@{$self->{"FILE"}}, $main_config);
    }
    if ( ! grep($_ eq $progname_config, @{$self->{"FILE"}}) ) {
        push(@{$self->{"FILE"}}, $progname_config);
    }

    if ( @files ) {
        push(@{$self->{"FILE"}}, @files);
    }

    bless($self, $class);

    $self->reread();

    return($self);
}

=item read

This will cause the configuration files to be reread.

=cut
sub
reread($)
{
    my $self                = shift;
    my @lines               = ();
    my %hash                = ();

    $self->{"STREAM"}       = ();

    foreach my $file ( @{$self->{"FILE"}} ) {
        dprint("Looking for config file: $file\n");
        if ( -f $file ) {
            open(FILE, $file);
            while(my $line = <FILE>) {
                push(@{$self->{"STREAM"}}, $line);
            }
            close FILE;
            nprint("Reading config file: $file\n");
        } else {
            dprint("Config file not found: $file\n");
        }
    }

    return();
}

=item get(config key)

This will read from the configuration object and return the values of the key
specified. If this method is called in a scalar context it will return the
first match found. Otherwise it will return an array of all matches.

=cut
sub
get($$)
{
    my $self                = shift;
    my $key                 = shift;
    my @values              = ();
    my $string              = ();

    if ( $key ) {
        my $cont;
        foreach my $line ( @{ $self->{"STREAM"} } ) {
            chomp $line;
            $line =~ s/^\s*#.*$//;
            $line =~ s/\s+$//;
            next if ! $line;
            if ( $line =~ /^\s*(.+?)\s*=\s*(.*?)(\\)$/ ) {
                if ( $1 eq $key ) {
                    if ( $string ) {
                        $string .= ",";
                    }
                    $string .= $2;
                    $cont = 1;
                }
            } elsif ( $line =~ /^\s*(.+?)\s*=\s*(.*)$/ ) {
                if ( $1 eq $key ) {
                    if ( $string ) {
                        $string .= ",";
                    }
                    $string .= $2;
                    $cont = ();
                }
            } elsif ( $cont ) {
                if ( $line =~ /^(.*?)\\$/ ) {
                    $string .= $1;
                    $cont = 1;
                } else {
                    $string .= $line;
                    $cont = ();
                }
            }
        }
    } else {
        return();
    }

    my @f = &parse_line(',\s*', 0, $string);
    push(@values, @f);

    if ( wantarray ) {
        return(@values);
    } else {
        return($values[0]);
    }
}

=back

=head1 SEE ALSO

Warewulf

=cut


1;
