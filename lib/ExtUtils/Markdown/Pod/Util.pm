#
#  This file is part of ExtUtils::Markdown::Pod.
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
package ExtUtils::Markdown::Pod::Util;


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
local $Data::Dumper::Indent=1;
local $Data::Dumper::Terse=1;
local $Data::Dumper::SortKeys=1;


#  Export functions
#
use base 'Exporter';
@EXPORT=qw(err msg verbose debug quiet_enable verbose_enable debug_enable Dumper slurp blurp touch arg perlrun);


#  Version information in a format suitable for CPAN etc. Must be
#  all on one line
#
$VERSION='0.010';


#  Debugging on ?
#
$Script=~s/\.pl$//;
($Carp::Verbose=++$DEBUG) if $ENV{uc("${Script}_DEBUG")};


#  Done
#
1;

#==================================================================================================


sub import0 {


    #  Manage activation of various ExtUtils::Makemaker sections for this class.
    #
    #  use ExtUtils::<This Package> qw(const_config) to just replace the macros section of the Makefile
    #  .. qw(dist_ci) to replace standard MakeMaker targets with our own
    #  .. qw(:all) or no tag (i.e defaults) to all targers
    #  
    #
    die Dumper(\@_);
    my ($class, @section)=@_;
    return if $_{$class}{'loaded'}++;
    msg("initializing $class import");


    #  Get params, bless self ref and remember import tags spec'd for later
    #  re-use
    #
    my $self=bless (\my %self, $class);
    #my %import_tag=map {$_ => 1} @{$self{'import_tag'}=\@_};
    #my %import_tag=map {$_ => 1} @{$self{'import_tag'}=\@import_tag};
    #$import_tag{':all'}++ unless keys %import_tag;


    #  sections to replace
    #
    #my @section=qw(
    #    const_config
    #    postamble
    #);
    {   no warnings 'redefine'; no strict 'refs';
        #foreach my $section (grep {$import_tag{$_} || $import_tag{':all'}} @section) {
        foreach my $section (@section) {
            $self{$section}=*{"MM::${section}"}{CODE} unless (*{"MM::${section}"}{CODE} eq \&{$section});
            #$self{$section}||=sub {};
            #msg('%s: %s', $section, $self{$section});
            msg("import $section");
            *{"MM::${section}"}= sub {&{$section}($self, @_)};
        }
    }

    msg("initializing $class import complete");

}



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
    my $caller=(caller(2))[3];
    my ($class, $method)=($caller=~/^(.*)::([^:]+)$/);
    $caller=~s/^_?!(_)//;
    #my $format=' @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @*';
    my $format=' @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @*';
    local $^A='';
    formline $format, "[$method]", $message;
    #formline $format, "[$caller]", $message;
    return $^A;

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


sub perlrun {

    
    #  Get self ref
    #
    my $self=shift();


    #  Construct PERL runtime
    #
    my $perl_inc_ar=&perl_inc;
    
    
    #  And modules
    #
    my $perl_mod_ar=&perl_mod;


    #  Now construct final PERLRUN string
    #
    my $perlrun;
    my $perlrun_inc=join(' ', map {"-I$_"} @{$perl_inc_ar});
    my $perlrun_mod=join(' ', map {"-M$_"} @{$perl_mod_ar});
    my $class=ref($self);
    if (my $import_tag_ar=$MY::->{__PACKAGE__}{'import_tag'}) {
        $perlrun=sprintf("\$(PERL) $perlrun_inc $perlrun_mod -M${class}=%s", join(',', @{$import_tag_ar}));
    }
    else {
        $perlrun="\$(PERL) $perlrun_inc $perlrun_mod -M${class}";
    }
    
    
    #  And return
    #
    return $perlrun
    
}


sub perl_mod {

    my %seen=(
        __PACKAGE__ => 1
    );
    my @m=sort 
        grep { !$seen{$_}++ } 
        map {(my $m = $_) =~ s{\.pm$}{}; $m =~ s{/}{::}g; $m;}
        grep { m{^ExtUtils/} }
        keys %INC;
    return \@m;
}


sub perl_inc {

    #  Return array ref of any additional libraries specified via command line (-I)
    #
    my %default_inc=map { $_ => 1 } @{ perl_inc_default() || [] };
    my %seen;
    my @lib=grep {
        !$default_inc{$_} && !$seen{$_}++
    } map {
        File::Spec->rel2abs($_)
    } grep {
        defined($_) && !ref($_) && length($_) && -d $_
    } @INC;

    return \@lib;
}


sub perl_inc_default {

    my @default_inc;
    if (open(my $perl_fh, '-|', $^X, '-e', 'print join qq(\0), grep { defined && !ref && length && -d } @INC')) {
        local $/;
        my $inc=<$perl_fh>;
        close($perl_fh);
        @default_inc=map {
            File::Spec->rel2abs($_)
        } split(/\0/, ($inc || ''));
    }
    return \@default_inc;
}


sub arg {

    #  Convert MakeMaker target args to a named parameter hash.
    #
    my (%param, @argv);
    (@param{qw(
        NAME
        NAME_SYM
        DISTNAME
        DISTVNAME
        VERSION
        VERSION_SYM
        VERSION_FROM
        LICENSE AUTHOR
        TO_INST_PM
        EXE_FILES
        DIST_DEFAULT_TARGET
        SUFFIX
        ABSTRACT_FROM
    )}, @argv)=@_;
    $param{'TO_INST_PM_AR'}=[split /\s+/, $param{'TO_INST_PM'}];
    $param{'EXE_FILES_AR'}=[split /\s+/, $param{'EXE_FILES'}];
    $param{'ARGV_AR'}=\@argv;
    return \%param

}



__END__

=begin markdown

# NAME

ExtUtils::Markdown::Pod::Util - small utility functions for markpod

# SYNOPSIS

```perl
use ExtUtils::Markdown::Pod::Util;

msg('markpod: %s -> %s: starting merge', $source, $target);
verbose('markpod: %s: skipped unsupported target', $target);
debug('processing file: %s', $filename);

my $text = slurp($filename);
blurp($filename, $text);
touch($filename);
```

# DESCRIPTION

`ExtUtils::Markdown::Pod::Util` provides the small shared helpers used by the
`ExtUtils::Markdown::Pod` modules and the `markpod` command.

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

`ExtUtils::Markdown::Pod`, `ExtUtils::Markdown::Pod::MM`

# AUTHOR

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE AND COPYRIGHT

This file is part of ExtUtils::Markdown::Pod.

This software is copyright (c) 2026 by Andrew Speer
<andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>

=end markdown


=head1 NAME

ExtUtils::Markdown::Pod::Util - small utility functions for markpod


=head1 SYNOPSIS


 use ExtUtils::Markdown::Pod::Util;
 
 msg('markpod: %s -> %s: starting merge', $source, $target);
 verbose('markpod: %s: skipped unsupported target', $target);
 debug('processing file: %s', $filename);
 
 my $text = slurp($filename);
 blurp($filename, $text);
 touch($filename);

=head1 DESCRIPTION

C<ExtUtils::Markdown::Pod::Util> provides the small shared helpers used by the
C<ExtUtils::Markdown::Pod> modules and the C<markpod> command.

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

C<ExtUtils::Markdown::Pod>, C<ExtUtils::Markdown::Pod::MM>


=head1 AUTHOR

Andrew Speer L<mailto:andrew.speer@isolutions.com.au>


=head1 LICENSE AND COPYRIGHT

This file is part of ExtUtils::Markdown::Pod.

This software is copyright (c) 2026 by Andrew Speer
L<mailto:andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

L<http://dev.perl.org/licenses/>

=cut
