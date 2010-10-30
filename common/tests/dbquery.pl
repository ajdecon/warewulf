#!/usr/bin/perl


use Warewulf::DB::MySQL;
use Warewulf::DBQuery;
$db = Warewulf::DB::MySQL->new("localhost", "warewulf", "root", "");


sub worker(@) {
    my @array = @_;
#    print "-------------------------------------\n";
    foreach my $h (@array) {
        print "name: $h->{name}\n";
        foreach my $k ( keys %{$h}) {
#            print "worker: $k: $h->{$k} \n";
        }
    }
}

$query = Warewulf::DBQuery->new("get");
$query->table("nodes");
$query->match("hwaddr", "IS", "NULL");
$query->function(\&worker);

#$query = Warewulf::DBQuery->new("set");
#$query->table("nodes");
#$query->match("name", "regexp", "n000[2-3]");
#$query->set("create_time", "5555");

#$query = Warewulf::DBQuery->new("insert");
#$query->table("nodes");
#$query->set("name", "moooo");
#$query->set("create_time", "9999");
#


#$query->set("create_time", "1234");
#$query->match("name", "=", "compute-group1");
#$query->order("id", "asc");
#$query->limit(10);


$db->query($query);
