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
use Warewulf::EventHandler;
use File::Basename;
use File::Path;
use Digest::MD5 qw(md5_hex);



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


=item name($string)

Set or return the name of this object. The string "UNDEF" will delete this
key from the object.

=cut

sub
name()
{
    my $self = shift;
    
    return $self->prop("name", qr/^([a-zA-Z0-9_\.\-]+)$/, @_);
}


=item mode($string)

Set the numeric permission "mode" of this file (e.g. 0644).

=cut

sub
mode()
{
    my $self = shift;
    #my $validator = sub {
    #    if ($_[0] =~ /^(\d+)$/) {
    #        return ($1 & 07777);
    #    } else {
    #        return 0;
    #    };

    #return $self->prop("mode", $validator, @_);

    # The below basically does the same thing as the above, just faster.
    return $self->prop("mode", sub { return (keys %{ +{$_[0] & 07777,1} })[0] || 0; }, @_);
}

=item modestring()

Returns the file permissions in string form.

=cut

sub
modestring()
{
    my $self = shift;
    my $mode = $self->mode() || 0;
    my $str = '-';

    $str .= (($mode & 0400) ? ('r') : ('-'));
    $str .= (($mode & 0200) ? ('w') : ('-'));
    if ($mode & 04000) {
        $str .= (($mode & 0100) ? ('s') : ('S'));
    } else {
        $str .= (($mode & 0100) ? ('x') : ('-'));
    }
    $str .= (($mode & 0040) ? ('r') : ('-'));
    $str .= (($mode & 0020) ? ('w') : ('-'));
    if ($mode & 02000) {
        $str .= (($mode & 0010) ? ('s') : ('S'));
    } else {
        $str .= (($mode & 0010) ? ('x') : ('-'));
    }
    $str .= (($mode & 0004) ? ('r') : ('-'));
    $str .= (($mode & 0002) ? ('w') : ('-'));
    if ($mode & 01000) {
        $str .= (($mode & 0001) ? ('t') : ('T'));
    } else {
        $str .= (($mode & 0001) ? ('x') : ('-'));
    }
    return $str;
}


=item checksum($string)

Set or get the checksum of this file.

=cut

sub
checksum()
{
    my $self = shift;
    
    return $self->prop("checksum", qr/^([a-z0-9]+)$/, @_);
}


=item uid($string)

Set or return the UID of this file.

=cut

sub
uid()
{
    my $self = shift;
    
    return $self->prop("uid", qr/^(\d+)$/, @_) || 0;
}


=item gid($string)

Set or return the GID of this file.

=cut

sub
gid()
{
    my $self = shift;
    
    return $self->prop("gid", qr/^(\d+)$/, @_) || 0;
}


=item size($string)

Set or return the size of the raw file stored within the data store.

=cut

sub
size()
{
    my $self = shift;
    
    return $self->prop("size", qr/^(\d+)$/, @_);
}



=item path($string)

Set or return the file system path of this file.

=cut

sub
path()
{
    my $self = shift;
    
    return $self->prop("path", qr/^([a-zA-Z0-9_\.\-\/]+)$/, @_);
}


=item format($string)

Set or return the format of this file.

=cut

sub
format()
{
    my $self = shift;
    
    return $self->prop("format", qr/^([a-z]+)$/, @_);
}


=item interpreter($string)

Set or return the interpreter needed to parse this file

=cut

sub
interpreter()
{
    my $self = shift;
    
    return $self->prop("interpreter", qr/^([a-zA-Z0-9\.\/\-_]+)$/, @_);
}



=item origin(@strings)

Set or return the origin(s) of this object. "UNDEF" will delete all data.

=cut

sub
origin()
{
    my ($self, @strings) = @_;
    my $key = "origin";

    if (@strings) {
        my $name = $self->get("name");
        if (defined($strings[0])) {
            my @neworigins;
            foreach my $string (@strings) {
                if ($string =~ /^([a-zA-Z0-9_\.\-\/]+)$/) {
                    &dprint("Object $name set $key += '$1'\n");
                    push(@neworigins, $1);
                } else {
                    &eprint("Invalid characters to set $key += '$string'\n");
                }
                $self->set($key, @neworigins);
            }
        } else {
            $self->del($key);
            &dprint("Object $name del $key\n");
        }
    }

    return($self->get($key));
}


=item sync()

Resync any file objects to their origin on the local file system. This will
persist immediately to the DataStore.

Note: This will also update some metadata for this file.

=cut

sub
sync()
{
    my ($self) = @_;
    my $name = $self->name();
    
    if ($self->origin()) {
        my $data;

        &dprint("Syncing file object: $name\n");

        foreach my $origin ($self->origin()) {
            if ($origin =~ /^(\/[a-zA-Z0-9\-_\/\.]+)$/) {
                if (-f $origin) {
                    if (open(FILE, $origin)) {
                        &dprint("   Including file to sync: $origin\n");
                        while(my $line = <FILE>) {
                            $data .= $line;
                        }
                        close FILE;
                    } else {
                        &wprint("Could not open origin path ($origin) for file object '$name'\n");
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

            &dprint("Persisting file object '$name' origin(s)\n");

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

    } elsif ($name eq "dynamic_hosts") {
        my $event = Warewulf::EventHandler->new();
        $event->handle("dynamic_hosts.update", ());
        &dprint("File was dynamic_hosts; triggering dynamic_hosts.update event\n");

    } else {
        &dprint("Skipping file object '$name' as it has no origin paths set\n");
    }
}


=item file_import($file)

Import a file at the defined path into the data store directly. This will
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
                my $format;
                my $import_size = 0;
                my $buffer;
                my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($path);

                if (open(FILE, $path)) {
                    while(my $length = sysread(FILE, $buffer, $db->chunk_size())) {
                        if ($import_size == 0) {
                            if ($buffer =~ /^#!\/bin\/sh/) {
                                $format = "shell";
                            } elsif ($buffer =~ /^#!\/bin\/bash/) {
                                $format = "bash";
                            } elsif ($buffer =~ /^#!\/[a-zA-Z0-9\/_\.]+\/perl/) {
                                $format = "perl";
                            } elsif ($buffer =~ /^#!\/[a-zA-Z0-9\/_\.]+\/python/) {
                                $format = "python";
                            } else {
                                $format = "data";
                            }
                        }
                        &dprint("Chunked $length bytes of $path\n");
                        $binstore->put_chunk($buffer);
                        $import_size += $length;
                    }
                    close FILE;

                    if ($import_size) {
                        $self->size($import_size);
                        $self->checksum(digest_file_hex_md5($path));
                        $self->format($format);
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

    if ($file and $file =~ /^([a-zA-Z0-9\._\-\/]+)$/) {
        $file = $1;
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
