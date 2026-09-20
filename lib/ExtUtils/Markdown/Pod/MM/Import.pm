#
#  This file is part of ExtUtils::Markdown::Pod.
#
#  This software is copyright (c) 2026 by Andrew Speer <andrew.speer.com.au>.
#
#  This is free software; you can redistribute it and/or modify it under
#  the same terms as the Perl 5 programming language system itself.
#
#  Full license text is available at:
#
#  <http://dev.perl.org/licenses/>
#
package ExtUtils::Markdown::Pod::MM::Import;


#  Pragma
#
use strict qw(vars);
use warnings;
use vars qw($VERSION);


#  Base Packages
#
use ExtUtils::Markdown::Pod::MM;
use ExtUtils::Markdown::Pod::MM::Util;
use ExtUtils::Markdown::Pod::MM::Constant;


#  External Packages
#
use ExtUtils::MakeMaker;
use Software::LicenseUtils;
use File::Basename qw(basename);
use Tie::File;


#  Version information in a formate suitable for CPAN etc. Must be
#  all on one line
#
$VERSION='0.011';


#  All done, init finished
#
1;


#======================================================================================================================


sub import {


    #  Manage activation of various ExtUtils::Makemaker sections for this class.
    #
    #  use ExtUtils::<This Package> qw(const_config) to just replace the macros section of the Makefile
    #  .. qw(dist_ci) to replace standard MakeMaker targets with our own
    #  .. qw(:all) or no tag (i.e defaults) to all targers
    #  
    #
    my ($class, @section)=@_;
    return if $_{$class}{'loaded'}++;
    return unless ($0=~/Makefile\.PL$/);
    msg("initializing $class import");


    #  Remember extension activation order for generated PERLRUN commands
    #
    {
        no warnings qw(once);
        push(@MY::ExtUtils_MM_Import_Order, $class)
            unless grep {$class eq $_} @MY::ExtUtils_MM_Import_Order;
        $MY::ExtUtils_MM_Import_Tag{$class}=[@section];
    }


    #  Get params, bless self ref and remember import tags spec'd for later
    #  re-use
    #
    my $self=bless (\my %self, $class);
    
    
    #  Build chain of MM modules loaded for this OS so we can search for
    #  code ref's associated with various ExtUtils::MakeMaker sections;
    #
    my @mm_isa=grep {/^ExtUtils::MM/} @ExtUtils::MM::ISA;
    push @mm_isa, map { @{"${_}::ISA"} } @mm_isa;
    die('no ExtUtils::MM inheritance found in @ISA') unless @mm_isa;
    

    #  Sections to augment with additional targets
    #
    {   no warnings qw(redefine once);
        foreach my $section (qw(const_config depend postamble post_initialize), @section) {
            next if $self{$section};
            $self{$section} =*{"ExtUtils::MM::${section}"}{CODE}; # unless (*{"ExtUtils::MM::${section}"}{CODE} eq \&{$section});
            $self{$section} ||= do {
                my ($cr)=grep {$_} (map { $_->can($section) } @mm_isa);
                $cr || sub {''};
            };
            $self{$section} ||= ExtUtils::MM_Unix->can($section) || sub {''};
            my $sub=sprintf('%s::MM::%s', ref($self), $section);
            if (my $cr=*{$sub}{CODE}) {
                msg("import $section from $sub");
                *{"ExtUtils::MM::${section}"}=sub { $cr->($self, @_) };
            }
            else {
                msg("import $section from %s", __PACKAGE__);
                *{"ExtUtils::MM::${section}"}=sub { &{$section}($self, @_) };
            }
        }
    }
    msg("initializing $class import complete");

}


sub const_config {


    #  Get self ref
    #
    #
    my ($self, $mm_or, @param)=@_;
    (my $section = (caller(0))[3]) =~ s/^.*:://;
    msg("generating %s $section", ref($self));
    

    #  Get original const_config ready for append
    #
    my $const_config=$self->{$section}($mm_or, @param);


    #  Import Constants into macros
    #
    my $constant_hr=\%{sprintf('%s::MM::Constant::Constant', ref($self))};
    foreach my $key (keys %{$constant_hr}) {

        #  Update macros with our config
        #
        next if $key eq 'MM_PREFIX';
        my $value=$constant_hr->{$key};
        msg("add macro: $key, value: $value");
        $mm_or->{'macro'}{$key}=$value;

    }


    #   Update license data. Get license type and author
    #
    my $license=$mm_or->{'LICENSE'};
    my @author=@{$mm_or->{'AUTHOR'} || []};
    my $author=shift(@author);


    #  Publish supplied values and enrich complete license metadata
    #
    $mm_or->{'macro'}{'LICENSE'}=$license if defined($license) && length($license);
    $mm_or->{'macro'}{'AUTHOR'}=$author if defined($author) && length($author);
    if ($license && $author) {
        my @license_module=Software::LicenseUtils->guess_license_from_meta_key($license);
        @license_module ||
            return err("unable to determine correct license module from string: $license");
        (@license_module > 1) &&
            return err("ambiguous license string: $license, resolves to %s", join(',', @license_module));
        my $license_or=(shift @license_module)->new({holder => $author});
        $mm_or->{'META_MERGE'}{'resources'}{'license'}=$license_or->url();
    }


    #  Now construct final PERLRUN string
    #
    my $perlrun=&perlrun($self, $mm_or);
    $mm_or->{'PERLRUN'}=$perlrun;


    #  Keep copy of DIST_DEFAULT
    #
    $mm_or->{'macro'}{'DIST_DEFAULT_TARGET'}=$mm_or->{'DIST_DEFAULT'};


    #  Return whatever our parent does
    #
    return $const_config;


}



#  MakeMaker::MY replacement depend section
#
sub depend {


    #  Get self ref
    #
    my ($self, $mm_or, @param)=@_;
    (my $section = (caller(0))[3]) =~ s/^.*:://;
    msg("generating %s $section", ref($self));


    #  Get original and modify
    #
    my $depend=$self->{$section}($mm_or, @param);


    #  Add VERSION_FROM without replacing existing dependencies
    #
    $depend='' unless defined($depend);
    if ($mm_or->{'VERSION_FROM'} &&
        $depend!~/^Makefile\s*:[^\n]*\$\(VERSION_FROM\)/m) {
        $depend.=$/ if length($depend) && substr($depend, -1) ne $/;
        $depend.='Makefile : $(VERSION_FROM)'.$/;
    }
    return $depend;

}


#  MakeMaker::MY replacement postamble section
#
sub postamble {


    #  Get self ref
    #
    my ($self, $mm_or, @param)=@_;
    (my $section = (caller(0))[3]) =~ s/^.*:://;
    msg("generating %s $section", ref($self));


    #  Get original postamble ready for append
    #
    my $postamble=$self->{$section}($mm_or, @param);


    #  Get patch dir and file name
    #
    if (my $patch_fn=${sprintf('%s::TEMPLATE_POSTAMBLE_FN', __PACKAGE__)}) {
        
        
        #  Yes, exists as var so implement
        #
        msg('using template: %s', basename($patch_fn));
        

        #  Generate a platform-safe target command and append the template
        #
        my $constant_hr=\%{sprintf('%s::MM::Constant::Constant', ref($self))};
        my $mm_prefix=$constant_hr->{'MM_PREFIX'} || mm_prefix(ref($self));
        my $pm_macro="${mm_prefix}_PM";
        my $argv_macro="${mm_prefix}_PM_ARGV";
        my $target_macro="${mm_prefix}_PM_TARGET";
        my $pm_target=$mm_or->oneliner(sprintf(
            'my $method=shift(@ARGV); $(%s)->$method($(%s), @ARGV)',
            $pm_macro,
            $argv_macro
        ));
        $pm_target=~s/^\$\(ABSPERLRUN\)/\$\(PERLRUN\) -M\$\($pm_macro\)/;
        $postamble.="$target_macro=$pm_target$/";
        $postamble.=slurp($patch_fn);
        

    }


    #  All done, return result
    #
    return $postamble;

}


sub post_initialize {


    #  Add license file, other support files here
    #
    my ($self, $mm_or, @param)=@_;
    (my $section = (caller(0))[3]) =~ s/^.*:://;
    msg("generating %s $section", ref($self));


    #  Get original postamble ready for append
    #
    my $post_initialize=$self->{$section}($mm_or, @param);


    #  Add license file
    #
    $mm_or->{'PM'}{'LICENSE'}='$(INST_LIBDIR)/$(BASEEXT)/LICENSE' if -e 'LICENSE';
    
    
    #  Don't install docs/tmp files etc.
    #
    my %pm=map { $_=>$mm_or->{'PM'}{$_} } grep { !/\.(?:md|xml|pod|bak|tmp|new|old|ref|0|1)$/ } keys %{$mm_or->{'PM'}};
    $mm_or->{'PM'}=\%pm;
    
    
    #  Update and install Git ref if needed/available
    #
    my $devnull=File::Spec->devnull();
    my $version_from_fn=$mm_or->{'VERSION_FROM'};
    my $git_ref_fn=$version_from_fn && "${version_from_fn}.sha";
    if ($version_from_fn && -f $version_from_fn &&
        (my $git_version=qx(git rev-parse --short HEAD 2>$devnull)) && !$?) {
        chomp($git_version);
        tie(my @lines, 'Tie::File', $git_ref_fn) ||
            die("error on Tie::File, $!");
        @lines=($git_version)
            unless @lines==1 && $lines[0] eq $git_version;
    }
    if ($git_ref_fn && -f $git_ref_fn) {
        if ($mm_or->{'PM'}{$version_from_fn}) {
            $mm_or->{'PM'}{$git_ref_fn}=$mm_or->{'PM'}{$version_from_fn}.'.sha';
        }
        elsif (grep {$version_from_fn eq $_} @{$mm_or->{'EXE_FILES'}}) {
            (my $git_ref_base_fn=$git_ref_fn)=~s{^.*[/\\]}{};
            $mm_or->{'PM'}{$git_ref_fn}='$(INST_SCRIPT)/'.$git_ref_base_fn;
        }
    }
    
    #  Done
    #
    return $post_initialize

}


#  Construct a default Makefile macro prefix from an extension class
#
sub mm_prefix {

    my $class=shift();
    $class=~s/::/_/g;
    return uc($class)

}


#  Not used yet
#
sub special_targets {

    my ($self, $mm_or, @param)=@_;
    (my $section = (caller(0))[3]) =~ s/^.*:://;
    msg("generating %s $section", ref($self));

    my $special_targets=$self->{$section}($mm_or, @param);
    $special_targets=~s/\.PHONY:\s+(.*)/\.PHONY: $1 cpanfile/m;
    return $special_targets;

}



__END__

=begin markdown

# NAME

ExtUtils::Markdown::Pod::MM::Import - install the MakeMaker lifecycle hooks

# DESCRIPTION

This module contains the import-time boundary between
`ExtUtils::Markdown::Pod` and `ExtUtils::MakeMaker`. While `Makefile.PL` is
running, it wraps the active `const_config`, `depend`, `postamble`, and
`post_initialize` implementations. Each wrapper calls the existing platform
implementation before applying the distribution behavior.

The hooks:

- publish the target constants as Makefile macros;
- retain the active local library paths and loaded MakeMaker extensions in the
  global `PERLRUN` command;
- add license metadata when both `LICENSE` and `AUTHOR` are supplied, and
  retain the default distribution target;
- make the generated Makefile depend on `VERSION_FROM` when needed;
- add the `doc` and `readme` targets;
- install `LICENSE`, exclude documentation and temporary sources from the
  install map, and record the Git revision beside `VERSION_FROM`.

Markdown selection, conversion, and Perl source updates are not implemented in
this module. Those operations belong to `Markdown::Pod::Embed` and are invoked
by the target methods in `ExtUtils::Markdown::Pod::MM`.

# IMPORT

Ordinary use needs no import arguments:

```perl
use ExtUtils::Markdown::Pod;
```

Import is ignored unless the running program is `Makefile.PL`. Repeated imports
in the same process do not install multiple wrappers.

# SEE ALSO

`ExtUtils::Markdown::Pod`, `ExtUtils::Markdown::Pod::MM`,
`ExtUtils::MakeMaker`

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

ExtUtils::Markdown::Pod::MM::Import - install the MakeMaker lifecycle hooks


=head1 DESCRIPTION

This module contains the import-time boundary between
C<ExtUtils::Markdown::Pod> and C<ExtUtils::MakeMaker>. While C<Makefile.PL> is
running, it wraps the active C<const_config>, C<depend>, C<postamble>, and
C<post_initialize> implementations. Each wrapper calls the existing platform
implementation before applying the distribution behavior.

The hooks:

=over

=item -

publish the target constants as Makefile macros;


=item -

retain the active local library paths and loaded MakeMaker extensions in the
  global C<PERLRUN> command;


=item -

add license metadata when both C<LICENSE> and C<AUTHOR> are supplied, and
  retain the default distribution target;


=item -

make the generated Makefile depend on C<VERSION_FROM> when needed;


=item -

add the C<doc> and C<readme> targets;


=item -

install C<LICENSE>, exclude documentation and temporary sources from the
  install map, and record the Git revision beside C<VERSION_FROM>.


=back

Markdown selection, conversion, and Perl source updates are not implemented in
this module. Those operations belong to C<Markdown::Pod::Embed> and are invoked
by the target methods in C<ExtUtils::Markdown::Pod::MM>.


=head1 IMPORT

Ordinary use needs no import arguments:


 use ExtUtils::Markdown::Pod;
Import is ignored unless the running program is C<Makefile.PL>. Repeated imports
in the same process do not install multiple wrappers.


=head1 SEE ALSO

C<ExtUtils::Markdown::Pod>, C<ExtUtils::Markdown::Pod::MM>,
C<ExtUtils::MakeMaker>


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
