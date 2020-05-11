#!perl

use FindBin;
use lib $FindBin::Bin . '/../lib';

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use cPlayTestHelpers;

use App::cnext::std;
use App::cnext::Tester;

use Cwd ();

my @requires_modules = qw{A1z::Html A1z::HTML5::Template};
my @develop_modules  = qw{B Carp Cwd XSLoader};

my $cpanfile = Cwd::abs_path( $FindBin::Bin . '/../fixtures/cpanfile.simple.test' );

ok -e $cpanfile, "cpanfile exists";

{
    foreach my $module (@requires_modules) {
        remove_module($module);
        ok !is_module_installed($module), "module $module is not installed";
    }

    cnext(
        command => 'cpanfile',
        args    => [ qw{--without-test}, $cpanfile ],
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
        ok is_module_installed($module), "module $module is now installed";
    }

    note "modules are already installed";

    cnext(
        command => 'cpanfile',
        args    => [ qw{--without-test}, $cpanfile ],
        exit    => 0,
        test    => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => array {
                item match qr{OK A1z::HTML5::Template is already installed};
                item match qr{OK A1z::Html is already installed};
                end;
            }, "distributions are already installed";
        },
    );

    note "remove one module and try to reinstall";
    remove_module( $requires_modules[0] );
    cnext(
        command => 'cpanfile',
        args    => [ qw{--without-test}, $cpanfile ],
        exit    => 0,
        test    => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => array {
                item match qr{OK A1z::HTML5::Template is already installed};
                item match qr{OK Installed distribution A1z-Html};
                end;
            }, "only install one distribution";
        },
    );

    note "remove one module and try to reinstall";
    remove_module($_) for @requires_modules;
    cnext(
        command => 'cpanfile',
        args    => [ qw{--without-test --with-develop}, $cpanfile ],
        exit    => 0,
        test    => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => array {
                item match qr{OK Installed distribution A1z-HTML5-Template};
                item match qr{OK Installed distribution A1z-Html};
                foreach my $module (@develop_modules) {
                    item match qr{OK $module is already installed};
                }
                end;
            }, "check develop modules";
        },
    );

    note "test with a non available module";
    cnext(
        command => 'cpanfile',
        args    => [ qw{--without-test --with-recommends}, $cpanfile ],
        exit    => 256,
        test    => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => array {
                item match qr{OK A1z::HTML5::Template is already installed};
                item match qr{OK A1z::Html is already installed};
                item match qr{FAIL Cannot find module or distribution 'Do::Not::Exist'};
                end;
            }, "cannot find module Do::Not::Exist";
        },
    );

}

done_testing;
