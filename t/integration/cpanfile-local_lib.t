#!perl

use FindBin;
use lib $FindBin::Bin . '/../lib';

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use cPlayTestHelpers;

use App::next::std;
use App::next::Tester;

use local::lib ();

use Cwd ();

my $tmp = File::Temp->newdir();

my @requires_modules = qw{A1z::Html A1z::HTML5::Template};
my @develop_modules  = qw{B Carp Cwd XSLoader};

my $cpanfile = Cwd::abs_path( $FindBin::Bin . '/../fixtures/cpanfile.simple.test' );

ok -e $cpanfile, "cpanfile exists";

{
    my $localdir = "$tmp/local";

    foreach my $module (@requires_modules) {
        remove_module($module);
        ok !is_module_installed($module), "module $module is not installed";
    }

    cnext(
        command => 'cpanfile',
        args    => [ qw{--without-test}, '-L', $localdir, $cpanfile ],
        exit    => 0,
        test    => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => array {
                item match qr{OK Installed distribution A1z-HTML5-Template};
                item match qr{OK Installed distribution A1z-Html};
                end;
            }, "two distributions installed";
        },
    );

    foreach my $module (@requires_modules) {
        ok !is_module_installed($module), "module $module is not installed to default INC";
        ok is_module_installed_to_local_lib( $module, $localdir ), "module $module is installed to local lib";
    }
}

done_testing;
