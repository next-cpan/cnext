#!perl

use FindBin;
use lib $FindBin::Bin . '/../lib';

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use cNextTestHelpers;

use App::cnext::std;
use App::cnext::Tester;

use File::pushd;

# custom modules with preset tags for testing
# https://github.com/next-cpan/cNext-Test-Module

my $module       = q[Next::Test::Module];
my $distribution = q[Next-Test-Module];
my $last_version = q[1.00];

note "Testing cnext install for module $module";

my $fixtures_directory = $FindBin::Bin . '/../fixtures';
die q[Missing fixtures] unless -d $fixtures_directory;

{
    note "Installing a tagged version";
    remove_module($module);
    ok !is_module_installed($module), "module is not installed";
    cnext(
        args => [ $distribution . '@' . $last_version ],
        exit => 0,
        test => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => array {
                item match qr{OK Installed distribution $distribution};
                end;
            }, "distribution installed";
        },
    );
    ok is_module_installed($module), "module is now installed";
}

{
    note "Trying to reinstall a tagged version";

    ok is_module_installed($module), "module is already installed";
    cnext(
        args => [ $distribution . '@' . $last_version ],
        exit => 0,
        test => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => array {
                item match qr{OK $distribution-$last_version is up to date.};
                end;
            }, "$distribution-$last_version is up to date";
        },
    );
    ok is_module_installed($module), "module is still installed";
}

{
    note "Installing a TRIAL version";

    my $tag = q[1.00_01];

    cnext(
        args => [ $distribution . '@' . $tag ],
        exit => 0,
        test => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => array {
                item match qr/OK Installed distribution ${distribution}-$tag/;
                end;
            }, "distribution $distribution\@$tag installed";
        },
    );
    ok is_module_installed($module), "module is now installed";
}

{
    my $tag = q[0.01];
    note "Installing an older version: ", $tag;

    # FIXME - need to use --retry when trying to downgrade
    remove_module($module);
    ok !is_module_installed($module), "module is not installed";

    cnext(
        args => [ $distribution . '@' . $tag ],
        exit => 0,
        test => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => array {
                item match qr/OK Installed distribution ${distribution}-$tag/;
                end;
            }, "distribution $distribution\@$tag installed";
        },
    );
    ok is_module_installed($module), "module is now installed";
}

{
    note "Using p5- in the tag alsow works";

    my $tag = q[p5-v1.00];

    remove_module($module);
    ok !is_module_installed($module), "module is not installed";

    cnext(
        args => [ $distribution . '@' . $tag ],
        exit => 0,
        test => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => array {
                item match qr/OK Installed distribution ${distribution}-1.00/;
                end;
            }, "distribution $distribution\@$tag installed";
        },
    );
    ok is_module_installed($module), "module is now installed";
}

{
    note "Using a named tag using a branch name: 'trial'";

    my $tag = q[trial];

    remove_module($module);
    ok !is_module_installed($module), "module is not installed";

    cnext(
        args => [ $distribution . '@' . $tag ],
        exit => 0,
        test => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => array {
                item match qr/OK Installed distribution ${distribution}-1.00_01/;
                end;
            }, "distribution $distribution\@$tag installed";
        },
    );
    ok is_module_installed($module), "module is now installed";
}

{
    note "Installing an unknow version";
    remove_module($module);

    my $unknow_version = q[0.66];

    cnext(
        args => [ $distribution . '@' . $unknow_version ],
        exit => 256,
        test => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => array {

                # cannot use @ inside the \Q..\E due to a bug in 5.20
                item match qr{\QFAIL Fail to install $distribution\E\@\Q0.66 or its dependencies.\E};
                end;
            }, "fail to install $distribution\@$unknow_version";
        },
    );
    ok !is_module_installed($module), "module is not installed";
}

done_testing;
