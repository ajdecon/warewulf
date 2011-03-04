#
# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#



package Warewulf::Module::Cli::Initramfs;

use Warewulf::Include;
use Warewulf::Config;
use Warewulf::Logger;
use Warewulf::Util;
use Warewulf::Provision::Tftp;
use Getopt::Long;
use File::Path;
use File::Basename;

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
    my ($self, @args) = @_;

    my $rpm;
    my $kversion;
    my $modules;
    my $depmod_map_arg = "";
    my $randstring = &rand_string("12");
    my $tmpdir = "/var/tmp/wwinitrd.$randstring";
    my $initramfsdir = &wwconfig("statedir") ."/warewulf/initramfs/";
    my $initramfsdefault = "base";
    my $config = Warewulf::Config->new("provision.conf");
    my $tftpboot = Warewulf::Provision::Tftp->new()->tftpdir();

    if (! &uid_test(0)) {
        &eprint("This command can only be run by the superuser!\n");
        return();
    }

    @ARGV = @args;

    GetOptions(
        'r|rpm=s'    => \$rpm,
    );

    my $name = shift(@ARGV);

    &dprint("Checking for initramfs name\n");
    if (! $name) {
        &eprint("What is the name of the initramfs image you want to create?\n");
        return();
    } elsif ($name =~ /^(a-zA-Z0-9_\-\.]+)$/) {
        &dprint("Got bootstrap name: $name\n");
        $name = $1;
    } else {
        &eprint("Ileagle characters in initramfs name\n");
        return();
    }

    &dprint("Checking for tftpboot sanity\n");
    if ($tftpboot =~ /^([a-zA-Z0-9_\-\/\.]+)$/) {
        $tftpboot = $1;
    }

    &dprint("Checking for tftpboot directory name for bootstrap name '$name'\n");
    if (! -d "$tftpboot/warewulf/bootstrap/$name") {
        mkpath("$tftpboot/warewulf/bootstrap/$name");
    }

    &dprint("Building list of drivers to include from configuration file\n");
    foreach my $m ($config->get("drivers")) {
        if ($m =~ /^([a-zA-Z0-9\/\*_\-]+)/) {
            $modules .= "$1 ";
        }
    }

    &dprint("Checking for base Warewulf initramfs archive\n");
    if (! -f "$initramfsdir/$initramfsdefault") {
        die "Could not locate the Warewulf CPIO archive at: $initramfsdir/$initramfsdefault!\n";
    }

    &dprint("Check for depmod option to create mapfiles\n");
    open(DEPMOD, "/sbin/depmod --help 2>&1 |");
    while (my $line = <DEPMOD>) {
        chomp $line;
        if ( $line =~ /^\s*-m\s+/ ) {
            $depmod_map_arg = "-m";
            &nprint("Will use the \"-m\" option to depmod to trigger map file generation\n");
        }
    }
    close DEPMOD;

    &dprint("Check to see what format of kernel we are working with\n");
    if ($rpm) {
        &dprint("Using RPM\n");
        if ($rpm =~ /^([\/\.\-_a-zA-Z0-9]+\.rpm)$/) {
            $rpm = $1;
            my $kversion;
            &dprint("creating temporary directory at: $tmpdir\n");
            mkpath($tmpdir);
            chdir($tmpdir);
            &nprint("Extracting the kernel modules\n");
            system("rpm2cpio $rpm | cpio --quiet -id $modules");
            foreach my $dir (glob("$tmpdir/lib/modules/*")) {
                if (-d $dir) {
                    $kversion = basename($dir);
                    last;
                }
            }
            if ($kversion =~ /^([0-9_\.]+\-[a-zA-Z0-9_\..]+)$/) {
                my $kversion_safe = $1;
                system("/sbin/depmod $depmod_map_arg -a -b $tmpdir $kversion_safe");
                foreach my $module ($config->get("capabilities")) {
                    &dprint("Searching to include module: $module\n");
                    if ($module =~ /^([a-zA-Z0-9\.\_-]+)$/) {
                        $module = $1;
                        my $file = "$initramfsdir/$module";
                        if (-f $file) {
                            &nprint("Including capability: $module\n");
                            system("cd $tmpdir; cpio -i -u --quiet < $file");
                        } else {
                            &dprint("Defined module not found: $module\n");
                        }
                    }
                }
                my $tmpinitramfs = "$tftpboot/warewulf/bootstrap/$name/initfs";
                system("cp $initramfsdir/$initramfsdefault $tmpinitramfs");
                &nprint("Finding and cleaning duplicate files\n");
                open(LIST, "cpio -it --quiet < $tmpinitramfs |");
                while(my $file = <LIST>) {
                    chomp($file);
                    if (-f "$tmpdir/$file") {
                        dprint "Removing redundant file: $file\n";
                        if ($file =~ /^([a-zA-Z0-9_\-\.\/]+)$/ ) {
                            unlink("$tmpdir/$1");
                        }
                    }
                }
                close LIST;
                system("cd $tmpdir; find . | cpio -o --quiet -H newc -A -F $tmpinitramfs");
                &nprint("Compressing the initramfs\n");
                system("gzip -f -9 $tmpinitramfs");
                system("rm -rf $tmpdir/*");
                &nprint("Extracting the kernel object\n");
                system("rpm2cpio $rpm | (cd $tmpdir; cpio --quiet -id */boot/vmlinuz-*)");
                system("cp $tmpdir/boot/vmlinuz-* $tftpboot/warewulf/bootstrap/$name/kernel");
                system("rm -rf $tmpdir");
            }
        }
    } else {
        &eprint("This command only understands RPM files at the moment\n");
    }

    @ARGV = ();
}



1;






