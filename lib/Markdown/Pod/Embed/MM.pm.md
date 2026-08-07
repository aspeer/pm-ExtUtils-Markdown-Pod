# NAME

Markdown::Pod::Embed::MM - MakeMaker integration for Markdown::Pod::Embed

# SYNOPSIS

In `Makefile.PL`:

```perl
BEGIN {
    use lib './lib';
    eval {
        require Markdown::Pod::Embed;
        Markdown::Pod::Embed->import;
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

`Markdown::Pod::Embed::MM` contains the `ExtUtils::MakeMaker` integration for
`Markdown::Pod::Embed`. The core processor is deliberately kept in
`Markdown::Pod::Embed`; this module handles the MakeMaker hook points, generated
Makefile targets, and README generation policy.

When `Markdown::Pod::Embed` is imported from `Makefile.PL`, import dispatch is
handed to this module. The module records enough MakeMaker context to rebuild
the command line used by the generated `doc` and `readme` targets.

# MAKEFILE INTEGRATION

The module adds a postamble fragment containing targets that invoke
`Markdown::Pod::Embed::MM` from the generated Makefile.

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
   `lib/Markdown/Pod/Embed.pm.md`.
3. Embedded Markdown in the `VERSION_FROM` file.

When the `VERSION_FROM` sidecar or embedded Markdown is used, the module creates
`README.md` as a symlink to the sidecar source when possible and adds any new
files to `MANIFEST`.

The Markdown is rendered to plain text with `pandoc` via `IPC::Run3`.

# FUNCTIONS

## import

Records the importing class, import tags, and current `@INC` so MakeMaker
targets can re-invoke the module with the same local library paths.

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

`Markdown::Pod::Embed`, `ExtUtils::MakeMaker`, `ExtUtils::MM`,
`ExtUtils::Manifest`

# AUTHOR

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE AND COPYRIGHT

This file is part of Markdown::Pod::Embed.

This software is copyright (c) 2026 by Andrew Speer
<andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>
