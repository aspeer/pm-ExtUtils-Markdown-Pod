#  This file is part of ExtUtils::Git.
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
package Markdown::Pod::Embed::MM;


#  Compiler Pragma
#
use strict qw(vars);
use vars   qw($VERSION @ISA);
use warnings;
no warnings qw(uninitialized);
sub BEGIN {local $^W=0}


#  External Packages
#
use Markdown::Pod::Embed::MM::Constant;
use Markdown::Pod::Embed::Constant;
#use ExtUtils::Git::Util;
#use ExtUtils::Git::Constant;
#use Software::License;
#use Software::LicenseUtils;
use IO::File;
#use File::Spec;
use Data::Dumper;
#use Carp;
#use Cwd;

#die Dumper(\%Markdown::Pod::Embed::MM::Constant::Constant);

#  Version information in a formate suitable for CPAN etc. Must be
#  all on one line
#
$VERSION='1.188';


#  use ExtUtils::MakeMaker as our parent class.
#
use base 'ExtUtils::MakeMaker';


#  All done, init finished
#
1;


#===================================================================================================

sub err {

    use Carp qw(croak confess);
    confess sprintf(shift(), @_);
    
}


sub msg {

    CORE::print sprintf(shift(), @_)."\n";
    
}


sub arg {

    #  Get args, does nothing but intercept distname for messages, convert to param
    #  hash
    #
    my (%param, @argv);
    (@param{qw(NAME NAME_SYM DISTNAME DISTVNAME VERSION VERSION_SYM VERSION_FROM LICENSE AUTHOR TO_INST_PM EXE_FILES DIST_DEFAULT_TARGET SUFFIX ABSTRACT_FROM)}, @argv)=@_;
    $param{'TO_INST_PM_AR'}=[split /\s+/, $param{'TO_INST_PM'}];
    $param{'EXE_FILES_AR'}=[split /\s+/, $param{'EXE_FILES'}];
    $param{'ARGV_AR'}=\@argv;
    return \%param

}


sub import {


    #  Manage activation of const_config and dist_ci targets via import tags. Import tags are
    #
    #  use ExtUtils::Git::MM qw(const_config) to just replace the macros section of the Makefile
    #  .. qw(dist_ci) to replace standard MakeMaker targets with our own
    #  .. qw(:all) to get both of the above, usual usage
    #

    #  Get params, bless self ref and remember import tags spec'd for later
    #  re-use
    #
    my $self=bless \my %self, shift();
    my %import_tag=map {$_ => 1} @{$self{'import_tag'}=\@_};
    $import_tag{':all'}++ unless keys %import_tag;


    #  Store for later use in MY::makefile section
    #
    $self{'ISA'}=\@INC;


    #  sections to replace
    #
    my @section=qw(
        const_config
        distdir
        depend
        postamble
        special_targets
    );    #dist_ci
    @section=qw(
        const_config
        postamble
    );
    {   no warnings 'redefine';
        foreach my $section (grep {$import_tag{$_} || $import_tag{':all'}} @section) {
            $self{$section}=UNIVERSAL::can('MY', $section);
            *{"MY::${section}"}=sub {&{$section}($self, @_)};
        }
    }


}


sub postamble {


    #  Get self ref
    #
    my $self=shift();


    #  Get patch dir and file name
    #
    my $patch_fn=$TEMPLATE_POSTAMBLE_FN;


    #  Open it
    #
    my $patch_fh=IO::File->new($patch_fn, O_RDONLY) ||
        return err("unable to open $patch_fn, $!");


    #  Get original and append
    #
    my $postamble=$self->{'postamble'}(@_);
    $postamble.=join('', <$patch_fh>);


    #  Close
    #
    $patch_fh->close();


    #  All done, return result
    #
    return $postamble;

}


sub const_config {


    #  Get self ref
    #
    my ($self, $mm)=(shift(), @_);


    #  Import Constants into macros
    #
    while (my ($key, $value)=each %{sprintf('%s::Constant::Constant', __PACKAGE__)}) {

        #  Update macros with our config
        #
        $mm->{'macro'}{$key}=$value;

    }


    #  Adjust PERLRUN to include @INC and this module
    #
    my $perlrun;
    my %perlrun_inc;
    my $perlrun_inc=join(' ', map {"-I$_"} grep {!$perlrun_inc{$_}++} @{$self->{'ISA'}});
    my $class=ref($self);
    if (my $include_tags_ar=$self->{'include_tags'}) {
        $perlrun=sprintf("\$(PERL) $perlrun_inc -M${class}=%s", join(',', @{$include_tags_ar}));
    }
    else {
        $perlrun="\$(PERL) $perlrun_inc -M${class}";
    }
    $mm->{'PERLRUN'}=$perlrun;


    #  Keep copy of DIST_DEFAULT
    #
    #$mm->{'macro'}{'DIST_DEFAULT_TARGET'}=$mm->{'DIST_DEFAULT'};


    #  Return whatever our parent does
    #
    return $self->{'const_config'}(@_);


}


sub doc {


    #  Convert MD files to POD
    #
    my ($self, $param_hr)=(shift(), arg(@_));
    my $exe_files_ar=$param_hr->{'EXE_FILES_AR'};
    my %exe_files=map {$_ => 1} @{$exe_files_ar};
    require Markdown::Pod::Embed;


    #  Get manifest - only convert files in manifest
    #
    require ExtUtils::Manifest;
    my $manifest_hr=ExtUtils::Manifest::maniread();


    #  Hash to hold files we generate so not processed twice
    #
    my %ignore_fn;


    #  Look for all Markdown files ignoring ones we created ourselves
    #
    my @manifest_md_fn=grep {/\.md$/} keys %{$manifest_hr};
    @manifest_md_fn=grep    {!$ignore_fn{$_}} @manifest_md_fn;
    msg('found following Markdown files for conversion %s', Dumper(\@manifest_md_fn))
        if @manifest_md_fn;



    #  Iterate
    #
    foreach my $fn (@manifest_md_fn) {

        #  Get target file name. If foo.pm.md, bar.pl.md and foo.pm or bar.pl exists, then
        #  convert Markdown to POD and install into target file.
        #

        #
        (my $target_fn=$fn)=~s/\.md$//;

        msg("considering target $target_fn from file: $fn");
        if ($target_fn=~/\.pm$/ || $target_fn=~/\.pl$/ || $exe_files{$target_fn}) {
            unless (-f $target_fn) {
                msg("skipped missing target $target_fn");
                next;
            }
            msg("converting $fn to POD");
            my $markpod_or=Markdown::Pod::Embed->new();
            #$markpod_or->markpod_process_and_update($target_fn) ||
            #    return err();
            msg("converted to POD: $target_fn");
        }
        else {
            msg("skipped $target_fn");

        }

    }


    #  Done
    #
    return \undef;

}
1;


__END__



#  MakeMaker::MY replacement const_config section
#
sub depend {


    #  Get self ref
    #
    my ($self, $mm)=(shift(), @_);


    #  Get original and modify
    #
    my $depend=$self->{'depend'}(@_);


    #  If nothing generate default
    #
    if (!$depend && $mm->{'VERSION_FROM'}) {
        $depend='Makefile : $(VERSION_FROM)';
    }
    return $depend;

}


#  MakeMaker::MY update postamble section to include a "git_import" and other functions
#
sub distdir {


    #  Get self ref
    #
    my $self=shift();


    #  Get original and modify
    #
    my $distdir=$self->{'distdir'}(@_);
    $distdir=~s/distmeta/distmeta git_distchanges/;
    return $distdir;

}



sub special_targets {

    my $self=shift();
    my $special_targets=$self->{'special_targets'}(@_);
    $special_targets=~s/\.PHONY:\s+(.*)/\.PHONY: $1 cpanfile/m;
    return $special_targets;

}
