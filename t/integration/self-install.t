#!perl

use FindBin;
use lib $FindBin::Bin . '/../lib';
use lib $FindBin::Bin . '/../../fatlib';

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use cPlayTestHelpers;

use App::cplay::std;
use App::cplay::Tester;

use App::cplay::InstallDirs;

note "Testing cplay --self-install";

if ( use_fatpack() ) {
    my $cplay_path = App::cplay::InstallDirs->new->bin . '/cplay';
    unlink $cplay_path if -e $cplay_path;
    ok !-e $cplay_path, "cplay_path does not exist";

    cplay(
        command => '--self-install',
        args    => [],
        exit    => 0,
        test    => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => array {
                item match qr{OK cplay is installed to };
                end;
            }, "cplay is installed to expected path";
        },
    );

    ok -f $cplay_path, "cplay is installed to $cplay_path";
    ok -x $cplay_path, "cplay is executable";
    unlink $cplay_path;
}
else {
    cplay(
        command => '--self-install',
        args    => [],
        exit    => 256,
        test    => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => array {
                item match qr{FAIL Can only install a FatPacked version of 'cplay'};
                end;
            }, "can only install a FatPacked version";
        },
    );
}

done_testing;
