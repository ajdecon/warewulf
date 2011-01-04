#!/usr/bin/perl

use CGI;
use Warewulf::DataStore;
use Warewulf::ObjectFactory;

my $q = CGI->new();
my $db = Warewulf::DataStore->new();

print $q->header();

my $hwaddr = $q->param('hwaddr');


my $nodeSet = $db->get_objects("node", "hwaddr", $hwaddr);
my $node = $nodeSet->get_object(0);

if ($node) {
    my $nodeName = $node->get("name");
    print "echo Welcome back $nodeName\n";
} else {
    my $newnode = Warewulf::ObjectFactory->new("node");
    $newnode->set("name", "newnode");
    $newnode->set("hwaddr", $hwaddr);
    $db->persist($newnode);

    print "echo Hello newnode, I have added you to my datastore\n";
}

