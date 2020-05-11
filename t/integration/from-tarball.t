#!perl

use FindBin;
use lib $FindBin::Bin . '/../lib';

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use cPlayTestHelpers;

use App::cnext::std;
use App::cnext::Tester;

use App::cnext::Http;

use File::Temp;

my $tmp = File::Temp->newdir();

note "Testing cnext --from-tarball";

my $module = q[A1z::Html];
my $url    = q[https://github.com/next-cpan/A1z-Html/archive/p5.tar.gz];

{
    note "from url $url";
    remove_module($module);
    ok !is_module_installed($module), "module is not installed";
    cnext(
        command => 'from-tarball',
        args    => [$url],
        exit    => 0,
        test    => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => array {
                item match qr{OK Installed distribution A1z-Html};
                end;
            }, "distribution installed from tarball";
        },
    );
    ok is_module_installed($module), "module intalled from tarball is now installed";
}

{
    note "using a local tarball file";

    my $http = App::cnext::Http->create;

    my $local_tarball = $tmp . "/local.tarball.tar.gz";

    ok $http->mirror( $url, $local_tarball );
    ok -e $local_tarball, "tarball is downloaded to a local path";

    # remove and install from tarball
    remove_module($module);
    ok !is_module_installed($module), "module is not installed";
    cnext(
        command => 'from-tarball',
        args    => [$local_tarball],
        exit    => 0,
        test    => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => array {
                item match qr{OK Installed distribution A1z-Html};
                end;
            }, "distribution installed from tarball";
        },
    );
    ok is_module_installed($module), "module intalled from tarball is now installed";
}

done_testing;
