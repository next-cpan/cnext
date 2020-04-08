package App::cplay::cmd::selfinstall;

use App::cplay::std;

use App::cplay::Logger;    # import all
use App::cplay::InstallDirs;

sub run ( $self, @argv ) {

    if ( !is_fatpacked() ) {
        FAIL("Can only install a FatPacked version of 'cplay'.");
        return 1;
    }

    my $dirs = App::cplay::InstallDirs->new;           # FIXME use the cli config / installer ?
    my $path = $dirs->install_to_bin( $0, 'cplay' );
    OK "cplay is installed to $path";

    return;
}

sub is_fatpacked() {
    return unless my $ref = ref $INC{'App/cplay/cmd/selfinstall.pm'};
    return $ref =~ m{^FatPacked} ? 1 : 0;
}

1;
