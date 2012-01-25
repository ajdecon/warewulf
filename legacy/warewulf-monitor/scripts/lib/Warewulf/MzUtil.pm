# Mezzanine Utilities Perl Module
# 
# Copyright (C) 2001-2009, Michael Jennings
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies of the Software, its documentation and marketing & publicity
# materials, and acknowledgment shall be given in the documentation, materials
# and software packages that this Software was used.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
# $Id: Util.pm,v 1.74 2011/02/01 08:42:25 mej Exp $
#

package Warewulf::MzUtil;
use Exporter;
use POSIX;
use English;
use Getopt::Long;
use File::Find;
use File::Copy;
use File::stat;
use URI;
use LWP::UserAgent;
use HTTP::Cookies;
use HTTP::Request;
use vars '$VERSION', '@ISA', '@EXPORT', '@EXPORT_OK', '%EXPORT_TAGS',
    '$debug', '$PROGNAME', '$VERSION', '$mz_uid', '$mz_gid', '%OPTION';

BEGIN {
    # set the version for version checking
    $VERSION     = 2.1;

    @ISA         = ('Exporter');

    @EXPORT = ('$debug', '$PROGNAME', '$VERSION', '$mz_uid',
               '$mz_gid', '%OPTION', '&mezz_init', '&bool_config_opt',
               '&debug_get', '&debug_set', '&print_version',
               '&file_user', '&file_group', '&file_owner',
               '&get_timestamp', '&fatal_error', '&dprintf',
               '&dprint', '&eprintf', '&eprint', '&wprintf',
               '&wprint', '&handle_signal', '&handle_fatal_signal',
               '&install_signal_handlers', '&handle_warning',
               '&get_backtrace', '&show_backtrace', '&print_args',
               '&untaint', '&is_tainted', '&examine_object',
               '&int_to_bytes', '&mkdirhier', '&nuke_tree',
               '&move_files', '&copy_files', '&copy_tree',
               '&get_temp_dir', '&create_temp_space',
               '&clean_temp_space', '&basename', '&dirname',
               '&grepdir', '&limit_files', '&str_trim', '&str_tokens',
               '&xpush', '&cat_file', '&parse_rpm_name',
               '&find_spec_file', '&should_ignore', '&trunc_file',
               '&touch_file', '&newest_file', '&checksum_file',
               '&run_cmd', '&run_mz_cmd', '&fetch_url', '&post_file',
               '&MEZZANINE_SUCCESS', '&MEZZANINE_FATAL_ERROR',
               '&MEZZANINE_SYNTAX_ERROR', '&MEZZANINE_SYSTEM_ERROR',
               '&MEZZANINE_COMMAND_FAILED', '&MEZZANINE_DUPLICATE',
               '&MEZZANINE_FILE_NOT_FOUND',
               '&MEZZANINE_FILE_OP_FAILED', '&MEZZANINE_UNSUPPORTED',
               '&MEZZANINE_ACCESS_DENIED', '&MEZZANINE_BAD_ADDITION',
               '&MEZZANINE_BAD_LOG_ENTRY', '&MEZZANINE_BAD_LOGIN',
               '&MEZZANINE_BAD_REMOVAL', '&MEZZANINE_CONFLICT_FOUND',
               '&MEZZANINE_FILE_REMOVED', '&MEZZANINE_INVALID_TAG',
               '&MEZZANINE_NEED_UPDATE', '&MEZZANINE_NO_SERVER',
               '&MEZZANINE_NO_SOURCES', '&MEZZANINE_SERVER_CRASH',
               '&MEZZANINE_BAD_PRODUCT', '&MEZZANINE_SPAWN_FAILED',
               '&MEZZANINE_PACKAGE_FAILED',
               '&MEZZANINE_BUILD_UNNEEDED',
               '&MEZZANINE_ARCH_MISMATCH', '&MEZZANINE_BAD_MODULE',
               '&MEZZANINE_BUILD_FAILURE', '&MEZZANINE_DEPENDENCIES',
               '&MEZZANINE_MISSING_FILES', '&MEZZANINE_EXTRA_FILES',
               '&MEZZANINE_SPEC_ERRORS', '&MEZZANINE_MISSING_PKGS',
               '&MEZZANINE_INVALID_PACKAGE', '&MEZZANINE_TERMINATED',
               '&MEZZANINE_CRASHED', '&MEZZANINE_UNSPECIFIED_ERROR');

    %EXPORT_TAGS = ( );

    # Exported variables go here
    @EXPORT_OK   = ('$VERSION');
}
use vars ('@EXPORT_OK');

### Private global variables

### Initialize exported package variables
$debug = 0;
$PROGNAME = "Mezzanine";
$VERSION = "0.0";
$mz_uid = $UID;
($mz_gid = $GID) =~ s/\s+.*$//;
%OPTION = ();

### Initialize private global variables
my $CMD_TIMEOUT = 0;

### Function prototypes
sub mezz_init($$@);
sub bool_config_opt($$$$);
sub debug_get();
sub debug_set($);
sub print_version($$$$);
sub file_user($);
sub file_group($);
sub file_owner($$$);
sub get_timestamp();
sub fatal_error(@);
sub dprintf(@);
sub dprint(@);
sub eprintf(@);
sub eprint(@);
sub wprintf(@);
sub wprint(@);
sub handle_signal(@);
sub handle_fatal_signal(@);
sub install_signal_handlers();
sub handle_warning(@);
sub get_backtrace();
sub show_backtrace();
sub print_args(@);
sub untaint($);
sub is_tainted($);
sub examine_object(@);
sub int_to_bytes($);
sub mkdirhier($$);
sub nuke_tree($);
sub move_files(@);
sub copy_files(@);
sub copy_tree($$);
sub get_temp_dir();
sub create_temp_space($$$);
sub clean_temp_space($);
sub basename($);
sub dirname($);
sub grepdir(& $);
sub str_trim(\$);
sub str_tokens($$);
sub xpush(\@; @);
sub limit_files(@ $);
sub cat_file($);
sub parse_rpm_name($);
sub find_spec_file($$);
sub should_ignore($);
sub trunc_file($);
sub touch_file($);
sub newest_file($);
sub checksum_file($);
sub fetch_url($);
sub post_file(@);
sub handle_alarm_for_subcommand(@);
sub find_cookie_jar($);

### Module cleanup
END {
}

### Return value constants
# No error
sub MEZZANINE_SUCCESS()             {0;}

# General errors
sub MEZZANINE_FATAL_ERROR()         {1;}
sub MEZZANINE_SYNTAX_ERROR()        {2;}
sub MEZZANINE_SYSTEM_ERROR()        {3;}
sub MEZZANINE_COMMAND_FAILED()      {4;}
sub MEZZANINE_FILE_NOT_FOUND()      {5;}
sub MEZZANINE_FILE_OP_FAILED()      {6;}
sub MEZZANINE_UNSUPPORTED()         {7;}

# revtool-related errors
sub MEZZANINE_ACCESS_DENIED()      {21;}
sub MEZZANINE_BAD_ADDITION()       {22;}
sub MEZZANINE_BAD_LOG_ENTRY()      {23;}
sub MEZZANINE_BAD_LOGIN()          {24;}
sub MEZZANINE_BAD_REMOVAL()        {25;}
sub MEZZANINE_CONFLICT_FOUND()     {26;}
sub MEZZANINE_FILE_REMOVED()       {27;}
sub MEZZANINE_INVALID_TAG()        {28;}
sub MEZZANINE_NEED_UPDATE()        {29;}
sub MEZZANINE_NO_SERVER()          {30;}
sub MEZZANINE_NO_SOURCES()         {31;}
sub MEZZANINE_SERVER_CRASH()       {32;}
sub MEZZANINE_DUPLICATE()          {33;}

# buildtool-related errors
sub MEZZANINE_BAD_PRODUCT()        {51;}
sub MEZZANINE_SPAWN_FAILED()       {52;}
sub MEZZANINE_PACKAGE_FAILED()     {53;}
sub MEZZANINE_BUILD_UNNEEDED()     {54;}

# pkgtool-related errors
sub MEZZANINE_ARCH_MISMATCH()      {61;}
sub MEZZANINE_BAD_MODULE()         {62;}
sub MEZZANINE_BUILD_FAILURE()      {63;}
sub MEZZANINE_DEPENDENCIES()       {64;}
sub MEZZANINE_MISSING_FILES()      {65;}
sub MEZZANINE_EXTRA_FILES()        {66;}
sub MEZZANINE_SPEC_ERRORS()        {67;}

# compstool-related errors
sub MEZZANINE_MISSING_PKGS()       {81;}

# srctool-related errors
sub MEZZANINE_INVALID_PACKAGE()    {100;}

# Abnormal errors
sub MEZZANINE_TERMINATED()        {120;}
sub MEZZANINE_CRASHED()           {121;}
sub MEZZANINE_UNSPECIFIED_ERROR() {127;}


### Function definitions

# Perform common startup tasks, including option parsing.
sub
mezz_init($$@)
{
    my @valid_opts;

    $PROGNAME = shift;
    $VERSION = shift;
    @valid_opts = @_;

    $ENV{"LANG"} = "C" if (! $ENV{"LANG"});
    umask 022;
    &install_signal_handlers();
    select STDERR; $| = 1;
    select STDOUT; $| = 1;

    Getopt::Long::Configure("no_getopt_compat", "bundling", "no_ignore_case");
    Getopt::Long::GetOptions(\%OPTION, @valid_opts);
    return %OPTION;
}

# Convenience function for handling a boolean config variable with a command-line option.
sub
bool_config_opt($$$$)
{
    my ($config, $cfgname, $optname, $default) = @_;

    if (!defined($default)) {
        $default = 0;
    }
    if (defined($OPTION{$optname})) {
        return $config->set($cfgname, $OPTION{$optname});
    } elsif (defined($config->get($cfgname))) {
        return $config->get($cfgname);
    } else {
        return $config->set($cfgname, $default);
    }
}

# Get debugging state
sub
debug_get()
{
    return $debug;
}

sub
debug_set($)
{
    $debug = $_[0];
}

sub
print_version($$$$)
{
    my ($progname, $version, $author, $rcs_info) = @_;

    $rcs_info =~ s/\$\s*Revision: (\S+) \$/$1/;
    $rcs_info =~ s/\$\s*Date: (\S+) (\S+) \$/$1 at $2/;
    $rcs_info =~ s/\$\s*Author: (\S+) \$ /$1/;
    print "\n";
    print "$progname $version by $author\n";
    print "Copyright (c) 2000-2007, $author\n";
    print "  ($rcs_info)\n";
    print "\n";
    exit MEZZANINE_SUCCESS;
}

sub
file_user($)
{
    if (defined($_[0])) {
        $mz_uid = $_[0];
    }
    dprint "UID:  $mz_uid\n";
    return $mz_uid;
}

sub
file_group($)
{
    if (defined($_[0])) {
        $mz_gid = $_[0];
    }
    dprint "GID:  $mz_gid\n";
    return $mz_gid;
}

sub
file_owner($$$)
{
    my ($user, $group, $root) = @_;
    local *PASSWD;
    local *GROUP;

    if ($user) {
        if (! $group) {
            $group = $user;
        }
        if (! $root) {
            $root = "";
        }

        open(PASSWD, "$root/etc/passwd") || return undef;
        while (<PASSWD>) {
            my $line;
            my @inp;

            chomp($line = $_);
            next if (substr($line, 0, length($user)) ne $user);
            @inp = split(':', $line);
            ($mz_uid, $mz_gid) = ($inp[2], $inp[3]);
            last;
        }
        close(PASSWD);

        open(GROUP, "$root/etc/group") || return ($mz_uid, $mz_gid);
        while (<GROUP>) {
            my $line;
            my @inp;

            chomp($line = $_);
            next if (substr($line, 0, length($group)) ne $group);
            @inp = split(':', $line);
            $mz_gid = $inp[2];
            last;
        }
        close(GROUP);
    }
    #dprint "UID:  $mz_uid     GID:  $mz_gid\n";
    return ($mz_uid, $mz_gid);
}

# Generate timestamp for debugging/log file
sub
get_timestamp()
{
    return POSIX::strftime("%A, %d %B %Y %H:%M:%S %Z", localtime);
}

# Report a fatal error
sub
fatal_error(@)
{
    print STDERR "$PROGNAME:  FATAL:  ", @_;
    exit(MEZZANINE_FATAL_ERROR);
}

# Debugging output
sub
dprintf(@)
{
    my ($f, $l, $s, $format);
    my @params = @_;

    return if (! $debug);
    $format = shift @params;
    if (!scalar(@params)) {
        return dprint($format);
    }
    (undef, undef, undef, $s) = caller(1);
    if (!defined($s)) {
        $s = "MAIN";
    }
    (undef, $f, $l) = caller(0);
    $f =~ s/^.*\/([^\/]+)$/$1/;
    $s =~ s/^\w+:://g;
    $s .= "()" if ($s =~ /^\w+$/);
    $f = "" if (!defined($f));
    $l = "" if (!defined($l));
    $format = "" if (!defined($format));
    for (my $i = 0; $i < scalar(@params); $i++) {
        if (!defined($params[$i])) {
            $params[$i] = "<undef>";
        }
    }
    if ($f ne $PROGNAME) {
        $f = "$PROGNAME/$f";
    }
    printf("[$f/$l/$s] $format", @params);
}

sub
dprint(@)
{
    my ($f, $l, $s);
    my @params = @_;

    return if (! $debug);
    (undef, undef, undef, $s) = caller(1);
    if (!defined($s)) {
        $s = "MAIN";
    }
    (undef, $f, $l) = caller(0);
    $f =~ s/^.*\/([^\/]+)$/$1/;
    $s =~ s/\w+:://g;
    $s .= "()" if ($s =~ /^\w+$/);
    $f = "" if (!defined($f));
    $l = "" if (!defined($l));
    $s = "" if (!defined($s));
    for (my $i = 0; $i < scalar(@params); $i++) {
        if (!defined($params[$i])) {
            $params[$i] = "<undef>";
        }
    }
    if ($f ne $PROGNAME) {
        $f = "$PROGNAME/$f";
    }
    print "[$f/$l/$s] ", @params;
}

# Print an error
sub
eprintf(@)
{
    print "$PROGNAME:  Error:  ";
    printf @_;
}
sub
eprint(@)
{
    print "$PROGNAME:  Error:  ", @_;
}

# Print a warning
sub
wprintf(@)
{
    print "$PROGNAME:  Warning:  ";
    printf @_;
}
sub
wprint(@)
{
    print "$PROGNAME:  Warning:  ", @_;
}

# Handle a terminate signal
sub
handle_signal(@)
{
    my $sig = $_[0];

    eprint "Someone sent me a SIG$sig asking me to exit, so I shall.\n";
    if (&debug_get()) {
        &show_backtrace();
    }
    exit MEZZANINE_TERMINATED;
}

# Handle a fatal signal
sub
handle_fatal_signal(@)
{
    my $sig = $_[0];

    eprint "Caught fatal signal SIG$sig.  Cleaning up and aborting...\n";
    exit MEZZANINE_CRASHED;
}

# Install standard signal handlers.
sub
install_signal_handlers()
{
    # Signal handling
    $SIG{"__WARN__"} = \&handle_warning;
    $SIG{"HUP"} = "IGNORE";
    $SIG{"INT"} = \&handle_signal;
    $SIG{"TERM"} = \&handle_signal;
    $SIG{"QUIT"} = \&handle_fatal_signal;
    $SIG{"ILL"} = \&handle_fatal_signal;
    $SIG{"ABRT"} = \&handle_fatal_signal;
    $SIG{"FPE"} = \&handle_fatal_signal;
    $SIG{"SEGV"} = \&handle_fatal_signal;
    $SIG{"BUS"} = \&handle_fatal_signal;
    #$SIG{"TSTP"} = \&handle_fatal_signal;
    #$SIG{"TTIN"} = \&handle_fatal_signal;
    #$SIG{"TTOU"} = \&handle_fatal_signal;
}

# Handle a perl warning
sub
handle_warning(@)
{
    if ($_[0] !~ /^Name \"\S+::opt_\w+\" used only once/) {
        dprint @_;
    }
    if ($_[0] =~ /^Deep recursion/) {
        &show_backtrace();
        &fatal_error("Aborting program due to excessive recursion.\n");
    }
}
BEGIN {
    # Take care of this ASAP at load time....
    $SIG{__WARN__} = \&handle_warning;
}

# Create a stack trace
sub
get_backtrace()
{
    my $start = shift || 1;
    my ($file, $line, $subroutine);
    my (@trace, @tmp);

    for (my $i = $start; @tmp = caller($i); $i++) {
        $subroutine = $tmp[3];
        (undef, $file, $line) = caller($i - 1);
        $file =~ s/^.*\/([^\/]+)$/$1/;
        push @trace, sprintf("%s\[%d\] $subroutine() at $file:$line\n",  ' ' x $i, $i - $start);
    }
    return @trace;
}

# Print a stack trace
sub
show_backtrace()
{
    my ($file, $line, $subroutine, $i);
    my @tmp;

    print "\n\nSTACK TRACE:\n";
    print "------------\n";
    print &get_backtrace(2);
}

# Print function arguments
sub
print_args(@)
{
    my @args;

    foreach my $arg (@_) {
        if (defined($arg)) {
            push @args, $arg;
        } else {
            push @args, "<undef>";
        }
    }
    return "Args:  \"" . join("\", \"", @args) . "\"\n";
}

# Untaint a variable based on a regular expression.
sub
untaint(@) {
    my @ret;

    while (scalar(@_)) {
        my $var_ref = shift;
        my $regexp;

        if (defined($_[0]) && (!ref($_[0]) || (ref($_[0]) eq "Regexp"))) {
            $regexp = $_[0];
            shift;
        } else {
            $regexp = qr/^([^\`]*)$/;
        }
        if (ref($var_ref) eq "SCALAR") {
            if (${$var_ref} =~ $regexp) {
                ${$var_ref} = $1;
                push @ret, ${$var_ref};
            } else {
                eprintf("Unable to untaint %s \"%s\":  $regexp does not match.\n", $var_ref, ${$var_ref});
                push @ret, '';
            }
        } else {
            eprintf("Invalid reference passed to untaint():  %s %s\n", ref($var_ref), $var_ref);
            push @ret, undef;
        }
    }
    if (wantarray()) {
        return @ret;
    } else {
        return $ret[0];
    }
}

# Check whether or not a particular variable is tainted.
sub
is_tainted($) {
    # "Borrowed" from the perlsec man page.
    return ! eval { eval("#" . substr($_[0], 0, 0)); 1 };
}

# Recursively descend a variable for debugging.
sub
examine_object(@)
{
    my ($item, $buffer, $indent, $indent_step) = @_;
    my $tainted;

    # Set default parameters.
    if (!defined($buffer)) {
        $buffer = "";
    }
    if (!defined($indent)) {
        $indent = 0;
    }
    if (!defined($indent_step)) {
        $indent_step = 4;
    }
    if (&is_tainted($item)) {
        $tainted = ' *TAINTED*';
    } else {
        $tainted = '';
    }

    # Figure out what type it is first.
    if (!defined($item)) {
        $buffer .= "UNDEF";
    } elsif (ref($item)) {
        my $type = ref($item);

        if ($type eq "SCALAR") {
            $buffer .= "SCALAR REF $item$tainted {\n" . (' ' x ($indent + $indent_step));
            $buffer = &examine_object(${$item}, $buffer, $indent + $indent_step, $indent_step);
            $buffer .= "\n" . (' ' x $indent) . '}';
        } elsif ($type eq "ARRAY") {
            $buffer .= "ARRAY REF $item$tainted {\n";
            for (my $i = 0; $i < scalar(@{$item}); $i++) {
                $buffer .= (' ' x ($indent + $indent_step)) . "$i:  ";
                $buffer = &examine_object($item->[$i], $buffer, $indent + $indent_step, $indent_step) . "\n";
            }
            $buffer .= (' ' x $indent) . '}';
        } elsif ($type eq "HASH") {
            $buffer .= "HASH REF $item$tainted {\n";
            foreach my $key (sort(keys(%{$item}))) {
                $buffer .= (' ' x ($indent + $indent_step));
                $buffer = &examine_object($key, $buffer, $indent + $indent_step, $indent_step) . " => ";
                $buffer = &examine_object($item->{$key}, $buffer, $indent + $indent_step, $indent_step) . "\n";
            }
            $buffer .= (' ' x $indent) . '}';
        } elsif ($type eq "CODE") {
            $buffer .= "CODE REF $item$tainted";
        } elsif ($type eq "REF") {
            $buffer .= "REF REF $item$tainted {\n" . (' ' x ($indent + $indent_step));
            $buffer = &examine_object(${$item}, $buffer, $indent + $indent_step, $indent_step);
            $buffer .= "\n" . (' ' x $indent) . '}';
        } elsif ($type eq "GLOB") {
            $buffer .= "GLOB REF $item$tainted";
        } elsif ($type eq "LVALUE") {
            $buffer .= "LVALUE REF $item$tainted";
        #} elsif ($type eq "Regexp") {
        } else {
            # Some object type.
            $buffer .= ref($item) . " REF $item$tainted {\n" . (' ' x ($indent + $indent_step));
            if (UNIVERSAL::isa($item, "CODE")) {
                $item = \&{$item};
            } elsif (UNIVERSAL::isa($item, "REF")) {
                $item = \${$item};
            } elsif (UNIVERSAL::isa($item, "HASH")) {
                $item = \%{$item};
            } elsif (UNIVERSAL::isa($item, "ARRAY")) {
                $item = \@{$item};
            } else {
                $item = \"UNKNOWN";  #"
            }
            $buffer = &examine_object($item, $buffer, $indent + $indent_step, $indent_step);
            $buffer .= "\n" . (' ' x $indent) . '}';
        }
    } elsif ($item =~ /^\d+$/) {
        $buffer .= "$item$tainted";
    } else {
        $buffer .= sprintf("\"%s\" (%d)%s", $item, length($item), $tainted);
    }
    return $buffer;
}

# Convert an integer to a bytes term.
sub
int_to_bytes($)
{
    my $num = $_[0];
    my ($suffix, $remainder);
    my @suffixes = ('B', "kB", "MB", "GB", "TB", "PB", "EB");

    for ($suffix = 0; $num >= 1024; $suffix++) {
        $remainder = $num % 1024;
        $num = sprintf("%7.6f", ($num / 1024));
    }
    $num = sprintf("%2.1f", $num);
    if (substr($num, -2, 2) eq ".0") {
        $num = int($num);
    }
    return $num . $suffixes[$suffix];
}

# Make a directory hierarchy
sub
mkdirhier($$)
{
    my ($dir, $mask) = @_;
    my @dirs;
    my $path = "";

    if (! $dir) {
        eprint "mkdirhier() called with empty directory!\n";
        &show_backtrace();
        return 0;
    }
    if (-d $dir) {
        #dprint "$dir exists, no need to create it.\n";
        return 1;
    }
    if (!defined($mask)) {
        $mask = 0755;
    }

    #dprint "mkdirhier($dir) called.\n";
    @dirs = split("/", $dir);
    foreach my $dir (@dirs) {
        $path .= "$dir/";
        if (! -d $path) {
            #dprint "Creating \"$path\"\n";
            mkdir($path, $mask) || eprint("Unable to create $path -- $!\n");
            #dprint "chown $mz_uid:$mz_gid $path\n";
            chown($mz_uid, $mz_gid, $path);
        }
    }
    if (! -d $_[0]) {
        dprint "Something went wrong in mkdirhier()!\n";
        return 0;
    } else {
        #dprint "Created $_[0] for $mz_uid:$mz_gid.\n";
        return 1;
    }
}

# Emulate rm -rf
sub
nuke_tree($)
{
    my @files;
    local *DIR;

    foreach my $path (@_) {
        if ($path && ($path =~ /^([^\0\`]+)$/)) {
            $path = $1;
        } else {
            next;
        }
        if ((-d $path) && !(-l $path)) {
            opendir(DIR, $path) || return 0;
            @files = readdir(DIR);
            closedir(DIR);
            foreach my $f (@files) {
                if ($f ne "." && $f ne "..") {
                    &nuke_tree("$path/$f");
                }
            }
            #dprint "Removing directory $path\n";
            rmdir $path || return 0;
        } else {
            #dprint "Unlinking $path\n";
            unlink($path) || return 0;
        }
    }
    return 1;
}

# Move files, a la "mv"
sub
move_files(@)
{
    # Last arg is destination
    my $dest = pop;
    my @flist = @_;
    my $fcnt = 0;
    my $addname = 0;

    if (!scalar(@flist)) {
        return 0;
    }
    if (-d $dest) {
        # We'll need to add the filename to the dest each time
        $dest .= '/' if ($dest !~ /\/$/);
        $addname = 1;
    } elsif (! -l $dest) {
        unlink($dest);
    }
    #dprint "Moving ", join(' ', @flist), " to $dest.\n";
    foreach my $f (@flist) {
        my ($target, $mode, $statobj);

        if ($addname) {
            ($target = $f) =~ s/^(.*\/)?([^\/]+)$/$dest$2/;
        } else {
            $target = $dest;
        }

        # Save permissions of the source file.
        $statobj = stat($f);
        if ($statobj) {
            $mode = ($statobj->mode() & 0775) || 0600;
        } else {
            $mode = 0600;
        }

        if (! -l $target) {
            unlink($target);
        }
        &mkdirhier(&dirname($target));
        if (!&File::Copy::move($f, $target)) {
            eprint "Unable to move $f to $target -- $!\n";
            return $fcnt;
        }

        # Set permissions on the target file appropriately.
        #dprint "chown $mz_uid:$mz_gid $target\n";
        chown($mz_uid, $mz_gid, $target) || dprint "chown($mz_uid, $mz_gid, $target) failed -- $!\n";
        chmod($mode, $target) || dprintf("chmod(%05o, $target) failed -- $!\n", $mode);
        $fcnt++;
    }
    return $fcnt;
}

# Copy files, a la "cp"
sub
copy_files(@)
{
    # Last arg is destination
    my $dest = pop;
    my @flist = @_;
    my $fcnt = 0;
    my $addname = 0;

    #dprintf("Copy params:  %s | %s\n", &examine_object($dest), &examine_object(\@flist));
    if (!scalar(@flist)) {
        # Nothing to do!
        return 0;
    } elsif ((! -d $dest) && (! -d $flist[0]) && (scalar(@flist) == 1)) {
        my $fname = $flist[0];

        # One-to-one file copy.
        dprint "Copying file $fname to $dest.\n";
        if (&File::Copy::copy($fname, $dest)) {
            $fcnt = 1;
            chown($mz_uid, $mz_gid, $dest) || dprint "chown($mz_uid, $mz_gid, $dest) failed -- $!\n";
        }
        return $fcnt;
    } elsif (-d $dest) {
        # We'll need to add the filename to the dest each time
        $dest .= '/' if ($dest !~ /\/$/);
        $addname = 1;
    } elsif (! -l $dest) {
        unlink($dest);
    }
    dprint "Copying ", join(' ', @flist), " to $dest.\n";
    foreach my $f (grep(-f $_, @flist)) {
        my ($target, $mode);

        if ($addname) {
            $target = $dest . &basename($f);
        } else {
            $target = $dest;
        }

        # Save permissions of the source file.
        $mode = ((stat($f))->mode() & 0775) || 0600;

        if (! -l $target) {
            unlink($target);
        }
        &mkdirhier(&dirname($target));
        if (!&File::Copy::copy($f, $target)) {
            eprint "Unable to copy $f to $target -- $!.  Copied $fcnt files.\n";
            return $fcnt;
        }

        # Set permissions on the target file appropriately.
        #dprint "chown $mz_uid:$mz_gid $target\n";
        chown($mz_uid, $mz_gid, $target) || dprint "chown($mz_uid, $mz_gid, $target) failed -- $!\n";
        chmod($mode, $target) || dprintf("chmod(%05o, $target) failed -- $!\n", $mode);
        $fcnt++;
    }
    return $fcnt;
}

# Copy an entire directory tree
sub
copy_tree($$)
{
    my ($old_path, $new_path) = @_;
    my @files;
    local *DIR;

    if (-d $new_path) {
        # The destination is a directory that already exists.
        if (substr($new_path, -1, 1) ne '/') {
            $new_path .= '/';
        }
        $new_path .= &basename($old_path);
    }

    if (-d $old_path && !(-l $old_path)) {
        my $file_stats;
        my $fcnt = 0;

        # The source is a directory.
        $file_stats = stat($old_path);

        # Create the destination directory.
        dprint "Creating target directory $new_path for $old_path.\n";
        if (! mkdir($new_path, $file_stats->mode & 07775)) {
            eprint "Unable to create directory $new_path -- $!\n";
            return 0;
        }
        chown($mz_uid, $mz_gid, $new_path);

        $fcnt += &copy_files(&grepdir(sub {! -d $_}, $old_path), $new_path);
        @files = &grepdir(sub {-d $_}, $old_path);
        foreach my $srcdir (@files) {
            my $dir = &basename($srcdir);

            next if ($dir eq "." || $dir eq "..");
            $fcnt += &copy_tree($srcdir, "$new_path/$dir");
        }
        return $fcnt;
    } else {
        # The source is a file.
        dprint "Direct copying $old_path to $new_path.\n";
        return &copy_files($old_path, $new_path);
    }
}

# Use proper TEMP directory.
sub
get_temp_dir()
{
    foreach my $var ("MEZZANINE_TMP", "MEZZANINE_TEMP", "MEZZANINE_TEMPDIR", "MEZZANINE_TMPDIR", "TEMP", "TMP", "TMPPATH") {
        if ($ENV{$var} && -d $ENV{$var} && -w _) {
            return $ENV{$var};
        }
    }
    return "/var/tmp";
}

# Create temporary working space in /var/tmp
sub
create_temp_space($$$)
{
    my ($pkg, $type, $tmpdir) = @_;
    my ($dir, $d);
    my @dirlist;

    if (! $tmpdir) {
        $tmpdir = &get_temp_dir() . sprintf("/mezzanine.temp.%s.%d.%04x",
                                            (($type) ? ($type) : ("misc")),
                                            $$, rand(32767));
    }
    if ($pkg) {
        $dir = "$tmpdir/$pkg";
    } else {
        $dir = $tmpdir;
    }
    dprint "Creating $type temp space in $dir.\n";
    &nuke_tree($dir);

    if ($type eq "nameonly") {
        return $dir;
    }

    &mkdirhier($dir) || return "";
    if ($type eq "SPM") {
	@dirlist = ("S", "P", "F");
    } elsif ($type eq "dironly" || $type eq "PDR") {
	@dirlist = ();
    } elsif ($type eq "build") {
	@dirlist = ("BUILD", "SOURCES", "SRPMS", "RPMS", "SPECS");
    }
    foreach my $d (@dirlist) {
	if (!&mkdirhier("$dir/$d")) {
	    eprint "Creation of $dir/$d failed -- $!\n";
	    return "";
	}
    }
    return $dir;
}

# Clean up temp space
sub
clean_temp_space($)
{
    my $tmpdir = $_[0];

    if (! $tmpdir) {
        return;
    }
    dprint "Cleaning temp space in $tmpdir.\n";
    return &nuke_tree($tmpdir);
}

# Strip the leading path off a directory/file name
sub
basename($)
{
    my $path = $_[0];

    if ($path) {
        $path =~ s/^.*\/([^\/]+)$/$1/;
    }
    return $path;
}

# Return the leading path of a directory/file name
sub
dirname($)
{
    my $path = $_[0];

    if ($path) {
        $path =~ s/^(.*)\/[^\/]+$/$1/;
    }
    return $path;
}

# Grep a directory for files matching a particular expression
sub
grepdir(& $)
{
    my ($func, $dir) = @_;
    my ($i, $cnt);
    my @files;
    local *DIR;

    if ($dir) {
        opendir(DIR, $dir) || return 0;
        $dir .= '/' if (substr($dir, -1, 1) ne '/');
    } else {
        opendir(DIR, ".") || return 0;
        $dir = "";
    }
    @files = grep(&$func($_ = ($dir . $_)), readdir(DIR));
    @files = map { &untaint(\$_); } @files;
    closedir(DIR);
    return @files;
}

# Remove files in a directory which are not in the list
sub
limit_files(@ $)
{
    my $dir = pop;
    my @files = @_;
    my @contents;
    local *DIR;

    @contents = &grepdir(sub {! -d $_}, $dir);
    if (!scalar(@contents)) {
        # Nothing to remove.
        return 1;
    }
    foreach my $f (@contents) {
        if (!scalar(@files) || !grep($_ eq &basename($f), @files)) {
            dprint "Removing $f\n";
            unlink($f) || eprint "Unable to remove $f -- $!\n";
        }
    }
    return 1;
}

# Trim whitespace
sub
str_trim(\$)
{
    # Use $_[0] because it acts like pass-by-reference.
    $_[0] =~ s/^\s+//;
    $_[0] =~ s/\s+$//;
    return $_[0];
}

# Tokenize a string in whitespace and quotes
sub
str_tokens($$)
{
    my ($str, $delim) = @_;
    my @str = split(//, $str);
    my @tokens = ();
    my ($i, $quote, $cnt, $len);
    sub is_delim { return ((defined($delim)) ? (index($delim, $_[0]) >= 0) : (isspace($_[0]))); }
    sub is_quote { return ($quote && ($quote eq $_[0])); }

    $i = 0;
    $len = scalar(@str);

    # Before we do anything, skip leading "whitespace."
    while (($i < $len) && (is_delim($str[$i]))) {
        $i++;
    }

    # The outermost loop is where we traverse the string.  Each new word
    # brings us back up to the top of the loop to start a new array element.
    for ($cnt = 0; $i < $len; $cnt++) {
        $tokens[$cnt] = "";

        # Process each character.
        while (($i < $len) && ($quote || !is_delim($str[$i]))) {
            if (($str[$i] eq "\'") || ($str[$i] eq "\"")) {
                # It's a quote character, so set/unset the quote variable.
                if ($quote) {
                    if ($quote eq $str[$i]) {
                        $quote = '';
                    } else {
                        # It's a single quote inside double quotes,
                        # or vice versa.  Leave it alone.
                        $tokens[$cnt] .= $str[$i];
                        $i++;
                    }
                } else {
                    $quote = $str[$i];
                }
                $i++;
            } else {
                # Handle any backslashes that are escaping delimiters or quotes.
                if (($str[$i] eq "\\") && (($str[$i+1] eq "\\") || is_delim($str[$i+1]) || is_quote($str[$i+1]))) {
                    $i++;
                }
                $tokens[$cnt] .= $str[$i];
                $i++;
            }
        }

        # Move past any additional "whitespace."
        while (($i < $len) && (is_delim($str[$i]))) {
            $i++;
        }
    }
    return @tokens;
}

# Exclusive push.  Only push if the item(s) aren't already in the list
sub
xpush(\@; @)
{
    my $parray = shift;
    my @items = @_;

    foreach my $item (@items) {
        push @{$parray}, $item if (!grep($_ eq $item, @{$parray}));
    }
}

# Return the contents of a file as a string
sub
cat_file($)
{
    my $filename = $_[0];
    my $contents = "";

    if ($filename =~ /^([^\0\`]+)$/) {
        $filename = $1;
    } else {
        return;
    }
    open(FF, "$filename") || return undef;
    $contents = join("", <FF>);
    close(FF);
    return $contents;
}

# Parse an RPM name into its components
sub
parse_rpm_name($)
{
    my $rpm = $_[0];

    if (! $rpm) {
        dprint "Bad value passed to parse_rpm_name().\n";
        &show_backtrace();
        return undef;
    }
    $rpm = &basename($rpm);
    if ($rpm =~ m/^(\S+)-([^-]+)-([^-]+)\.([^\.]+)\.rpm$/) {
        return ($1, $2, $3, $4);
    } else {
        dprint "\"$rpm\" doesn't look like an RPM name.\n";
        return $rpm;
    }
}

# Find spec file
sub
find_spec_file($$)
{
    my ($pkgname, $dir, $recurse) = @_;
    my ($spec_count, $spec_in_count);
    my (@spec_ins, @specs);

    if (! $dir) {
        $dir = ".";
    }

    if (-d $dir) {
        if ($recurse) {
            find({ "wanted" => sub { /\.spec(?:\.in)?$/ && push @specs, &untaint(\$_); }, "no_chdir" => 1 }, $dir);
        } else {
            @specs = &grepdir(sub { /\.spec(?:\.in)?$/ }, $dir);
        }
        @specs = sort @specs;
    }

    if (scalar(@specs) == 0) {
        dprint "No spec files found for $pkgname in $dir!\n";
        return undef;
    } elsif (scalar(@specs) == 1) {
        dprint "Found single spec file for $pkgname in $dir:  $specs[0]\n";
        return $specs[0];
    }

    # First, see which are *.spec and which are *.spec.in
    @spec_ins = grep { substr($_, -3, 3) eq ".in" } @specs;
    $spec_in_count = scalar(@spec_ins);
    @specs = grep { substr($_, -3, 3) ne ".in" } @specs;
    $spec_count = scalar(@specs);

    if ($spec_count == 0) {
        # No *.spec files, so use *.spec.in.
        @specs = @spec_ins;
        $spec_count = $spec_count_in;
        @spec_ins = ();
        $spec_count_in = 0;
    }

    if ($spec_count == 1) {
        dprint "Found primary spec file for $pkgname in $dir:  $specs[0]\n";
        return $specs[0];
    }

    # Didn't work.  We still have too many.
    if ($pkgname) {
        my @pkg_specs;

        # See if there's a package name match.
        @pkg_specs = grep { /^$pkgname/ } @specs;
        if (scalar(@pkg_specs)) {
            # If we have some, focus on those.
            @specs = @pkg_specs;
            if (scalar(@specs) == 1) {
                dprint "Found single package spec file for $pkgname in $dir:  $specs[0]\n";
                return $specs[0];
            }
        }

        if (scalar(@specs) > 1) {
            # Still have too many.  What to do next?
        }
    }
    dprintf("Found %d spec file(s) for $pkgname in $dir:  %s\n",
            join(", ", @specs));
    return $specs[0];
}

sub
should_ignore($)
{
    my $fname = $_[0];

    # Ignore revision control goop
    return 1 if ($fname =~ /^(CVS|SCCS|RCS|BitKeeper)$/);
    # Ignore the revtool-generated ChangeLog
    return 1 if ($fname =~ /^[Cc]hanges?\.?[Ll]og$/);
    # Ignore dotfiles
    return 1 if ($fname =~ /^\./);
    # Ignore backup files
    return 1 if ($fname =~ /\~$/);
    # Ignore spec files
    return 1 if ($fname =~ /\.spec(\.in)?$/);
    # Ignore the debian/ directory
    return 1 if ($fname =~ /^debian$/ && -d $fname);

    return 0;
}

sub
trunc_file($)
{
    my $file = $_[0];
    local *TMP;

    if ($file =~ /^([^\0\`]+)$/) {
        $file = $1;
    } else {
        return;
    }
    open(TMP, ">$file") && close(TMP);
    chown($mz_uid, $mz_gid, $file);
}

sub
touch_file($)
{
    my $file = $_[0];
    local *TMP;

    if ($file =~ /^([^\0\`]+)$/) {
        $file = $1;
    } else {
        return;
    }
    open(TMP, ">$file") && close(TMP);
    chown($mz_uid, $mz_gid, $file);
}

sub
newest_file(@)
{
    my @dirs = @_;
    my ($newest_name, $newest_time) = ("", 0);
    my $stat_info;

    dprint &print_args(@_);
    foreach my $dir (@dirs) {
        if (-d $dir) {
            find({ "wanted" => sub {
                                   #dprint "Checking $_\n";
                                   if (-d $_ || $_ =~ m^/(CVS|SCCS|RCS|BitKeeper|\.svn)/^) {
                                       return;
                                   }
                                   $stat_info = stat($_);
                                   #dprintf("Got mtime is %s\n", ($stat_info->mtime || "<undef>"));
                                   if (defined($stat_info->mtime) && ($stat_info->mtime > $newest_time)) {
                                       $newest_name = $_;
                                       $newest_time = $stat_info->mtime;
                                   }
                               }, "no_chdir" => 1
                 }, $dir);
        } else {
            #dprint "Checking $dir\n";
            $stat_info = stat($dir);
            if ($stat_info->mtime > $newest_time) {
                $newest_name = $dir;
                $newest_time = $stat_info->mtime;
            }
        }
    }
    dprintf("\"$newest_name\" is newest with mtime of %s.\n",
            POSIX::strftime("%Y-%m-%d %H:%M:%S", localtime($newest_time)));
    return $newest_name;
}

# Generate System V file checksum.
sub
checksum_file($)
{
    my $filename = shift;
    my $contents;
    local *FILE;

    if (!open(FILE, $filename)) {
        return 0;
    }
    $contents = join("", <FILE>);
    close(FILE);

    $contents = unpack("%32C*", $contents) % 65535;
    dprintf("Got checksum %d for file %s\n", $contents, $filename);
    return $contents;
}

# Generic wrapper to grab command output
sub
run_cmd($$$)
{
    my ($prog, $params, $show_output, $timeout) = @_;
    my ($err, $msg, $line, $cmd) = undef;
    my @output;
    local *CMD;
    local $SIG{"ALRM"};
    local $SIG{"CHLD"} = "DEFAULT";

    if (!defined($timeout)) {
        # Wait 15 minutes by default.
        $timeout = 900;
    }
    if (ref($params)) {
        my $tmp = "";

        dprintf("Command parameters:  %s\n", &examine_object($params));
        foreach my $param (@{$params}) {
            if ($param =~ /\'/) {
                $param =~ s,\',\'\"\'\"\',g;
            }
            $tmp .= "\'$param\' ";
        }
        $cmd = "$prog $tmp";
    } else {
        $cmd = "$prog $params";
    }

    dprint "About to run $cmd\n";
    if (!open(CMD, "$cmd 2>&1 |")) {
        return (-1, "Execution of \"$cmd\" failed -- $!");
    }

    # Allow only $timeout seconds between lines of output.
    if ($timeout) {
        $SIG{"ALRM"} = \&handle_alarm_for_subcommand;
        alarm($timeout);
    }

    while (<CMD>) {
        if ($CMD_TIMEOUT) {
            eprint "Command TIMED OUT after $timeout seconds.\n";
            $CMD_TIMEOUT = 0;
            $SIG{"ALRM"} = "IGNORE";
            last;
        }
        chomp($line = $_);
        push @output, $line;
        $line =~ s/^.*\r//g;
        if ($show_output) {
            print "$show_output$line\n";
        } else {
            dprint "From $prog -> $line\n";
        }
        if ($timeout) {
            alarm($timeout);
        }
    }
    if (close(CMD)) {
        $err = 0;
    } elsif ($!) {
        push @output, "Error closing pipe:  $!\n";
        $err = 555;
    } else {
        $err = $? >> 8;
    }
    dprint "\"$cmd\" returned $err\n";

    # It won't hurt to always reset.
    alarm(0);
    $SIG{"ALRM"} = "IGNORE";
    $CMD_TIMEOUT = 0;

    if (wantarray()) {
        return ($err, @output);
    } else {
        return $err;
    }
}

# Wrapper for Mezzanine commands specifically
sub
run_mz_cmd($$$)
{
    my ($prog, $params, $show_output) = @_;
    my ($err, $msg, $line, $cmd) = undef;
    my (@output, @tmp);

    $params = "--debug $params" if ($debug);
    @output = &run_cmd($prog, $params, $show_output);
    $err = shift @output;
    if ($err) {
        my @tmp;

        @tmp = grep(/^\w+:\s*error:\s*(\S.*)$/i, @output);
        if (scalar(@tmp)) {
            $msg = $tmp[$#tmp];
        }
    }
    if (wantarray()) {
        return ($err, ($show_output ? $msg : @output));
    } else {
        return $err;
    }
}

sub
fetch_url($)
{
    my $url = shift;
    my $dest = shift;
    my @headers = @_;
    my %headers;
    my ($uri, $user_agent, $response, $coderef, $filehandle);

    if (scalar(@headers) % 2) {
        pop @headers;
    }
    %headers = @headers;

    # Local anonymous subroutine to handle chunks of data as they come in.
    $coderef = sub {
        my ($data_chunk, $response, $protocol) = @_;

        if (! $headers{":no_progress"}) {
            print '.';
        }
        if (! $filehandle) {
            dprintf("Response was:  %s\n", $response->status_line());

            dprintf("Response Headers:  %s\n",
                    join(", ", map {
                                    sprintf("%s -> \"%s\"", $_, $response->header($_));
                                   } $response->header_field_names()));

            $url = $response->request()->uri();
            dprint "Final URL was:  $url\n";

            if (! $dest) {
                $dest = &basename($uri->path());
            }
            if ($dest eq "mem") {
                # If dest is set to 'mem', $filehandle is actually a string
                # buffer containing the content returned by the request.
                $filehandle = "";
            } elsif (!open($filehandle, ">$dest")) {
                die("Unable to write to $dest -- $!");
            }
        }

        #dprintf("Writing %d bytes to %s\n", length($data_chunk), $dest);
        if ($dest eq "mem") {
            $filehandle .= $data_chunk;
        } else {
            print $filehandle $data_chunk;
        }
    };

    # Create a URI object from the URL given.
    $uri = URI->new($url);
    if (! $uri) {
        return "Unable to create URI object from $url";
    }

    # Create the useragent, and make sure we can handle the given URL.
    $user_agent = LWP::UserAgent->new("agent" => "$PROGNAME/$VERSION", "env_proxy" => 1, "timeout" => 30);
    &find_cookie_jar($user_agent);
    if (! $user_agent->is_protocol_supported($uri->scheme())) {
        return "Unsupported method:  " . $uri->scheme();
    }

    dprint "Calling useragent GET method on $url\n";
    $response = $user_agent->get($url, ":content_cb" => $coderef, @headers);
    dprint "Back from GET.\n";
    dprintf("Response was:  %s\n", $response->status_line());

    if ($response->is_redirect()) {
        # Too many redirects; bail out.
        return "Too many redirects";
    } elsif ($response->is_error()) {
        return $response->status_line();
    }

    if ($filehandle && ($dest ne "mem")) {
        close($filehandle);
    }
    
    if ($response->header("X-Die")) {
        if ($dest && -e $dest) {
            &nuke_tree($dest);
        }
        return $response->header("X-Die");
    }

    if (! $headers{":no_progress"}) {
        print "done.\n";
    }
    return (($dest eq "mem") ? ($filehandle) : ($dest));
}

sub
post_file(@)
{
    my $url = shift;
    my $file = shift;
    my %params = @_;
    my %post_map;
    my ($user_agent, $response);

    # Check for an HTTP URL.
    if ($url !~ m,^https?://,) {
        return "Unsupported URL $url";
    }

    # Create the useragent
    $user_agent = LWP::UserAgent->new("agent" => "$PROGNAME/$VERSION", "env_proxy" => 1, "timeout" => 30);
    push @{$user_agent->requests_redirectable()}, 'POST';
    &find_cookie_jar($user_agent);

    # Create the file upload hash.
    foreach my $key (keys(%params)) {
        if ($params{$key} eq '**FILE**') {
            $params{$key} = [ $file ];
        }
    }
    %post_map = (
                 'Content_Type' => 'form-data',
                 'Content' => \%params
                );

    # Post the file.
    dprintf("Calling useragent POST method on $url:  %s\n", &examine_object(\%post_map));
    $response = $user_agent->post($url, %post_map);
    dprintf("Response was:  %s\n", $response->status_line());
    dprintf("Content:\n----\n%s\n----\n", $response->content());

    if ($response->is_redirect()) {
        # Too many redirects; bail out.
        return "Too many redirects";
    } elsif ($response->is_error()) {
        return $response->status_line();
    } elsif ($response->header("X-Die")) {
        return $response->header("X-Die");
    }
    return '';
}

### Private functions

sub
handle_alarm_for_subcommand(@)
{
    $CMD_TIMEOUT = 1;
}

sub
find_cookie_jar($)
{
    my $user_agent = shift;
    my $cookie_file;

    foreach my $var ("MEZZANINE_COOKIE_JAR", "COOKIE_JAR", "COOKIES") {
        if (exists($ENV{$var}) && -r $ENV{$var}) {
            $cookie_file = $ENV{$var};
            last;
        }
    }
    if (! $cookie_file) {
        foreach my $path ('.', "$ENV{HOME}/.netscape", "$ENV{HOME}/.mozilla", "$ENV{HOME}/.mozilla/firefox/*") {
            foreach my $fname (glob("$path/cookies.txt")) {
                if ($fname && -r $fname) {
                    $cookie_file = $fname;
                    last;
                }
            }
            if ($cookie_file) {
                last;
            }
        }
    }

    if ($cookie_file) {
        eval {
            require HTTP::Cookies::Netscape || die("Not found.");

            dprint "Using cookie jar $cookie_file.\n";
            $user_agent->cookie_jar(HTTP::Cookies::Netscape->new('file' => $cookie_file));
        };
        if ($@) {
            dprint "Unable to load Netscape cookie module.  Falling back on LWP cookie jar.\n";
            $user_agent->cookie_jar(HTTP::Cookies->new('file' => $cookie_file));
        }
    }
    return $cookie_file;
}

1;
