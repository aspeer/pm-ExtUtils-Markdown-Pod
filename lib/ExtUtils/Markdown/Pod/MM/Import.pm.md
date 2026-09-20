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
