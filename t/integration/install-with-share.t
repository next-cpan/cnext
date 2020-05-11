#!perl

use FindBin;
use lib $FindBin::Bin . '/../lib';

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use cPlayTestHelpers;

use App::next::std;
use App::next::Tester;

use App::next::Http;

use File::Temp;
use Config;

my $tmp = File::Temp->newdir();

use File::pushd;

my $module       = q[With::Share];
my $distribution = q[With-Share];

my $fixtures_directory = $FindBin::Bin . '/../fixtures';
die q[Missing fixtures] unless -d $fixtures_directory;

note "Testing cplay using $distribution with a perl binary/script";

my @share_files = qw{
  file.txt
  private/data
};

my $share_dist = qq[auto/share/dist/$distribution];

sub check_share_files_and_dir($root) {
    ok -d "$root/auto/share",  "auto/share created";
    ok -d "$root/$share_dist", "dist/:dist share dir created";

    foreach my $f (@share_files) {
        ok -f "$root/$share_dist/$f", "$f";
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

    cplay(
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

    check_share_files_and_dir( $local_dir . '/lib/perl5' );
}

{
    note "Global Installation of ", $distribution;

    remove_module($module);
    ok !is_module_installed($module), "module $module is not installed";

    my $dir = $fixtures_directory . '/' . $distribution;
    ok -d $dir or die;
    my $in_dir = pushd($dir);

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
    ok is_module_installed($module), "module $module is intalled";

    check_share_files_and_dir( $Config{installsitelib} );
}

done_testing;
