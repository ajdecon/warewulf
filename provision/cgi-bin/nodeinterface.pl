#!/usr/bin/perl

use CGI;
use Warewulf::DB;
use Warewulf::ObjectFactory;

my $q = CGI->new();
my $db = Warewulf::DB->new();

print $q->header();

my $hwaddr = $q->param('hwaddr');


my $ethernetSet = $db->get_objects("ethernet", "name", $hwaddr);
my $eth = $ethernetSet->get_object(0);

if ($eth) {
    my $ethName = $eth->get("name");
    my $nodeSet = $db->get_objects("node", "hwaddr", $ethName);
    my $node = $nodeSet->get_object(0);
    if ($node) {
        my $nodeName = $node->get("name");
        print "echo Welcome back Mr. $nodeName\n";
    } else {
        print "echo Welcome back Mr. $ethName\n";
    }
} else {
    my $newnode = Warewulf::ObjectFactory->new("ethernet");
    $newnode->set("name", $hwaddr);
    $db->persist($newnode);

    print "echo Hello Mr. $hwaddr, I have added you to my datastore\n";
}

