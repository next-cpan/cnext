#!perl

use FindBin;
use lib $FindBin::Bin . '/../lib';

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use cPlayTestHelpers;

use App::cplay::std;
use App::cplay::Tester;

use File::Temp;

use local::lib ();

my $tmp = File::Temp->newdir();

# using a module without any deps
my $module       = q[A1z::Html];
my $distribution = q[A1z-Html];

note "Testing cplay install for module $module";

{
    note "Trying local::lib while the module is not installed";
    my $localdir = "$tmp/local";

    remove_module($module);
    ok !is_module_installed($module), "module is not installed";
    cplay(
        command => 'install',
        args    => [ '-L', $localdir, $module ],
        exit    => 0,
        test    => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => array {
                item match qr{OK Installed distribution A1z-Html};
                end;
            }, "distribution installed";
        },
    );
    ok !is_module_installed($module), "module is not installed to the default INC";
    ok -d $localdir, "localdir was created";

    {
        local %ENV;
        local::lib->setup_env_hash_for($localdir);
        ok is_module_installed($module), "module is installed to local lib";
    }

    note "try re-installing to local::lib";
    cplay(
        command => 'install',
        args    => [ '-L', $localdir, $module ],
        exit    => 0,
        test    => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => array {
                item match qr{OK A1z::Html is up to date}a;
                end;
            }, "distribution is up to date";
        },
    );

    note "try re-installing to local::lib with --reinstall";
    cplay(
        command => 'install',
        args    => [ '-L', $localdir, '--reinstall', $module ],
        exit    => 0,
        test    => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => array {
                item match qr{OK Installed distribution A1z-Html};
                end;
            }, "--reinstall distribution";
        },
    );
}

{
    note "Trying local::lib while the module is installed";

    # 1 - install the module
    cplay(
        command => 'install',
        args    => [$module],
        exit    => 0,
        test    => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => array {
                item match qr{OK Installed distribution A1z-Html};
                end;
            }, "distribution installed";
        },
    );

    ok is_module_installed($module), "module is installed to the default INC";

    my $localdir = "$tmp/second";
    cplay(
        command => 'install',
        args    => [ '-L', $localdir, $module ],
        exit    => 0,
        test    => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => array {
                item match qr{OK Installed distribution A1z-Html};
                end;
            }, "distribution installed";
        },
    );
    ok is_module_installed($module), "module is installed to the default INC";
    ok -d $localdir, "localdir was created";

    {
        local %ENV;
        local::lib->setup_env_hash_for($localdir);
        ok is_module_installed($module), "module is installed to local lib";
    }

    note "try re-installing to local::lib";
    cplay(
        command => 'install',
        args    => [ '-L', $localdir, $module ],
        exit    => 0,
        test    => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => array {
                item match qr{OK A1z::Html is up to date}a;
                end;
            }, "distribution is up to date";
        },
    );
}

done_testing;
