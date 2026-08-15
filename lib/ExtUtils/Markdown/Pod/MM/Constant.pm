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

#


#  Pragma
#
package ExtUtils::Markdown::Pod::MM::Constant;
use strict qw(vars);
use warnings;
use vars qw($VERSION @ISA %EXPORT_TAGS @EXPORT_OK @EXPORT %Constant);


#  Modules we need
#
use File::Spec;
use File::Basename qw(dirname);


#  Version information
#
$VERSION='0.010';


#  Get module file name and path, derive name of file to store local constants
#
use Cwd qw(abs_path);
my $local_fn=abs_path(__FILE__) . '.local';


#  Hash of constants
#
%Constant=(

    TEMPLATE_POSTAMBLE_FN =>
        File::Spec->catfile(dirname(__FILE__), 'postamble.inc'),
        
    MARKPOD_PM => 'ExtUtils::Markdown::Pod::MM',
    
    MARKPOD_PM_ARGV => join(',', qw[
        "$(NAME)"
        "$(NAME_SYM)"
        "$(DISTNAME)"
        "$(DISTVNAME)"
        "$(VERSION)"
        "$(VERSION_SYM)"
        "$(VERSION_FROM)"
        "$(LICENSE)"
        "$(AUTHOR)"
        "$(TO_INST_PM)"
        "$(EXE_FILES)"
        "$(DIST_DEFAULT_TARGET)"
        "$(SUFFIX)"
        "$(ABSTRACT_FROM)"
    ]),


    #  Local constants override anything above
    #
    %{do($local_fn) || {}},
    %{do(glob(sprintf('~/.%s.local', __PACKAGE__))) || {}}    # || {} avoids warning

);


#  Export constants to namespace, place in export tags
#
require Exporter;
@ISA=qw(Exporter);
foreach (keys %Constant) {${$_}=$Constant{$_}}
@EXPORT=map {'$' . $_} keys %Constant;
@EXPORT_OK=@EXPORT;
%EXPORT_TAGS=(all => [@EXPORT_OK]);
$_=\%Constant;
__END__

=begin markdown

# NAME

ExtUtils::Markdown::Pod::MM::Constant - constants for MakeMaker integration

# SYNOPSIS

```perl
use ExtUtils::Markdown::Pod::MM::Constant;

my $postamble = $TEMPLATE_POSTAMBLE_FN;
my $module    = $MM_PM;
my $argv      = $MM_ARGV;
```

# DESCRIPTION

`ExtUtils::Markdown::Pod::MM::Constant` defines constants used by
`ExtUtils::Markdown::Pod::MM` when it extends `ExtUtils::MakeMaker`.

The constants describe where the Makefile postamble template lives, which Perl
module should be invoked by the generated targets, and which MakeMaker
variables should be passed back into the target dispatcher.

# CONSTANTS

`$TEMPLATE_POSTAMBLE_FN`
: Path to the bundled `postamble.inc` template.

`$MM_PM`
: Module name invoked by the generated Makefile targets. This is normally
  `ExtUtils::Markdown::Pod::MM`.

`$MM_ARGV`
: Quoted list of MakeMaker variables passed to the target dispatcher so methods
  such as `doc` and `readme` can reconstruct their input parameters.

# LOCAL OVERRIDES

Local constants can be overridden by files loaded from:

```text
lib/ExtUtils/Markdown/Pod/MM/Constant.pm.local
~/.ExtUtils::Markdown::Pod::MM::Constant.local
```

Those files are expected to return a hash reference suitable for merging into
`%Constant`.

# SEE ALSO

`ExtUtils::Markdown::Pod::MM`, `ExtUtils::MakeMaker`

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

ExtUtils::Markdown::Pod::MM::Constant - constants for MakeMaker integration


=head1 SYNOPSIS


 use ExtUtils::Markdown::Pod::MM::Constant;
 
 my $postamble = $TEMPLATE_POSTAMBLE_FN;
 my $module    = $MM_PM;
 my $argv      = $MM_ARGV;

=head1 DESCRIPTION

C<ExtUtils::Markdown::Pod::MM::Constant> defines constants used by
C<ExtUtils::Markdown::Pod::MM> when it extends C<ExtUtils::MakeMaker>.

The constants describe where the Makefile postamble template lives, which Perl
module should be invoked by the generated targets, and which MakeMaker
variables should be passed back into the target dispatcher.


=head1 CONSTANTS

C<$TEMPLATE_POSTAMBLE_FN>
: Path to the bundled C<postamble.inc> template.

C<$MM_PM>
: Module name invoked by the generated Makefile targets. This is normally
  C<ExtUtils::Markdown::Pod::MM>.

C<$MM_ARGV>
: Quoted list of MakeMaker variables passed to the target dispatcher so methods
  such as C<doc> and C<readme> can reconstruct their input parameters.


=head1 LOCAL OVERRIDES

Local constants can be overridden by files loaded from:


 lib/ExtUtils/Markdown/Pod/MM/Constant.pm.local
 ~/.ExtUtils::Markdown::Pod::MM::Constant.local
Those files are expected to return a hash reference suitable for merging into
C<%Constant>.


=head1 SEE ALSO

C<ExtUtils::Markdown::Pod::MM>, C<ExtUtils::MakeMaker>


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
