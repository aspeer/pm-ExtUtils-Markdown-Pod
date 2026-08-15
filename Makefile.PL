use 5.006;
use strict;
use warnings;
use version;
use ExtUtils::MakeMaker;


#  Bring in helper MakeMaker modules if available, non-fatal if not
#
eval {
    # Utiltity sync targets
    require Local::ExtUtils::Common; Local::ExtUtils::Common->import(); 1 
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
        'Software::LicenseUtils'=>  0,
        'base'                  =>  0,
        'constant'              =>  0,
        'strict'                =>  0,
        'vars'                  =>  0,
        'warnings'              =>  0,
    },
    CONFIGURE_REQUIRES  =>  {
        'ExtUtils::MakeMaker'   =>  0,
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
