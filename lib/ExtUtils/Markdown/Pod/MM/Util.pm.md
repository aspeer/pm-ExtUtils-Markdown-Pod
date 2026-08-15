# NAME

ExtUtils::Markdown::Pod::MM::Util - small utility functions for markpod

# SYNOPSIS

```perl
use ExtUtils::Markdown::Pod::MM::Util;

msg('markpod: %s -> %s: starting merge', $source, $target);
verbose('markpod: %s: skipped unsupported target', $target);
debug('processing file: %s', $filename);

my $text = slurp($filename);
blurp($filename, $text);
touch($filename);
```

# DESCRIPTION

`ExtUtils::Markdown::Pod::MM::Util` provides the small shared helpers used by the
`ExtUtils::Markdown::Pod` modules and the `markpod` command.

It is intentionally lightweight. It does not provide a logging framework or a
configuration system; it only centralises status output, debug output, errors,
and simple file helpers.

# OUTPUT HELPERS

Status output is written to STDERR so generated document content can safely be
written to STDOUT.

`msg`
: Prints a normal status line unless quiet mode is enabled.

`verbose`
: Prints a verbose status line only when verbose mode is enabled and quiet mode
  is not enabled.

`debug`
: Prints a developer diagnostic line when debug mode is enabled. Debug messages
  include caller package, method, and line number.

`err`
: Formats an error message, writes it to STDERR, and croaks.

# CONTROL HELPERS

`quiet_enable`
: Enables quiet mode.

`verbose_enable`
: Enables verbose mode.

`debug_enable`
: Enables or disables debug mode.

The command-line tool wires these to `--quiet`, `--verbose`, and `--debug`.
Debug mode can also be enabled with the script-specific environment variable
derived from `FindBin`.

# FILE HELPERS

`slurp`
: Reads a whole file into a scalar.

`blurp`
: Writes a scalar to a file, replacing the existing content.

`touch`
: Creates an empty file if it does not already exist.

# CAVEATS

The helper state is process-global. That is suitable for this distribution's
CLI and MakeMaker use, but callers embedding the module in a longer-running
process should avoid treating the output flags as object-local state.

# SEE ALSO

`ExtUtils::Markdown::Pod`, `ExtUtils::Markdown::Pod::MM`

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
