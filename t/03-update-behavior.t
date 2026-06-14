#!perl

use strict;
use warnings;
use lib 'lib';

use File::Temp qw(tempdir);
use Test::More;

use Markdown::Pod::Embed;

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

{
    my $dir=tempdir(CLEANUP => 1);
    my $fn="${dir}/backup.pm";
    my $orig=<<'PM';
package Sample::Backup;
1;
__END__

=begin markdown

# NAME

Sample::Backup - original markdown

=end markdown
=cut
PM
    spew($fn, $orig);

    my $changed=Markdown::Pod::Embed->new->markpod_process_and_update($fn);
    ok($changed > 0, 'default update changes markdown-backed POD');
    ok(-f "${fn}.bak", 'default update creates backup file');
    is(slurp("${fn}.bak"), $orig, 'backup file preserves original content');
}

{
    my $dir=tempdir(CLEANUP => 1);
    my $fn="${dir}/multi-markdown.pm";
    spew($fn, <<'PM');
package Sample::MultiMarkdown;
1;
__END__

=begin markdown

# NAME

Sample::MultiMarkdown - first markdown block

=end markdown
=cut

=begin markdown

# DESCRIPTION

Second markdown block

=end markdown
=cut
PM

    my $markpod_or=Markdown::Pod::Embed->new({nobackup => 1});
    my $changed=$markpod_or->markpod_process($fn);
    ok($changed > 0, 'multiple markdown-backed POD sections report changes');
    like($markpod_or->markdown, qr/first markdown block.*Second markdown block/s, 'markdown getter contains both sources in order');

    $markpod_or->markpod_inplace_update($fn);
    my $updated=slurp($fn);
    like($updated, qr/^=head1 NAME\b/m, 'first generated heading is present');
    like($updated, qr/^=head1 DESCRIPTION\b/m, 'second generated heading is present');
}

done_testing;
