# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#
#
# $Id: Pxelinux.pm 50 2010-11-02 01:15:57Z gmk $
#

package Warewulf::Provision::Pxelinux;

use Warewulf::Config;
use Warewulf::Logger;
use Warewulf::Object;
use File::Path;

our @ISA = ('Warewulf::Object');

=head1 NAME

Warewulf::Pxelinux - Pxelinux integration

=head1 ABOUT


=head1 SYNOPSIS

    use Warewulf::Pxelinux;

    my $obj = Warewulf::Pxelinux->new();
    $obj->update($NodeObj);

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
    my $self = ();

    $self = {};

    bless($self, $class);

    return $self->init(@_);
}


sub
init()
{
    my $self = shift;
    my $config = Warewulf::Config->new("provision.conf");
    my $tftpboot = $config->get("tftpboot") || "/tftpboot";

    if ($tftpboot =~ /^([a-zA-Z0-9_\-\/\.]+)$/) {
        $self->{"TFTPROOT"} = $1;
    } else {
        &eprint("Invalid tftpboot directory configuration! ($tftpboot)\n");
    }

    return($self);
}


=item update(@nodeobjects)

Update or create (if not already present) a pxelinux config for the passed
node object

=cut
sub
update()
{
    my ($self, @nodeobjs) = @_;

    foreach my $nodeobj (@nodeobjs) {
        my $name = $nodeobj->get("name") || "undefined";
        my ($bootstrap) = $nodeobj->get("bootstrap");
        my ($append) = $nodeobj->get("append");
        my @masters = $nodeobj->get("master");
        my @hwaddrs = $nodeobj->get("hwaddr");
        my $tftproot = $self->{"TFTPROOT"};

        &dprint("Creating a pxelinux config for node '$name'\n");

        if ($bootstrap and @hwaddrs) {

            if (! -d "$tftproot/pxelinux.cfg") {
                &iprint("Creating pxelinux configuration directory: $tftproot/pxelinux.cfg");
                mkpath("$tftproot/pxelinux.cfg");
            }

            foreach my $hwaddr (@hwaddrs) {
                &iprint("Creating a Pxelinux configuration for: $name/$hwaddr\n");
                my $config = $hwaddr;
                $config =~ s/:/-/g;
                &dprint("Creating pxelinux config at: $tftproot/pxelinux.cfg/$config\n");
                open(PXELINUX, "> $tftproot/pxelinux.cfg/$config");
                print PXELINUX "DEFAULT bootstrap\n";
                print PXELINUX "LABEL bootstrap\n";
                print PXELINUX "SAY Now booting Warewulf bootstrap: $bootstrap\n";
                print PXELINUX "KERNEL /warewulf/$bootstrap/kernel\n";
                print PXELINUX "APPEND ro initrd=/warewulf/$bootstrap/bootstrap ";
                if (@masters) {
                    my $master = join(",", @masters);
                    print PXELINUX "wwmaster=$master ";
                }
                print PXELINUX "quiet\n";
            }
        } else {
            &dprint("Need more object information to create a pxelinux config file for this node\n");
        }
    }
}


=item delete(@nodeobjects)

Delete a pxelinux configuration for the passed node object.

=cut
sub
delete()
{
    my ($self, @nodeobjs) = @_;

    foreach my $nodeobj (@nodeobjs) {
        my $name = $nodeobj->get("name") || "undefined";
        my @hwaddrs = $nodeobj->get("hwaddr");
        my $tftproot = $self->{"TFTPROOT"};

        &dprint("Deleting pxelinux entries for node: $name\n");

        foreach my $hwaddr (@hwaddrs) {
            &iprint("Deleting Pxelinux configuration for: $name/$hwaddr\n");
            my $config = $hwaddr;
            $config =~ s/:/-/g;
            if (-f "$tftproot/pxelinux.cfg/$config") {
                unlink("$tftproot/pxelinux.cfg/$config");
            }
        }
    }
}

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
