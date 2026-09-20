#!perl

#  Load
#
use Test::More qw(no_plan);
use_ok( 'Markdown::Pod::Embed' );
$_='caller value';
use_ok( 'ExtUtils::Markdown::Pod' );
is( $_, 'caller value', 'loading module preserves caller default variable' );
ok( !exists $INC{'ExtUtils/Markdown/Pod/MM/Import.pm'},
    'processor compatibility facade does not load MakeMaker integration' );
use_ok( 'ExtUtils::Markdown::Pod::MM' );
use_ok( 'ExtUtils::Markdown::Pod::MM::Util' );
use_ok( 'ExtUtils::Markdown::Pod::Constant' );
use_ok( 'ExtUtils::Markdown::Pod::MM::Import' );
