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
package ExtUtils::Markdown::Pod;


#  Compiler pragma and package variables
#
use strict qw(vars);
use vars qw($VERSION $VERSION_GIT_SHA $AUTHORITY @ISA);
use warnings;


#  Keep the historic processing API as a compatibility facade. The
#  implementation belongs to the independent Markdown processor.
#
use Markdown::Pod::Embed ();
@ISA=qw(Markdown::Pod::Embed);


#  Version information
#
$AUTHORITY='cpan:ASPEER';
$VERSION='0.011';
$VERSION_GIT_SHA=do { local(@ARGV, $/, $_); @ARGV=($_=__FILE__.'.sha'); <> if -f $_ };
chomp($VERSION_GIT_SHA) if defined($VERSION_GIT_SHA);


#  Done
#
1;


#===================================================================================================


sub import {


    #  MakeMaker integration is activated only while processing Makefile.PL.
    #  Markdown conversion remains implemented by Markdown::Pod::Embed.
    #
    return unless $0=~/Makefile\.PL$/i;
    require ExtUtils::Markdown::Pod::MM::Import;
    goto &ExtUtils::Markdown::Pod::MM::Import::import;

}


__END__

=begin markdown

# NAME

ExtUtils::Markdown::Pod - MakeMaker integration for Markdown-maintained POD

# SYNOPSIS

In `Makefile.PL`:

```perl
use ExtUtils::MakeMaker;
use ExtUtils::Markdown::Pod;

WriteMakefile(
    NAME         => 'Example',
    VERSION_FROM => 'lib/Example.pm',
);
```

This adds `doc` and `readme` targets to the generated Makefile.

For optional integration, load and import the module before `WriteMakefile`:

```perl
use ExtUtils::MakeMaker;

eval {
    require ExtUtils::Markdown::Pod;
    ExtUtils::Markdown::Pod->import();
    1;
};

WriteMakefile(
    NAME         => 'Example',
    VERSION_FROM => 'lib/Example.pm',
);
```

If the optional module cannot be loaded, MakeMaker continues without the
additional lifecycle hooks and documentation targets. The equivalent explicit
command-line activation is:

```text
perl -MExtUtils::Markdown::Pod Makefile.PL
```

# DESCRIPTION

`ExtUtils::Markdown::Pod` integrates documentation maintenance and the project's
established distribution conventions with `ExtUtils::MakeMaker`. Importing it
from `Makefile.PL` installs the MakeMaker lifecycle hooks used to configure the
generated Makefile, package metadata and install map, Git-SHA provenance, and
documentation targets. The generated global `PERLRUN` preserves
the active local library paths and MakeMaker extensions.

The responsibilities are deliberately separated:

- `ExtUtils::Markdown::Pod::MM::Import` installs and implements the MakeMaker
  lifecycle hooks.
- `ExtUtils::Markdown::Pod::MM` generates and executes the `doc` and `readme`
  targets.
- `Markdown::Pod::Embed` selects Markdown, converts it to POD, and updates Perl
  source files.

The documentation targets use files listed in `MANIFEST`. `doc` processes
Markdown sidecars for matching Perl modules, scripts, and declared executable
files. `readme` renders the best available README Markdown source as plain text.

# PROCESSOR COMPATIBILITY

For compatibility with earlier releases, this package inherits the processing
methods supplied by `Markdown::Pod::Embed`. New code that only converts or
updates Markdown/POD should use `Markdown::Pod::Embed` directly; it does not
need MakeMaker and does not install MakeMaker hooks.

# ERRORS

MakeMaker hook errors and target failures are fatal. Importing this module from
a program other than `Makefile.PL` does not alter `ExtUtils::MakeMaker`.

# SEE ALSO

`ExtUtils::Markdown::Pod::MM`, `ExtUtils::Markdown::Pod::MM::Import`,
`Markdown::Pod::Embed`, `ExtUtils::MakeMaker`

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

ExtUtils::Markdown::Pod - MakeMaker integration for Markdown-maintained POD


=head1 SYNOPSIS

In C<Makefile.PL>:


 use ExtUtils::MakeMaker;
 use ExtUtils::Markdown::Pod;

 WriteMakefile(
     NAME         => 'Example',
     VERSION_FROM => 'lib/Example.pm',
 );
This adds C<doc> and C<readme> targets to the generated Makefile.

For optional integration, load and import the module before C<WriteMakefile>:


 use ExtUtils::MakeMaker;

 eval {
     require ExtUtils::Markdown::Pod;
     ExtUtils::Markdown::Pod->import();
     1;
 };

 WriteMakefile(
     NAME         => 'Example',
     VERSION_FROM => 'lib/Example.pm',
 );
If the optional module cannot be loaded, MakeMaker continues without the
additional lifecycle hooks and documentation targets. The equivalent explicit
command-line activation is:


 perl -MExtUtils::Markdown::Pod Makefile.PL

=head1 DESCRIPTION

C<ExtUtils::Markdown::Pod> integrates documentation maintenance and the project's
established distribution conventions with C<ExtUtils::MakeMaker>. Importing it
from C<Makefile.PL> installs the MakeMaker lifecycle hooks used to configure the
generated Makefile, package metadata and install map, Git-SHA provenance, and
documentation targets. The generated global C<PERLRUN> preserves
the active local library paths and MakeMaker extensions.

The responsibilities are deliberately separated:

=over

=item -

C<ExtUtils::Markdown::Pod::MM::Import> installs and implements the MakeMaker
  lifecycle hooks.


=item -

C<ExtUtils::Markdown::Pod::MM> generates and executes the C<doc> and C<readme>
  targets.


=item -

C<Markdown::Pod::Embed> selects Markdown, converts it to POD, and updates Perl
  source files.


=back

The documentation targets use files listed in C<MANIFEST>. C<doc> processes
Markdown sidecars for matching Perl modules, scripts, and declared executable
files. C<readme> renders the best available README Markdown source as plain text.


=head1 PROCESSOR COMPATIBILITY

For compatibility with earlier releases, this package inherits the processing
methods supplied by C<Markdown::Pod::Embed>. New code that only converts or
updates Markdown/POD should use C<Markdown::Pod::Embed> directly; it does not
need MakeMaker and does not install MakeMaker hooks.


=head1 ERRORS

MakeMaker hook errors and target failures are fatal. Importing this module from
a program other than C<Makefile.PL> does not alter C<ExtUtils::MakeMaker>.


=head1 SEE ALSO

C<ExtUtils::Markdown::Pod::MM>, C<ExtUtils::Markdown::Pod::MM::Import>,
C<Markdown::Pod::Embed>, C<ExtUtils::MakeMaker>


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
