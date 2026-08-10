#!perl

use strict;
use warnings;
use lib 'lib';

use Cwd qw(getcwd);
use File::Path qw(make_path);
use File::Temp qw(tempdir);
use Test::More;

use ExtUtils::Markdown::Pod::Constant;
use ExtUtils::Markdown::Pod::MM;

plan skip_all => 'pandoc is required for README generation tests'
    unless $PANDOC_EXE;

sub slurp {
    my ($fn)=@_;
    open my $fh, '<', $fn or die "open $fn: $!";
    local $/=undef;
    return scalar <$fh>;
}

sub spew {
    my ($fn, $content)=@_;
    open my $fh, '>', $fn or die "open $fn: $!";
    print {$fh} $content;
    close $fh or die "close $fn: $!";
}

my $cwd=getcwd();
my $dir=tempdir(CLEANUP => 1);
chdir $dir or die "chdir $dir: $!";

make_path('lib/Sample');

my $version_from='lib/Sample/Readme.pm';
spew($version_from, <<'PM');
package Sample::Readme;
our $VERSION = '0.001';
1;
PM
spew("${version_from}.md", <<'MD');
# NAME

Sample::Readme - README generated from version source sidecar
MD
spew('MANIFEST', <<'MANIFEST');
lib/Sample/Readme.pm
lib/Sample/Readme.pm.md
MANIFEST

ExtUtils::Markdown::Pod::MM::readme(
    undef,
    '',
    '',
    '',
    '',
    '',
    '',
    $version_from,
    '',
    '',
    '',
    '',
    '',
    '',
    '',
);

ok(-f 'README', 'README is generated');
like(slurp('README'), qr/Sample::Readme - README generated from version source sidecar/, 'README uses VERSION_FROM sidecar markdown');
ok(-l 'README.md', 'README.md symlink is created');
is(readlink('README.md'), "${version_from}.md", 'README.md symlink points at VERSION_FROM sidecar');

chdir $cwd or die "chdir $cwd: $!";

done_testing;
