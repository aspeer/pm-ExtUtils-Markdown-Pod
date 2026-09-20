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

`ExtUtils::Markdown::Pod::MM` generates and executes the documentation targets
used by `ExtUtils::MakeMaker`. Markdown source selection, Markdown-to-POD
conversion, and Perl source updates are delegated to `Markdown::Pod::Embed`.

`ExtUtils::Markdown::Pod::MM::Import` installs the MakeMaker lifecycle hooks and
appends the target template. This module handles the resulting `doc` and
`readme` invocations.

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

README generation observes the existing project files before creating anything:

1. If `README.md` exists, it is used to generate or update `README`.
2. If `README` exists without `README.md`, both are left unchanged.
3. If neither exists, Markdown is obtained from the sidecar or embedded
   documentation of the file named by `VERSION_FROM` and written to a new,
   regular `README.md` file. `README` is then rendered from that file.
4. If the `VERSION_FROM` file has no sidecar or embedded Markdown, no README
   file is created.

The module never creates a `VERSION_FROM.md` sidecar. Generated README files are
added to `MANIFEST`.

`Markdown::Pod::Embed` renders the Markdown to plain text with `pandoc`.

# FUNCTIONS

## arg

Converts the positional arguments passed through the generated Makefile target
into a named hash used by `doc` and `readme`.

## doc

Processes sidecar Markdown files from `MANIFEST` and updates supported Perl
targets in place.

## readme

Renders the project README from Markdown according to the precedence described
above.

## manifest_add

Adds generated support files to `MANIFEST`.

# CAVEATS

This module contains MakeMaker-specific target generation and execution. The
hook installation is isolated in `MM::Import`, and Markdown/POD processing is
isolated in `Markdown::Pod::Embed`.

The implementation expects a traditional MakeMaker distribution layout with a
usable `MANIFEST` file.

# SEE ALSO

`ExtUtils::Markdown::Pod`, `ExtUtils::Markdown::Pod::MM::Import`,
`Markdown::Pod::Embed`, `ExtUtils::MakeMaker`, `ExtUtils::Manifest`

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
