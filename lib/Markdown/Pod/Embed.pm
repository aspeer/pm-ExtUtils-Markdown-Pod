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


#  Compiler pragma
#
package Markdown::Pod::Embed;
use strict;
use warnings;
use vars qw($VERSION @EXPORT_OK $VERSION_GIT_SHA $AUTHORITY);


#  Base Packages
#
use Markdown::Pod::Embed::Util;
use Markdown::Pod::Embed::Constant;


#  Base external modules
#
use File::Copy;


#  Other external modules
#
use PPI;
use Markdown::Pod;


#  Version information
#
$AUTHORITY='cpan:ASPEER';
$VERSION='0.004';
$VERSION_GIT_SHA=do { local (@ARGV, $/) = ($_=__FILE__.'.sha'); <> if -f $_ };
chomp($VERSION_GIT_SHA) if defined $VERSION_GIT_SHA;


#  Done
#
1;

#===================================================================================================


sub import {

    #  Let MakeMaker (MM) Module handle import routines
    #
    if ($0=~/Makefile\.PL$/) {
        require Markdown::Pod::Embed::MM;
        goto &Markdown::Pod::Embed::MM::import;
    }

}


sub new {

    #  Bless self ref and retun
    #
    my ($class, $opt_hr)=@_;
    debug("instantiating new $class object with supplied options %s", Dumper($opt_hr));


    #  Get default options and overrides
    #
    my %opt=(
        %{$OPTION_HR},
        $opt_hr ? %{$opt_hr} : ()
    );
    debug('final option hash %s', Dumper(\%opt));


    #  Done
    #
    return bless({opt=>\%opt}, $class);

}


sub markpod_process {


    #  Find and replace POD in a file
    #
    my ($self, $fn)=@_;
    debug("processing file: $fn");


    #  Create new PPI documents from supplied file
    #
    my $ppi_doc_or=PPI::Document->new($fn) ||
        return err ("nable to create new PPI instance on file $fn");


    my $sidecar_md=$self->markpod_markdown_file_read($fn);
    my $end_or=$ppi_doc_or->find_first('PPI::Statement::End');
    
    
    #  Find Pod section and massage. If no POD exists, create one from sidecar markdown
    #
    my $pod_or_ar=$ppi_doc_or->find('PPI::Token::Pod');
    unless ($pod_or_ar) {
        unless (defined $sidecar_md) {
            msg("skipped file with no pod or markdown source: $fn");
            return undef;
        }
        $self->markpod_end_normalize($end_or) if $end_or;
        my $pod_md=$sidecar_md;
        my $pod=
            $self->markpod_pod_merge($pod_md) ||
                return err();
        $pod.="\n=cut\n";
        unless ($end_or) {
            $ppi_doc_or->add_element(PPI::Token::Separator->new("__END__\n\n"));
        }
        $ppi_doc_or->add_element(PPI::Document->new(\$pod));
        @{$self}{qw(

            pod_changed
            markdown
            ppi_doc_or
            
        )}=(
            
            1,
            $pod_md,
            $ppi_doc_or
        );
        return 1;
    }
    debug('pod_or_ar: %s', Dumper($pod_or_ar));
    my $end_changed=0;
    if ($end_or && (defined $sidecar_md || grep { $_->content()=~/^=begin markdown(?=\s*)/im } @{$pod_or_ar})) {
        $end_changed=$self->markpod_end_normalize($end_or);
    }
    my $sidecar_target_idx=0;
    if (defined $sidecar_md) {
        foreach my $idx (0 .. $#{$pod_or_ar}) {
            if ($pod_or_ar->[$idx]->content()=~/^=begin markdown(?=\s*)/im) {
                $sidecar_target_idx=$idx;
                last;
            }
        }
    }
    my ($md, $pod_changed, @pod, @raw_pod)=(undef, $end_changed);
    foreach my $idx (0 .. $#{$pod_or_ar}) {
        my $pod_or=$pod_or_ar->[$idx];
        my $pod_content=$pod_or->content();
        my $pod_md=$self->markpod_markdown_extract($pod_content);
        if (defined $sidecar_md && $idx == $sidecar_target_idx) {
            $pod_md=$sidecar_md;
            undef $sidecar_md;
        }
        unless (defined $pod_md) {
            debug("pod: no markdown source, preserving existing POD");
            push @pod, $pod_content;
            push @raw_pod, $pod_content;
            next;
        }
        $md.=$pod_md;
        my $pod=
            $self->markpod_pod_merge($pod_md) ||
                return err();
        push @raw_pod, $self->{'pod'};
        $pod.="\n=cut\n";
        if ($pod_changed += ($pod ne $pod_content)) {
            debug("pod: updating");
            $pod_or->set_content($pod);
        }
        else {
            debug("pod: no change, not updating");
        }
        push @pod, $pod;
    }
    
    
    #  Join POD
    #
    my $pod=join($/, @raw_pod);
    
    
    #  Store results
    #
    @{$self}{qw(

        pod_changed
        markdown
        ppi_doc_or
        
    )}=(
        
        $pod_changed,
        $md || '',
        $ppi_doc_or
    );
    
    
    #  Return number of pod lines that would have changed
    #
    return $pod_changed;
    
}


sub markpod_end_normalize {

    my ($self, $end_or)=@_;
    my $content=$end_or->content();
    my @children=$end_or->children();
    return 0 unless @children;

    my $pod_idx;
    foreach my $idx (0 .. $#children) {
        if ($children[$idx]->isa('PPI::Token::Pod')) {
            $pod_idx=$idx;
            last;
        }
    }

    my $last_gap_idx=defined $pod_idx ? $pod_idx - 1 : $#children;
    foreach my $idx (0 .. $#children) {
        if ($idx == 0) {
            $children[$idx]->set_content("__END__");
        }
        elsif ($idx == 1 && $idx <= $last_gap_idx) {
            $children[$idx]->set_content("\n\n");
        }
        elsif ($idx <= $last_gap_idx) {
            $children[$idx]->set_content('');
        }
    }
    if (!defined $pod_idx && @children == 1) {
        $end_or->add_element(PPI::Token::Whitespace->new("\n\n"));
    }
    return $content ne $end_or->content();

}


sub markpod_markdown_file_read {

    my ($self, $fn)=@_;
    my $md_fn="${fn}.md";
    return undef unless -f $md_fn;
    my $md=slurp($md_fn);
    chomp($md);
    $md=$self->markpod_markdown_normalize($md);
    unless (length $md) {
        debug("markdown sidecar file is empty, falling back to embedded markdown: $md_fn");
        return undef;
    }
    debug("using markdown sidecar file: $md_fn");
    return $md;

}



sub markpod_inplace_update {


    #  Update file in place
    #
    #my ($self, $fn, $ppi_doc_or, )=@_;
    #$ppi_doc_or ||= $self->markpod($fn) ||
    #  return err();
    my ($self, $fn)=@_;
    my $ppi_doc_or=$self->ppi_doc_or()
        || return err();


    #  Make a backup copy if needed
    #
    debug("updating file ${fn}");
    File::Copy::copy($fn, "${fn}.bak") unless $self->{'opt'}{'nobackup'};


    #  Save
    #
    $ppi_doc_or->save($fn) ||
        return err("unable to save to file: $fn, $!");
        

}


sub markpod_process_and_update {


    #  Process a file and save any resulting changes
    #
    my ($self, $fn)=@_;
    my $pod_changed=$self->markpod_process($fn);
    return undef unless defined $pod_changed;
    if ($pod_changed) {
        $self->markpod_inplace_update($fn) ||
            return err();
    }
    return $pod_changed;

}


sub markpod_markdown_source {


    #  Resolve markdown source for a file using sidecar-first precedence
    #
    my ($self, $fn)=@_;
    my $sidecar_md=$self->markpod_markdown_file_read($fn);
    return $sidecar_md if defined $sidecar_md;


    #  Fall back to embedded markdown in POD blocks
    #
    my $ppi_doc_or=PPI::Document->new($fn) ||
        return err ("unable to create new PPI instance on file $fn");
    my $pod_or_ar=$ppi_doc_or->find('PPI::Token::Pod') || return undef;
    my $md='';
    foreach my $pod_or (@{$pod_or_ar}) {
        my $pod_md=$self->markpod_markdown_extract($pod_or->content()) || next;
        $md.=$pod_md;
    }
    return length $md ? $md : undef;

}


sub markpod_markdown_extract {

    my ($self, $pod)=@_;
    my $md;
    if ($pod=~/^=begin markdown(?=\s*)(.*?)\n(.*?)\n*^=end markdown\s*$/gims || $pod=~/^=begin markdown(?=\s*)(.*?)\n(.*)\n*$/gims) {
        if (my $fn=$1) {
            $fn=~s/^\s*//;
            debug("suggested output filename: $fn");
            $self->{'opt'}{'outfile'} ||= $fn;
        }
        $md=$2;
    }
    else {
        return undef;
    }
    chomp($md);
    $md=$self->markpod_markdown_normalize($md);
    debug('extracted markdown %s', Dumper(\$md));
    return $md;

}


sub markpod_markdown_normalize {

    my ($self, $md)=@_;
    $md=~s/\A(?:[ \t]*\r?\n)+//;
    return $md;

}


sub markpod_pod_merge {

    my ($self, $md)=@_;
    my $md2pod_or=Markdown::Pod->new() ||
        return err ('unable to create new Markdown::Pod object');
    my $pod=$md2pod_or->markdown_to_pod(dialect => $self->{'opt'}{'dialect'}, markdown => $md);
    #  Make a note of raw POD for getter function
    $self->{'pod'}=$pod;
    debug('created pod %s', Dumper(\$pod));
    $pod=join(
        "\n",
        '=begin markdown',
        '',
        $md,
        '',
        '=end markdown',
        '',
        $pod
    );
    #  This is markdown merged with created POD
    return $pod;

}


sub markpod_markdown_text {


    #  Convert Markdown to text
    #
    my ($self, $md, $fn)=@_;


    #  Need IPC::Run3
    #
    eval {
        require IPC::Run3;
        1;
    } || return err('unable to load IPC::Run3 module');


    #  Need pandoc for this bit
    #
    $PANDOC_EXE ||
        return err('pandoc is required for markdown to text conversion');

    #  Run the Pandoc conversion to markup
    #
    my $text;
    {   my $command_ar=
            $PANDOC_CMD_MD2TEXT_CR->($PANDOC_EXE, '-');

        #die Dumper($command_ar, \$md, ($fn || \$text), \undef);
        IPC::Run3::run3($command_ar, \$md, ($fn || \$text), \undef) ||
            return err('unable to run3 %s', Dumper($command_ar));
        if ((my $err=$?) >> 8) {
            return err("error $err on run3 of: %s", Dumper($command_ar));
        }
    }

    #  Done
    #
    return $text || '';

}


sub outfile {


    #  Save output to a file or send to STDOUT
    #
    my ($self, $output, $fn)=@_;


    #  Send to STDOUT or selected output file
    #
    return blurp($fn, $output) if $fn;
    print STDOUT $output;
    return 1;
    

}    



#  Getters
#
sub markdown { $_[0]->{'markdown'} }
sub pod { $_[0]->{'pod'} }
sub ppi_doc_or { $_[0]->{'ppi_doc_or'} }


1;
__END__

=begin markdown
# NAME

Markdown::Pod::Embed - embed Markdown as POD in Perl source files

# OVERVIEW

```perl
use Markdown::Pod::Embed;

my $markpod = Markdown::Pod::Embed->new({
    dialect  => 'GitHub',
    nobackup => 1,
});

my $changed = $markpod->markpod_process('lib/My/Module.pm');

if (defined $changed && $changed) {
    $markpod->markpod_inplace_update('lib/My/Module.pm');
}

my $markdown = $markpod->markdown;
my $pod      = $markpod->pod;
```

```perl
use Markdown::Pod::Embed;

my $markpod = Markdown::Pod::Embed->new;
$markpod->markpod_process_and_update('bin/my-tool.pl');
```

# SYNOPSIS

`Markdown::Pod::Embed` is the core processing module behind the `markpod`
utility. It reads a Perl source file, determines the Markdown source to use for
documentation, converts that Markdown to POD via `Markdown::Pod`, and updates
the parsed source document via `PPI`.

The module is intended for Perl developers who are comfortable with POD,
Markdown, CPAN-style module layouts, and source filters that work at the file
level rather than at runtime.

# DESCRIPTION

The module supports two documentation sources:

1. A sidecar Markdown file with the same path as the Perl source file plus
   `.md`, for example `lib/My/Module.pm.md` or `bin/tool.pl.md`.
2. A Markdown block embedded in an existing POD section using
   `=begin markdown ... =end markdown`.

When Markdown is found, the module regenerates a merged POD section containing:

1. The original Markdown wrapped in `=begin markdown` / `=end markdown`.
2. The POD generated from that Markdown.

This preserves Markdown as the source form while still making the file usable by
POD consumers such as `perldoc`, `pod2man`, and related toolchain components.

# PRECEDENCE

Markdown source precedence is as follows:

1. If a sidecar `.md` file exists, it wins.
2. Otherwise, embedded Markdown in the main file wins.
3. Otherwise, plain POD remains unchanged.

The current implementation applies those rules in these concrete cases:

1. If a file has existing POD and a sidecar exists, the sidecar replaces the
   Markdown source for one POD section in the file, preferring an existing
   Markdown-backed section when present.
2. If a file has existing POD but no sidecar, embedded Markdown sections are
   regenerated in place and plain POD sections are preserved.
3. If a file has no POD at all but a sidecar exists, a new POD section is
   created and appended to the file.
4. If a file has no POD and no sidecar, the file is skipped and no update is
   made.

This module does not currently concatenate multiple Markdown-backed POD sections
into a single final document. Each Markdown-backed POD section is processed
independently.

# FILE LAYOUT

The expected layouts are straightforward.

Embedded Markdown in a Perl file:

```pod
 =begin markdown

# NAME

My::Module - short description

# SYNOPSIS

`use My::Module;`

 =end markdown
 =cut
```

Sidecar Markdown file for a Perl source file:

```text
lib/My/Module.pm
lib/My/Module.pm.md
```

For scripts:

```text
bin/my-tool.pl
bin/my-tool.pl.md
```

# METHODS

## new

Constructor.

```perl
my $markpod = Markdown::Pod::Embed->new(\%opt);
```

Recognised options currently include:

`dialect`
: Markdown dialect passed to `Markdown::Pod`. The default is `GitHub`.

`nobackup`
: When false, `markpod_inplace_update` writes a `.bak` file before saving.

## markpod_process

```perl
my $changed = $markpod->markpod_process($filename);
```

Parses the target file and updates the in-memory `PPI::Document`.

Return value:

1. A positive integer if the processed POD differs from the current POD in the
   file.
2. `0` if the file was processed but nothing changed.
3. `undef` if the file was skipped, typically because it has neither POD nor a
   sidecar file.

Side effects:

1. Stores the processed `PPI::Document` internally for later save.
2. Stores extracted or sidecar Markdown internally.
3. Stores the raw generated POD internally.

## markpod_inplace_update

```perl
$markpod->markpod_inplace_update($filename);
```

Writes the current in-memory `PPI::Document` back to disk. This method assumes a
successful prior call to `markpod_process`.

Unless `nobackup` is true, the original file is copied to `$filename.bak`
before saving.

## markpod_process_and_update

```perl
my $changed = $markpod->markpod_process_and_update($filename);
```

Convenience wrapper which calls `markpod_process` and, if the file was actually
processed, writes the result back to disk with `markpod_inplace_update`.

This is the preferred entry point for higher-level orchestration such as
MakeMaker integration.

## markdown

```perl
my $markdown = $markpod->markdown;
```

Returns the Markdown source that was used during the most recent processing run.
Where multiple Markdown-backed sections were processed, their Markdown is
concatenated in processing order.

## pod

```perl
my $pod = $markpod->pod;
```

Returns the raw POD generated from the most recent Markdown conversion.

This is the generated POD only, not the full merged POD block containing
`=begin markdown` and `=end markdown`.

## ppi_doc_or

```perl
my $ppi_doc = $markpod->ppi_doc_or;
```

Returns the current `PPI::Document` object from the most recent processed file.

# HOW IT WORKS

At a high level the module does the following:

1. Parse the target file with `PPI`.
2. Look for a same-path sidecar Markdown file with a `.md` suffix.
3. Find POD tokens in the parsed document.
4. Extract embedded Markdown from POD blocks where present.
5. Choose the Markdown source according to the precedence rules described
   above.
6. Convert Markdown to POD using `Markdown::Pod`.
7. Rebuild the POD block as embedded Markdown plus generated POD.
8. Store the updated `PPI::Document` for later serialisation or in-place save.

If no POD exists but a sidecar exists, the module creates a new POD section and
appends it to the source file, inserting `__END__` if needed.

# EXAMPLES

Regenerate POD in place for a module:

```perl
use Markdown::Pod::Embed;

my $markpod = Markdown::Pod::Embed->new;
my $changed = $markpod->markpod_process('lib/My/Module.pm');

if (defined $changed && $changed) {
    $markpod->markpod_inplace_update('lib/My/Module.pm');
}
```

Process a script with no existing POD but with a sidecar file:

```perl
use Markdown::Pod::Embed;

my $markpod = Markdown::Pod::Embed->new({ nobackup => 1 });
$markpod->markpod_process_and_update('bin/my-tool.pl');
```

Extract the raw generated POD for piping into another formatter:

```perl
use Markdown::Pod::Embed;

my $markpod = Markdown::Pod::Embed->new;
$markpod->markpod_process('bin/my-tool.pl');

my $pod = $markpod->pod;
print $pod;
```

# CAVEATS

This module operates at file level and mutates parsed source documents. It is
not a runtime POD renderer.

The current implementation does not yet provide a higher-level policy for
collapsing several Markdown-backed POD regions into one final document section.
If a file contains several separate Markdown POD blocks, each block is handled
individually.

Sidecar processing is file-oriented and assumes a same-path `.md` companion
file. There is no search path, manifest lookup, or alternate naming policy in
the core module itself.

# SEE ALSO

`markpod`, `Markdown::Pod`, `PPI`, `perlpod`, `perlpodspec`, `pod2man`

# AUTHOR

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE AND COPYRIGHT

This file is part of markpod.

This software is copyright (c) 2024 by Andrew Speer
<andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>

=end markdown


=head1 NAME

Markdown::Pod::Embed - embed Markdown as POD in Perl source files


=head1 OVERVIEW


 use Markdown::Pod::Embed;
 
 my $markpod = Markdown::Pod::Embed->new({
     dialect  => 'GitHub',
     nobackup => 1,
 });
 
 my $changed = $markpod->markpod_process('lib/My/Module.pm');
 
 if (defined $changed && $changed) {
     $markpod->markpod_inplace_update('lib/My/Module.pm');
 }
 
 my $markdown = $markpod->markdown;
 my $pod      = $markpod->pod;

 use Markdown::Pod::Embed;
 
 my $markpod = Markdown::Pod::Embed->new;
 $markpod->markpod_process_and_update('bin/my-tool.pl');

=head1 SYNOPSIS

C<Markdown::Pod::Embed> is the core processing module behind the C<markpod>
utility. It reads a Perl source file, determines the Markdown source to use for
documentation, converts that Markdown to POD via C<Markdown::Pod>, and updates
the parsed source document via C<PPI>.

The module is intended for Perl developers who are comfortable with POD,
Markdown, CPAN-style module layouts, and source filters that work at the file
level rather than at runtime.


=head1 DESCRIPTION

The module supports two documentation sources:

=over

=item 1.

A sidecar Markdown file with the same path as the Perl source file plus
   C<.md>, for example C<lib/My/Module.pm.md> or C<bin/tool.pl.md>.


=item 2.

A Markdown block embedded in an existing POD section using
   C<=begin markdown ... =end markdown>.


=back

When Markdown is found, the module regenerates a merged POD section containing:

=over

=item 1.

The original Markdown wrapped in C<=begin markdown> / C<=end markdown>.


=item 2.

The POD generated from that Markdown.


=back

This preserves Markdown as the source form while still making the file usable by
POD consumers such as C<perldoc>, C<pod2man>, and related toolchain components.


=head1 PRECEDENCE

Markdown source precedence is as follows:

=over

=item 1.

If a sidecar C<.md> file exists, it wins.


=item 2.

Otherwise, embedded Markdown in the main file wins.


=item 3.

Otherwise, plain POD remains unchanged.


=back

The current implementation applies those rules in these concrete cases:

=over

=item 1.

If a file has existing POD and a sidecar exists, the sidecar replaces the
   Markdown source for one POD section in the file, preferring an existing
   Markdown-backed section when present.


=item 2.

If a file has existing POD but no sidecar, embedded Markdown sections are
   regenerated in place and plain POD sections are preserved.


=item 3.

If a file has no POD at all but a sidecar exists, a new POD section is
   created and appended to the file.


=item 4.

If a file has no POD and no sidecar, the file is skipped and no update is
   made.


=back

This module does not currently concatenate multiple Markdown-backed POD sections
into a single final document. Each Markdown-backed POD section is processed
independently.


=head1 FILE LAYOUT

The expected layouts are straightforward.

Embedded Markdown in a Perl file:


  =begin markdown
 
 # NAME
 
 My::Module - short description
 
 # SYNOPSIS
 
 `use My::Module;`
 
  =end markdown
  =cut
Sidecar Markdown file for a Perl source file:


 lib/My/Module.pm
 lib/My/Module.pm.md
For scripts:


 bin/my-tool.pl
 bin/my-tool.pl.md

=head1 METHODS


=head2 new

Constructor.


 my $markpod = Markdown::Pod::Embed->new(\%opt);
Recognised options currently include:

C<dialect>
: Markdown dialect passed to C<Markdown::Pod>. The default is C<GitHub>.

C<nobackup>
: When false, C<markpod_inplace_update> writes a C<.bak> file before saving.


=head2 markpod_process


 my $changed = $markpod->markpod_process($filename);
Parses the target file and updates the in-memory C<PPI::Document>.

Return value:

=over

=item 1.

A positive integer if the processed POD differs from the current POD in the
   file.


=item 2.

C<0> if the file was processed but nothing changed.


=item 3.

C<undef> if the file was skipped, typically because it has neither POD nor a
   sidecar file.


=back

Side effects:

=over

=item 1.

Stores the processed C<PPI::Document> internally for later save.


=item 2.

Stores extracted or sidecar Markdown internally.


=item 3.

Stores the raw generated POD internally.


=back


=head2 markpod_inplace_update


 $markpod->markpod_inplace_update($filename);
Writes the current in-memory C<PPI::Document> back to disk. This method assumes a
successful prior call to C<markpod_process>.

Unless C<nobackup> is true, the original file is copied to C<$filename.bak>
before saving.


=head2 markpod_process_and_update


 my $changed = $markpod->markpod_process_and_update($filename);
Convenience wrapper which calls C<markpod_process> and, if the file was actually
processed, writes the result back to disk with C<markpod_inplace_update>.

This is the preferred entry point for higher-level orchestration such as
MakeMaker integration.


=head2 markdown


 my $markdown = $markpod->markdown;
Returns the Markdown source that was used during the most recent processing run.
Where multiple Markdown-backed sections were processed, their Markdown is
concatenated in processing order.


=head2 pod


 my $pod = $markpod->pod;
Returns the raw POD generated from the most recent Markdown conversion.

This is the generated POD only, not the full merged POD block containing
C<=begin markdown> and C<=end markdown>.


=head2 ppi_doc_or


 my $ppi_doc = $markpod->ppi_doc_or;
Returns the current C<PPI::Document> object from the most recent processed file.


=head1 HOW IT WORKS

At a high level the module does the following:

=over

=item 1.

Parse the target file with C<PPI>.


=item 2.

Look for a same-path sidecar Markdown file with a C<.md> suffix.


=item 3.

Find POD tokens in the parsed document.


=item 4.

Extract embedded Markdown from POD blocks where present.


=item 5.

Choose the Markdown source according to the precedence rules described
   above.


=item 6.

Convert Markdown to POD using C<Markdown::Pod>.


=item 7.

Rebuild the POD block as embedded Markdown plus generated POD.


=item 8.

Store the updated C<PPI::Document> for later serialisation or in-place save.


=back

If no POD exists but a sidecar exists, the module creates a new POD section and
appends it to the source file, inserting C<__END__> if needed.


=head1 EXAMPLES

Regenerate POD in place for a module:


 use Markdown::Pod::Embed;
 
 my $markpod = Markdown::Pod::Embed->new;
 my $changed = $markpod->markpod_process('lib/My/Module.pm');
 
 if (defined $changed && $changed) {
     $markpod->markpod_inplace_update('lib/My/Module.pm');
 }
Process a script with no existing POD but with a sidecar file:


 use Markdown::Pod::Embed;
 
 my $markpod = Markdown::Pod::Embed->new({ nobackup => 1 });
 $markpod->markpod_process_and_update('bin/my-tool.pl');
Extract the raw generated POD for piping into another formatter:


 use Markdown::Pod::Embed;
 
 my $markpod = Markdown::Pod::Embed->new;
 $markpod->markpod_process('bin/my-tool.pl');
 
 my $pod = $markpod->pod;
 print $pod;

=head1 CAVEATS

This module operates at file level and mutates parsed source documents. It is
not a runtime POD renderer.

The current implementation does not yet provide a higher-level policy for
collapsing several Markdown-backed POD regions into one final document section.
If a file contains several separate Markdown POD blocks, each block is handled
individually.

Sidecar processing is file-oriented and assumes a same-path C<.md> companion
file. There is no search path, manifest lookup, or alternate naming policy in
the core module itself.


=head1 SEE ALSO

C<markpod>, C<Markdown::Pod>, C<PPI>, C<perlpod>, C<perlpodspec>, C<pod2man>


=head1 AUTHOR

Andrew Speer L<mailto:andrew.speer@isolutions.com.au>


=head1 LICENSE AND COPYRIGHT

This file is part of markpod.

This software is copyright (c) 2024 by Andrew Speer
L<mailto:andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

L<http://dev.perl.org/licenses/>

=cut
