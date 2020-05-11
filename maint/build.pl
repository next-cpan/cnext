#!/usr/bin/env perl

use strict;
use warnings;

use File::pushd;
use File::Find;

use App::FatPacker ();    # need fatpack

sub generate_file {
    my ( $base, $target, $fatpack, $shebang_replace ) = @_;

    open my $in,  "<", $base         or die $!;
    open my $out, ">", "$target.tmp" or die $!;

    print STDERR "Generating $target from $base\n";

    while (<$in>) {
        next                                     if /Auto-removed/;
        s|^#!/usr/bin/env perl|$shebang_replace| if $shebang_replace;
        s/DEVELOPERS:.*/DO NOT EDIT -- this is an auto generated file/;
        s/.*__FATPACK__/$fatpack/;
        print $out $_;
    }

    close $out;

    unlink $target;
    rename "$target.tmp", $target;
}

system "rm", "-r", ".build" if -d '.build';
mkdir ".build", 0777;
system qw(cp -r fatlib lib .build/);

my $fatpack;
my $fatpack_compact;

{
    my $dir = pushd '.build';

    unlink 'lib/.keep';
    unlink 'fatlib/.keep';

    $fatpack = qx{fatpack file};

    my @files;
    my $want = sub {
        push @files, $_ if /\.pm$/;
    };

    print qx{pwd};
    find( { wanted => $want, no_chdir => 1 }, "fatlib", "lib" );
    system 'perlstrip', '--cache', '-v', @files;

    unlink "lib/App/cnext/Tester.pm";    # remove Tester from fatpack

    $fatpack_compact = qx{fatpack file};
}

generate_file( 'script/cnext.PL', "cnext", $fatpack_compact );
bump_git_revision('cnext');
chmod 0755, "cnext";

my $perltidy = qx{which perltidy};
if ( $? == 0 && length $perltidy ) {     # probably want to add a '# notidy file tag'
    chomp $perltidy if $perltidy;
    `$perltidy script/cnext.PL && mv script/cnext.PL.tdy script/cnext.PL`;
    `$perltidy cnext && mv cnext.tdy cnext`;
}

END {
    unlink "cnext.tmp";
    system "rm", "-r", ".build";
}

sub bump_git_revision {
    my $f = shift or die;

    -f $f or die;

    my $last_change = qx{git log -n1 --pretty=format:%h lib};
    return unless $? == 0;
    return unless defined $last_change;
    chomp $last_change;
    return unless length $last_change;

    my $content;
    {
        local $/;
        open( my $fh, '<:utf8', $f ) or die;
        $content = readline $fh;
    }

    $content =~ s{~REVISION~}{$last_change};

    open( my $fh, '>:utf8', $f ) or die;
    print {$fh} $content;

    return;
}
