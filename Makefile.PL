use 5.006;
use strict;
use ExtUtils::MakeMaker;
BEGIN {
    use lib './lib';
    eval {
        require Markdown::Pod::Embed;
        Markdown::Pod::Embed->import;
        1;
    }
};
my $mm_ver = $ExtUtils::MakeMaker::VERSION;
if ($mm_ver =~ /_/) { # dev version
    $mm_ver = eval $mm_ver;
    die $@ if $@;
}
my %WriteMakefile=(
    NAME                => 'Markdown::Pod::Embed',
    DISTNAME            => 'Markdown-Pod-Embed',
    VERSION_FROM        => 'lib/Markdown/Pod/Embed.pm',
    ABSTRACT_FROM       => 'lib/Markdown/Pod/Embed.pm',
    EXE_FILES           => ['bin/markpod.pl'],
    LICENSE             => 'perl',
    AUTHOR              => 'Andrew Speer <andrew.speer@isolutions.com.au>',
    MIN_PERL_VERSION	=> '5.006',
    PREREQ_PM           =>  {
        'Test::Simple'  =>  0.44,
		'Markdown::Pod'	        =>  0,
		'PPI'			=>  0,
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

package MY;
use File::Copy qw(copy);
use File::Spec;
use Tie::File;
use Cwd qw(abs_path);

sub post_initialize {

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
    $mm_or->SUPER::post_initialize;

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
    $mm_or->SUPER::init_main();

}
