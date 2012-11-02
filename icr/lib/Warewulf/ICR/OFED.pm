# Warewulf Copyright (c) 2001-2003 Gregory M. Kurtzer
# 
# Warewulf Copyright (c) 2003-2013, The Regents of the University of
# California, through Lawrence Berkeley National Laboratory (subject to
# receipt of any required approvals from the U.S. Dept. of Energy).
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# (1) Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
# 
# (2) Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
# 
# (3) Neither the name of the University of California, Lawrence Berkeley
# National Laboratory, U.S. Dept. of Energy nor the names of its contributors
# may be used to endorse or promote products derived from this software
# without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
# 
# You are under no obligation whatsoever to provide any bug fixes, patches,
# or upgrades to the features, functionality or performance of the source
# code ("Enhancements") to anyone; however, if you choose to make your
# Enhancements available either publicly, or directly to Lawrence Berkeley
# National Laboratory, without imposing a separate written license agreement
# for such Enhancements, then you hereby grant the following license: a
# non-exclusive, royalty-free perpetual license to install, use, modify,
# prepare derivative works, incorporate into other computer software,
# distribute, and sublicense such enhancements or derivative works thereof,
# in binary and source code form.
#
# Copyright (c) 2003-2012, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#
## Copyright (c) 2012, Intel(R) Corporation
##
## Redistribution and use in source and binary forms, with or without 
## modification, are permitted provided that the following conditions are met:
##
##    * Redistributions of source code must retain the above copyright notice, 
##      this list of conditions and the following disclaimer.
##    * Redistributions in binary form must reproduce the above copyright 
##      notice, this list of conditions and the following disclaimer in the 
##      documentation and/or other materials provided with the distribution.
##    * Neither the name of Intel(R) Corporation nor the names of its contributors 
##      may be used to endorse or promote products derived from this software 
##      without specific prior written permission.
##
## THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
## AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
## IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
## ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
## LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
## CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
## SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
## INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
## CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
## ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
## POSSIBILITY OF SUCH DAMAGE.
##
# $Id$
#

package Warewulf::ICR::OFED;

use strict;
use warnings;
use English qw/-no_match_vars/;
use File::Basename;
use IO::Select;
use Socket;

use Warewulf::Logger;
use Warewulf::Network;
use Warewulf::System::Rhel;
use Warewulf::File;

my $OFED_tmp_dir;
my $ofed_conf       = 'ofed.conf';
my $ib0_config_file = '/etc/sysconfig/network-scripts/ifcfg-ib0';
my $master_ib0_ip;
my $ib0_mask;

=head1 NAME

Warewulf::ICR::OFED

=head1 SYNOPSIS

    use Warewulf::ICR::OFED;

=head1 DESCRIPTION

Helper function for the configuration of Open Fabrics Alliance 
(OFA www.openfabrics.org) the OpenFabrics Enterprise Distribution (OFED)

=head1 FUNCTIONS

=over 4

=item config_ib0 ()

Create the file /etc/sysconfig/network-scripts/ifcfg-ib0. Configure the sub-net
to be one more of the first eth interface of the system. 

=cut

sub
config_ib0
{

    # Set the configuration for the ib0-config file
    # Get the data of eth0 and add 1 to the sub-net
    my $net        = Warewulf::Network->new();
    my $eth0_dev   = ($net->list_devices())[0];
    my $eth0_net   = $net->network($eth0_dev);
    my $ib0_prefix = $net->calc_prefix($eth0_dev);
    my $eth0_mask     = $net->netmask($eth0_dev);
    my $eth0_mask_ser = $net->ip_serialize($eth0_mask);
    my $eth0_mask_bin = unpack("B*", pack("N", $eth0_mask_ser));
    my $count         = ($eth0_mask_bin =~ tr/0//);
    my $eth0_net_ser  = $net->ip_serialize($eth0_net);
    my $nrotoadd      = 2**$count;
    my $ib0_net_ser   = $nrotoadd + $eth0_net_ser;
    my $ib0_net       = $net->ip_unserialize($ib0_net_ser);
    $ib0_mask = $eth0_mask;
    my $ib0_broadcast_ser = $ib0_net_ser + ~$eth0_mask_ser;
    my $ib0_broadcast     = $net->ip_unserialize($ib0_broadcast_ser);
    my $ib0_ip_ser        = $ib0_net_ser + 1;
    $master_ib0_ip = $net->ip_unserialize($ib0_ip_ser);

    my $IB;
    if (not open($IB, q{>}, "$ib0_config_file")) {
        &eprint("Can't open $ib0_config_file: $ERRNO\n");
        &eprint("Skipping ib0 configuration.\n");
        return 1;
    }

    print $IB "DEVICE='ib0'";
    print $IB "BOOTPROTO='static'";
    print $IB "IPADDR=$master_ib0_ip";
    print $IB "PREFIX=$ib0_prefix" if (defined $ib0_prefix);
    print $IB "NETMASK=$ib0_mask";
    print $IB "NETWORK=$ib0_net";
    print $IB "BROADCAST=$ib0_broadcast";
    print $IB "ONBOOT=yes";

    close $IB;
    return;
}

1;

# vim:filetype=perl:syntax=perl:expandtab:sw=4:ts=4:
