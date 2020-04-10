#!perl

use FindBin;
use lib $FindBin::Bin . '/../lib';
use lib $FindBin::Bin . '/../fatlib';

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use cPlayTestHelpers;

use App::cplay::std;
use App::cplay::Tester;

use App::cplay::IPC;
use App::cplay::Helpers qw{read_file write_file};

use File::Temp;
use File::pushd;

note "Testing cplay start action";

my $tmp = File::Temp->newdir();

my $intmp = pushd("$tmp");
{
    my $distribution = q[My-First-Module];
    my $module       = q[My::First::Module];

    note "create a distribution using 'cplay start': ", $distribution;

    remove_module($module);
    ok !is_module_installed($module), "module is not installed";

    cplay(
        command => 'start',
        args    => [$distribution],
        exit    => 0,
        test    => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => array {
                item match qr{OK Directory for $distribution created.};
                end;
            }, "create $distribution distribution";
        },
    );

    ok -d $distribution, "-d $distribution" or die;
    my $in = pushd($distribution);
    ok -f q[lib/My/First/Module.pm], 'lib/My/First/Module.pm';
    ok -f q[BUILD.json],             'BUILD.json';

    ok !is_module_installed($module), "module is not installed";

    cplay(
        command => 'install',
        args    => [qw{.}],
        exit    => 0,
        test    => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => array {
                item match qr{\QOK Installed distribution My-First-Module-0.001\E};
                end;
            }, "$distribution is now installed";
        },
    );

    my $module_path = module_path($module);
    ok is_module_installed($module), "module is now installed using 'install .'";
    is -s $module_path, -s q[lib/My/First/Module.pm], "installed module is ours";

    unlink $module_path;    # remove it as perms are ro
    write_file( $module_path, q[#!false] );
    ok -e $module_path, "updated file";

    isnt -s $module_path, -s q[lib/My/First/Module.pm], "module has changed on disk";

    note "reinstall it a second time";
    cplay(
        command => 'install',
        args    => [qw{.}],
        exit    => 0,
        test    => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => array {
                item match qr{\QOK Installed distribution My-First-Module-0.001\E};
                end;
            }, "$distribution is now installed";
        },
    );
    is -s $module_path, -s q[lib/My/First/Module.pm], "installed module is ours";
}

undef $intmp;    # allow tmp destruction

done_testing;
