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


=item size($string)

Set or return the size of the raw file stored within the datastore.

=cut

sub
size()
{
    my ($self, $string) = @_;
    my $key = "size";

    if (defined($string)) {
        if (uc($string) eq "UNDEF") {
            my $name = $self->get("name");
            &dprint("Object $name delete $key\n");
            $self->del($key);
        } elsif ($string =~ /^([0-9]+)$/) {
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


=item sync()

Resync any file objects to their origin(s) on the local file system. This will
persist immeadiatly to the DataStore.

Note: This will also update some metadata for this file.

=cut

sub
sync()
{
    my ($self) = @_;
    
    if ($self->origin()) {
        my $data;

        foreach my $origin ($self->origin()) {
            if ($origin =~ /^(\/[a-zA-Z0-9\-_\/\.]+)$/) {
                if (-f $origin) {
                    if (open(FILE, $origin)) {
                        while(my $line = <FILE>) {
                            $data .= $line;
                        }
                        close FILE;
                    }
                }
            }

        }

        if ($data) {
            my $db = Warewulf::DataStore->new();
            my $binstore = $db->binstore($self->id());
            my $total_len = length($data);
            my $cur_len = 0;
            my $start = 0;

            while($total_len > $cur_len) {
                my $buffer = substr($data, $start, $db->chunk_size());
                $binstore->put_chunk($buffer);
                $start += $db->chunk_size();
                $cur_len += length($buffer);
                &dprint("Chunked $cur_len of $total_len\n");
            }

            $self->checksum(md5_hex($data));
            $self->size($total_len);
            $db->persist($self);
        }

    }
}


=item file_import($file)

Import a file at the defined path into the datastore directly. This will
interact directly with the DataStore because large file imports may
exhaust memory.

Note: This will also update the object metadata for this file.

=cut

sub
file_import()
{
    my ($self, $path) = @_;

    my $id = $self->id();

    if (! $id) {
        &eprint("This object has no ID!\n");
        return();
    }

    if ($path) {
        if ($path =~ /^([a-zA-Z0-9_\-\.\/]+)$/) {
            if (-f $path) {
                my $db = Warewulf::DataStore->new();
                my $binstore = $db->binstore($id);
                my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($path);

                my $buffer;
                if (open(FILE, $path)) {
                    while(my $length = sysread(FILE, $buffer, $db->chunk_size())) {
                        &dprint("Chunked $length bytes of $path\n");
                        $binstore->put_chunk($buffer);
                        $size += $length;
                    }
                    close FILE;

                    if ($size) {
                        if (! $self->uid()) {
                            $self->uid($uid);
                        }
                        if (! $self->gid()) {
                            $self->gid($gid);
                        }
                        if (! $self->path()) {
                            $self->path($path);
                        }
                        if (! $self->mode()) {
                            $self->mode(sprintf("%05o", $mode & 07777));
                        }
                        $self->size($size);
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



=item file_export($file)

Export the data from a file object to a location on the file system.

=cut

sub
file_export()
{
    my ($self, $file) = @_;

    if ($file) {
        my $db = Warewulf::DataStore->new();
        if (! -f $file) {
            my $dirname = dirname($file);

            if (! -d $dirname) {
                mkpath($dirname);
            }
        }

        my $binstore = $db->binstore($self->id());
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
