#!/usr/bin/perl

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
use strict;
use vars qw($VERSION);
use warnings;


#  Base External modules
#
use Markdown::Pod::Embed;
use Markdown::Pod::Embed::Util;
use Markdown::Pod::Embed::Constant;


#  Other external modules
#
use IO::File;
use Fcntl;
use Pod::Usage;
use FindBin qw($RealBin $Script);
use Getopt::Long qw(GetOptionsFromArray :config auto_version auto_help);


#  Constantas
#
use constant {


    #  Command line options in Getopt::Long format
    #
    OPTION_AR => [

        qw(man verbose quiet debug),
        'dialect=s',
        'inplace|i',
        'infile_ar|file|fn|f|in=s@',
        'outfile|output|o=s',
        'extract_markdown|extract_md|extract|noconvert|md|markdown',
        'extract_pod|pod',
        'nobackup'
    ],


    #  Option defaults
    #
    OPTION_HR => {
        %{$OPTION_HR},                              # From Markdown::Pod::Embed::Constant;
        %{do(glob("~/.${Script}.option")) || {}}    # || {} avoids warning
    },


    #  Environment prefix which will override option, e.g. MARKPOD_NOBACKUP=1
    #
    OPTION_ENV_PREFIX => 'MARKPOD',

};


#  Version Info, must be all one line for MakeMaker, CPAN.
#
$VERSION='0.013';


#  Run main
#
exit(${&main(&getopt(\@ARGV)) || die err ()} || 0);    # || 0 stops warnings


#===================================================================================================


sub main {    #no subsort


    #  Get base object blassed with options as first arg.
    #
    my $self=Markdown::Pod::Embed->new((my $opt_hr=shift()));
    
    
    #  Output file name. Might be empty
    #
    my $output_fn=$opt_hr->{'outfile'};


    #  Iterate over infiles
    #
    foreach my $fn (@{$opt_hr->{'infile_ar'}}) {


        #  Sanity check on file name
        #
        debug("processing file: $fn");
        unless (-f $fn) {
            return err ("file $fn not found");
        }
        
        
        #  Process
        #
        my $pod_changed_sr=$self->markpod_process($fn) ||
            return err();
        unless (defined ${$pod_changed_sr}) {
            debug("markpod_process skipped file: $fn");
            next;
        }
        my $pod_changed=${$pod_changed_sr};
        debug("markpod_process completed with $pod_changed lines updated");


        #  Do whatever opts tell us
        #
        if ($opt_hr->{'extract_markdown'}) {
        
        
            #  Just want markdown
            #
            my $markdown_sr=$self->markdown() ||
                return err() ;
                

            #  Send to STDOUT or selected output file
            #
            &outfile($markdown_sr, $output_fn);
            
        }
        elsif ($opt_hr->{'extract_pod'}) {


            #  Just want POD
            #
            my $pod_sr=$self->pod() ||
                return err();
        
                
            #  Send to STDOUT or selected output file
            #
            &outfile($pod_sr, $output_fn);
            
        }
        elsif ($opt_hr->{'inplace'}) {
        
        
            #  Want to update inplace. Only do if changed
            #
            if ($pod_changed) {
                #my $ppi_doc_or=$self->ppi_doc_or($fn) ||
                #    return err();
                $self->markpod_inplace_update($fn) ||
                    return err();
            }
            
        }
        else {

            #  Guess we want the whole resulting file output somewhere
            #
            my $ppi_doc_or=$self->ppi_doc_or($fn) ||
                return err();
            my $output=$ppi_doc_or->serialize();
            
            
            #  Send to STDOUT or selected output file
            #
            &outfile(\$output, $output_fn);
            
        }
    }


    #  Done
    #
    return \undef;


}


sub outfile {


    #  Save output to a file or send to STDOUT
    #
    my ($output_sr, $fn)=@_;


    #  Send to STDOUT or selected output file
    #
    my $fh=$fn ? do {
        IO::File->new($fn, O_CREAT|O_TRUNC|O_WRONLY) ||
            return err("unable to open output file $fn, $!");
        } : *STDOUT;
    print $fh ${$output_sr};
    

}    


sub getopt {


    #  ARGV usually supplied as array ref but could be anyting
    #
    my $opt_ar=shift() || \@ARGV;


    #  Base options will pass to compile. Get option defauts from ENV or Constant/options file
    #
    my %opt=(

        map {
            $_ => do {my $key=sprintf("%s_%s", +OPTION_ENV_PREFIX, uc($_)); defined $ENV{$key} ? $ENV{$key} : +OPTION_HR->{$_}}
        } keys %{+OPTION_HR}

    );
    debug('opt stage 1: %s', Dumper(\%opt));


    #  Now import command line options.
    #
    GetOptionsFromArray($opt_ar, \%opt, @{+OPTION_AR}, '' => \${opt {'stdin'}}, '<>' => sub {push @{$opt{'infile_ar'}}, shift() . ''}) ||
        pod2usage(2);
    debug_enable($opt{'debug'});
    debug('opt stage 2: %s', Dumper(\%opt));
    pod2usage(-verbose => 2) if $opt{'man'};
    


    #  Done
    #
    return \%opt;

}


1;
__END__


=begin markdown

# NAME

markpod - convert markdown formatted pod to pure pod

# SYNOPSIS

`markpod filename <filename> <filename>`

# EXAMPLES

```
#  Convert markdown in file to POD. Backup will be taken
markpod bin/foo.pl --inplace

#  Extract markdown from file and output to standalone file
markpod bin/foo.pl --extract --outfile=bin/foo.pl.md
```


# DESCRIPTION

markpod scans a file for markdown formatted pod and - if found - converts it to pure
pod, and then appends it to the pod section of the file. It allows the user to write perl
documentation in markdown format within a pod block - and then have it
converted to "normal" pod for use with all standard utilities that expect
pod documentation (e.g. perldoc etc.)

# OPTIONS

**--file|fn|f** input file to process

**--inplace** update the file in place

**--outfile** file to write to. If omitted will overwrite input file (i.e. inplace update)

**--dialect** which Markdown dialect to use from Markdent module. Options are Standard, GitHub (default) and Theory 

**--extract** just extract the Markdown from the input file and don't update POD. Print to STDOUT or file (using --output)

**--extract_pod** just extract the POD from the input file. Print to STDOUT or file (using --output)

**--nobackup** don't backup input file when doing inplace update

**--help** show help synopsis

**--man** show man page

**--version** show version information

# USAGE

Create a pod section in the perl code using the markdown formatter "begin"
convention, e.g.

```
 =pod
 =begin markdown 

 # POD Heading
 Some **Bold** Test
 [Perl Link](http://perl.org)
 Some `code` in this section

 =end markdown 
 =cut 
```
  
Once markpod is run it would be converted to the following.

 =head1 POD Heading

 Some B\<Bold\> Test
 L\<Perl Link|http://perl.org\>
 Some C\<code\> in this section

 =cut

# AUTHOR

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT

This file is part of markpod.

This software is copyright (c) 2024 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>

=end markdown


=head1 NAME

markpod - convert markdown formatted pod to pure pod


=head1 SYNOPSIS

C<<< markpod filename <filename> <filename> >>>


=head1 EXAMPLES

#  Convert markdown in file to POD. Backup will be taken

C<markpod bin/foo.pl --inplace>

#  Extract markdown from file and output to standalone file

C<markpod bin/foo.pl --extract --outfile=bin/foo.pl.md>


=head1 DESCRIPTION

markpod scans a file for markdown formatted pod and - if found - converts it to pure
pod, and then appends it to the pod section of the file. It allows the user to write perl
documentation in markdown format within a pod block - and then have it
converted to "normal" pod for use with all standard utilities that expect
pod documentation (e.g. perldoc etc.)


=head1 OPTIONS

B<--file|fn|f> input file to process

B<--inplace> update the file in place

B<--outfile> file to write to. If omitted will overwrite input file (i.e. inplace update)

B<--dialect> which Markdown dialect to use from Markdent module. Options are Standard, GitHub (default) and Theory 

B<--extract> just extract the Markdown from the input file and don't update POD. Print to STDOUT or file (using --output)

B<--extract_pod> just extract the POD from the input file. Print to STDOUT or file (using --output)

B<--nobackup> don't backup input file when doing inplace update

B<--help> show help synopsis

B<--man> show man page

B<--version> show version information


=head1 USAGE

Create a pod section in the perl code using the markdown formatter "begin"
convention, e.g.


  =pod
  =begin markdown 
 
  # POD Heading
  Some **Bold** Test
  [Perl Link](http://perl.org)
  Some `code` in this section
 
  =end markdown 
  =cut 
Once markpod is run it would be converted to the following.

 =head1 POD Heading

 Some B<Bold> Test
 L<Perl Link|L<http://perl.org\>>
 Some C<code> in this section

 =cut


=head1 AUTHOR

Andrew Speer L<mailto:andrew.speer@isolutions.com.au>


=head1 LICENSE and COPYRIGHT

This file is part of markpod.

This software is copyright (c) 2024 by Andrew Speer L<mailto:andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

L<http://dev.perl.org/licenses/>

=cut
