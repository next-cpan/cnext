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

my $module = q[Alien::Saxon];
my $distro = q[Alien-Saxon];

# FIXME: once we can install a repository using 'install .'
#   we could provide a fixture to test and not depend on a 3rdparty module
note "Testing cnext using $distro with a perl binary/script";

my $url = qq[https://github.com/next-cpan/${distro}/archive/p5.tar.gz];

my @share_files = qw{
  saxon9-xqj.jar
  notices/JAMESCLARK.txt
  notices/UNICODE.txt
  notices/CERN.txt
  notices/LICENSE.txt
  notices/THAI.txt
  saxon9he.jar
  doc/index.html
  doc/img/saxonica_logo.gif
  doc/img/logo_crop-mid-blue-background.gif
};

my $share_dist = qq[auto/share/dist/$distro];

sub check_share_files_and_dir($root) {
    ok -d "$root/auto/share",  "extlib/lib/perl5/auto/share created";
    ok -d "$root/$share_dist", "dist/Alien-Saxon share dir created";

    foreach my $f (@share_files) {
        ok -f "$root/$share_dist/$f", "$f";
    }

    return;
}

{
    note "Local Installation of ", $distro;

    my $local_dir = "$tmp/local_dir";

    cnext(
        command => 'from-tarball',
        args    => [ '-n', '-L', $local_dir, $url ],
        exit    => 0,
        test    => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => array {
                item match qr{OK Installed distribution $distro};
                end;
            }, "distribution installed from tarball";
        },
    );

    check_share_files_and_dir( $local_dir . '/lib/perl5' );
}

{
    note "Global Installation of ", $distro;

    remove_module($module);
    ok !is_module_installed($module), "module $module is not installed";

    cnext(
        command => 'from-tarball',
        args    => [ qw{-n}, $url ],
        exit    => 0,
        test    => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => array {
                item match qr{OK Installed distribution $distro};
                end;
            }, "distribution installed from tarball";
        },
    );
    ok is_module_installed($module), "module $module is intalled";

    check_share_files_and_dir( $Config{installsitelib} );
}

done_testing;
