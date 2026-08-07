#
#  This file is part of Markdown::Pod::Embed.
#
#  This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.
#
#  This is free software; you can redistribute it and/or modify it under
#  the same terms as the Perl 5 programming language system itself.
#
#  Full license text is available at:
#
#  <http://dev.perl.org/licenses/>
#

package Markdown::Pod::Embed::Util;


#  Pragma
#
use strict;
use vars qw($VERSION $DEBUG $QUIET $VERBOSE @EXPORT);
use warnings;


#  External modules
#
use FindBin qw($RealBin $Script);
FindBin::again();
use Data::Dumper;
use IO::File;
$Data::Dumper::Indent=1;
$Data::Dumper::Terse=1;


#  Export functions
#
use base 'Exporter';
@EXPORT=qw(err msg verbose debug quiet_enable verbose_enable debug_enable Dumper slurp blurp touch);


#  Version information in a format suitable for CPAN etc. Must be
#  all on one line
#
$VERSION='0.009';


#  Debugging on ?
#
$Script=~s/\.pl$//;
($Carp::Verbose=++$DEBUG) if $ENV{uc("${Script}_DEBUG")};


#  Done
#
1;

#==================================================================================================


sub quiet_enable {


    #  Turn on quiet flag
    #
    $QUIET=shift() || 1;
    

}


sub verbose {

    #  Print verbose message
    #
    return if $QUIET || !$VERBOSE;
    return CORE::print STDERR &fmt(@_), $/;

}


sub verbose_enable {

    #  Turn on verbose flag
    #
    $VERBOSE=shift() || 1;

}


sub debug_enable {

    #  Turn on debugging flag
    #
    $DEBUG=shift();
    
}


sub debug {

    #  Debug
    #
    $DEBUG || return;
    my $debug=sprintf(shift(), @_);
    chomp($debug);
    my ($package, undef, $line, $method) = caller(1);  # '1' for caller of the function
    print STDERR sprintf("[%s:%d] %s$/", 
        join('::', grep {$_} ($package, $method)),
        $line,
        $debug
    );

}


sub err {

    #  Quit on errors
    #
    my $msg=&fmt('error: %s', @_);
    CORE::print STDERR $msg, "\n";
    eval {require Carp; 1};
    Carp::croak;

}


sub fmt {

    #  Format message nicely. Always called by err or msg so caller=2
    #
    my $message=sprintf(shift(), @_);
    chomp($message);
    return $message;

}


sub msg {

    #  Print message
    #
    return (CORE::print STDERR &fmt(@_), $/) unless $QUIET;

}


sub slurp {

    #  Slurp in file content
    #
    my ($fn)=@_;
    my $fh=IO::File->new($fn, 'r') ||
        return err("unable to open file $fn, $!");
    local $/=undef;
    my $text=<$fh>;
    $fh->close();
    return $text || '';

}


sub blurp {

    #  Save file content
    #
    my ($fn, $text)=@_;
    my $fh=IO::File->new($fn, 'w') ||
        return err("unable to open $fn for write, $!");
    print $fh $text;
    $fh->close();
    return 1;

}


sub touch {

    my ($fn)=@_;
    return 1 if -e $fn;
    return blurp($fn, '');

}
__END__

=begin markdown

# NAME

Markdown::Pod::Embed::Util - small utility functions for markpod

# SYNOPSIS

```perl
use Markdown::Pod::Embed::Util;

msg('markpod: %s -> %s: starting merge', $source, $target);
verbose('markpod: %s: skipped unsupported target', $target);
debug('processing file: %s', $filename);

my $text = slurp($filename);
blurp($filename, $text);
touch($filename);
```

# DESCRIPTION

`Markdown::Pod::Embed::Util` provides the small shared helpers used by the
`Markdown::Pod::Embed` modules and the `markpod` command.

It is intentionally lightweight. It does not provide a logging framework or a
configuration system; it only centralises status output, debug output, errors,
and simple file helpers.

# OUTPUT HELPERS

Status output is written to STDERR so generated document content can safely be
written to STDOUT.

`msg`
: Prints a normal status line unless quiet mode is enabled.

`verbose`
: Prints a verbose status line only when verbose mode is enabled and quiet mode
  is not enabled.

`debug`
: Prints a developer diagnostic line when debug mode is enabled. Debug messages
  include caller package, method, and line number.

`err`
: Formats an error message, writes it to STDERR, and croaks.

# CONTROL HELPERS

`quiet_enable`
: Enables quiet mode.

`verbose_enable`
: Enables verbose mode.

`debug_enable`
: Enables or disables debug mode.

The command-line tool wires these to `--quiet`, `--verbose`, and `--debug`.
Debug mode can also be enabled with the script-specific environment variable
derived from `FindBin`.

# FILE HELPERS

`slurp`
: Reads a whole file into a scalar.

`blurp`
: Writes a scalar to a file, replacing the existing content.

`touch`
: Creates an empty file if it does not already exist.

# CAVEATS

The helper state is process-global. That is suitable for this distribution's
CLI and MakeMaker use, but callers embedding the module in a longer-running
process should avoid treating the output flags as object-local state.

# SEE ALSO

`Markdown::Pod::Embed`, `Markdown::Pod::Embed::MM`

# AUTHOR

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE AND COPYRIGHT

This file is part of Markdown::Pod::Embed.

This software is copyright (c) 2026 by Andrew Speer
<andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>

=end markdown


=head1 NAME

Markdown::Pod::Embed::Util - small utility functions for markpod


=head1 SYNOPSIS


 use Markdown::Pod::Embed::Util;
 
 msg('markpod: %s -> %s: starting merge', $source, $target);
 verbose('markpod: %s: skipped unsupported target', $target);
 debug('processing file: %s', $filename);
 
 my $text = slurp($filename);
 blurp($filename, $text);
 touch($filename);

=head1 DESCRIPTION

C<Markdown::Pod::Embed::Util> provides the small shared helpers used by the
C<Markdown::Pod::Embed> modules and the C<markpod> command.

It is intentionally lightweight. It does not provide a logging framework or a
configuration system; it only centralises status output, debug output, errors,
and simple file helpers.


=head1 OUTPUT HELPERS

Status output is written to STDERR so generated document content can safely be
written to STDOUT.

C<msg>
: Prints a normal status line unless quiet mode is enabled.

C<verbose>
: Prints a verbose status line only when verbose mode is enabled and quiet mode
  is not enabled.

C<debug>
: Prints a developer diagnostic line when debug mode is enabled. Debug messages
  include caller package, method, and line number.

C<err>
: Formats an error message, writes it to STDERR, and croaks.


=head1 CONTROL HELPERS

C<quiet_enable>
: Enables quiet mode.

C<verbose_enable>
: Enables verbose mode.

C<debug_enable>
: Enables or disables debug mode.

The command-line tool wires these to C<--quiet>, C<--verbose>, and C<--debug>.
Debug mode can also be enabled with the script-specific environment variable
derived from C<FindBin>.


=head1 FILE HELPERS

C<slurp>
: Reads a whole file into a scalar.

C<blurp>
: Writes a scalar to a file, replacing the existing content.

C<touch>
: Creates an empty file if it does not already exist.


=head1 CAVEATS

The helper state is process-global. That is suitable for this distribution's
CLI and MakeMaker use, but callers embedding the module in a longer-running
process should avoid treating the output flags as object-local state.


=head1 SEE ALSO

C<Markdown::Pod::Embed>, C<Markdown::Pod::Embed::MM>


=head1 AUTHOR

Andrew Speer L<mailto:andrew.speer@isolutions.com.au>


=head1 LICENSE AND COPYRIGHT

This file is part of Markdown::Pod::Embed.

This software is copyright (c) 2026 by Andrew Speer
L<mailto:andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

L<http://dev.perl.org/licenses/>

=cut
