#!/usr/bin/perl

use CGI;

my $q = CGI->new();

print $q->header();

print "echo Hello World\n";


