#!perl

use FindBin;
use lib $FindBin::Bin . '/../lib';
use lib $FindBin::Bin . '/../../fatlib';

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use cNextTestHelpers;

use App::cnext::std;
use App::cnext::Tester;

use App::cnext::IPC ();

use App::cnext::InstallDirs;

use Cwd qw{abs_path};

note "Testing cnext --self-install";

if ( use_fatpack() ) {
    my $install_to_dir = App::cnext::InstallDirs->new->bin;
    my $cnext_path     = $install_to_dir . '/cnext';

    {
        note "PATH is set";
        unlink $cnext_path if -e $cnext_path;
        ok !-e $cnext_path, "cnext_path does not exist";

        cnext(
            command => '--self-install',
            args    => [],
            exit    => 0,
            env     => {
                PATH => $ENV{PATH} . ':' . $install_to_dir,
            },
            test => sub($out) {
                my $lines = [ split( /\n/, $out->{output} ) ];
                is $lines => array {
                    item match qr{OK\s+cnext is installed to };
                    end;
                }, "cnext is installed to expected path";
            },
        );

        ok -f $cnext_path, "cnext is installed to $cnext_path";
        ok -x $cnext_path, "cnext is executable";

        my ( $exit, $out, $err ) = App::cnext::IPC::run3( [ $cnext_path, '--version' ] );
        is $exit,  0,                         'cnext --version exits with 0';
        like $out, qr{^\s*cnext\s+\d+\.\d+}a, 'cnext --version output' or diag ":$out:";
        is $err,   undef,                     'nothing on stderr';

        unlink $cnext_path;
    }

    {
        note "Testing when PATH does not contain the install dir";

        my $clean_path = clean_path($install_to_dir);
        note $clean_path;

        cnext(
            command => '--self-install',
            args    => [],
            exit    => 0,
            env     => {
                PATH => $clean_path,
            },
            test => sub($out) {
                my $lines = [ split( /\n/, $out->{output} ) ];
                is $lines => array {
                    item match qr{OK\s+cnext is installed to };
                    item match qr{WARN\s+.+is not in your PATH};
                    end;
                }, "cnext is installed to expected path";
            },
        );

        ok -f $cnext_path, "cnext is installed to $cnext_path";
        ok -x $cnext_path, "cnext is executable";

        unlink $cnext_path;
    }

    foreach my $type (qw{site perl vendor}) {
        note "Testing installdirs=$type";

        my $install_to_dir = App::cnext::InstallDirs->new( type => $type )->bin;
        next unless $install_to_dir;

        note "install_to_dir: ", $install_to_dir;
        my $cnext_path = $install_to_dir . '/cnext';

        unlink $cnext_path;

        cnext(
            command => '--self-install',
            args    => [ qw{--installdirs}, $type ],
            exit    => 0,
            env     => {
                PATH => $ENV{PATH} . ':' . $install_to_dir,
            },
            test => sub($out) {
                my $lines = [ split( /\n/, $out->{output} ) ];
                is $lines => array {
                    item match qr{OK\s+cnext is installed to };
                    end;
                }, "cnext is installed to expected path";
            },
        );

        ok -f $cnext_path, "cnext is installed to $cnext_path";
        ok -x $cnext_path, "cnext is executable";

        unlink $cnext_path;
    }

}
else {
    cnext(
        command => '--self-install',
        args    => [],
        exit    => 256,
        test    => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => array {
                item match qr{FAIL Can only install a FatPacked version of 'cnext'};
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
