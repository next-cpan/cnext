#!perl

use FindBin;
use lib $FindBin::Bin . '/../fatlib';

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Test::MockModule;

use App::cnext::std;
use App::cnext::InstallDirs;

use File::Slurper qw{read_text write_text read_binary write_binary};

use File::Copy;

use File::Temp;
my $tmp = File::Temp->newdir();

my $MYPERL = q[/usr/bin/myperl];

my @tests = (
    [ '#!perl'                => "#!$MYPERL" ],
    [ '#!./perl'              => "#!$MYPERL" ],
    [ '#!/usr/bin/perl'       => "#!$MYPERL" ],
    [ '#!/usr/local/bin/perl' => "#!$MYPERL" ],
    [ '#!/usr/bin/env perl'   => "#!$MYPERL" ],
    [ '#!env perl'            => "#!$MYPERL" ],

    [ '#!perl -w'              => "#!$MYPERL -w" ],
    [ '#!./perl -w'            => "#!$MYPERL -w" ],
    [ '#!/usr/bin/perl -w'     => "#!$MYPERL -w" ],
    [ '#!/usr/bin/env perl -w' => "#!$MYPERL -w" ],
    [ '#!env perl -w'          => "#!$MYPERL -w" ],

    [ '#!/usr/bin/perl -w -w -w' => "#!$MYPERL -w -w -w" ],

    [ "#!/usr/local/perl/perls/perl-5.30.1/bin/perl" => "#!$MYPERL" ],
    [ "#!$^X"                                        => "#!$MYPERL" ],

    # non perl
    [ '#!sh'        => "#!sh" ],
    [ '#!/bin/sh'   => "#!/bin/sh" ],
    [ '#!/bin/ruby' => "#!/bin/ruby" ],
);

my $idir = App::cnext::InstallDirs->new;

foreach my $test (@tests) {
    my ( $shebang, $updated_shebang ) = @$test;

    note "$shebang => $updated_shebang";

    my $script = "$tmp/sample-script";

    write_text( $script, hello_world($shebang) );

    if ( $shebang ne $updated_shebang ) {
        ok $idir->adjust_perl_shebang( $script, $MYPERL ), "adjust_perl_shebang updated - $shebang -> $updated_shebang";
    }
    else {
        ok !$idir->adjust_perl_shebang( $script, $MYPERL ), "adjust_perl_shebang no shebang to update";
    }

    my $updated_content        = read_text($script);
    my $expect_updated_content = hello_world($updated_shebang);

    is $updated_content, $expect_updated_content, "file uses '$updated_shebang'";
}

{
    note "checking a binary file";
    my $tmpfile = "$tmp/myperl";
    ok File::Copy::copy( $^X, $tmpfile ), "create a tmp binary file";

    ok !$idir->adjust_perl_shebang( $tmpfile, $^X ), "adjust_perl_shebang do not alter a compiled binary file";
    is -s $tmpfile, -s $^X, "file size not altered";

    is read_binary($tmpfile), read_binary($^X), "binary file content preserved";
}

done_testing;

sub hello_world($shebang) {
    return <<"EOS";
$shebang

use v5.20;

say q[hello world];

1;
EOS

}

