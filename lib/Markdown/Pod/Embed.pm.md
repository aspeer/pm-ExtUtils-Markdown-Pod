
# NAME

Markdown::Pod::Embed - convert markdown formatted pod to pure pod

# SYNOPSIS

```perl

use Markdown::Pod::Embed
my $markpod_or=Markdown::Pod::Embed ->new()
$markpod_or->markpod_process('foo.pl');
my $pod_sr=$markpod_or->pod()
print ${$pod_sr}
```

# DESCRIPTION

Helper module for the markpod utility that can also be used independently. 


# METHODS

**new()** 

Create a new Markdown::Pod::Embed reference. Usage:

`my $markpod_or=Markdown::Pod::Embed->new(\%opt)`

See OPTIONS section for options that can be supplied to creator

**markpod_process( filename )** 

Process the named file. Will return number of POD lines changed from any existing in file as scalar reference

```perl
my $lines_changed_sr=$markpod_or->markpod_process('foo.pl');
print "lines changed: ", ${$lines_changed_sr}, "\n";
```

# AUTHOR

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT

This file is part of markpod.

This software is copyright (c) 2024 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>
