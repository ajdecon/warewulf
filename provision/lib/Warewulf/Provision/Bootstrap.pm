# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#
#
# $Id: Bootstrap.pm 50 2010-11-02 01:15:57Z gmk $
#

package Warewulf::Provision::Bootstrap;

use Warewulf::Config;
use Warewulf::Logger;
use Warewulf::Object;
use Warewulf::DataStore;
use Warewulf::DSOFactory;
use Warewulf::Include;
use Warewulf::Util;
use Warewulf::Provision::Tftp;
use File::Path;

our @ISA = ('Warewulf::Object');

=head1 NAME

Warewulf::Bootstrap - Bootstrap integration

=head1 ABOUT


=head1 SYNOPSIS

    use Warewulf::Bootstrap;

    my $obj = Warewulf::Bootstrap->new();
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

sub
build_bootstrap()
{
    my ($self, $bootstrapObj) = @_;

    if ($bootstrapObj) {
        my $bootstrap_name = $bootstrapObj->get("name");
        my $bootstrap_id = $bootstrapObj->get("_id");

        if ($bootstrap_id =~ /^([0-9]+)$/) {
            &nprint("Building bootstrap: $bootstrap_name\n");
            my $id = $1;
            my $ds = Warewulf::DataStore->new();
            my $config = Warewulf::Config->new("bootstrap.conf");
            my $tftpboot = Warewulf::Provision::Tftp->new()->tftpdir();
            my $initramfsdir = &wwconfig("statedir") ."/warewulf/initramfs/";
            my $randstring = &rand_string("12");
            my $tmpdir = "/var/tmp/wwinitrd.$randstring";
            my $binstore = $ds->binstore($bootstrapObj->get("_id"));
            my $bootstrapdir = "$tftpboot/warewulf/bootstrap/$bootstrap_id/";
            my $initramfs = "$initramfsdir/initfs";

            if (-f "$bootstrapdir/cookie") {
                open(COOKIE, "$bootstrapdir/cookie");
                chomp (my $cookie = <COOKIE>);
                close COOKIE;
                if ($cookie eq $bootstrapObj->get("checksum")) {
# Lets not return yet, because we don't have a way to force it yet...
#                    return;
                }
            }

            mkpath($tmpdir);
            mkpath($bootstrapdir);
            chdir($tmpdir);
            
            open(CPIO, "| gunzip | cpio -id --quiet");
            while(my $buffer = $binstore->get_chunk()) {
                print CPIO $buffer;
            }
            close CPIO;

            foreach my $module ($config->get("capabilities")) {
                if ($module =~ /^([a-zA-Z0-9\.\_-]+)$/) {
                    $module = $1;
                    my $file = "$initramfsdir/$module";
                    &dprint("Searching to include module: $initramfsdir/$module\n");
                    if (-f $file) {
                        &nprint("Including capability: $module\n");
                        system("cd $tmpdir/initramfs; cpio -i -u --quiet < $file");
                    } else {
                        &dprint("Defined module not found: $module\n");
                    }
                }
            }
            if (-f "$initramfsdir/base") {
                system("cd $tmpdir/initramfs; cpio -i -u --quiet < $initramfsdir/base");
            } else {
                &eprint("Could not locate the Warewulf bootstrap 'base' capability\n");
            }


            system("cd $tmpdir/initramfs; find . | cpio -o --quiet -H newc -F $bootstrapdir/initfs");
            &nprint("Compressing the initramfs\n");
            system("gzip -f -9 $bootstrapdir/initfs");
            &nprint("Locating the kernel object\n");
            system("cp $tmpdir/kernel $bootstrapdir/kernel");
            system("rm -rf $tmpdir");
            open(COOKIE, "> $bootstrapdir/cookie");
            print COOKIE $bootstrapObj->get("checksum");
            close COOKIE;
            &nprint("Bootstrap image '$bootstrap_name' is ready\n");

        }
    }

}




1;
