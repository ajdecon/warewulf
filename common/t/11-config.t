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
use Warewulf::Object;
use Warewulf::Config;

my $cfgpath = "./t";
my $cfgfile = "11-config_test_file.conf";
my ($t1, $t2, $t3, $t4, $t5);

plan("tests" => (
         + 1       # Inheritance tests
         + 3       # Sanity checks for test config file
         + 4       # No-args tests
     ));

# Make sure we inherit from Warewulf::Object
isa_ok("Warewulf::Config", "Warewulf::Object");

# Make sure we have our test config file and can read it.
ok(-e "$cfgpath/$cfgfile", "Test config file $cfgfile exists");
ok(-r "$cfgpath/$cfgfile", "Test config file $cfgfile is readable");
ok(-s "$cfgpath/$cfgfile", "Test config file $cfgfile is not empty");

# Make sure we can create an instance with no arguments, then set the path,
# then load the config file.
$t1 = new_ok("Warewulf::Config", [], "Test Config Object (no args)");
can_ok($t1, "set_path", "load");
ok($t1->set_path($cfgpath), "Able to set config file search path to $cfgpath");
ok($t1->load($cfgfile), "Able to load test config file $cfgfile");
