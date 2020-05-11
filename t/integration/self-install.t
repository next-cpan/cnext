#!perl

use FindBin;
use lib $FindBin::Bin . '/../lib';
use lib $FindBin::Bin . '/../../fatlib';

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use cPlayTestHelpers;

use App::next::std;
use App::next::Tester;

use App::next::IPC ();

use App::next::InstallDirs;

use Cwd qw{abs_path};

note "Testing cplay --self-install";

if ( use_fatpack() ) {
    my $install_to_dir = App::next::InstallDirs->new->bin;
    my $cplay_path     = $install_to_dir . '/cplay';

    {
        note "PATH is set";
        unlink $cplay_path if -e $cplay_path;
        ok !-e $cplay_path, "cplay_path does not exist";

        cplay(
            command => '--self-install',
            args    => [],
            exit    => 0,
            env     => {
                PATH => $ENV{PATH} . ':' . $install_to_dir,
            },
            test => sub($out) {
                my $lines = [ split( /\n/, $out->{output} ) ];
                is $lines => array {
                    item match qr{OK\s+cplay is installed to };
                    end;
                }, "cplay is installed to expected path";
            },
        );

        ok -f $cplay_path, "cplay is installed to $cplay_path";
        ok -x $cplay_path, "cplay is executable";

        my ( $exit, $out, $err ) = App::next::IPC::run3( [ $cplay_path, '--version' ] );
        is $exit,  0,                         'cplay --version exits with 0';
        like $out, qr{^\s*cplay\s+\d+\.\d+}a, 'cplay --version output' or diag ":$out:";
        is $err,   undef,                     'nothing on stderr';

        unlink $cplay_path;
    }

    {
        note "Testing when PATH does not contain the install dir";

        my $clean_path = clean_path($install_to_dir);
        note $clean_path;

        cplay(
            command => '--self-install',
            args    => [],
            exit    => 0,
            env     => {
                PATH => $clean_path,
            },
            test => sub($out) {
                my $lines = [ split( /\n/, $out->{output} ) ];
                is $lines => array {
                    item match qr{OK\s+cplay is installed to };
                    item match qr{WARN\s+.+is not in your PATH};
                    end;
                }, "cplay is installed to expected path";
            },
        );

        ok -f $cplay_path, "cplay is installed to $cplay_path";
        ok -x $cplay_path, "cplay is executable";

        unlink $cplay_path;
    }

    foreach my $type (qw{site perl vendor}) {
        note "Testing installdirs=$type";

        my $install_to_dir = App::next::InstallDirs->new( type => $type )->bin;
        next unless $install_to_dir;

        note "install_to_dir: ", $install_to_dir;
        my $cplay_path = $install_to_dir . '/cplay';

        unlink $cplay_path;

        cplay(
            command => '--self-install',
            args    => [ qw{--installdirs}, $type ],
            exit    => 0,
            env     => {
                PATH => $ENV{PATH} . ':' . $install_to_dir,
            },
            test => sub($out) {
                my $lines = [ split( /\n/, $out->{output} ) ];
                is $lines => array {
                    item match qr{OK\s+cplay is installed to };
                    end;
                }, "cplay is installed to expected path";
            },
        );

        ok -f $cplay_path, "cplay is installed to $cplay_path";
        ok -x $cplay_path, "cplay is executable";

        unlink $cplay_path;
    }

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

sub clean_path( $to_remove ) {
    my @path = split( ':', $ENV{PATH} );

    my @keep;
    $to_remove = abs_path($to_remove);
    foreach my $p (@path) {
        next if abs_path($p) eq $to_remove;
        push @keep, $p;
    }

    return join( ':', @keep );
}
