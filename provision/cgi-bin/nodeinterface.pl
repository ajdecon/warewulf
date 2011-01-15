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
my %nhash = $node->get_hash();

if ($node) {
    my $nodeName = $node->get("name");
} else {
    $node = Warewulf::ObjectFactory->new("node");
    $node->set("name", "newnode");
    $node->set("hwaddr", $hwaddr);
    $db->persist($node);
}


foreach my $script ($node->get("bootscript")) {
    my $s = $db->get_objects("script", "name", $script);
    my $sobj = $s->get_object(0);
    my $script = $db->get_data($sobj->get("id"));
    foreach my $key (keys %nhash) {
        my $uc_key = uc($key);
        $script =~ s/\$\{?$uc_key\}?/$nhash{$key}/g;
    }
    print $script;
}
