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

my $modname = "Warewulf::Object";
my @methods = ("new", "init", "get", "set", "add", "del", "get_hash",
               "to_string", "debug_string");

plan("tests" => (
         + 8              # Instantiation, method, and initialization tests
         + 2              # String representation method tests
         + 1              # get_hash() method tests
         + 0              # get()/set() member tests
));

my ($obj1, $obj2, $obj3);

# Make sure we can create identical objects regardless of whether values
# are passed in via set(), init() directly, or the constructor.
$obj1 = new_ok($modname, [], "Instantiate Object 1 (no args)");
$obj1->init("name" => "me");
can_ok($obj1, @methods);

$obj2 = new_ok($modname, [], "Instantiate Object 2 (no args)");
$obj2->set("name" => "me");

$obj3 = new_ok($modname, [ "name" => "me" ], "Instantiate Object 3 (with args)");

is($obj1->get("name"), "me", "Object member matches supplied initializer");
is_deeply($obj1, $obj2, "Objects 1 and 2 are identical");
is_deeply($obj2, $obj3, "Objects 2 and 3 are identical");

$obj2->init();
isnt($obj2->get("name"), "me", "init() resets all object members");

undef $obj2;
undef $obj3;

#######################################
### String representation method tests
#######################################
is($obj1->to_string(), "{ $obj1 }", "to_string() method returns proper result");
is($obj1->debug_string(), "{ $obj1:  \"NAME\" => \"me\" }", "debug_string() method returns proper result");

#######################################
### get_hash() method tests
#######################################
my $href;
$href = $obj1->get_hash();
is_deeply($href, { "NAME" => "me" }, "get_hash() returns correct data");

#######################################
### get()/set() member tests
#######################################
