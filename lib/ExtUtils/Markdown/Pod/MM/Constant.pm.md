# NAME

ExtUtils::Markdown::Pod::MM::Constant - constants for MakeMaker integration

# SYNOPSIS

```perl
use ExtUtils::Markdown::Pod::MM::Constant;

my $postamble = $TEMPLATE_POSTAMBLE_FN;
my $module    = $MM_PM;
my $argv      = $MM_ARGV;
```

# DESCRIPTION

`ExtUtils::Markdown::Pod::MM::Constant` defines constants used by
`ExtUtils::Markdown::Pod::MM` when it extends `ExtUtils::MakeMaker`.

The constants describe where the Makefile postamble template lives, which Perl
module should be invoked by the generated targets, and which MakeMaker
variables should be passed back into the target dispatcher.

# CONSTANTS

`$TEMPLATE_POSTAMBLE_FN`
: Path to the bundled `postamble.inc` template.

`$MM_PM`
: Module name invoked by the generated Makefile targets. This is normally
  `ExtUtils::Markdown::Pod::MM`.

`$MM_ARGV`
: Quoted list of MakeMaker variables passed to the target dispatcher so methods
  such as `doc` and `readme` can reconstruct their input parameters.

# LOCAL OVERRIDES

Local constants can be overridden by files loaded from:

```text
lib/ExtUtils/Markdown/Pod/MM/Constant.pm.local
~/.ExtUtils::Markdown::Pod::MM::Constant.local
```

Those files are expected to return a hash reference suitable for merging into
`%Constant`.

# SEE ALSO

`ExtUtils::Markdown::Pod::MM`, `ExtUtils::MakeMaker`

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
