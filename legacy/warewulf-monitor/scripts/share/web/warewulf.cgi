#!/usr/bin/perl
#
# Copyright (c) 2001-2003 Gregory M. Kurtzer
# 
# Copyright (c) 2003-2012, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#



use CGI;
use lib "/usr/lib/warewulf/", "/usr/lib64/warewulf/";
use Warewulf::Status;

$q = new CGI;
print $q->header;

%nodestats = &node_status();

if ( $ENV{PATH_INFO} =~ /\/(.+)\/(.+)[\/]?$/ ) {
   $cluster_view = $1;
   $node_view = "$1:$2";
   $node_name = "$2";
} elsif ( $ENV{PATH_INFO} =~ /\/(.+)[\/]?$/ ) {
   $cluster_view = $1;
}

$nodecount = 0;
$rowcount = 0;
$nodes_total = 0;
$nodes_up = 0;
$nodes_down = 0;
$nodes_unknown = 0;
$cpuutil_total = 0;
$cpucount_total = 0;
$rack = 1;

foreach $node ( sort keys %nodestats ) {
   if ( $node =~ /^(.+):(.+)$/ ) {
      $cluster = $1;
      $nodename = $2;
   } else {
      $nodename = $node;
   }
   if ( $cluster ) {
      if ( $nodestats{$node}{NODESTATUS} eq 'READY' ) {
         $cluster{$cluster}{NODES_READY} ++;
         $cluster{$cluster}{CPUUTIL} += $nodestats{$node}{CPUUTIL};
         $cluster{$cluster}{LOADAVG} += $nodestats{$node}{LOADAVG};
         $cluster{$cluster}{MEMTOTAL} += $nodestats{$node}{MEMTOTAL};
         $cluster{$cluster}{MEMUSED} += $nodestats{$node}{MEMUSED};
         $cluster{$cluster}{PROCS} += $nodestats{$node}{PROCS};
         $cluster{$cluster}{UPTIME} += $nodestats{$node}{UPTIME};
         $cluster{$cluster}{CPUCOUNT} += $nodestats{$node}{CPUCOUNT};
         $grid_cpuutil += $nodestats{$node}{CPUUTIL};
         $grid_nodes_ready ++;
      } else {
         $cluster{$cluster}{NODES_DOWN} ++;
      }
      $cluster{$cluster}{NODES_TOTAL} ++;
   }
   if ( $cluster_last ne $nodestats{$node}{CLUSTERNAME} ) {
      $rack=1;
      $rowcount = 0;
   }
   $cluster_last = $nodestats{$node}{CLUSTERNAME};
   if ( $cluster_view ) {
      $nodestring = $nodename;
   } else {
      $nodestring = "$nodename ($nodestats{$node}{CLUSTERNAME})";
   }
   if ( $rowcount >= 32 ) {
      $rack++;
      $rowcount = 0;
      $cluster{$cluster}{NODE_DISPLAY} .= "<br />";
   }
   $cluster_cpu_hash{$cluster}{$rack}{CPUUTIL} += $nodestats{$node}{CPUUTIL};
   $cluster_cpu_hash{$cluster}{$rack}{COUNT} ++;
   $rowcount++;
   $nodecount++;
   $cluster{$cluster}{NODE_DISPLAY} .= "<a href='/warewulf/$nodestats{$node}{CLUSTERNAME}/$nodename'>";
   next if ( $cluster_view and $cluster_view ne $nodestats{$node}{CLUSTERNAME} );
   if ( $nodestats{$node}{NODESTATUS} eq 'DOWN' ) {
      $cluster{$cluster}{NODE_DISPLAY} .= "<img border=0 src=/warewulf/images/node-dead.png alt='' title='$node status: $nodestats{$node}{NODESTATUS}'>";
      $nodes_down++;
   } elsif ( $nodestats{$node}{NODESTATUS} ne 'READY' ) {
      $cluster{$cluster}{NODE_DISPLAY} .= "<img border=0 src=/warewulf/images/node-unknown.png alt='' title='$node status: UNKNOWN'>";
      $nodes_unknown++;
   } else {
      if ( $nodestats{$node}{LOADAVG} > $nodestats{$node}{CPUCOUNT} * 2 ) {
         $cluster{$cluster}{NODE_DISPLAY} .= "<img border=0 src=/warewulf/images/node-over.png alt='' title='$nodestring load: $nodestats{$node}{LOADAVG}'>";
      } elsif ( $nodestats{$node}{CPUUTIL} <= 10 ) {
         $cluster{$cluster}{NODE_DISPLAY} .= "<img border=0 src=/warewulf/images/node-00.png alt='' title='$nodestring cpu: $nodestats{$node}{CPUUTIL}%'>";
      } elsif ( $nodestats{$node}{CPUUTIL} <= 20 ) {
         $cluster{$cluster}{NODE_DISPLAY} .= "<img border=0 src=/warewulf/images/node-10.png alt='' title='$nodestring cpu: $nodestats{$node}{CPUUTIL}%'>";
      } elsif ( $nodestats{$node}{CPUUTIL} <= 30 ) {
         $cluster{$cluster}{NODE_DISPLAY} .= "<img border=0 src=/warewulf/images/node-20.png alt='' title='$nodestring cpu: $nodestats{$node}{CPUUTIL}%'>";
      } elsif ( $nodestats{$node}{CPUUTIL} <= 40 ) {
         $cluster{$cluster}{NODE_DISPLAY} .= "<img border=0 src=/warewulf/images/node-30.png alt='' title='$nodestring cpu: $nodestats{$node}{CPUUTIL}%'>";
      } elsif ( $nodestats{$node}{CPUUTIL} <= 50 ) {
         $cluster{$cluster}{NODE_DISPLAY} .= "<img border=0 src=/warewulf/images/node-40.png alt='' title='$nodestring cpu: $nodestats{$node}{CPUUTIL}%'>";
      } elsif ( $nodestats{$node}{CPUUTIL} <= 60 ) {
         $cluster{$cluster}{NODE_DISPLAY} .= "<img border=0 src=/warewulf/images/node-50.png alt='' title='$nodestring cpu: $nodestats{$node}{CPUUTIL}%'>";
      } elsif ( $nodestats{$node}{CPUUTIL} <= 70 ) {
         $cluster{$cluster}{NODE_DISPLAY} .= "<img border=0 src=/warewulf/images/node-60.png alt='' title='$nodestring cpu: $nodestats{$node}{CPUUTIL}%'>";
      } elsif ( $nodestats{$node}{CPUUTIL} <= 80 ) {
         $cluster{$cluster}{NODE_DISPLAY} .= "<img border=0 src=/warewulf/images/node-70.png alt='' title='$nodestring cpu: $nodestats{$node}{CPUUTIL}%'>";
      } elsif ( $nodestats{$node}{CPUUTIL} <= 90 ) {
         $cluster{$cluster}{NODE_DISPLAY} .= "<img border=0 src=/warewulf/images/node-80.png alt='' title='$nodestring cpu: $nodestats{$node}{CPUUTIL}%'>";
      } elsif ( $nodestats{$node}{CPUUTIL} <= 90 ) {
         $cluster{$cluster}{NODE_DISPLAY} .= "<img border=0 src=/warewulf/images/node-90.png alt='' title='$nodestring cpu: $nodestats{$node}{CPUUTIL}%'>";
      } elsif ( $nodestats{$node}{CPUUTIL} <= 100 ) {
         $cluster{$cluster}{NODE_DISPLAY} .= "<img border=0 src=/warewulf/images/node-100.png alt='' title='$nodestring cpu: $nodestats{$node}{CPUUTIL}%'>";
      }
      $nodes_up++;
      $cpuutil_total += $nodestats{$node}{CPUUTIL};
      $cpucount_total += $nodestats{$node}{CPUCOUNT};
      $cluster_load += $nodestats{$node}{LOADAVG};
   }
   $cluster{$cluster}{NODE_DISPLAY} .= "</a>";
   $nodes_total++;
}

$cluster_table = "<table border=0 cellpadding=5 >\n";
foreach $cluster ( sort keys %cluster ) {
   next if ( $cluster_view and $cluster_view ne $cluster );
   if ( $cluster{$cluster}{NODES_DOWN} < 1 ) {
      $tmp_down = 0;
   } else {
      $tmp_down = $cluster{$cluster}{NODES_DOWN};
   }
   if ( $cluster{$cluster}{NODES_READY} > 0 ) {
      $tmp_cpu = sprintf("%.1f", $cluster{$cluster}{CPUUTIL}/$cluster{$cluster}{NODES_READY});
   } else {
      $tmp_cpu = 0;
   }
   $cluster_table .= "<tr>\n";
   if ( ! $cluster_view ) {
      $cluster_table .= "<td valign=center align=left><a href='/warewulf/$cluster'><b>$cluster</b></a><br />\n";
   }
   $cluster_table .= "<td valign=center align=left NOWRAP>$cluster{$cluster}{NODE_DISPLAY}</td>\n";
   $cluster_table .= "</tr>\n";
}
$cluster_table .= "</table>\n";

if ( $nodes_up > 0 ) {
	$cluster_cpuutil .= sprintf("%d", $cpuutil_total / $nodes_up);
} else {
	$cluster_cpuutil .= sprintf("0");
}

if ( $cluster_cpuutil == 10 ) {
   $grid_cluster_cpuutil = "overload";
}


foreach $cluster ( sort keys %cluster ) {
   $cluster_count++;
   next if ( $cluster_view and $cluster_view ne $cluster );
   $tmp_html = $nodedispl_html;
   $clusters_html .= "<table border=0 cellpadding=15 style='display:inline;'><tr><td align=center NOWRAP>";
   $clusters_html .= "<a href='/warewulf/$cluster'><b>$cluster</b></a><br />";
   foreach $rack ( sort keys %{$cluster_cpu_hash{$cluster}} ) {
      $rack_util = sprintf("%d", $cluster_cpu_hash{$cluster}{$rack}{CPUUTIL}/$cluster_cpu_hash{$cluster}{$rack}{COUNT});
      if ( $rack_util == 00 ) {
         $clusters_html .= "<a href='/warewulf/$cluster'>";
         $clusters_html .= "<img alt='' title='$cluster rack $rack utilization: $rack_util%' border=0 src=/warewulf/images/cluster-00.png>";
         $clusters_html .= "</a>\n";
      } elsif ( $rack_util < 25 ) {
         $clusters_html .= "<a href='/warewulf/$cluster'>";
         $clusters_html .= "<img alt='' title='$cluster rack $rack utilization: $rack_util%' border=0 src=/warewulf/images/cluster-25.png>";
         $clusters_html .= "</a>\n";
      } elsif ( $rack_util < 50 ) {
         $clusters_html .= "<a href='/warewulf/$cluster'>";
         $clusters_html .= "<img alt='' title='$cluster rack $rack utilization: $rack_util%' border=0 src=/warewulf/images/cluster-50.png>";
         $clusters_html .= "</a>\n";
      } elsif ( $rack_util < 75 ) {
         $clusters_html .= "<a href='/warewulf/$cluster'>";
         $clusters_html .= "<img alt='' title='$cluster rack $rack utilization: $rack_util%' border=0 src=/warewulf/images/cluster-75.png>";
         $clusters_html .= "</a>\n";
      } elsif ( $rack_util <= 100 ) {
         $clusters_html .= "<a href='/warewulf/$cluster'>";
         $clusters_html .= "<img alt='' title='$cluster rack $rack utilization: $rack_util%' border=0 src=/warewulf/images/cluster-100.png>";
         $clusters_html .= "</a>\n";
      }
   }
   $clusters_html .= "</td></tr></table>\n";
}

if ( $node_view and $cluster_count <= 1 ) {
   $grid_html .= "<a href='/warewulf/'><b>Cluster View</b></a>\n";
} elsif ( $node_view ) {
   $grid_html .= "<a href='/warewulf/$cluster_view'><b>Cluster View</b></a>\n";
} elsif ( $cluster_view ) {
   $grid_html .= "<a href='/warewulf'><b>View all clusters</b></a>\n";
}


if ( $cluster_view ) {
   $cluster_name = $cluster_view;
} else {
   $cluster_name = "Cluster Totals ($cluster_count clusters)";
}

if ( $cluster_count <= 1 ) {
   $cluster_name = $cluster;
   $clusters_html = ();
}
   
$cluster_load = sprintf("%.2f", $cluster_load);

$cluster_info_html .= "<table border=0 cellpadding=0 cellspacing=0 width=100%>\n";
$cluster_info_html .= "<tr><td align=center><h2>$cluster_name</h2></td></tr>\n";

$cluster_info_html .= "<table border=0 cellpadding=0 cellspacing=0 width=100%>\n";
$cluster_info_html .= "<tr><td width=33% align=left><b>CPU total</b>: $cpucount_total</td>\n";
$cluster_info_html .= "<td width=33% align=center><b>Overall CPU utilization</b>: $cluster_cpuutil%</td>\n";
$cluster_info_html .= "<td width=33% align=right><b>Load Average</b>: $cluster_load</td></tr>\n";
$cluster_info_html .= "</table>\n";

$cluster_info_html .= "<table border=0 cellpadding=0 cellspacing=0 width=100%>\n";
$cluster_info_html .= "<tr><td align=left width=25%><b>Nodes total</b>: $nodes_total</td>\n";
$cluster_info_html .= "<td align=left width=25%><b>Nodes up</b>: $nodes_up</td>\n";
$cluster_info_html .= "<td align=right width=25%><b>Nodes down</b>: $nodes_down</td>\n";
$cluster_info_html .= "<td align=right width=25%><b>Nodes unknown</b>: $nodes_unknown</td></tr>\n";
$cluster_info_html .= "</table>\n";
$cluster_info_html .= "</tr></td></table>\n";

if ( $node_view ) {
   $node_body_content = "<h2>$node_name</h2>";
   $node_body_content .= "<table border=0 cellspacing=0 cellpadding=0 width=100%>\n";
   foreach $stat ( sort keys %{$nodestats{$node_view}} ) {
      $node_body_content .= "<tr><td><b>$stat</b>:</td><td>$nodestats{$node_view}{$stat}</td></tr>\n";
   }
   $node_body_content .= "</table>\n";
} else {
   $node_body_content = $nodegrouplist;
}

$main_out .= "$cluster_info_html\n";
$main_out .= "$grid_html<br />\n";
$main_out .= "$cluster_table\n";
$main_out .= "$node_body_content<hr>\n";
$main_out .= "$clusters_html\n";

open(TMPL, "template.html");
while(<TMPL>) {
   $_ =~ s/<!-- cluster info -->/$cluster_info_html/g;
   $_ =~ s/<!-- node body -->/$node_body_content/g;
   $_ =~ s/<!-- grid link -->/$grid_html/g;
   $_ =~ s/<!-- cluster links -->/$clusters_html/g;
   $_ =~ s/<!-- main -->/$main_out/g;
   $_ =~ s/<!-- title -->/The Warewulf Cluster Monitor: $cluster_name $node_name/g;
   print;
}
close TMPL;

