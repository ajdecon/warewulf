# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#
#
# $Id: Term.pm 50 2010-11-02 01:15:57Z mej $
#

package Warewulf::Term;

use Warewulf::Object;
use Warewulf::Logger;
use File::Basename;
use File::Path;
use Term::ReadLine;

our @ISA = ('Warewulf::Object');
my $singleton;

=head1 NAME

Warewulf::Term - Warewulf's general object instance object interface.

=head1 ABOUT


=head1 SYNOPSIS

    use Warewulf::Term;

    my $obj = Warewulf::Term->new();


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
        $singleton->{"ATTRIBS"} = $singleton->{"TERM"}->Attribs;

        $singleton->{"TERM"}->ornaments(0);
        $singleton->{"TERM"}->MinLine(undef);

        $singleton->{"ATTRIBS"}->{completion_function} = \&auto_complete;

        if ( -t STDIN && -t STDOUT ) {
            $singleton->{"INTERACTIVE"} = "1";
        } else {
            $singleton->{"INTERACTIVE"} = undef;
        }

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
    my $dir;
    
    if ($file) {
        $dir = dirname($file);
    }

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

=item auto_complete()

auto_complete internal static function

=cut
sub
auto_complete()
{
    my ($text, $line, $start) = @_;
    my $self = $singleton;
    my @ret;


    if (exists($self->{"ARRAY"})) {
        push(@ret, @{$self->{"ARRAY"}});
    } elsif ($line =~ /^\s*([^ ]+)\s+/) {
        my $keyword = $1;
        if (exists($self->{"COMPLETE"}{"$keyword"})) {
            foreach my $ref (@{$self->{"COMPLETE"}{"$keyword"}}) {
                push(@ret, $ref->complete("$line"));
            }
        }
    } elsif (exists($self->{"COMPLETE"})) {
        foreach my $keyword (sort keys %{$self->{"COMPLETE"}}) {
            push(@ret, $keyword);
        }
    }

    return(@ret);
}


=item complete($keyword, $objecthandler)

Pass a keyword and an object handler to be called on tab completion

=cut
sub
complete()
{
    my ($self, $keyword, $object) = @_;

    &dprint("Adding keyword '$keyword' to complete\n");

    if ($keyword and $object) {
        push(@{$self->{"COMPLETE"}{"$keyword"}}, $object);
    }
}



=item interactive($is_interactive)

Test to see if the terminal is interactive. If you pass a "1" or "0" to it you
can override the default behavior and make it so that it will return true or
false for subsequent calls (respectively).

=cut
sub
interactive($)
{
    my ($self, $interactive) = @_;

    if (defined($interactive)) {
        if ($interactive eq "1") {
            $self->{"INTERACTIVE"} = 1;
        } elsif ($interactive eq "0") {
            $self->{"INTERACTIVE"} = undef;
        }
    }

    return($self->{"INTERACTIVE"});
}


=item get_input($prompt, $array_ref_of_completions)

Get input from the user. If the array of potential completions are given then
the first entry will be considered the default.

=cut
sub
get_input($)
{
    my ($self, $prompt, @completions) = @_;
    my $attribs = $self->{"TERM"}->Attribs;
    my $ret;

    if ($self->interactive) {

        if (@completions) {
            @{$self->{"ARRAY"}} = @completions;
        }
        $ret = $self->{"TERM"}->readline($prompt);
        if (@completions) {
            delete($self->{"ARRAY"});
        }

        if (! $ret and exists($completions[0])) {
            $ret = $completions[0];
        }

        if ($ret) {
            $ret =~ s/^\s+//;
            $ret =~ s/\s+$//;
        }
    } else {
        $ret = $completions[0];
    }

    return($ret);
}


## Initial tests
#my $obj = Warewulf::Term->new();
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
