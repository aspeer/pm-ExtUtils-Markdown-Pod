requires 'Cwd';
requires 'Carp';
requires 'Data::Dumper';
requires 'Digest::MD5';
requires 'ExtUtils::MM';
requires 'ExtUtils::Manifest';
requires 'Exporter';
requires 'Fcntl';
requires 'File::Basename';
requires 'File::Spec';
requires 'FindBin';
requires 'Getopt::Long';
requires 'IO::File';
requires 'Markdown::Pod::Embed', '0.010';
requires 'Pod::Usage';
requires 'Software::LicenseUtils';
requires 'Tie::File';
requires 'base';
requires 'constant';
requires 'strict';
requires 'vars';
requires 'warnings';

on configure => sub {
    requires 'perl', '5.008';
    requires 'ExtUtils::MakeMaker';
    requires 'Tie::File';
    requires 'version';
};

on test => sub {
    requires 'File::Path';
    requires 'File::Temp';
    requires 'Test::More';
};
