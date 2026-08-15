requires 'Cwd';
requires 'Carp';
requires 'Data::Dumper';
requires 'Digest::MD5';
requires 'ExtUtils::MM';
requires 'ExtUtils::Manifest';
requires 'Exporter';
requires 'Fcntl';
requires 'File::Basename';
requires 'File::Copy';
requires 'File::Spec';
requires 'FindBin';
requires 'Getopt::Long';
requires 'IO::File';
requires 'IPC::Run3';
requires 'Markdown::Pod';
requires 'PPI';
requires 'Pod::Usage';
requires 'Software::LicenseUtils';
requires 'base';
requires 'constant';
requires 'strict';
requires 'vars';
requires 'warnings';

on configure => sub {
    requires 'perl', '5.006';
    requires 'ExtUtils::MakeMaker';
    requires 'version';
};

on test => sub {
    requires 'File::Path';
    requires 'File::Temp';
    requires 'Test::More';
};
