# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#
#
# $Id: Tftp.pm 50 2010-11-02 01:15:57Z gmk $
#

package Warewulf::Provision::Tftp;

use Warewulf::Config;
use Warewulf::Logger;
use Warewulf::Object;
use File::Path;

our @ISA = ('Warewulf::Object');

my $singleton;

=head1 NAME

Warewulf::Tftp - Tftp integration

=head1 ABOUT


=head1 SYNOPSIS

    use Warewulf::Tftp;

    my $obj = Warewulf::Tftp->new();
    $obj->update($NodeObj);

=head1 METHODS

=over 12
=cut


=item new()

The new constructor will create the object that references configuration the
stores.

=cut
sub
new($$)
{
    my $proto = shift;
    my $class = ref($proto) || $proto;

    if (! $singleton) {
        $singleton = {};
        bless($singleton, $class);
        return $singleton->init(@_);
    } else {
        return($singleton);
    }
}


sub
init()
{
    my $self = shift;
    my $config = Warewulf::Config->new("provision.conf");
    my $tftpboot = $config->get("tftpboot");

    if (! $tftpboot) {
        if (-d "/var/lib/tftpboot") {
            &dprint("Found tftpboot directory at /var/lib/tftpboot\n");
            $self->set("TFTPROOT", "/var/lib/tftpboot");
        } elsif (-d "/tftpboot") {
            &dprint("Found tftpboot directory at /tftpboot\n");
            $self->set("TFTPROOT", "/tftpboot");
        } else {
            &cprint("Could not locate TFTP server directory!\n");
            return();
        }
    } elsif ($tftpboot =~ /^([a-zA-Z0-9_\-\/\.]+)$/) {
        $self->set("TFTPROOT", $1);
    } else {
        &eprint("TFTPBOOT configuration contains illegal characters!\n");
    }

    return($self);
}


=item tftpdir($dirname)

Get/set the system's TFTP directory.

=cut
sub
tftpdir()
{
    my ($self, $tftpdir) = @_;

    if ($tftpdir) {
        $self->set("TFTPROOT", $tftpdir);
    }

    return($self->get("TFTPROOT"));
}




=back

=head1 SEE ALSO

Warewulf::Object

=head1 COPYRIGHT

Copyright (c) 2001-2003 Gregory M. Kurtzer

Copyright (c) 2003-2011, The Regents of the University of California,
through Lawrence Berkeley National Laboratory (subject to receipt of any
required approvals from the U.S. Dept. of Energy).  All rights reserved.

=cut


1;
