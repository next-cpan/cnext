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
use Config;

my $tmp = File::Temp->newdir();

use File::pushd;

my $module       = q[With::Share::Module];
my $distribution = q[With-Share-Module];

my $fixtures_directory = $FindBin::Bin . '/../fixtures';
die q[Missing fixtures] unless -d $fixtures_directory;

note "Testing cnext using $distribution with a perl binary/script";

my @share_files = qw{
  Dist-One/another-file.txt
  Dist-One/one.txt

  Dist-Two/a/b/c/file.txt
};

my $share_dist = qq[auto/share/dist/$distribution];

sub check_share_files_and_dir($root) {
    ok -d "$root/auto/share/module", "share/module dir created";

    foreach my $f (@share_files) {
        ok -f "$root/auto/share/module/$f", "$f";
    }

    {
        my $i = pushd("$root/auto/share/module");
        note qx{find .};
    }

    return;
}

{
    note "Local Installation of ", $distribution;

    my $local_dir = "$tmp/local_dir";

    remove_module($module);
    ok !is_module_installed($module), "module is not installed";

    my $dir = $fixtures_directory . '/' . $distribution;
    ok -d $dir or die;
    my $in_dir = pushd($dir);

    cnext(
        command => 'install',
        args    => [ '-L', $local_dir, '.' ],
        exit    => 0,
        test    => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => array {
                item match qr{OK Installed distribution $distribution};
                end;
            }, "distribution installed";
        },
    );

    my $root = $local_dir . '/lib/perl5';
    ok !-d "$root/auto/share/dist", "share/dist dir created";
    check_share_files_and_dir($root);
}

{
    note "Global Installation of ", $distribution;

    remove_module($module);
    ok !is_module_installed($module), "module $module is not installed";

    my $dir = $fixtures_directory . '/' . $distribution;
    ok -d $dir or die;
    my $in_dir = pushd($dir);

    cnext(
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
    ok is_module_installed($module), "module $module is intalled";

    check_share_files_and_dir( $Config{installsitelib} );
}

done_testing;
