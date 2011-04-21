#
# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#



package Warewulf::Module::Cli::Bootstrap;

use Warewulf::Include;
use Warewulf::Config;
use Warewulf::Logger;
use Warewulf::Util;
use Warewulf::Provision::Tftp;
use Getopt::Long;
use File::Path;
use File::Basename;
use File::Copy;

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
options()
{
    my %hash;

    $hash{"-r, --root"} = "Look into this chroot directory to find the kernel";
    $hash{"-n, --name"} = "Override the default name of the kernel version with the given string";

    return(%hash);
}

sub
description()
{
    my $output;

    $output .= "This command will create the bootstrap images that nodes use to\n";
    $output .= "bootstrap the provisioning process.\n";

    return($output);
}

sub
summary()
{
    my $output;

    $output .= "Build provisioning bootstrap images";

    return($output);
}


sub
examples()
{
    my @output;

    push(@output, "bootstrap 2.6.32-71.el6.x86_64");
    push(@output, "bootstrap --name testbootstrap 2.6.32-71.el6.x86_64");
    push(@output, "bootstrap --root /path/to/chroot 2.6.32-71.el6.x86_64");

    return(@output);
}


sub
exec()
{
    my ($self, @args) = @_;

    my $kversion;
    my $modules;
    my $depmod_map_arg = "";
    my $randstring = &rand_string("12");
    my $tmpdir = "/var/tmp/wwinitrd.$randstring";
    my $initramfsdir = &wwconfig("statedir") ."/warewulf/initramfs/";
    my $initramfsdefault = "base";
    my $config = Warewulf::Config->new("provision.conf");
    my $tftpboot = Warewulf::Provision::Tftp->new()->tftpdir();
    my $opt_root;
    my $opt_name;
    my $opt_kversion;
    my $module_count = 0;
    my $firmware_count = 0;

    if (! &uid_test(0)) {
        &eprint("This command can only be run by the superuser!\n");
        return();
    }

    @ARGV = @args;

    GetOptions(
        'r|root=s'   => \$opt_root,
        'n|name=s'   => \$opt_name,
    );

    $opt_kversion = shift(@ARGV);

    &dprint("Checking for bootstrap kernel version\n");
    if (! $opt_kversion) {
        &eprint("What is the kernel version for the bootstrap you wish to create?\n");
        return();
    } elsif ($opt_kversion =~ /^([a-zA-Z0-9_\-\.]+)$/) {
        &dprint("Got kernel version: $opt_kversion\n");
        $opt_kversion = $1;
    } else {
        &eprint("Illegal characters in kernel version!\n");
        return();
    }

    if ($opt_root and $opt_root =~ /^(?:\/|([a-zA-Z0-9_\-\.\/]+)(?<!\/)\/*)$/) {
        $opt_root = "$1/";
        &iprint("Using root directory: $opt_root\n");
    } elsif ($opt_root) {
        &eprint("Root directory name contains illegal characters!\n");
        return();
    } else {
        $opt_root = "/";
    }

    if ($opt_name and $opt_name =~ /^([a-zA-Z0-9_\-\.]+)$/) {
        $opt_name = $1;
        &iprint("Using bootstrap name: $opt_name\n");
    } elsif ($opt_name) {
        &eprint("Bootstrap name contains illegal characters!\n");
        return();
    } else {
        $opt_name = $opt_kversion;
    }



    &dprint("Checking for tftpboot directory name name '$opt_name'\n");
    if (! -d "$tftpboot/warewulf/bootstrap/$opt_name") {
        mkpath("$tftpboot/warewulf/bootstrap/$opt_name");
        &iprint("Created TFTP directory: $tftpboot/warewulf/bootstrap/$opt_name\n");
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
            &iprint("Will use the \"-m\" depmod option to trigger map file generation\n");
        }
    }
    close DEPMOD;



    mkpath($tmpdir);
    chdir($opt_root);

    if (! -f "./boot/vmlinuz-$opt_kversion") {
        &eprint("Can't locate the boot kernel: ". $opt_root ."boot/vmlinuz-$opt_kversion\n");
        return();
    }

    if ($config->get("drivers")) {
        mkpath("$tmpdir/lib/modules/$opt_kversion");
        foreach my $m ($config->get("drivers")) {
            if ($m and $m =~ /^([a-zA-Z0-9\/\*_\-\.]+)/) {
                my $m_clean = $1;
                open(FIND, "find ./lib/modules/$opt_kversion/kernel/$m_clean -type f 2>/dev/null |");
                while(my $module = <FIND>) {
                    chomp($module);
                    if ($module =~ /([a-zA-Z0-9\/_\-\.]+)/) {
                        $module = $1;
                        my $path = dirname($module);
                        &dprint("Including driver: $module\n");
                        if (! -d "$tmpdir/$path") {
                            mkpath("$tmpdir/$path");
                        }
                        if (copy($module, "$tmpdir/$path")) {
                            $module_count++;
                        }
                    }
                }
                close FIND;
            }
        }

        if ($module_count > 0) {
            &nprint("Number of drivers included in bootstrap: $module_count\n");
            system("/sbin/depmod $depmod_map_arg -a -b $tmpdir $opt_kversion");
        }
    }

    if ($config->get("firmware")) {
        mkpath("$tmpdir/lib/firmware");
        foreach my $f ($config->get("firmware")) {
            if ($f and $f =~ /^([a-zA-Z0-9\/\*_\-\.]+)/) {
                my $f_clean = $1;
                open(FIND, "find ./lib/firmware/$f_clean -type f 2>/dev/null |");
                while(my $firmware = <FIND>) {
                    chomp($firmware);
                    if ($firmware =~ /([a-zA-Z0-9\/_\-\.]+)/) {
                        $firmware = $1;
                        my $path = dirname($firmware);
                        &dprint("Including firmware: $firmware\n");
                        if (! -d "$tmpdir/$path") {
                            mkpath("$tmpdir/$path");
                        }
                        if (copy($firmware, "$tmpdir/$path")) {
                            $firmware_count++;
                        }
                    }
                }
                close FIND;
            }
        }

        if ($firmware_count > 0) {
            &nprint("Number of firmware images included in bootstrap: $firmware_count\n");
        }
    }

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

    my $tmpinitramfs = "$tftpboot/warewulf/bootstrap/$opt_name/initfs";
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
    &nprint("Locating the kernel object\n");
    system("cp ./boot/vmlinuz-$opt_kversion $tftpboot/warewulf/bootstrap/$opt_name/kernel");
    system("rm -rf $tmpdir");
    &nprint("Bootstrap image '$opt_name' is ready\n");

    @ARGV = ();
}



1;






