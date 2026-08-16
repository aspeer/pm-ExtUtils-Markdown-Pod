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
package ExtUtils::Markdown::Pod::MM;


#  Compiler Pragma
#
use strict qw(vars);
use vars   qw($VERSION @ISA $IMPORTED);
use warnings;
no warnings qw(uninitialized);
sub BEGIN {local $^W=0}


#  Base Packages
#
use ExtUtils::Markdown::Pod::MM::Util;


#  External Packages
#
use Digest::MD5 qw(md5_hex);


#  Version information in a formate suitable for CPAN etc. Must be
#  all on one line
#
$VERSION='0.010';


#  All done, init finished
#
1;


#======================================================================================================================

#  Makefile Targets from here down
# 
sub doc {


    #  Convert MD files to POD
    #
    my ($self, $param_hr)=(shift(), arg(@_));
    msg($self);
    my $exe_files_ar=$param_hr->{'EXE_FILES_AR'};
    my %exe_files=map {$_ => 1} @{$exe_files_ar};
    require ExtUtils::Markdown::Pod;


    #  Get manifest - only convert files in manifest
    #
    require ExtUtils::Manifest;
    my $manifest_hr=ExtUtils::Manifest::maniread();


    #  Hash to hold files we generate so not processed twice
    #
    my %ignore_fn;


    #  Look for all Markdown files ignoring ones we created ourselves
    #
    my @manifest_md_fn=sort grep {/\.md$/ && !m{^t/}} keys %{$manifest_hr};
    @manifest_md_fn=grep    {!$ignore_fn{$_}} @manifest_md_fn;


    #  Iterate
    #
    foreach my $fn (@manifest_md_fn) {

        #  Get target file name. If foo.pm.md, bar.pl.md and foo.pm or bar.pl exists, then
        #  convert Markdown to POD and install into target file.
        #

        #
        (my $target_fn=$fn)=~s/\.md$//;

        if ($target_fn=~/\.pm$/ || $target_fn=~/\.pl$/ || $exe_files{$target_fn}) {
            unless (-f $target_fn) {
                verbose("markpod: %s -> %s: skipped, missing target", $fn, $target_fn);
                next;
            }
            msg("markpod: %s -> %s: starting merge", $fn, $target_fn);
            my $markpod_or=ExtUtils::Markdown::Pod->new();
            my $pod_changed=$markpod_or->markpod_process_and_update($target_fn);
            if (!defined $pod_changed) {
                msg("markpod: %s -> %s: finished, skipped", $fn, $target_fn);
            }
            elsif ($pod_changed) {
                msg("markpod: %s -> %s: finished, updated pod", $fn, $target_fn);
            }
            else {
                msg("markpod: %s -> %s: finished, no changes", $fn, $target_fn);
            }
        }
        else {
            verbose("markpod: %s -> %s: skipped, unsupported target", $fn, $target_fn);

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
    require ExtUtils::Markdown::Pod;


    #  Get manifest for any file additions we make
    #
    require ExtUtils::Manifest;
    my $manifest_hr=ExtUtils::Manifest::maniread();
    my @manifest_add;
    my $version_from_fn=$param_hr->{'VERSION_FROM'};
    my $version_from_md_fn=sprintf('%s.md', $version_from_fn);
    my $readme_md_fn='README.md';
    my $readme_fn='README';
    my $markpod_or=ExtUtils::Markdown::Pod->new();
    my $md;
    my $source_fn;


    #  Resolve source precedence for README markdown
    #
    if (-f $readme_md_fn && !-l $readme_md_fn) {
        $source_fn=$readme_md_fn;
        $md=slurp($readme_md_fn);
    }
    elsif (-e $version_from_md_fn) {
        readme_symlink($readme_md_fn, $version_from_md_fn, \@manifest_add, $manifest_hr) ||
            return err();
        $source_fn=$version_from_md_fn;
        $md=$markpod_or->markpod_markdown_source($version_from_fn);
    }
    else {
        $md=$markpod_or->markpod_markdown_source($version_from_fn);
        unless (defined $md && length $md) {
            msg('markpod: %s -> %s: skipped, no markdown source', $version_from_fn, $readme_fn);
            return undef;
        }
        $source_fn=$version_from_fn;
        touch($version_from_md_fn);
        push @manifest_add, $version_from_md_fn unless exists $manifest_hr->{$version_from_md_fn};
        readme_symlink($readme_md_fn, $version_from_md_fn, \@manifest_add, $manifest_hr) ||
            return err();
    }
    msg('markpod: %s -> %s: starting render', $source_fn, $readme_fn);


    #  No markdown means nothing to render
    #
    unless (defined $md && length $md) {
        msg('markpod: %s -> %s: finished, skipped empty markdown source', $source_fn, $readme_fn);
        manifest_add(\@manifest_add) if @manifest_add;
        return undef;
    }


    #  Convert markdown to text
    #
    my $text=$markpod_or->markpod_markdown_text($md);
    

    #  Update README only when changed
    #
    my $existing_readme=-f $readme_fn ? slurp($readme_fn) : '';
    if (md5_hex($existing_readme) ne md5_hex($text)) {
        $markpod_or->outfile($text, $readme_fn) ||
            return err();
        msg('markpod: %s -> %s: finished, updated', $source_fn, $readme_fn);
    }
    else {
        msg('markpod: %s -> %s: finished, no changes', $source_fn, $readme_fn);
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
    verbose('markpod: %s -> %s: created symlink', $target_fn, $link_fn);
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

=begin markdown

# NAME

ExtUtils::Markdown::Pod::MM - MakeMaker integration for ExtUtils::Markdown::Pod

# SYNOPSIS

In `Makefile.PL`:

```perl
BEGIN {
    use lib './lib';
    eval {
        require ExtUtils::Markdown::Pod;
        ExtUtils::Markdown::Pod->import;
        1;
    };
}
```

Then run:

```bash
perl Makefile.PL
make doc
make readme
```

# DESCRIPTION

`ExtUtils::Markdown::Pod::MM` contains the `ExtUtils::MakeMaker` integration for
`ExtUtils::Markdown::Pod`. The core processor is deliberately kept in
`ExtUtils::Markdown::Pod`; this module handles the MakeMaker hook points, generated
Makefile targets, and README generation policy.

When `ExtUtils::Markdown::Pod` is imported from `Makefile.PL`, import dispatch is
handed to this module. The module records enough MakeMaker context to rebuild
the command line used by the generated `doc` and `readme` targets.

# MAKEFILE INTEGRATION

The module adds a postamble fragment containing targets that invoke
`ExtUtils::Markdown::Pod::MM` from the generated Makefile.

`doc`
: Finds Markdown files listed in `MANIFEST`, derives each target by removing
  the trailing `.md`, and merges supported sidecars into matching `.pm`, `.pl`,
  or executable files. Markdown files under `t/` are ignored so test fixtures
  are not rewritten by documentation builds.

`readme`
: Builds `README` from the best available Markdown source.

The generated status output is concise and goes to STDERR:

```text
markpod: lib/My/Module.pm.md -> lib/My/Module.pm: starting merge
markpod: lib/My/Module.pm.md -> lib/My/Module.pm: finished, updated pod
```

Unsupported or missing targets are reported only when verbose output has been
enabled.

# README SOURCE PRECEDENCE

README generation uses this source order:

1. A real `README.md` file, if present.
2. The sidecar for `VERSION_FROM`, for example
   `lib/ExtUtils/Markdown/Pod.pm.md`.
3. Embedded Markdown in the `VERSION_FROM` file.

When the `VERSION_FROM` sidecar or embedded Markdown is used, the module creates
`README.md` as a symlink to the sidecar source when possible and adds any new
files to `MANIFEST`.

The Markdown is rendered to plain text with `pandoc` via `IPC::Run3`.

# FUNCTIONS

## import

Records the importing class, import tags, and current `@INC` so MakeMaker
targets can re-invoke the module with the same local library paths. Emits a
status message confirming that the Makefile targets were installed.

## arg

Converts the positional arguments passed through the generated Makefile target
into a named hash used by `doc` and `readme`.

## doc

Processes sidecar Markdown files from `MANIFEST` and updates supported Perl
targets in place.

## readme

Renders the project README from Markdown according to the precedence described
above.

## readme_symlink

Creates or refreshes the `README.md` symlink used when the README source is the
`VERSION_FROM` sidecar.

## manifest_add

Adds generated support files to `MANIFEST`.

# CAVEATS

This module intentionally contains the MakeMaker-specific behavior and package
hooking so the core processor does not need to know about MakeMaker internals.

The implementation expects a traditional MakeMaker distribution layout with a
usable `MANIFEST` file.

# SEE ALSO

`ExtUtils::Markdown::Pod`, `ExtUtils::MakeMaker`, `ExtUtils::MM`,
`ExtUtils::Manifest`

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

ExtUtils::Markdown::Pod::MM - MakeMaker integration for ExtUtils::Markdown::Pod


=head1 SYNOPSIS

In C<Makefile.PL>:


 BEGIN {
     use lib './lib';
     eval {
         require ExtUtils::Markdown::Pod;
         ExtUtils::Markdown::Pod->import;
         1;
     };
 }
Then run:


 perl Makefile.PL
 make doc
 make readme

=head1 DESCRIPTION

C<ExtUtils::Markdown::Pod::MM> contains the C<ExtUtils::MakeMaker> integration for
C<ExtUtils::Markdown::Pod>. The core processor is deliberately kept in
C<ExtUtils::Markdown::Pod>; this module handles the MakeMaker hook points, generated
Makefile targets, and README generation policy.

When C<ExtUtils::Markdown::Pod> is imported from C<Makefile.PL>, import dispatch is
handed to this module. The module records enough MakeMaker context to rebuild
the command line used by the generated C<doc> and C<readme> targets.


=head1 MAKEFILE INTEGRATION

The module adds a postamble fragment containing targets that invoke
C<ExtUtils::Markdown::Pod::MM> from the generated Makefile.

C<doc>
: Finds Markdown files listed in C<MANIFEST>, derives each target by removing
  the trailing C<.md>, and merges supported sidecars into matching C<.pm>, C<.pl>,
  or executable files. Markdown files under C<t/> are ignored so test fixtures
  are not rewritten by documentation builds.

C<readme>
: Builds C<README> from the best available Markdown source.

The generated status output is concise and goes to STDERR:


 markpod: lib/My/Module.pm.md -> lib/My/Module.pm: starting merge
 markpod: lib/My/Module.pm.md -> lib/My/Module.pm: finished, updated pod
Unsupported or missing targets are reported only when verbose output has been
enabled.


=head1 README SOURCE PRECEDENCE

README generation uses this source order:

=over

=item 1.

A real C<README.md> file, if present.


=item 2.

The sidecar for C<VERSION_FROM>, for example
   C<lib/ExtUtils/Markdown/Pod.pm.md>.


=item 3.

Embedded Markdown in the C<VERSION_FROM> file.


=back

When the C<VERSION_FROM> sidecar or embedded Markdown is used, the module creates
C<README.md> as a symlink to the sidecar source when possible and adds any new
files to C<MANIFEST>.

The Markdown is rendered to plain text with C<pandoc> via C<IPC::Run3>.


=head1 FUNCTIONS


=head2 import

Records the importing class, import tags, and current C<@INC> so MakeMaker
targets can re-invoke the module with the same local library paths. Emits a
status message confirming that the Makefile targets were installed.


=head2 arg

Converts the positional arguments passed through the generated Makefile target
into a named hash used by C<doc> and C<readme>.


=head2 doc

Processes sidecar Markdown files from C<MANIFEST> and updates supported Perl
targets in place.


=head2 readme

Renders the project README from Markdown according to the precedence described
above.


=head2 readme_symlink

Creates or refreshes the C<README.md> symlink used when the README source is the
C<VERSION_FROM> sidecar.


=head2 manifest_add

Adds generated support files to C<MANIFEST>.


=head1 CAVEATS

This module intentionally contains the MakeMaker-specific behavior and package
hooking so the core processor does not need to know about MakeMaker internals.

The implementation expects a traditional MakeMaker distribution layout with a
usable C<MANIFEST> file.


=head1 SEE ALSO

C<ExtUtils::Markdown::Pod>, C<ExtUtils::MakeMaker>, C<ExtUtils::MM>,
C<ExtUtils::Manifest>


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
