# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#
#

package Warewulf::File;

use Warewulf::Object;
use Warewulf::Logger;
use Warewulf::DataStore;
use Warewulf::Util;
use File::Basename;
use File::Path;


our @ISA = ('Warewulf::Object');

=head1 NAME

Warewulf::File - Warewulf's general object instance object interface.

=head1 ABOUT

This is the primary Warewulf interface for dealing with files within the
Warewulf DataStore.

=head1 SYNOPSIS

    use Warewulf::File;

    my $obj = Warewulf::File->new();

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
    my $self = ();

    $self = $class->SUPER::new();
    bless($self, $class);

    return $self->init(@_);
}


=item id()

Return the Database ID for this object.

=cut

sub
id()
{
    my ($self) = @_;

    return($self->get("_id") || "UNDEF");
}



=item name($string)

Set or return the name of this object. The string "UNDEF" will delete this
key from the object.

=cut

sub
name()
{
    my ($self, $string) = @_;
    my $key = "name";

    if (defined($string)) {
        if (uc($string) eq "UNDEF") {
            my $name = $self->get("name");
            &dprint("Object $name delete $key\n");
            $self->del($key);
        } elsif ($string =~ /^([a-zA-Z0-9_\.\-]+)$/) {
            my $name = $self->get("name") || "UNDEF";
            &dprint("Object $name set $key = '$1'\n");
            $self->set($key, $1);
        } else {
            &eprint("Invalid characters to set $key = '$string'\n");
        }
    }

    return($self->get($key) || "UNDEF");
}


=item mode($string)

Set the numeric permission "mode" of this file (e.g. 0644).

=cut

sub
mode()
{
    my ($self, $string) = @_;
    my $key = "mode";

    if (defined($string)) {
        if (uc($string) eq "UNDEF") {
            my $name = $self->get("name");
            &dprint("Object $name delete $key\n");
            $self->del($key);
        } elsif ($string =~ /^(\d+)$/) {
            my $name = $self->get("name");
            &dprint("Object $name set $key = '$1'\n");
            $self->set($key, $1);
        } else {
            &eprint("Invalid characters to set $key = '$string'\n");
        }
    }

    return($self->get($key) || "UNDEF");
}


=item checksum($string)

Set or get the checksum of this file.

=cut

sub
checksum()
{
    my ($self, $string) = @_;
    my $key = "checksum";

    if (defined($string)) {
        if (uc($string) eq "UNDEF") {
            my $name = $self->get("name");
            &dprint("Object $name delete $key\n");
            $self->del($key);
        } elsif ($string =~ /^([a-z0-9]+)$/) {
            my $name = $self->get("name");
            &dprint("Object $name set $key = '$1'\n");
            $self->set($key, $1);
        } else {
            &eprint("Invalid characters to set $key = '$string'\n");
        }
    }

    return($self->get($key) || "UNDEF");
}


=item uid($string)

Set or return the UID of this file.

=cut

sub
uid()
{
    my ($self, $string) = @_;
    my $key = "uid";

    if (defined($string)) {
        if (uc($string) eq "UNDEF") {
            my $name = $self->get("name");
            &dprint("Object $name delete $key\n");
            $self->del($key);
        } elsif ($string =~ /^(\d+)$/) {
            my $name = $self->get("name");
            &dprint("Object $name set $key = '$1'\n");
            $self->set($key, $1);
        } else {
            &eprint("Invalid characters to set $key = '$string'\n");
        }
    }

    return($self->get($key) || "UNDEF");
}


=item gid($string)

Set or return the GID of this file.

=cut

sub
gid()
{
    my ($self, $string) = @_;
    my $key = "gid";

    if (defined($string)) {
        if (uc($string) eq "UNDEF") {
            my $name = $self->get("name");
            &dprint("Object $name delete $key\n");
            $self->del($key);
        } elsif ($string =~ /^(\d+)$/) {
            my $name = $self->get("name");
            &dprint("Object $name set $key = '$1'\n");
            $self->set($key, $1);
        } else {
            &eprint("Invalid characters to set $key = '$string'\n");
        }
    }

    return($self->get($key) || "UNDEF");
}


=item path($string)

Set or return the target path of this file.

=cut

sub
path()
{
    my ($self, $string) = @_;
    my $key = "path";

    if (defined($string)) {
        if (uc($string) eq "UNDEF") {
            my $name = $self->get("name");
            &dprint("Object $name delete $key\n");
            $self->del($key);
        } elsif ($string =~ /^([a-zA-Z0-9_\.\-\/]+)$/) {
            my $name = $self->get("name");
            &dprint("Object $name set $key = '$1'\n");
            $self->set($key, $1);
        } else {
            &eprint("Invalid characters to set $key = '$string'\n");
        }
    }

    return($self->get($key) || "UNDEF");
}



=item origin(@strings)

Set or return the origin(s) of this object.

=cut

sub
origin()
{
    my ($self, @strings) = @_;
    my $key = "origin";

    if (@strings) {
        my $name = $self->get("name");
        my @newgroups;
        foreach my $string (@strings) {
            if ($string =~ /^([a-zA-Z0-9_\.\-\/]+)$/) {
                &dprint("Object $name set $key += '$1'\n");
                push(@newgroups, $1);
            } else {
                &eprint("Invalid characters to set $key += '$string'\n");
            }
            $self->set($key, @newgroups);
        }
    }

    return($self->get($key));
}


=item import($file)

Import a file at the defined path into the datastore directly. This will
interact directly with the DataStore because large file imports may
exhaust memory.

Note: This will also update the object metadata for this file.

=cut

sub
import()
{
    my ($self, $path) = @_;

    if ($path) {
        if ($path =~ /^([a-zA-Z0-9_\-\.\/]+)$/) {
            if (-f $path) {
                my $db = Warewulf::DataStore->new();
                my $binstore = $db->binstore($self->id());
                my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($path);
                my $size;

                my $size;
                my $buffer;
                if (open(FILE, $path)) {
                    while(my $length = sysread(FILE, $buffer, $db->chunk_size())) {
                        &dprint("Chunked $length bytes of $path\n");
                        $binstore->put_chunk($buffer);
                        $size += $length;
                    }
                    close FILE;

                    if ($size) {
                        $self->size($size);
                        $self->uid($uid);
                        $self->gid($gid);
                        $self->path($path);
                        $self->mode(sprintf("%05o", $mode & 07777));
                        $self->checksum(digest_file_hex_md5($path));
                        $db->persist($self);
                    } else {
                        &eprint("Could not import file!\n");
                    }
                } else {
                    &eprint("Could not open file: $!\n");
                }
            } else {
                &eprint("File not found: $path\n");
            }
        } else {
            &eprint("Invalid characters in file name: $path\n");
        }
    }
}



=item export($file)

Export the data from a file object to a location on the file system.

=cut

sub
export()
{
    my ($self, $file) = @_;

    if ($file) {
        if (! -f $file) {
            my $dirname = dirname($file);

            if (! -d $dirname) {
                mkpath($dirname);
            }
        }

        my $binstore = $db->binstore($obj->get("_id"));
        if (open(FILE, "> $file")) {
            while(my $buffer = $binstore->get_chunk()) {
                print FILE $buffer;
            }
            close FILE;
        } else {
            &eprint("Could not open file for writing: $!\n");
        }
    }
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
