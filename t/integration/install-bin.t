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

my $module = q[Acme::Stardate];
my $distro = q[Acme-Stardate];

note "Testing cnext using $distro with a perl binary/script";

my $url = qq[https://github.com/next-cpan/${distro}/archive/p5.tar.gz];

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

    ok -d $local_dir, "local_dir was created";

    my $binary = "$local_dir/bin/stardate";

    ok -f "$local_dir/lib/perl5/Acme/Stardate.pm", "pm file installed";
    ok -e $binary, "bin/stardate binary was installed";
    ok -x _, "bin/stardate binary is excecutable";

    {
        open( my $fh, '<', $binary ) or die;
        my $shebang = <$fh>;
        chomp $shebang;

        is $shebang, qq[#!$^X], "shebang is using current Perl";
    }
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

    my $binary = $Config{installsitebin} . '/stardate';
    ok -x $binary, "binary installed to installsitebin";
}

if ( $Config{installbin} ) {
    note "Installation of ", $distro, " --installdir perl";

    remove_module($module);
    ok !is_module_installed($module), "module $module is not installed";

    cnext(
        command => 'from-tarball',
        args    => [ qw{-n --installdir perl}, $url ],
        exit    => 0,
        test    => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => array {
                item match qr{OK Installed distribution $distro};
                end;
            }, "distribution installed from tarball";
        },
    );

    ok is_module_installed($module), "module $module is intalled to vendor";

    my $binary = $Config{installbin} . '/stardate';
    ok -x $binary, "binary installed to installbin";
}

if ( $Config{installvendorbin} ) {
    note "Installation of ", $distro, " --installdir vendor";

    remove_module($module);
    ok !is_module_installed($module), "module $module is not installed";

    cnext(
        command => 'from-tarball',
        args    => [ qw{-n --installdir vendor}, $url ],
        exit    => 0,
        test    => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => array {
                item match qr{OK Installed distribution $distro};
                end;
            }, "distribution installed from tarball";
        },
    );

    ok is_module_installed($module), "module $module is intalled to vendor";

    my $binary = $Config{installvendorbin} . '/stardate';
    ok -x $binary, "binary installed to vendorbin";
}
else {
    note "Installation of ", $distro, " --installdir vendor [vendor not defined]";

    remove_module($module);
    ok !is_module_installed($module), "module $module is not installed";

    cnext(
        command => 'from-tarball',
        args    => [ qw{-n --installdir vendor}, $url ],
        exit    => 6400,
        test    => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => array {
                item match qr{FATAL install lib is not defined for vendor};
                etc;
            }, "FATAL install lib is not defined for vendor";
        },
    );

}

done_testing;
