use 5.006;
use strict;
use ExtUtils::MakeMaker;
use File::Copy qw(copy);
use File::Spec;
use Tie::File;
use Cwd qw(abs_path);
use version;


#  Self load
#
BEGIN {
    use lib './lib';
    eval {
        require ExtUtils::Markdown::Pod;
        ExtUtils::Markdown::Pod->import;
        1;
    }
};


#  Main Makefile.PL section
#
my $mm_ver = $ExtUtils::MakeMaker::VERSION;
if ($mm_ver =~ /_/) { # dev version
    $mm_ver = eval $mm_ver;
    die $@ if $@;
}
my %WriteMakefile=(
    NAME                => 'ExtUtils::Markdown::Pod',
    DISTNAME            => 'ExtUtils-Markdown-Pod',
    VERSION_FROM        => 'lib/ExtUtils/Markdown/Pod.pm',
    ABSTRACT_FROM       => 'lib/ExtUtils/Markdown/Pod.pm',
    EXE_FILES           => ['bin/markpod.pl'],
    LICENSE             => 'perl',
    AUTHOR              => 'Andrew Speer <andrew.speer@isolutions.com.au>',
    MIN_PERL_VERSION	=> '5.006',
    PREREQ_PM           =>  {
        'Config'                =>  0,
        'Cwd'                   =>  0,
        'Carp'                  =>  0,
        'Data::Dumper'          =>  0,
        'Digest::MD5'           =>  0,
        'ExtUtils::MM'          =>  0,
        'ExtUtils::Manifest'    =>  0,
        'Exporter'              =>  0,
        'Fcntl'                 =>  0,
        'File::Basename'        =>  0,
        'File::Copy'            =>  0,
        'File::Spec'            =>  0,
        'FindBin'               =>  0,
        'Getopt::Long'          =>  0,
        'IO::File'              =>  0,
        'IPC::Run3'             =>  0,
        'Markdown::Pod'	        =>  0,
        'PPI'			=>  0,
        'Pod::Usage'            =>  0,
        'base'                  =>  0,
        'constant'              =>  0,
        'strict'                =>  0,
        'vars'                  =>  0,
        'warnings'              =>  0,
    },
    CONFIGURE_REQUIRES  =>  {
        'ExtUtils::MakeMaker'   =>  0,
        'File::Copy'            =>  0,
        'File::Spec'            =>  0,
        'Tie::File'             =>  0,
        'Cwd'                   =>  0,
        'version'               =>  0,
    },
    TEST_REQUIRES       =>  {
        'File::Path'            =>  0,
        'File::Temp'            =>  0,
        'Test::More'            =>  0,
    },
    META_MERGE => { 
        'meta-spec'     => {
            version     => 2
        },
        resources       => {
            homepage    => 'https://github.com/aspeer/pl-markpod',
            repository  => {
                type    => 'git',
                url     => 'https://github.com/aspeer/pl-markpod.git',
                web     => 'https://github.com/aspeer/pl-markpod'
            }
        }
    },
    'depend'            => {
        Makefile        => '$(VERSION_FROM)',
    },
    'dist'		=> {
	COMPRESS        =>  'gzip -9f',
	SUFFIX		=>  '.gz'
    },
);
my %MM_Compat=(
    '5.46'		=> [q(PM_FILTER)],
    '6.31'              => [q(LICENSE)],
    '6.46'              => [q(META_MERGE)],
    '6.48'              => [q(MIN_PERL_VERSION)],
    '6.52'              => [q(CONFIGURE_REQUIRES)],
    '6.5503'            => [q(BUILD_REQUIRES)],
    '6.64'              => [q(TEST_REQUIRES)],
);
while (my($mm_ver_test, $ar)=each %MM_Compat) {
    if (version->parse($mm_ver) < version->parse($mm_ver_test)) {
        delete @WriteMakefile{@{$ar}};
    }
}
WriteMakefile(%WriteMakefile);


#  Custom extensions
#
sub MY::postamble {

    #  Stub, add custom postamble here if required
    #
    my $mm_or=shift();
    my $postamble; eval {ExtUtils::Git->import(); $postamble=&MY::postamble($mm_or)};
    my $super_postamble=$mm_or->MY::SUPER::postamble;
    return $postamble if defined $postamble && index($postamble, $super_postamble) >= 0;
    return ($postamble || '') . $super_postamble;

}


sub MY::post_initialize {

    #  Add license file, other support files here
    #
    my $mm_or=shift();
    $mm_or->{'PM'}{'LICENSE'}='$(INST_LIBDIR)/$(BASEEXT)/LICENSE' if -e 'LICENSE';
    
    
    #  Add git ref if needed
    #
    if (grep {$mm_or->{'VERSION_FROM'} eq $_} @{$mm_or->{'EXE_FILES'}}) {
        push @{$mm_or->{'EXE_FILES'}}, $mm_or->{'VERSION_FROM'}.'.sha';
    }
    
    
    #  Don't install docs/tmp files etc.
    #
    my %pm=map { $_=>$mm_or->{'PM'}{$_} } grep { !/\.(?:md|xml|pod|bak|tmp|0)$/ } keys %{$mm_or->{'PM'}};
    $mm_or->{'PM'}=\%pm;
    
    
    #  Update Git Ref in file if needed/available
    #
    my $devnull=File::Spec->devnull();
    if (my $git_version=qx(git rev-parse --short HEAD 2>$devnull)) {
        chomp $git_version;
        tie my @lines, 'Tie::File', $mm_or->{'VERSION_FROM'} . '.sha' || die "error on Tie::File, $!";
        $lines[0]=$git_version;
    }
    $mm_or->MY::SUPER::post_initialize;

}


sub MM::init_main {

    #  Strip .pl, .sh extension from script files before installing
    #
    my $mm_or=shift();
    my @fn;
    foreach my $fn (@{$mm_or->{'EXE_FILES'}}) {
        (my $fn_new=$fn)=~s/\.(?:pl|sh)$//;
        if ($fn_new ne $fn) {
            -f $fn_new || do { eval{symlink(abs_path($fn), $fn_new)} || copy(abs_path($fn), $fn_new) }
        }
        push @fn, $fn_new;
    }
    $mm_or->{'EXE_FILES'}=\@fn;
    $mm_or->MY::SUPER::init_main();

}
