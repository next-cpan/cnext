package App::cplay::cmd::selfinstall;

use App::cplay::std;

use App::cplay::Logger;    # import all
use App::cplay::InstallDirs;

use App::cplay::Helpers qw{write_file};

use File::Basename ();
use Cwd            ();

sub run ( $cli, @argv ) {

    if ( !is_fatpacked() ) {
        FAIL("Can only install a FatPacked version of 'cplay'.");
        return 1;
    }

    FATAL("No source code") unless length( $main::SOURCE_CODE // '' );

    $App::cplay::Logger::VERBOSE = 1;    # force enable verbose

    my $tmp_file = $cli->build_dir . "/cplay.tmp";

    write_file( $tmp_file, $main::SOURCE_CODE );

    my $dirs = App::cplay::InstallDirs->new;                  # FIXME use the cli config / installer ?
    my $path = $dirs->install_to_bin( $tmp_file, 'cplay' );
    OK "cplay is installed to $path";
    check_path_for($path);

    unlink $tmp_file;

    return;
}

sub is_fatpacked() {
    return unless my $ref = ref $INC{'App/cplay/cmd/selfinstall.pm'};
    return $ref =~ m{^FatPacked} ? 1 : 0;
}

sub check_path_for($bin) {
    my $indir = File::Basename::dirname( Cwd::abs_path($bin) );

    if ( defined $ENV{PATH} ) {
        my @path = split( ':', $ENV{PATH} );
        foreach my $p (@path) {
            next unless $p =~ m{^/};    # skip relative path
            $p = Cwd::abs_path($p);

            if ( $p eq $indir ) {
                return 1;
            }
        }
    }

    WARN("$indir is not in your PATH");

    return;
}

1;

