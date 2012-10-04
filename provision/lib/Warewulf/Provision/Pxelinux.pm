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

use Warewulf::ACVars;
use Warewulf::Config;
use Warewulf::Logger;
use Warewulf::Object;
use Warewulf::Network;
use Warewulf::DataStore;
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
    my $datadir = &Warewulf::ACVars::get("datadir");
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
        if (! -f "$tftpdir/warewulf/chain.c32") {
            if (-f "$datadir/warewulf/chain.c32") {
                &iprint("Copying chain.c32 to the appropriate directory\n");
                mkpath("$tftpdir/warewulf/");
                system("cp $datadir/warewulf/chain.c32 $tftpdir/warewulf/chain.c32");
            } else {
                &eprint("Could not locate Warewulf's internal chain.c32! Go find one!\n");
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
    my $netobj = Warewulf::Network->new();
    my $db = Warewulf::DataStore->new();
    my $config = Warewulf::Config->new("provision.conf");
    my $devname = $config->get("network device");
    my $master_ipaddr = $netobj->ipaddr($devname);

    if (! $master_ipaddr) {
        &wprint("Could not generate PXE configurations, check 'network device' configuration!\n");
        return undef;
    }



    &dprint("Updating PXE configuration files now\n");

    if (! $tftproot) {
        &dprint("Not updating Pxelinux because no TFTP root directory was found!\n");
        return();
    }

    if (! -d "$tftproot/warewulf/pxelinux.cfg") {
        &iprint("Creating pxelinux configuration directory: $tftproot/warewulf/pxelinux.cfg");
        mkpath("$tftproot/warewulf/pxelinux.cfg");
    }

    foreach my $nodeobj (@nodeobjs) {
        my $hostname = $nodeobj->name() || "undef";
        my $nodename = $nodeobj->nodename() || "undef";
        my $bootstrapid = $nodeobj->get("bootstrapid");
        my @kargs = $nodeobj->get("kargs");
        my @masters = $nodeobj->get("master");
        my $bootstrapname;

        &dprint("Evaluating node $nodename\n");

        if ($bootstrapid) {
            my $bootstrapObj = $db->get_objects("bootstrap", "_id", $bootstrapid)->get_object(0);
            if ($bootstrapObj) {
                $bootstrapname = $bootstrapObj->name();
            } else {
                &wprint("Defined bootstrap is not valid for node $nodename, skipping...\n");
                next;
            }
        } else {
            &dprint("No bootstrap defined for node $nodename, skipping...\n");
            next;
        }


        foreach my $devname (sort($nodeobj->netdevs_list())) {
            my $hwaddr = $nodeobj->hwaddr($devname);
            my $ipv4_addr = $nodeobj->ipaddr($devname);
            my $netmask = $nodeobj->netmask($devname);
            my $gateway = $nodeobj->gateway($devname);
            my $hwprefix = "01";

            if (! $devname) {
                &iprint("Skipping unknown device name for: $nodename\n");
                next;
            }

            if (! $hwaddr) {
                &iprint("Skipping $nodename-$devname: No hwaddr defined\n");
                next;
            }

            if ($hwaddr =~ /(([0-9a-f]{2}:){7}[0-9a-f]{2})$/) {
                $hwprefix = "20";
            }

            &dprint("Creating a pxelinux config for node '$nodename-$devname/$hwaddr'\n");

            if ($hwaddr =~ /^([0-9a-zA-Z:]+)$/) {
                $hwaddr = $1;
                &iprint("Building Pxelinux configuration for: $nodename/$hwaddr\n");
                $hwaddr =~ s/:/-/g;
                my $config = $hwprefix ."-". $hwaddr;

                if (! $bootstrapid) {
                    &iprint("Skipping $nodename-$devname-$hwaddr: No bootstrap defined\n");
                    if (-f "$tftproot/warewulf/pxelinux.cfg/$config") {
                        # If we know gotten this far, but not going to write a config, we
                        # can remove it.
                        unlink("$tftproot/warewulf/pxelinux.cfg/$config");
                    }
                    next;
                }

                &dprint("Creating pxelinux config at: $tftproot/warewulf/pxelinux.cfg/$config\n");
                if (!open(PXELINUX, "> $tftproot/warewulf/pxelinux.cfg/$config")) {
                    &eprint("Could not open PXELinux config: $!\n");
                    next;
                }
                print PXELINUX "# Configuration for Warewulf node: $hostname\n";
                if ($nodeobj->get("bootlocal")) {
                    print PXELINUX "DEFAULT bootlocal\n";
                } else {
                    print PXELINUX "DEFAULT bootstrap\n";
                }
                print PXELINUX "LABEL bootlocal\n";
                print PXELINUX "KERNEL chain.c32\n";
                print PXELINUX "APPEND hd0\n";

                print PXELINUX "LABEL bootstrap\n";
                print PXELINUX "SAY Now booting $hostname with Warewulf bootstrap ($bootstrapname)\n";
                print PXELINUX "KERNEL bootstrap/$bootstrapid/kernel\n";
                print PXELINUX "APPEND ro initrd=bootstrap/$bootstrapid/initfs.gz ";
                if (@kargs) {
                    print PXELINUX join(" ", @kargs) . " ";
                } else {
                    print PXELINUX "quiet ";
                }
                if (scalar(@masters) > 0) {
                    my $master = join(",", @masters);
                    print PXELINUX "wwmaster=$master ";
                } else {
                    print PXELINUX "wwmaster=$master_ipaddr ";
                }
                if ($devname and $ipv4_addr and $netmask) {
                    print PXELINUX "wwipaddr=$ipv4_addr wwnetmask=$netmask wwnetdev=$devname ";
                } else {
                    &dprint("Skipping static network definition because configuration not complete\n");
                }
                if ($gateway) {
                    print PXELINUX "wwgateway=$gateway ";
                } else {
                    &dprint("Skipping static gateway configuration as it is unconfigured\n");
                }
                print PXELINUX "\n";
                if (! close PXELINUX) {
                    &eprint("Could not write Pxelinux configuration file: $!\n");
                }
            } else {
                &eprint("Node: $nodename-$devname: Bad characters in hwaddr: '$hwaddr'\n");
            }
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
        my $nodename = $nodeobj->get("name") || "undefined";
        my @hwaddrs = $nodeobj->get("_hwaddr");

        &dprint("Deleting pxelinux entries for node: $nodename\n");

        foreach my $netdev ($nodeobj->get("netdevs")) {
            my $hwaddr = $netdev->get("hwaddr");
            if ($hwaddr =~ /^([0-9a-zA-Z:]+)$/) {
                $hwaddr = $1;
                &iprint("Deleting Pxelinux configuration for: $nodename/$hwaddr\n");
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
