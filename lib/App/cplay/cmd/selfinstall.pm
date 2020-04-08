package App::cplay::cmd::selfinstall;

use App::cplay::std;

use App::cplay::Logger;    # import all
use App::cplay::InstallDirs;
use App::cplay::Installer;

sub run ( $cli, @argv ) {
    if ( !is_fatpacked() ) {
        FAIL("Can only install a FatPacked version of 'cplay'.");
        return 1;
    }

    my $url = q[https://git.io/cplay];    # or http://get.cplay.us

    my $installer = App::cplay::Installer->new( cli => $cli );
    my $tmp_file  = $installer->cli->build_dir . "/cplay.tmp";
    $installer->cli->http->mirror( $url, $tmp_file );

    my $dirs = App::cplay::InstallDirs->new;                  # FIXME use the cli config / installer ?
    my $path = $dirs->install_to_bin( $tmp_file, 'cplay' );
    OK "cplay is installed to $path";

    unlink $tmp_file;

    return;
}

sub is_fatpacked() {
    return unless my $ref = ref $INC{'App/cplay/cmd/selfinstall.pm'};
    return $ref =~ m{^FatPacked} ? 1 : 0;
}

1;
