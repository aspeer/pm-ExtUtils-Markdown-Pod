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
use vars qw($VERSION $DEBUG $QUIET @EXPORT);
use warnings;


#  External modules
#
use FindBin qw($RealBin $Script);
FindBin::again();
use Data::Dumper;
$Data::Dumper::Indent=1;
$Data::Dumper::Terse=1;


#  Export functions
#
use base 'Exporter';
@EXPORT=qw(err msg arg debug debug_enable Dumper);


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
    $QUIET++;
    

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
    my $caller=(caller(2))[3] || 'main';
    $caller=~s/^_?!(_)//;
    my $format='@<<<<<<<<<<<<<<<<<<<<<< @<';
    local $^A='';
    formline $format, "[${caller}]", '';
    $message=$^A . $message; $^A=undef;
    return $message;

}


sub msg {

    #  Print message
    #
    return (CORE::print &fmt(@_), $/) unless $QUIET;

}
