#!perl

use FindBin;
use lib $FindBin::Bin . '/../lib';

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use cPlayTestHelpers;

use App::next::std;
use App::next::Tester;

use File::pushd;

# using a module without any deps
my $module       = q[A1z::Html];
my $distribution = q[A1z-Html];
my $last_version = q[0.04];

my $fixtures_directory = $FindBin::Bin . '/../fixtures';
die q[Missing fixtures] unless -d $fixtures_directory;

note "Testing cplay install for module $module";

{
    remove_module($module);
    ok !is_module_installed($module), "module is not installed";
    cplay(
        command => 'test',
        args    => [$module],
        exit    => 0,
        test    => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => array {
                item match qr{OK Tests Succeeds for $distribution};
                end;
            }, "distribution tested";
        },
    );
    ok !is_module_installed($module), "module is not installed";
}

{
    remove_module($module);
    ok !is_module_installed($module), "module is not installed";
    cplay(
        command => 'test',
        args    => [ '-n', $module ],
        exit    => 256,
        test    => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => array {
                item match qr{ERROR Cannot disable tests when using 'test' command.};
                end;
            }, "Cannot disable tests when using 'test' command.";
        },
    );
    ok !is_module_installed($module), "module is not installed";
}

{
    note "Running tests on a broken module";

    my $module       = q[Test::Failure];
    my $distribution = q[Test-Failure];

    my $dir = $fixtures_directory . '/' . $distribution;
    ok -d $dir or die;
    my $in_dir = pushd($dir);

    remove_module($module);
    ok !is_module_installed($module), "module is not installed";
    cplay(
        command => 'test',
        args    => ['.'],
        exit    => 256,
        test    => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => array {
                item match qr{ERROR Fail to run tests for Test-Failure};
                item match qr{\QFAIL Fail to test distribution from .\E};
                end;
            }, "Detect a failing unit test";
        },
    );
    ok !is_module_installed($module), "module is not installed";
}

{
    note "Running tests using a play workflow";

    my $module       = q[My::Custom::Distro];
    my $distribution = q[My-Custom-Distro];

    remove_module($module);    # before chdir
    ok !is_module_installed($module), "module is not installed";

    my $dir = $fixtures_directory . '/' . $distribution;
    ok -d $dir or die;
    my $in_dir = pushd($dir);

    cplay(
        command => 'test',
        args    => ['.'],
        exit    => 0,
        test    => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => array {
                item match qr{OK Tests Succeeds for $distribution};
                end;
            }, "Test Succeeds on a play workflow";
        },
    );
    ok !is_module_installed($module), "module is not installed";
}

{
    note "Running tests using a Makefile.PL workflow";

    my $module       = q[Makefile::Workflow];
    my $distribution = q[Makefile-Workflow];

    remove_module($module);    # before chdir
    ok !is_module_installed($module), "module is not installed";

    my $dir = $fixtures_directory . '/' . $distribution;
    ok -d $dir or die;
    my $in_dir = pushd($dir);

    cplay(
        command => 'test',
        args    => ['.'],
        exit    => 0,
        test    => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => array {
                item match qr{OK Tests Succeeds for $distribution};
                end;
            }, "Test Succeeds on a Makefile.PL workflow";
        },
    );

    undef $in_dir;
    ok !is_module_installed($module), "module is not installed";
}

{
    note "Running tests using a Build.PL workflow";

    my $module       = q[Build::Workflow];
    my $distribution = q[Build-Workflow];

    remove_module($module);    # before chdir
    ok !is_module_installed($module), "module is not installed";

    my $dir = $fixtures_directory . '/' . $distribution;
    ok -d $dir or die;
    my $in_dir = pushd($dir);

    cplay(
        command => 'test',
        args    => ['.'],
        exit    => 0,
        test    => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => array {
                item match qr{OK Tests Succeeds for $distribution};
                end;
            }, "Test Succeeds on a Build.PL workflow";
        },
    );

    undef $in_dir;
    ok !is_module_installed($module), "module is not installed";
}

done_testing;
