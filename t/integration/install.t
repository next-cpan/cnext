#!perl

use FindBin;
use lib $FindBin::Bin . '/../lib';

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use cPlayTestHelpers;

use App::cplay::std;
use App::cplay::Tester;

# using a module without any deps
my $module       = q[A1z::Html];
my $distribution = q[A1z-Html];
my $last_version = q[0.04];

note "Testing cplay install for module $module";

{
    remove_module($module);
    ok !is_module_installed($module), "module is not installed";
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
    ok is_module_installed($module), "module is now installed";
}

{
    remove_module($module);
    ok !is_module_installed($module), "module is not installed";
    cplay(
        args => [$module],
        exit => 0,
        test => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => array {
                item match qr{OK Installed distribution A1z-Html};
                end;
            }, "distribution installed";
        },
    );
    ok is_module_installed($module), "module is now installed";
}

{
    remove_module($module);
    ok !is_module_installed($module), "module is not installed";
    cplay(
        command => 'install',
        args    => [$distribution],
        exit    => 0,
        test    => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => array {
                item match qr{OK Installed distribution A1z-Html};
                end;
            }, "distribution installed";
        },
    );
    ok is_module_installed($module), "module is now installed";
}

{
    note "requesting a specific version";
    remove_module($module);
    cplay(
        args => [ $distribution . '@' . $last_version ],
        exit => 0,
        test => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => array {
                item match qr{OK Installed distribution A1z-Html};
                end;
            }, "distribution installed";
        },
    );
    ok is_module_installed($module), "module is now installed";
}

{
    note "requesting a specific version - missing";
    remove_module($module);
    cplay(
        args => [ $distribution . '@0.00666' ],
        exit => 256,
        test => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => array {
                item match qr{FAIL\s+Cannot find distribution A1z-Html\@0\.00666};
                item match qr{FAIL\s+Fail to install A1z-Html\@0\.00666};
                end;
            }, "distribution installed";
        },
    );
    ok !is_module_installed($module), "module is not installed";
}

{
    remove_module($module);
    cplay(
        args => [$distribution],
        exit => 0,
        test => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => array {
                item match qr{OK Installed distribution A1z-Html};
                end;
            }, "distribution installed";
        },
    );
    ok is_module_installed($module), "module is now installed";
}

{
    note "try installing an existing distribution";
    ok is_module_installed($module), "module is already installed";
    cplay(
        args => [$distribution],
        exit => 0,
        test => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => array {
                item match qr{OK A1z-Html-[\d\.]+ is up to date}a;
                end;
            }, "distribution installed";
        },
    );
}

{
    note "try reinstalling an existing distribution";
    cplay(
        args => [ qw{--reinstall}, $distribution ],
        exit => 0,
        test => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => array {
                item match qr{OK Installed distribution A1z-Html};
                end;
            }, "distribution installed";
        },
    );
}

{
    note "--debug";
    cplay(
        args => [ qw{--reinstall -d}, $distribution ],
        exit => 0,
        test => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => bag {
                item match qr{fetch\s+https://github.com/pause-play/A1z-Html/archive};
                item match qr{DEBUG\s+signature OK};
                item match qr{install\s+Running Tests for A1z-Html};
                item match qr{DEBUG\s+.+\QTest::Harness\E};
                item match qr{install\s+succeeds for A1z-Html};
                item match qr{OK\s+Installed distribution A1z-Html};
                etc;
            }, "debug output" or diag explain $lines;
        },
    );
}

{
    note "--verbose";
    cplay(
        args => [ qw{--reinstall -v}, $distribution ],
        exit => 0,
        test => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => bag {
                item match qr{fetch\s+https://github.com/pause-play/A1z-Html/archive};
                item match qr{install\s+Running Tests for A1z-Html};
                item match qr{install\s+succeeds for A1z-Html};
                item match qr{OK\s+Installed distribution A1z-Html};
                etc;
            }, "verbose output" or diag explain $lines;

            unlike $out->{output}, qr{\bDEBUG\b}, "no debug";
        },
    );
}

{
    note "--no-test";
    cplay(
        args => [ qw{--reinstall -d --no-test}, $distribution ],
        exit => 0,
        test => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => bag {
                item match qr{fetch\s+https://github.com/pause-play/A1z-Html/archive};
                item match qr{DEBUG\s+signature OK};
                item match qr{install\s+succeeds for A1z-Html};
                item match qr{OK\s+Installed distribution A1z-Html};
                etc;
            }, "debug output" or diag explain $lines;

            unlike $out->{output}, qr{Running Tests}, "no Running Tests";
        },
    );
}

done_testing;
