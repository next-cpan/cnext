#!/usr/bin/perl
# A hacked-up script to bump $VERSION in cpanm because the file is not auto-bumped by milla release process
use strict;
use warnings;

sub find_version {
    my $file = shift;

    open my $fh, "<", $file or die $!;
    while (<$fh>) {
        /package App::cplay;our\$VERSION="(.*?)"/ and return $1;
    }
    return;
}

my $new_ver     = shift @ARGV           or die "missing version use: $0 VERSION";
my $current_ver = find_version("cplay") or die;

system( 'perl-reversion', '-current', $current_ver, '-set', $new_ver, 'cplay' ) == 0 or die $?;
chmod 0755, 'cplay';
