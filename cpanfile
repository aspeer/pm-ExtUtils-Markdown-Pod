requires 'ASPEER::MakeMaker', '1.006';
requires 'Cwd';
requires 'Digest::MD5';
requires 'Docbook::Convert', '0.028';
requires 'ExtUtils::Manifest';
requires 'Exporter';
requires 'File::Basename';
requires 'File::Spec';
requires 'Markdown::Pod::Embed', '0.011';
requires 'perl', '5.010';
requires 'strict';
requires 'vars';
requires 'warnings';

on configure => sub {
    requires 'perl', '5.010';
    requires 'ExtUtils::MakeMaker';
    requires 'version';
};

on test => sub {
    requires 'File::Path';
    requires 'File::Temp';
    requires 'Test::More';
};
