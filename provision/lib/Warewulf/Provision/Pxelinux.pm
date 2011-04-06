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
use Warewulf::Include;
use Warewulf::Provision::Tftp;
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
    my $self = {};

    bless($self, $class);

    return $self->init(@_);
}

sub
init()
{
    my $self = shift;


    return($self);
}


=item setup()

Setup the basic pxelinux environment (e.g. gpxelinux.0).

=cut
sub
setup()
{
    my $self = shift;
    my $datadir = &wwconfig("datadir");
    my $tftpdir = Warewulf::Provision::Tftp->new()->tftpdir();

    if ($tftpdir) {
        if (! -f "$tftpdir/warewulf/gpxelinux.0") {
            if (-f "$datadir/warewulf/gpxelinux.0") {
                &iprint("Copying gpxelinux.0 to the appropriate directory\n");
                mkpath("$tftpdir/warewulf/");
                system("cp $datadir/warewulf/gpxelinux.0 $tftpdir/warewulf/gpxelinux.0");
            } else {
                &eprint("Could not locate Warewulf's internal gpxelinux.0! Go find one!\n");
            }
        }
    } else {
        &wprint("Not integrating with TFTP, no TFTP root directory was found.\n");
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
    my $tftproot = Warewulf::Provision::Tftp->new()->tftpdir();

    if (! $tftproot) {
        &dprint("Not updating Pxelinux because no TFTP root directory was found!\n");
        return();
    }

    foreach my $nodeobj (@nodeobjs) {
        my $name = $nodeobj->get("name") || "undefined";
        my ($bootstrap) = $nodeobj->get("bootstrap");
        my @append = $nodeobj->get("append");
        my @masters = $nodeobj->get("master");
        my @hwaddrs = $nodeobj->get("hwaddr");

        &dprint("Creating a pxelinux config for node '$name'\n");

        if ($bootstrap and @hwaddrs) {

            if (! -d "$tftproot/warewulf/pxelinux.cfg") {
                &iprint("Creating pxelinux configuration directory: $tftproot/warewulf/pxelinux.cfg");
                mkpath("$tftproot/warewulf/pxelinux.cfg");
            }

            foreach my $hwaddr (@hwaddrs) {
                if ($hwaddr =~ /^([0-9a-zA-Z:]+)$/) {
                    $hwaddr = $1;
                    &iprint("Building Pxelinux configuration for: $name/$hwaddr\n");
                    $hwaddr =~ s/:/-/g;
                    my $config = "01-". $hwaddr;
                    &dprint("Creating pxelinux config at: $tftproot/warewulf/pxelinux.cfg/$config\n");
                    open(PXELINUX, "> $tftproot/warewulf/pxelinux.cfg/$config");
                    print PXELINUX "DEFAULT bootstrap\n";
                    print PXELINUX "LABEL bootstrap\n";
                    print PXELINUX "SAY Now booting Warewulf bootstrap image: $bootstrap\n";
                    print PXELINUX "KERNEL bootstrap/$bootstrap/kernel\n";
                    print PXELINUX "APPEND ro initrd=bootstrap/$bootstrap/initfs.gz ";
                    if (scalar(@masters) > 1) {
                        my $master = join(",", @masters);
                        print PXELINUX "wwmaster=$master ";
                    }
                    if (@append) {
                        print PXELINUX join(" ", @append);
                    } else {
                        print PXELINUX "quiet";
                    }
                    print PXELINUX "\n";
                    if (! close PXELINUX) {
                        &eprint("Could not write Pxelinux configuration file: $!\n");
                    }
                } else {
                    &eprint("Bad characters in hwaddr: $hwaddr\n");
                }
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
    my $tftproot = Warewulf::Provision::Tftp->new()->tftpdir();

    if (! $tftpboot) {
        &dprint("Not updating Pxelinux because no TFTP root directory was found!\n");
        return();
    }

    foreach my $nodeobj (@nodeobjs) {
        my $name = $nodeobj->get("name") || "undefined";
        my @hwaddrs = $nodeobj->get("hwaddr");

        &dprint("Deleting pxelinux entries for node: $name\n");

        foreach my $hwaddr (@hwaddrs) {
            if ($hwaddr =~ /^([0-9a-zA-Z:]+)$/) {
                $hwaddr = $1;
                &iprint("Deleting Pxelinux configuration for: $name/$hwaddr\n");
                $hwaddr =~ s/:/-/g;
                my $config = "01-". $hwaddr;
                if (-f "$tftproot/pxelinux.cfg/$config") {
                    unlink("$tftproot/pxelinux.cfg/$config");
                }
            } else {
                &eprint("Bad characters in hwaddr: $hwaddr\n");
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
