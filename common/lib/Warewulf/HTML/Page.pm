# Copyright (c) 2003-2010, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 2 of the License, or (at your
# option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# The GNU GPL Document can be found at:
# http://www.gnu.org/copyleft/gpl.html
#
# $Id$
#

package Warewulf::HTML::Page;

use Warewulf::Util;
use Exporter;
use CGI;

=head1 NAME


=head1 ABOUT


=head1 SYNOPSIS

    use Warewulf::HTML::Page;

    # Create a new page object
    my $page = Warewulf::HTML::Page->new();

    # Optionally set the page's domain for cookies
    $page->domain("domainname");

    # Retrieve a paramater (POST, GET, or cookie in that order)
    my $param = $page->get("param");

    # Set a cookie
    $page->cookie("name", "value");

    # Get a cookie that has already been set
    my $cookie = $page->cookie("name");


=head1 METHODS

=over 12
=cut


=item new()

The new constructor will create the object.

=cut

sub
new($$)
{
    my $proto               = shift;
    my $class               = ref($proto) || $proto;
    my $self;

    %{$self} = ();

    bless($self, $class);

    $self->{"CGI"} = new CGI;

    $self->{"SESSION"} = $self->cookie("session");

    if (! defined($self->{"SESSION"})) {
        $self->{"SESSION"} = &rand_string(64);
        $self->cookie("session", $self->{"SESSION"});
    }


    return($self);
}



=item get(name)

This method will retrieve a paramater that was passed to the current page
either by POST/GET or cookie).

=cut
sub
get($$)
{
    my $self                = shift;
    my $param               = shift;

    return(defined($self->{"CGI"}->param($param)) ? $self->{"CGI"}->param($param) : $self->{"CGI"}->cookie("$param"));
}


sub
set($$$)
{
    my $self                = shift;
    my $param               = shift;
    my $value               = shift;

    $self->{"CGI"}->param($param, $value);

}


=item upload(paramater_name)

Get the file handle of a file that was uploaded via a form.

=cut
sub
upload($$)
{
    my $self                = shift;
    my $param               = shift;

    return(defined($self->{"CGI"}->upload($param)) and  $self->{"CGI"}->upload($param));
}

=item cookie(name, value)

You can either create a cookie or retrieve a cookie with this method. If you
pass a value, the cookie will be set. Without it, a cookie will be retrieved.

This can be called multiple times to create multiple cookies.

=cut
sub
cookie($$$)
{
    my $self                = shift;
    my $name                = shift;
    my $value               = shift;
    my $domain              = $self->domain() || "";

    if ($value) {
        push(@{$self->{"COOKIE_ARRAY"}}, $self->{"CGI"}->cookie(-name=>"$name", -value=>"$value", -expires=>"", -path=>'/', -domain=>"$domain"));
    }

    return($self->{"CGI"}->cookie("$name"));
}

=item domain(domain)

Set the domain that will be used for things like cookies

=cut
sub
domain($$)
{
    my $self                = shift;
    my $script              = shift;

    if ($script) {
        $self->{"DOMAIN"} = $script;
    }

    return($self->{"DOMAIN"});
}


=item session()

Return the session ID for this connection

=cut
sub
session($)
{
    my $self                = shift;

    return($self->{"SESSION"});
}


=item header()

Print the page header

=cut
sub
header($)
{
    my $self                = shift;
    my @args                = @_;
    return $self->{"CGI"}->header(-cookie=>\@{$self->{"COOKIE_ARRAY"}});
}



1;
