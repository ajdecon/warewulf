# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#
#

package Warewulf::Monitor;

use Warewulf::Object;
use Warewulf::ObjectSet;
use Warewulf::Logger;
use Warewulf::Config;
use JSON::XS;
use IO::Socket;


@ISA = ('Warewulf::Object');

=head1 NAME

Warewulf::Monitor - Warewulf Monitor module to provide abilies to communicate
                    with Warewulf monitor database.

=head1 ABOUT

Blah blah blah

=head1 SYNOPSIS

    use Warewulf::Monitor;

    my $monitor = Warewulf::Monitor->new();
    $monitor->set_query("key='CPUCOUNT' and value=8");
    my $ObjectSet = $monitor->query_data();

    foreach my $node_object ( $ObjectSet->get_list()) {
        printf("%-20s CPU: %s\n", $node_object->get("name"), $node_object->get("cpuutil"));
    }



=head1 METHODS

=over 12

=cut



=item new()

The new constructor will create the object that references configuration the
stores.

=cut

my $HEADERSIZE=62; #int(4) + time_t(8) + char nodename[50]
my $APPLICATION=2;

sub
new($$)
{
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = ();
    
    $self = $class->SUPER::new();
    bless($self, $class);
    return $self->init(@_);
}

##
# initialize monitor object with defaut
# localhost at port 9000
##
sub init()
{
    my ($self, @args) = @_;
    $self->set_masters();

    return $self;
}

##
# Private method to send raw and complete 
# sql query to monitor master
# it returns a object set according the query
##
my $query = sub
{
    my ($self, $query) = @_;
    my $json = JSON::XS->new();
    my $ObjectSet = Warewulf::ObjectSet->new();
    my $data;
    my %nodeHash=();
    my @socks;
    my @masters;
    @masters=$self->get("masters");

    # Build Socket conditionally if ! exists
    if (! $self->get("sockets")) {
        # Make socket connection for each master
        foreach my $masterString (@masters) {
            my ($master,$port)=split(/:/, $masterString);
            my $socket = IO::Socket::INET->new(PeerAddr => "$master",
                                               PeerPort => $port,
                                               Proto => 'tcp')
                       or die "Could not connect to $master:$port!\n";

            push(@socks,$socket);

            #register connection type for this socket 
            register_conntype ($socket,$APPLICATION);
            my $register_data=recv_all($socket);
        }
        $self->set("sockets", \@socks);
    }
    @socks=$self->get("sockets");

    #send raw query as json packet
    foreach my $sock (@socks) {
        send_query($sock,$query);
        my $data=recv_all($sock);

        #decode json packet and restore it in the object set data structure
        my %decoded_json = %{decode_json($data)};

        foreach my $node (keys %decoded_json) {
            next if ($node eq "JSON_CT");

            my %decoded_node= %{decode_json($decoded_json{$node})};
            if($nodeHash{$node}) {
                if($decoded_node{"TIMESTAMP"}>$nodeHash{"$node"}) {
                    ObjectSet->del("name",$node);
                } else {
                    next;
                }
            }
 
            my $tmpObject = Warewulf::Object->new();
            $tmpObject->set("name",$node);
            foreach my $entry (keys %decoded_node) {
                $tmpObject->set($entry, $decoded_node{"$entry"});
                &dprint("Set entry for node: $node ($entry....)\n");
            }
            $nodeHash{$node}=$decoded_node{"TIMESTAMP"};
            $ObjectSet->add($tmpObject);
        }

        if (! $self->persist_socket()) {
            # tear down socket
            close($sock);
        }
    }

    return $ObjectSet;
};

##
# Use enable_filter("1") to enable the node display filter
# It sets the query for a specific set of nodes from the users 
# enviornment variable for '$NODES' as a node list (with ',' delim) 
# or defined as a file path.
# If format of $NODES is invalid, all available nodes will be returned.
##

sub enable_filter()
{
    my ($self, $bool) = @_;
    if ($bool) {
	#enable filter
	my $whereClause="";	
	if ( $ENV{NODES} ) {
	    if ( -f "$ENV{NODES}" ) {
		open(NODES, "< $ENV{NODES}");
		$whereClause="key='NODENAME' and ";
		while ($match=<NODES>) {
		    chomp $match;
		    $match =~ s/#.*$//;
		    $match =~ s/\s+$//;
		    next unless $match;
		    $match =~ s/\*/.*/g;
		    $match =~ s/\+/\\+/g;
		    $whereClause = $whereClause . "value LIKE '%$match%' or ";
		}
		$whereClause=substr($whereClause,0,-3);
	    } elsif ( $ENV{NODES} =~ /^\/.+$/ ) {
		# ignore node files that don't exist
	    } else {
		$whereClause="key='NODENAME' and ";
		foreach $match ( split(/,/, $ENV{NODES}) ) {
		    $match =~ s/\*/.*/g;
		    $match =~ s/\+/\\+/g;
		    $whereClause = $whereClause . "value LIKE '%$match%' or ";
		}
		$whereClause=substr($whereClause,0,-3);
	    }
	}
	$self->set_query($whereClause);
    }
    return;
}


##
# use persist_socket("1") to prevent socket being closed
# after each query
##
sub persist_socket()
{
    my ($self, $bool) = @_;

    if ($bool) {
        $self->set("persist_socket", "1");
    }

    return $self->get("persist_socket");
}

##
# set monitor master host and port from config file
# if no config file is found, use localhost:9000
##
sub set_masters()
{
    my ($self) = @_;
    my $conf = Warewulf::Config->new("monitor.conf");
    
    my @masters=$conf->get("masters");
    if (! @masters){
        push(@masters,"localhost:9000");
    }
    
    $self->set("masters", \@masters);
}

sub get_masters()
{
    my ($self) = @_;
    my @mastersOnly;
    my @masters=$self->get("masters");
    foreach $masterString (@masters) {
        my ($master,$port)=split(/:/, $masterString);
        push(@mastersOnly,$master);
    }
    return @mastersOnly;
}


##
# set the where clause for a query for this object
##
sub set_query(){
    my ($self, $whereClause) = @_;
#    $self->set("query","select * from wwstats where $whereClause");
    $self->set("query","$whereClause");
}

##
# retrieving data from the "query" that is set via set_query()
# if "query" is not set, get all the data
##
sub query_data(){
    my ($self) = @_;
    if ($self->get("query")) {
        return $query->($self, $self->get("query"));
    } else {
        return $query->($self, "");
    }
}

sub register_conntype {
    my ($socket, $type) = @_;
    my $json = JSON::XS->new();
    my $jsonStruc;
    $jsonStruc->{CONN_TYPE} = $type;
    my $json_text = $json->encode($jsonStruc);
    send_all($socket,$json_text);
}

sub send_query {
    my ($socket, $sql) = @_;
    my $sqlJson = JSON::XS->new();
    my $jsonStruc;
    $jsonStruc->{"sqlite_cmd"}=$sql;
    my $jsonQuery=$sqlJson->encode($jsonStruc);
    send_all($socket,$jsonQuery);
}

sub send_all {
    my ($socket, $payload) = @_;
    my $length=length($payload);
    my $ts=time();
    my $nodename="";
    $socket->send(pack('i Q A[50] a*', $length,$ts,$nodename,$payload));
}

sub recv_all {
    my ($socket) = @_;
    my $header;
    my $rawdata;
    $socket->recv($header, $HEADERSIZE,MSG_WAITALL);
    # only unpack the length value in the header
    # timestamp and nodename are ignored
    my $pktsize=unpack('i',$header);
    $socket->recv($rawdata, $pktsize,MSG_WAITALL);
    my $data=unpack('a*',$rawdata);
    return $data;
}


sub
update_node_entry()
{
    # will send post to monitor
}


#my $obj = Warewulf::Config->new("/home/kaisong/repo/svn-repo/warewulf/trunk/monitor/lib/Warewulf/monitor.conf");




=back

=head1 SEE ALSO

Warewulf::Object

=head1 COPYRIGHT

Copyright (c) 2001-2003 Gregory M. Kurtzer

Copyright (c) 2003-2011, The Regents of the University of California,
through Lawrence Berkeley National Laboratory (subject to receipt of any
required approvals from the U.S. Dept. of Energy).  All rights reserved.

=cut

# vim:filetype=perl:syntax=perl:expandtab:ts=4:sw=4:
1;
