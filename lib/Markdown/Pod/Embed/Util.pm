#
#  This file is part of markpod.
#
#  This software is copyright (c) 2024 by Andrew Speer <andrew.speer@isolutions.com.au>.
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
$VERSION='0.013';


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
