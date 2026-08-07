
# NAME

markpod - merge Markdown documentation into Perl POD

# SYNOPSIS

```bash
markpod.pl --inplace lib/My/Module.pm
markpod.pl --extract-markdown lib/My/Module.pm
markpod.pl --extract-pod lib/My/Module.pm
```

# EXAMPLES

```bash
# Convert sidecar or embedded Markdown to POD and update the file.
markpod.pl --inplace bin/foo.pl
```

```bash
# Extract Markdown to a sidecar file.
markpod.pl bin/foo.pl --extract-markdown --outfile=bin/foo.pl.md
```

```bash
# Convert and write the transformed source to STDOUT.
markpod.pl lib/My/Module.pm
```

# DESCRIPTION

`markpod.pl` is the command-line interface for `Markdown::Pod::Embed`. It
processes Perl modules and scripts, finds Markdown documentation, converts that
Markdown to POD, and writes a merged documentation block back into the source.

Markdown can come from a same-path sidecar file such as `lib/My/Module.pm.md`
or from an embedded POD block beginning with `=begin markdown`.

The generated output keeps the Markdown source and appends generated POD, so the
file remains editable in Markdown while still working with POD tools such as
`perldoc`, `pod2man`, and CPAN metadata extractors.

Status messages are written to STDERR. Converted source, extracted Markdown, and
extracted POD are written to STDOUT unless `--outfile` is supplied.

# OPTIONS

**--file|--fn|--f|--in** input file to process. Positional filenames are also
accepted.

**--inplace** update the file in place

**--outfile|--output|--o** file to write extracted Markdown, extracted POD, or
transformed source to. Without this option, output goes to STDOUT.

**--dialect** Markdown dialect passed to `Markdown::Pod`. The default is
`GitHub`.

**--extract-markdown|--extract|--md|--markdown** extract Markdown from the input
file without updating POD.

**--extract-pod|--pod** extract generated POD from the input file.

**--nobackup** do not create a `.bak` file when doing an in-place update.

**--quiet** suppress status output.

**--verbose** include additional status messages, such as skipped MakeMaker
targets and backup behavior.

**--debug** enable developer diagnostics.

**--help** show help synopsis.

**--man** show the full manual page.

**--version** show version information.

# STATUS OUTPUT

Normal status output is intentionally short:

```text
markpod: lib/My/Module.pm.md -> lib/My/Module.pm: starting merge
markpod: lib/My/Module.pm: finished, updated pod
```

Use `--quiet` to suppress status lines.

# USAGE

Create a Markdown section in POD using the `=begin markdown` convention:

```markdown
 =pod
 =begin markdown 

 # POD Heading
 Some **Bold** Text
 [Perl Link](http://perl.org)
 Some `code` in this section

 =end markdown 
 =cut 
```

After `markpod.pl --inplace` runs, the block is rewritten to retain the Markdown
and append generated POD:

```pod
 =begin markdown

 # POD Heading
 Some **Bold** Text
 [Perl Link](http://perl.org)
 Some `code` in this section

 =end markdown

 =head1 POD Heading

 Some B\<Bold\> Text
 L\<Perl Link|http://perl.org\>
 Some C\<code\> in this section

 =cut
```

# AUTHOR

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT

This file is part of Markdown::Pod::Embed.

This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>
