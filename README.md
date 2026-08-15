# NAME

ExtUtils::Markdown::Pod - keep Perl documentation in Markdown and ship it as POD

# SYNOPSIS

With `ExtUtils::MakeMaker`:

```bash
perl -MExtUtils::Markdown::Pod Makefile.PL
make doc
```

From the command line:

```bash
markpod.pl --inplace lib/My/Module.pm
markpod.pl --extract-markdown lib/My/Module.pm > lib/My/Module.pm.md
markpod.pl --extract-pod lib/My/Module.pm
```

From a Perl module or script:

```perl
use ExtUtils::Markdown::Pod;

my $markpod = ExtUtils::Markdown::Pod->new({
    dialect  => 'GitHub',
    nobackup => 1,
});

my $changed = $markpod->markpod_process_and_update('lib/My/Module.pm');
```

The MakeMaker import hook adds `doc` and `readme` targets to the generated
Makefile.

# DESCRIPTION

`ExtUtils::Markdown::Pod` lets a distribution keep documentation in Markdown while
still embedding generated POD in Perl modules and scripts. The Markdown source
can live in a sidecar file such as `lib/My/Module.pm.md`, or inside a POD block
marked with `=begin markdown` and `=end markdown`.

When a file is processed, the module converts the Markdown to POD using
`Markdown::Pod`, then writes a merged documentation block back to the Perl file.
The merged block keeps the original Markdown and appends the generated POD, so
the Markdown remains editable while tools such as `perldoc`, `pod2man`,
`ABSTRACT_FROM`, and CPAN indexers can consume normal POD.

# MARKDOWN SOURCE PRECEDENCE

The processor uses a simple precedence rule:

1. A same-path sidecar file ending in `.md` wins.
2. Otherwise, embedded Markdown in a POD block is used.
3. Otherwise, existing plain POD is left unchanged.

For example, `lib/My/Module.pm.md` is the source for
`lib/My/Module.pm`. For a script, `bin/tool.pl.md` is the source for
`bin/tool.pl`.

# MAKE TARGETS

The MakeMaker integration lives in `ExtUtils::Markdown::Pod::MM` and is loaded
automatically when `ExtUtils::Markdown::Pod` is imported by `Makefile.PL`.

`make doc`
: Processes Markdown sidecars listed in `MANIFEST` and merges them into their
  matching `.pm`, `.pl`, or executable targets. Markdown files under `t/` are
  ignored so test fixtures are not rewritten by documentation builds.

`make readme`
: Builds `README` from `README.md`, from the `VERSION_FROM` sidecar, or from
  embedded Markdown in the `VERSION_FROM` file.

Status output is written to STDERR. Normal output is intentionally compact:

```text
markpod: lib/My/Module.pm.md -> lib/My/Module.pm: starting merge
markpod: lib/My/Module.pm.md -> lib/My/Module.pm: finished, updated pod
```

# COMMAND LINE OPTIONS

`--inplace`
: Update the input file instead of writing the transformed source to STDOUT.

`--file`, `--fn`, `--f`, `--in`
: Input file. Positional filenames are also accepted.

`--outfile`, `--output`, `--o`
: File to write extracted Markdown, extracted POD, or transformed source to.

`--extract-markdown`, `--extract`, `--md`, `--markdown`
: Extract Markdown without writing generated POD back to the source file.

`--extract-pod`, `--pod`
: Extract generated POD.

`--dialect`
: Markdown dialect passed through to `Markdown::Pod`. The default is `GitHub`.

`--nobackup`
: Do not create a `.bak` file when updating in place.

`--quiet`
: Suppress status output.

`--verbose`
: Include skip and support messages that are normally hidden.

`--debug`
: Enable developer-oriented diagnostics.

# DOGFOODING

This distribution uses its own sidecar workflow. The important modules and the
CLI have adjacent Markdown files:

```text
lib/ExtUtils/Markdown/Pod.pm.md
lib/ExtUtils/Markdown/Pod/MM.pm.md
lib/ExtUtils/Markdown/Pod/Constant.pm.md
lib/ExtUtils/Markdown/Pod/MM/Constant.pm.md
lib/ExtUtils/Markdown/Pod/MM/Util.pm.md
bin/markpod.pl.md
README.md
```

Running `make doc` regenerates embedded POD in the modules and script from
those files. Running `make readme` regenerates `README`.

# DEPENDENCIES

The core conversion path requires `Markdown::Pod` and `PPI`.

README generation uses `pandoc` through `IPC::Run3`. If `pandoc` is not
available, README generation will fail and the README-specific test is skipped.

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
