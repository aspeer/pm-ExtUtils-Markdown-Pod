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
use vars   qw($VERSION @ISA $IMPORTED);
use warnings;
no warnings qw(uninitialized);
sub BEGIN {local $^W=0}


#  External Packages
#
use Markdown::Pod::Embed::MM::Constant;
use Markdown::Pod::Embed::Constant;
use Markdown::Pod::Embed::Util;
#use ExtUtils::Git::Util;
#use ExtUtils::Git::Constant;
#use Software::License;
#use Software::LicenseUtils;
#use File::Spec;
use Digest::MD5 qw(md5_hex);
#use File::Copy;
use Config;
use File::Spec;

#use Carp;
#use Cwd;

#die Dumper(\%Markdown::Pod::Embed::MM::Constant::Constant);

#  Version information in a formate suitable for CPAN etc. Must be
#  all on one line
#
$VERSION='1.188';


#  use ExtUtils::MakeMaker as our parent class.
#
#use base 'ExtUtils::MakeMaker';
use base 'ExtUtils::MM';


#  All done, init finished
#
1;


#===================================================================================================


sub import {

    $MY::->{__PACKAGE__}{'class'}=shift();
    $MY::->{__PACKAGE__}{'import_tag'}=\@_ if @_;
    $MY::->{__PACKAGE__}{'INC'}=\@INC;
    1;
    
}


sub arg {

    #  Convert MakeMaker target args to a named parameter hash.
    #
    my (%param, @argv);
    (@param{qw(NAME NAME_SYM DISTNAME DISTVNAME VERSION VERSION_SYM VERSION_FROM LICENSE AUTHOR TO_INST_PM EXE_FILES DIST_DEFAULT_TARGET SUFFIX ABSTRACT_FROM)}, @argv)=@_;
    $param{'TO_INST_PM_AR'}=[split /\s+/, $param{'TO_INST_PM'}];
    $param{'EXE_FILES_AR'}=[split /\s+/, $param{'EXE_FILES'}];
    $param{'ARGV_AR'}=\@argv;
    return \%param

}



sub ExtUtils::MY::postamble {


    #  Get self ref
    #
    my $mm_or=shift();
    msg("MM::postamble $mm_or");


    #  Get original postamble ready for append
    #
    my $postamble=$mm_or->SUPER::postamble();


    #  Get patch dir and file name
    #
    my $patch_fn=$TEMPLATE_POSTAMBLE_FN;


    #  Open it and slurp in
    #
    $postamble.=slurp($patch_fn);


    #  All done, return result
    #
    return $postamble;

}


sub MM::const_config {


    #  Get self ref
    #
    my $mm_or=shift();
    msg("MM::const_config $mm_or: %s", Dumper($MY::->{__PACKAGE__}));


    #  Import Constants into macros
    #
    while (my ($key, $value)=each %{sprintf('%s::Constant::Constant', __PACKAGE__)}) {

        #  Update macros with our config
        #
        $mm_or->{'macro'}{$key}=$value;

    }


    #  Setup PERLRUN to recreate any added libraries, start by pulling @INC as of import time
    #
    my @INC=@{$MY::->{__PACKAGE__}{'INC'}};
    

    #  Discard duplicates
    #
    my %perlrun_inc;
    @INC=grep {!$perlrun_inc{File::Spec->canonpath($_)}++} @INC;
    
    
    #  Discard any compiled or environmental library paths
    #
    foreach my $lib (map {$Config{$_}} qw(privlib archlib sitelib sitearch vendorlib vendorarch)) { 
        @INC=grep {!/^\Q${lib}\E/} @INC;
    }
    foreach my $lib (split (/\:/, $ENV{'PERL5LIB'})) { 
        @INC=grep {!/^\Q${lib}\E/} @INC;
    }
    
    
    #  Now construct final PERLRUN string
    #
    my $perlrun;
    my $perlrun_inc=join(' ', map {"-I$_"} grep {!$perlrun_inc{$_}++} @INC);
    my $class=$MY::->{'__PACKAGE__'}{'class'};
    if (my $import_tag_ar=$MY::->{__PACKAGE__}{'import_tag'}) {
        $perlrun=sprintf("\$(PERL) $perlrun_inc -M${class}=%s", join(',', @{$import_tag_ar}));
    }
    else {
        $perlrun="\$(PERL) $perlrun_inc -M${class}";
    }
    $mm_or->{'PERLRUN'}=$perlrun;

    
    #  Macros all set, return whatever master const_config does
    #
    return $mm_or->SUPER::const_config();


}


# Makefile Targets from here down
# 
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
    msg('processing markdown targets: %s', Dumper(\@manifest_md_fn))
        if @manifest_md_fn;



    #  Iterate
    #
    foreach my $fn (@manifest_md_fn) {

        #  Get target file name. If foo.pm.md, bar.pl.md and foo.pm or bar.pl exists, then
        #  convert Markdown to POD and install into target file.
        #

        #
        (my $target_fn=$fn)=~s/\.md$//;

        msg("processing target: $target_fn");
        if ($target_fn=~/\.pm$/ || $target_fn=~/\.pl$/ || $exe_files{$target_fn}) {
            unless (-f $target_fn) {
                msg("skipped missing target: $target_fn");
                next;
            }
            my $markpod_or=Markdown::Pod::Embed->new();
            my $pod_changed=$markpod_or->markpod_process_and_update($target_fn);
            if (!defined $pod_changed) {
                msg("skipped pod update: $target_fn");
            }
            elsif ($pod_changed) {
                msg("updated pod: $target_fn");
            }
            else {
                msg("no changes to pod: $target_fn");
            }
        }
        else {
            msg("skipped unsupported target: $target_fn");

        }

    }


    #  Done
    #
    return undef;

}


sub readme {


    #  Build README text from README.md, VERSION_FROM sidecar or embedded markdown
    #
    my ($self, $param_hr)=(shift(), arg(@_));
    require Markdown::Pod::Embed;


    #  Get manifest for any file additions we make
    #
    require ExtUtils::Manifest;
    my $manifest_hr=ExtUtils::Manifest::maniread();
    my @manifest_add;
    my $version_from_fn=$param_hr->{'VERSION_FROM'};
    my $version_from_md_fn=sprintf('%s.md', $version_from_fn);
    my $readme_md_fn='README.md';
    my $readme_fn='README';
    my $markpod_or=Markdown::Pod::Embed->new();
    my $md;


    #  Resolve source precedence for README markdown
    #
    if (-f $readme_md_fn && !-l $readme_md_fn) {
        msg('using README.md as markdown source');
        $md=slurp($readme_md_fn);
    }
    elsif (-e $version_from_md_fn) {
        readme_symlink($readme_md_fn, $version_from_md_fn, \@manifest_add, $manifest_hr) ||
            return err();
        $md=$markpod_or->markpod_markdown_source($version_from_fn);
        msg('using markdown sidecar source: %s', $version_from_md_fn);
    }
    else {
        $md=$markpod_or->markpod_markdown_source($version_from_fn);
        unless (defined $md && length $md) {
            msg('skipped README update: no markdown source for %s', $version_from_fn);
            return undef;
        }
        touch($version_from_md_fn);
        push @manifest_add, $version_from_md_fn unless exists $manifest_hr->{$version_from_md_fn};
        readme_symlink($readme_md_fn, $version_from_md_fn, \@manifest_add, $manifest_hr) ||
            return err();
        msg('using embedded markdown source: %s', $version_from_fn);
    }


    #  No markdown means nothing to render
    #
    unless (defined $md && length $md) {
        msg('skipped README update: resolved markdown source is empty');
        manifest_add(\@manifest_add) if @manifest_add;
        return undef;
    }


    #  Convert markdown to text
    #
    my $text=$markpod_or->markpod_markdown_text($md);
    msg("rendered README text");
    

    #  Update README only when changed
    #
    my $existing_readme=-f $readme_fn ? slurp($readme_fn) : '';
    if (md5_hex($existing_readme) ne md5_hex($text)) {
        $markpod_or->outfile($text, $readme_fn) ||
            return err();
        msg('updated README');
    }
    else {
        msg('no changes, README not updated');
    }

    manifest_add(\@manifest_add) if @manifest_add;

}


sub readme_symlink {

    my ($link_fn, $target_fn, $manifest_add_ar, $manifest_hr)=@_;
    if (-e $link_fn || -l $link_fn) {
        if (-l $link_fn) {
            my $current_target=readlink($link_fn);
            return 1 if defined $current_target && $current_target eq $target_fn;
            unlink($link_fn) ||
                return err("unable to remove stale symlink $link_fn, $!");
        }
        else {
            return err("$link_fn exists and is not a symlink");
        }
    }
    symlink($target_fn, $link_fn) ||
        return err("link of $target_fn to $link_fn failed, $!");
    push @{$manifest_add_ar}, $link_fn unless exists $manifest_hr->{$link_fn};
    msg('created symlink: %s -> %s', $link_fn, $target_fn);
    return 1;

}


sub manifest_add {

    my ($file_ar)=@_;
    return undef unless @{$file_ar};
    require ExtUtils::Manifest;
    my %add=map { $_ => '' } @{$file_ar};
    ExtUtils::Manifest::maniadd(\%add);
    return 1;

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
