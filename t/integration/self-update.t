#!perl

use FindBin;
use lib $FindBin::Bin . '/../lib';
use lib $FindBin::Bin . '/../../fatlib';

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Test::MockModule;

use cPlayTestHelpers;

use App::next::std;
use App::next::Tester;

use App::next::IPC ();

use Cwd qw{abs_path};

use File::Copy;
use File::Temp;

use Digest::Perl::MD5;    # fatpack in

my $tmp = File::Temp->newdir( DIR => $ENV{HOME} );

note "Testing cnext --self-update";

if ( use_fatpack() ) {
    my ( $fatpacked, @ilib ) = App::next::Tester::find_cnext;

    my $local_cnext = $tmp . '/cnext';

    File::Copy::copy( $fatpacked, $local_cnext ) or die;
    qx{chmod +x $local_cnext};

    my $mock = Test::MockModule->new('App::next::Tester');
    $mock->redefine(
        'find_cnext' => sub {
            return $local_cnext unless wantarray;
            return ( $local_cnext, @ilib );
        }
    );

    ok -f $local_cnext, '-f';
    ok -x _, '-x';

    qx{echo "__END__\nsomething" >> $local_cnext};
    is $?, 0, "append __END__ to local_cnext" or die;

    my $signature_before = signature($local_cnext);

    cnext(
        command => '--self-update',
        args    => [],
        exit    => 0,
        test    => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => array {
                item match qr{OK\s+cnext is already up to date using version};
                item match qr{INFO\s+you can force an update by running: cnext selfupdate force};
                end;
            }, "cnext is installed to expected path" or diag explain $out;
        },
        debug => 1,
    );

    is signature($local_cnext), $signature_before, "cnext file was not changed";

    cnext(
        command => '--self-update',
        args    => ['force'],
        exit    => 0,
        test    => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => array {
                item match qr{INFO\s+running 'selfupdate force'};
                item match qr{OK\s+cnext is updated to version};
                end;
            }, "cnext is installed to expected path" or diag explain $out;
        },
        debug => 1,
    );

    isnt signature($local_cnext), $signature_before, "cnext file was updated";

    ok -f $local_cnext, "cnext is installed to $local_cnext";
    ok -x $local_cnext, "cnext is executable";
}
else {
    cnext(
        command => '--self-update',
        args    => [],
        exit    => 256,
        test    => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => array {
                item match qr{FAIL Can only update a FatPacked version of 'cnext'};
                end;
            }, "can only update a FatPacked version";
        },
    );
}

done_testing;

sub signature($f) {
    open( my $fh, '<', $f ) or die;
    return Digest::Perl::MD5->new->addfile($fh)->hexdigest;
}
