#!/usr/bin/perl -Tw
#
# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#
#
# $Id$
#

use Test::More;
use Warewulf::Include;

my @var_names = (
    "PROGNAME",
    "VERSION",
    "PREFIX",
    "STATEDIR",
    "SYSCONFDIR",
    "LIBDIR",
    "DATAROOTDIR",
    "DATADIR",
    "LIBEXECDIR",
    "PERLMODDIR"
);

plan("tests" => (
         + 1                         # Inheritance tests
         + 1                         # Variable count tests
         + (scalar(@var_names) * 4)  # Variable tests
     ));

# Make sure we inherit from Exporter
isa_ok("Warewulf::Include", "Exporter");

# Make sure we account for all the variables that exist currently.
cmp_ok(scalar(@var_names), '==', scalar(keys(%Warewulf::Include::wwconfig)),
       "All Warewulf::Include variable names accounted for");

# Make sure we get back the same value regardless of case
# and that it begins with a '/'.
foreach my $var (@var_names) {
    my ($val_uc, $val_lc);

    $val_uc = &wwconfig($var);
    $val_lc = &wwconfig(lc($var));
    ok(defined($val_uc) && $val_uc, "$var is returned (uppercase)");
    ok(defined($val_lc) && $val_lc, "$var is returned (lowercase)");
    cmp_ok($val_uc, 'eq', $val_lc, "$var values match");
    if ($var eq "PROGNAME") {
        my $len = length($val_uc);

        cmp_ok(substr($0, -$len, $len), 'eq', $val_uc, "PROGNAME matches \$0");
    } elsif ($var eq "VERSION") {
        like($val_uc, qr/^[\d\.]+$/, "VERSION is a valid version number");
    } else {
        like($val_uc, qr/^\//, "$var starts with '/'");
    }
}
