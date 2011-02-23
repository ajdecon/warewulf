#
# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#



package Warewulf::Module::Cli::BootStrap;

use Warewulf::Include;
use Warewulf::Config;
use Warewulf::Logger;
use Warewulf::Util;
use Getopt::Long;
use File::Path;

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
    my $tftpboot = $config->get("tftpdir") || "/tftpboot";

    if (! &uid_test(0)) {
        &eprint("This command can only be run by the superuser!\n");
        return();
    }

    @ARGV = @args;

    GetOptions(
        'r|rpm'      => \$rpm,
    );

    my $name = shift(@ARGV);

    if (! $name) {
        &eprint("What is the name of the bootstrap image you want to create?\n");
    }

    if ($tftpboot =~ /^([a-zA-Z0-9_\-\/\.]+)$/) {
        $tftpboot = $1;
    }

    if (! -d "$tftpboot/warewulf/$name") {
        mkpath("$tftpboot/warewulf/$name");
    }

    foreach my $m ($config->get("drivers")) {
        if ($m =~ /^([a-zA-Z0-9\/\*_\-]+)/) {
            $modules .= "$1 ";
        }
    }

    if (! -f "$initramfsdir/$initramfsdefault") {
        die "Could not locate the Warewulf CPIO archive at: $initramfsdir/$initramfsdefault!\n";
    }

    # Check for depmod option for map files
    open(DEPMOD, "/sbin/depmod --help 2>&1 |");
    while (my $line = <DEPMOD>) {
        chomp $line;
        if ( $line =~ /^\s*-m\s+/ ) {
            $depmod_map_arg = "-m";
            &nprint("Will use the \"-m\" option to depmod to trigger map file generation\n");
        }
    }
    close DEPMOD;

    if ($rpm) {
        $rpm = $ARGV[0];
        if ($ARGV[0] =~ /^([\/\.\-_a-zA-Z0-9]+\.rpm)$/) {
            $rpm = $1;
            if (-f $rpm) {
                open(RPM, "rpm -qp --qf '%{version}-%{release}' $rpm 2>/dev/null |");
                $kversion = <RPM>;
                close RPM;
            }
            if ($kversion =~ /^([0-9_\.]+\-[a-zA-Z0-9_\..]+)$/) {
                my $kversion_safe = $1;
                &dprint("creating temporary directory at: $tmpdir\n");
                mkpath($tmpdir);
                &nprint("Extracting the kernel modules\n");
                system("rpm2cpio $rpm | (cd $tmpdir; cpio --quiet -id $modules)");
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
                system("cp $tmpdir/boot/vmlinuz-* $tftpboot/warewulf/$name/kernel");
                system("rm -rf $tmpdir");
            }
        }
    } else {
        &eprint("This command only understands RPM files at the moment\n");
    }

    @ARGV = ();
}



1;






