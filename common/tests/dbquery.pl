#!/usr/bin/perl


use Warewulf::DB::MySQL;
use Warewulf::DBQuery;
use Warewulf::Logger;
$db = Warewulf::DB::MySQL->new("localhost", "warewulf", "root", "");

&set_log_level("DEBUG");

sub worker(@) {
    my @array = @_;
#    print "-------------------------------------\n";
    foreach my $h (@array) {
        print "name: $h->{name}: ";
        foreach my $k ( keys %{$h}) {
            print "$k=$h->{$k}, ";
        }
        print "\n";
    }
}

$query = Warewulf::DBQuery->new("get");
$query->table("nodes");
#$query->match("hwaddr", "IS", "NULL");
$query->match("cluster", "=", "nano");
$query->order("cluster");
$query->order("name");
$query->function(\&worker);
$db->query($query);

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


