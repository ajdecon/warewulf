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
} else {
    $node = Warewulf::ObjectFactory->new("node");
    $node->set("name", "newnode");
    $node->set("hwaddr", $hwaddr);
    $db->persist($node);
}

foreach my $script ($node->get("bootscript")) {
    if (! $script) {
        next;
    }
    my $s = $db->get_objects("script", "name", $script);
    my $sobj = $s->get_object(0);
    my $sbinstore = $db->binstore($sobj->get("id"));
    my $script;
    my %nhash = $node->get_hash();
    while(my $buffer = $sbinstore->get_chunk()) {
        $script .= $buffer;
    }
    foreach my $key (keys %nhash) {
        my $uc_key = uc($key);
        my $val;
        if (ref($nhash{"$key"}) eq "ARRAY") {
            $val = $nhash{"$key"}->[0];
        } else {
            $val = $nhash{"$key"};
        }
        $script =~ s/\$\{?$uc_key\}?/$val/g;
    }
    print $script;
}
