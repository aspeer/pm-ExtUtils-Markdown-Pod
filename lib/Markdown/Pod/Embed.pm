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
package Markdown::Pod::Embed;
use strict;
use warnings;
use vars qw($VERSION @EXPORT_OK $VERSION_GIT_SHA $AUTHORITY);


#  Base Packages
#
use Markdown::Pod::Embed::Util;
use Markdown::Pod::Embed::Constant;


#  Base external modules
#
use IO::File;
use File::Copy;


#  Other external modules
#
use PPI;
use Markdown::Pod;


#  Version information
#
$AUTHORITY='cpan:ASPEER';
$VERSION='0.004';
$VERSION_GIT_SHA=do { local (@ARGV, $/) = ($_=__FILE__.'.sha'); <> if -f $_ };
chomp($VERSION_GIT_SHA) if defined $VERSION_GIT_SHA;


#  Done
#
1;

#===================================================================================================


sub new {

    #  Bless self ref and retun
    #
    my ($class, $opt_hr)=@_;
    debug("instantiating new $class object with supplied options %s", Dumper($opt_hr));


    #  Get default options and overrides
    #
    my %opt=(
        %{$OPTION_HR},
        $opt_hr ? %{$opt_hr} : ()
    );
    debug('final option hash %s', Dumper(\%opt));


    #  Done
    #
    return bless({opt=>\%opt}, $class);

}


sub markpod_process {


    #  Find and replace POD in a file
    #
    my ($self, $fn)=@_;
    debug("processing file: $fn");


    #  Create new PPI documents from supplied file
    #
    my $ppi_doc_or=PPI::Document->new($fn) ||
        return err ("nable to create new PPI instance on file $fn");


    #  Find Pod section and massage. Return early if nothing to do (no POD)
    #
    my $pod_or_ar=$ppi_doc_or->find('PPI::Token::Pod') || do {
        msg("no POD section found in file: $fn, skipping");
        return \undef;
    };
    debug('pod_or_ar: %s', Dumper($pod_or_ar));
    my $sidecar_md_sr=$self->markpod_markdown_file_read($fn);
    my ($md, $pod_changed, @pod, @raw_pod)=(undef, 0);
    foreach my $pod_or (@{$pod_or_ar}) {
        my $pod_content=$pod_or->content();
        my $pod_md_sr=$self->markpod_markdown_extract($pod_content);
        if (!$pod_md_sr && $sidecar_md_sr) {
            $pod_md_sr=$sidecar_md_sr;
            undef $sidecar_md_sr;
        }
        unless ($pod_md_sr) {
            debug("pod: no markdown source, preserving existing POD");
            push @pod, $pod_content;
            push @raw_pod, $pod_content;
            next;
        }
        my $pod_md=${$pod_md_sr};
        $md.=$pod_md;
        my $pod=${
            $self->markpod_pod_merge($pod_md) ||
                return err();
        };
        push @raw_pod, $self->{'pod'};
        $pod.="\n=cut\n";
        if ($pod_changed += ($pod ne $pod_content)) {
            debug("pod: updating");
            $pod_or->set_content($pod);
        }
        else {
            debug("pod: no change, not updating");
        }
        push @pod, $pod;
    }
    
    
    #  Join POD
    #
    my $pod=join($/, @raw_pod);
    
    
    #  Store results
    #
    @{$self}{qw(

        pod_changed
        markdown
        ppi_doc_or
        
    )}=(
        
        $pod_changed,
        $md || '',
        $ppi_doc_or
    );
    
    
    #  Return scalar ref of pod lines that would have changed
    #
    return \$pod_changed;
    
}


sub markpod_markdown_file_read {

    my ($self, $fn)=@_;
    my $md_fn="${fn}.md";
    return undef unless -f $md_fn;
    my $fh=IO::File->new($md_fn, 'r') ||
        return err("unable to open markdown file $md_fn, $!");
    local $/=undef;
    my $md=<$fh>;
    chomp($md);
    debug("using markdown sidecar file: $md_fn");
    return \$md;

}



sub markpod_inplace_update {


    #  Update file in place
    #
    #my ($self, $fn, $ppi_doc_or, )=@_;
    #$ppi_doc_or ||= $self->markpod($fn) ||
    #  return err();
    my ($self, $fn)=@_;
    my $ppi_doc_or=$self->ppi_doc_or()
        || return err();


    #  Make a backup copy if needed
    #
    debug("updating file ${fn}");
    File::Copy::copy($fn, "${fn}.bak") unless $self->{'opt'}{'nobackup'};


    #  Save
    #
    $ppi_doc_or->save($fn) ||
        return err("unable to save to file: $fn, $!");
        

}


sub markpod_markdown_extract {

    my ($self, $pod)=@_;
    my $md;
    if ($pod=~/^=begin markdown(?=\s*)(.*?)\n(.*?)\n*^=end markdown\s*$/gims || $pod=~/^=begin markdown(?=\s*)(.*?)\n(.*)\n*$/gims) {
        if (my $fn=$1) {
            $fn=~s/^\s*//;
            debug("suggested output filename: $fn");
            $self->{'opt'}{'outfile'} ||= $fn;
        }
        $md=$2;
    }
    else {
        return undef;
    }
    chomp($md);
    debug('extracted markdown %s', Dumper(\$md));
    return \$md;

}


sub markpod_pod_merge {

    my ($self, $md)=@_;
    my $md2pod_or=Markdown::Pod->new() ||
        return err ('unable to create new Markdown::Pod object');
    my $pod=$md2pod_or->markdown_to_pod(dialect => $self->{'opt'}{'dialect'}, markdown => $md);
    #  Make a note of raw POD for getter function
    $self->{'pod'}=$pod;
    debug('created pod %s', Dumper(\$pod));
    $pod=join(
        "\n",
        '=begin markdown',
        $md,
        '',
        '=end markdown',
        '',
        $pod
    );
    #  This is markdown merged with created POD
    return \$pod;

}


sub outfile {


    #  Save output to a file or send to STDOUT
    #
    my ($self, $output_sr, $fn)=@_;


    #  Send to STDOUT or selected output file
    #
    my $fh=$fn ? do {
        IO::File->new($fn, O_CREAT|O_TRUNC|O_WRONLY) ||
            return err("unable to open output file $fn, $!");
        } : *STDOUT;
    print $fh ${$output_sr};
    

}    


#  Getters
#
foreach my $sub (qw(markdown pod ppi_doc_or)) {

    no strict qw(refs);
    *{sprintf("%s::${sub}", __PACKAGE__)}=sub { ref($_[0]->{$sub}) ? $_[0]->{$sub} : \($_[0]->{$sub}) }
    
}


1;
__END__

=begin markdown

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

=end markdown


=head1 NAME

Markdown::Pod::Embed - convert markdown formatted pod to pure pod


=head1 SYNOPSIS


 
 use Markdown::Pod::Embed
 my $markpod_or=Markdown::Pod::Embed ->new()
 $markpod_or->markpod_process('foo.pl');
 my $pod_sr=$markpod_or->pod()
 print ${$pod_sr}

=head1 DESCRIPTION

Helper module for the markpod utility that can also be used independently. 


=head1 METHODS

B<new()> 

Create a new Markdown::Pod::Embed reference. Usage:

C<<< my $markpod_or=Markdown::Pod::Embed->new(\%opt) >>>

See OPTIONS section for options that can be supplied to creator

B<markpod_process( filename )> 

Process the named file. Will return number of POD lines changed from any existing in file as scalar reference


 my $lines_changed_sr=$markpod_or->markpod_process('foo.pl');
 print "lines changed: ", ${$lines_changed_sr}, "\n";

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
