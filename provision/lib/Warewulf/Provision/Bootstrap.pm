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

use Warewulf::ACVars;
use Warewulf::Config;
use Warewulf::Logger;
use Warewulf::Object;
use Warewulf::DataStore;
use Warewulf::Util;
use Warewulf::Provision::Tftp;
use File::Path;
use File::Basename;

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

=item delete_bootstrap()

Remove a bootable bootstrap image from the local file system.

=cut

sub
delete_bootstrap()
{
    my ($self, $bootstrapObj) = @_;

    if ($bootstrapObj) {
        my $bootstrap_name = $bootstrapObj->get("name");
        my $bootstrap_id = $bootstrapObj->get("_id");

        if ($bootstrap_id =~ /^([0-9]+)$/) {
            my $id = $1;
            my $tftpboot = Warewulf::Provision::Tftp->new()->tftpdir();
            my $bootstrapdir = "$tftpboot/warewulf/bootstrap/$bootstrap_id/";

            &nprint("Deleting local bootable bootstrap files: $bootstrap_name\n");

            if (-f "$bootstrapdir/initfs") {
                if (unlink("$bootstrapdir/initfs")) {
                    &iprint("Removed file: $bootstrapdir/initfs\n");
                } else {
                    &eprint("Could not remove file: $bootstrapdir/initfs\n");
                }
            }
            if (-f "$bootstrapdir/kernel") {
                if (unlink("$bootstrapdir/kernel")) {
                    &iprint("Removed file: $bootstrapdir/kernel\n");
                } else {
                    &eprint("Could not remove file: $bootstrapdir/kernel\n");
                }
            }
            if (-f "$bootstrapdir/cookie") {
                if (unlink("$bootstrapdir/cookie")) {
                    &iprint("Removed file: $bootstrapdir/cookie\n");
                } else {
                    &eprint("Could not remove file: $bootstrapdir/cookie\n");
                }
            }
            if (-d "$bootstrapdir") {
                if (unlink("$bootstrapdir")) {
                    &iprint("Removed directory: $bootstrapdir\n");
                } else {
                    &eprint("Could not remove directory: $bootstrapdir\n");
                }
            }
            
        }
    }
}

=item build_bootstrap()

Write the bootstrap image to the TFTP directory. This does more then just pull
it out of the data store and dump it to a file. It also merges it with the
appropriate Warewulf initrd userspace components for the provision master in
question.

=cut

sub
build_bootstrap()
{
    my ($self, $bootstrapObj) = @_;

    if ($bootstrapObj) {
        my $bootstrap_name = $bootstrapObj->get("name");
        my $bootstrap_id = $bootstrapObj->get("_id");

        if (!$bootstrap_name) {
            &dprint("Skipping build_bootstrap() as the name is undefined\n");
            return();
        }

        if ($bootstrap_id =~ /^([0-9]+)$/) {
            my $id = $1;
            my $ds = Warewulf::DataStore->new();
            my $tftpboot = Warewulf::Provision::Tftp->new()->tftpdir();
            my $initramfsdir = &Warewulf::ACVars::get("statedir") . "/warewulf/initramfs/";
            my $randstring = &rand_string("12");
            my $tmpdir = "/var/tmp/wwinitrd.$randstring";
            my $binstore = $ds->binstore($bootstrapObj->get("_id"));
            my $bootstrapdir = "$tftpboot/warewulf/bootstrap/$bootstrap_id/";
            my $initramfs = "$initramfsdir/initfs";

            &nprint("Integrating the Warewulf bootstrap: $bootstrap_name\n");

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

            foreach my $path (glob($initramfsdir . "/capabilities/*")) {
                if ($path =~ /^([a-zA-Z0-9\.\_\-\/]+)$/) {
                    my $file = $1;
                    my $module = basename($file);
                    &nprint("Including capability: $module\n");
                    system("cd $tmpdir/initramfs; cpio -i -u --quiet < $file");
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
        } else {
            &dprint("Bootstrap ID is invalid\n");
        }
    } else {
        &dprint("Bootstrap object is undefined\n");
    }

}




1;
