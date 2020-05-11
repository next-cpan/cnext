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

use App::cnext::IPC;
use App::cnext::Helpers qw{read_file};

use File::Temp;
use File::pushd;

note "Testing cnext start action";

my $tmp = File::Temp->newdir();

my $intmp = pushd("$tmp");

{
    cnext(
        command => 'start',
        args    => [],
        exit    => 256,
        test    => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => array {
                item match qr{ERROR Need one or more module / distribution name};
                end;
            }, "missing args";
        },
    );
}

{
    cnext(
        command => 'start',
        args    => [qw{My-Custom-Module}],
        exit    => 0,
        test    => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => array {
                item match qr{OK Directory for My-Custom-Module created};
                end;
            }, "distribution structure created";
        },
    );

    ok -d q[My-Custom-Module],                       "My-Custom-Module";
    ok -d q[My-Custom-Module/t],                     "My-Custom-Module/t";
    ok -d q[My-Custom-Module/lib],                   "My-Custom-Module/lib";
    ok -d q[My-Custom-Module/lib/My],                "My-Custom-Module/lib/My";
    ok -d q[My-Custom-Module/lib/My/Custom],         "My-Custom-Module/lib/My/Custom";
    ok !-d q[My-Custom-Module/lib/My/Custom/Module], "!-d My-Custom-Module/lib/My/Custom/Module";

    ok -f q[My-Custom-Module/lib/My/Custom/Module.pm], 'main module .pm';

    ok -f q[My-Custom-Module/t/00-load.t], 't/00-load.t';
    ok -f q[My-Custom-Module/BUILD.json],  'BUILD.json';

    {
        note "check BUILD.json";
        require App::cnext::Roles::JSON;
        my $build = App::cnext::Roles::JSON->new->json->decode( read_file( q[My-Custom-Module/BUILD.json], ':utf8' ) );
        is $build, {
            'abstract'            => 'Abstract for My-Custom-Module',
            'builder'             => 'play',
            'builder_API_version' => 1,
            'license'             => 'perl',
            'maintainers'         => [ D() ],
            'name'                => 'My-Custom-Module',
            'primary'             => 'My::Custom::Module',
            'provides'            => {
                'My::Custom::Module' => {
                    'file'    => 'lib/My/Custom/Module.pm',
                    'version' => '0.001'
                }
            },
            'recommends_runtime' => {},
            'requires_build'     => {},
            'requires_develop'   => {},
            'requires_runtime'   => {},
            'source'             => 'p5',
            'scripts'            => [],
            'version'            => '0.001',
            'xs'                 => 0,
          },
          'BUILD.json content'
          or diag explain $build;

    }

    {
        my $in_dir = pushd('My-Custom-Module');

        my @test = ( $^X, '-Ilib', 't/00-load.t' );
        my ( $status, $out, $err ) = App::cnext::IPC::run3( [@test] );
        is $status, 0, "perl -Ilib t/00-load.t";
        is $out, <<OUT, "test output";
ok 1 - use My::Custom::Module;
ok 2 - VERSION set
1..2
OUT
        is $err, undef, "nothing on stderr";
    }
}

{
    note "try creating the same module another time";
    cnext(
        command => 'start',
        args    => [qw{My-Custom-Module}],
        exit    => 256,
        test    => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => array {
                item match qr{FAIL Cannot create directory for My-Custom-Module.};
                end;
            }, "distribution structure created";
        },
    );
}

{
    note "Try creating two modules";

    cnext(
        command => 'start',
        args    => [qw{First-Module SecondOne}],
        exit    => 0,
        test    => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => array {
                item match qr{OK Directory for First-Module created.};
                item match qr{OK Directory for SecondOne created.};
                end;
            }, "create two distributions";
        },
    );

    ok -f q[First-Module/lib/First/Module.pm], 'lib/First/Module.pm';
    ok -f q[SecondOne/lib/SecondOne.pm],       'lib/SecondOne.pm';
}

undef $intmp;    # allow tmp destruction

done_testing;
