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

#


#  Pragma
#
package Markdown::Pod::Embed::MM::Constant;
use strict qw(vars);
use warnings;
use vars qw($VERSION @ISA %EXPORT_TAGS @EXPORT_OK @EXPORT %Constant);


#  Modules we need
#
use File::Spec;
use File::Basename qw(dirname);


#  Version information
#
$VERSION='0.013';


#  Get module file name and path, derive name of file to store local constants
#
use Cwd qw(abs_path);
my $local_fn=abs_path(__FILE__) . '.local';


#  Hash of constants
#
%Constant=(

    TEMPLATE_POSTAMBLE_FN =>
        File::Spec->catfile(dirname(__FILE__), 'Constant', 'postamble.inc'),
        
        
    MM_PM => 'Markdown::Pod::Embed::MM',
    
    MM_ARGV => q["$(NAME)" "$(NAME_SYM)" "$(DISTNAME)" "$(DISTVNAME)" "$(VERSION)" ] .
        q["$(VERSION_SYM)" "$(VERSION_FROM)" "$(LICENSE)" "$(AUTHOR)" "$(TO_INST_PM)" "$(EXE_FILES)" "$(DIST_DEFAULT_TARGET)" "$(SUFFIX)" "$(ABSTRACT_FROM)"],

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
