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

note "Testing cplay --self-update";

if ( use_fatpack() ) {
    my ( $fatpacked, @ilib ) = App::next::Tester::find_cplay;

    my $local_cplay = $tmp . '/cplay';

    File::Copy::copy( $fatpacked, $local_cplay ) or die;
    qx{chmod +x $local_cplay};

    my $mock = Test::MockModule->new('App::next::Tester');
    $mock->redefine(
        'find_cplay' => sub {
            return $local_cplay unless wantarray;
            return ( $local_cplay, @ilib );
        }
    );

    ok -f $local_cplay, '-f';
    ok -x _, '-x';

    qx{echo "__END__\nsomething" >> $local_cplay};
    is $?, 0, "append __END__ to local_cplay" or die;

    my $signature_before = signature($local_cplay);

    cplay(
        command => '--self-update',
        args    => [],
        exit    => 0,
        test    => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => array {
                item match qr{OK\s+cplay is already up to date using version};
                item match qr{INFO\s+you can force an update by running: cplay selfupdate force};
                end;
            }, "cplay is installed to expected path" or diag explain $out;
        },
        debug => 1,
    );

    is signature($local_cplay), $signature_before, "cplay file was not changed";

    cplay(
        command => '--self-update',
        args    => ['force'],
        exit    => 0,
        test    => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => array {
                item match qr{INFO\s+running 'selfupdate force'};
                item match qr{OK\s+cplay is updated to version};
                end;
            }, "cplay is installed to expected path" or diag explain $out;
        },
        debug => 1,
    );

    isnt signature($local_cplay), $signature_before, "cplay file was updated";

    ok -f $local_cplay, "cplay is installed to $local_cplay";
    ok -x $local_cplay, "cplay is executable";
}
else {
    cplay(
        command => '--self-update',
        args    => [],
        exit    => 256,
        test    => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => array {
                item match qr{FAIL Can only update a FatPacked version of 'cplay'};
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
