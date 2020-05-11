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
use File::Find;

# using a module without any deps
my $module       = q[My::Custom::Distro];
my $distribution = q[My-Custom-Distro];
my $last_version = q[0.01];

note "Testing cplay install .";

my $dir = $FindBin::Bin . '/../fixtures/My-Custom-Distro';

my $tmp = File::Temp->newdir();

{
    my $in_dir = pushd($dir);

    remove_module($module);
    ok !is_module_installed($module), "module is not installed";

    cplay(
        command => 'install',
        args    => ['.'],
        exit    => 0,
        test    => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => array {
                item match qr{OK Installed distribution $distribution};
                end;
            }, "distribution installed";
        },
    );

    ok is_module_installed($module), "module is now installed";

    ok !-d q[blib], 'blib is not left behind';

    note "Checking that we can reinsyall the distribution";
    cplay(
        command => 'install',
        args    => [qw{-n .}],
        exit    => 0,
        test    => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => array {
                item match qr{OK Installed distribution $distribution};
                end;
            }, "distribution (re)installed without tests";
        },
    );

}

{
    note "Testing a local lib installation";
    my $in_dir = pushd($dir);

    my $local_dir = "$tmp/vendor";

    cplay(
        command => 'install',
        args    => [ qw{-n -L}, $local_dir, '.' ],
        exit    => 0,
        test    => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => array {
                item match qr{OK Installed distribution $distribution};
                end;
            }, "distribution installed to local directory";
        },
    );

    ok -d $local_dir, "local_dir created" or die;
    my $lib_dir = "$local_dir/lib/perl5";
    ok -d $lib_dir, "lib_dir created" or die;
    {
        my $cd = pushd($lib_dir);

        my @files;
        File::Find::find(
            {
                wanted => sub {
                    push @files, $File::Find::name;
                },
                no_chdir => 1
            },
            'My'
        );

        is [ sort @files ], [
            sort qw{
              My
              My/Custom
              My/Custom/Distro.pm
              My/Custom/Distro
              My/Custom/Distro/SubModule.pm
              }
          ],
          "all files/directories installed to local_lib";
    }

}

done_testing;
