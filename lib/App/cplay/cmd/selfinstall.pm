package App::cplay::cmd::selfinstall;

use App::cplay::std;

use App::cplay::Logger;    # import all
use App::cplay::Installer;

use App::cplay::Helpers qw{write_file is_fatpacked};

use File::Basename ();
use Cwd            ();

sub run ( $cli, @argv ) {
    if ( !is_fatpacked() ) {
        FAIL("Can only install a FatPacked version of 'cplay'.");
        return 1;
    }

    FATAL("No source code") unless length( $main::SOURCE_CODE // '' );

    App::cplay::Logger::setup_for_script();

    my $tmp_file = $cli->build_dir . "/cplay.tmp";
    write_file( $tmp_file, $main::SOURCE_CODE );

    my $installer = App::cplay::Installer->new( cli => $cli );
    my $dirs      = $installer->installdirs;
    my $path      = $dirs->install_to_bin( $tmp_file, 'cplay' );
    OK "cplay is installed to $path";
    check_path_for($path);

    unlink $tmp_file;

    return;
}

sub check_path_for($bin) {
    my $indir = File::Basename::dirname( Cwd::abs_path($bin) );

    if ( defined $ENV{PATH} ) {
        my @path = split( ':', $ENV{PATH} );
        foreach my $p (@path) {
            next unless $p =~ m{^/};    # skip relative path
            $p = Cwd::abs_path($p);
            return 1 if $p eq $indir;
        }
    }

    WARN("$indir is not in your PATH");

    return;
}

1;

