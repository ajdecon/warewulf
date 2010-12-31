# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#
#
# $Id: Cli.pm 50 2010-11-02 01:15:57Z mej $
#

package Warewulf::Cli;

use Warewulf::Object;
use File::Basename;
use File::Path;
use Term::ReadLine;

our @ISA = ('Warewulf::Object');
my $singleton;

=head1 NAME

Warewulf::Cli - Warewulf's general object instance object interface.

=head1 ABOUT


=head1 SYNOPSIS

    use Warewulf::Cli;

    my $obj = Warewulf::Cli->new();


=head1 METHODS

=over 12
=cut


=item new()

The new constructor will create the object that references configuration the
stores.

=cut
sub
new($$)
{
    my $proto = shift;
    my $class = ref($proto) || $proto;

    if (! $singleton) {
        $singleton = {};
        $singleton->{"TERM"} = Term::ReadLine->new("Warewulf");

        $singleton->{"TERM"}->ornaments(0);
        $singleton->{"TERM"}->MinLine(undef);

        bless($singleton, $class);
    }

    return $singleton;
}

=item history_load($filename)

Read and initilize terminal with previous history

=cut
sub
history_load()
{
    my ($self, $file) = @_;
    my $dir = dirname($file);
    
    if ($file) {
        if (! -d $dir) {
            mkpath($dir);
        }
        $self->{"TERM"}->ReadHistory($file);
        $self->{"HISTFILE"} = $file;
    }

    return();
}


=item history_save([$filename])

Save history to file. If a filename is passed, it will use that, otherwise it
will automatically save to the same file name that was used when initalized
with history_load().

=cut
sub
history_save()
{
    my ($self, $file) = @_;
    my $dir = dirname($file);

    if (exists($self->{"TERM"})) {
        $self->{"TERM"}->StifleHistory(1000);

        if ($file) {
            if (! -d $dir) {
                mkpath($dir);
            }
            $self->{"TERM"}->WriteHistory($file);
        } elsif (exists($self->{"HISTFILE"})) {
            $self->{"TERM"}->WriteHistory($self->{"HISTFILE"});
        }
    }

    return();
}


=item history_add()

Add a string to the history

=cut
sub
history_add($)
{
    my ($self, $set) = @_;

    if ($set) {
        $self->{"TERM"}->AddHistory($set);
    }

    return($set);
}


=item complete($keyword, $funcref)

Pass a keyword and a function reference to be called on tab completion

=cut
sub
complete()
{
    my ($self, $keyword, $func) = @_;
    my $attribs = $self->{"TERM"}->Attribs;

    $attribs->{completion_function} = \&auto_complete;

    if ($keyword) {
        push(@{$self->{"COMPLETE"}{"$keyword"}}, $func || undef);
    }
}


=item auto_complete()

auto_complete internal static function

=cut
sub
auto_complete()
{
    my ($text, $line, $start) = @_;
    my $self = $singleton;
    my @ret;

    if ($line =~ /^\s*([^ ]+)\s+/) {
        my $keyword = $1;
        if (exists($self->{"COMPLETE"}{"$keyword"})) {
            foreach my $ref (@{$self->{"COMPLETE"}{"$keyword"}}) {
                push(@ret, &$ref("$keyword"));
            }
        }
    } elsif (exists($self->{"COMPLETE"})) {
        foreach my $keyword (sort keys %{$self->{"COMPLETE"}}) {
            push(@ret, $keyword);
        }
    }

    return(@ret);
}


=item interactive()

Test to see if the terminal is interactive.

=cut
sub
interactive($)
{
    my ($self) = @_;

    if ( -t STDIN && -t STDOUT ) {
        return(1);
    } else {
        return();
    }
}


=item get_input($prompt, $array_ref_of_completions)

Get input from the user. If the array of potential completions are given then
the first entry will be considered the default.

=cut
sub
get_input($)
{
    my ($self, $prompt, $completions) = @_;
    my $attribs = $self->{"TERM"}->Attribs;
    my $ret;

    $attribs->{completion_entry_function} = $attribs->{list_completion_function};
    $attribs->{completion_word} = $completions;

    $ret = $self->{"TERM"}->readline($prompt);

    $attribs->{completion_entry_function} = undef;
    $attribs->{completion_word} = undef;

    if (! $ret and exists($completions->[0])) {
        $ret = $completions->[0];
    }

    return($ret);
}


## Initial tests
#my $obj = Warewulf::Cli->new();
#
#$obj->history_add("Hello World");
#my $out = $obj->get_input("Hello World: ", ["yes", "no", "hello"]);
#
#print "->$out<-\n";
#


=back

=head1 SEE ALSO

Warewulf::Object

=head1 COPYRIGHT

Copyright (c) 2001-2003 Gregory M. Kurtzer

Copyright (c) 2003-2011, The Regents of the University of California,
through Lawrence Berkeley National Laboratory (subject to receipt of any
required approvals from the U.S. Dept. of Energy).  All rights reserved.

=cut


1;
