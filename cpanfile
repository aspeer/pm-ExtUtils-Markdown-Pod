requires 'Markdown::Pod::Embed';
requires 'Markdown::Pod::Embed::Constant';
requires 'Markdown::Pod::Embed::Util';
requires 'FindBin';
requires 'Getopt::Long';
requires 'Markdown::Pod';
requires 'PPI';
requires 'Pod::Usage';
requires 'constant';
requires 'strict';
requires 'vars';
requires 'warnings';
requires 'with';

on configure => sub {
    requires 'perl', '5.006';
};

on test => sub {
    requires 'Test::More';
};
