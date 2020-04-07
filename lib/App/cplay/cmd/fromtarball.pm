package App::cplay::cmd::fromtarball;

use App::cplay::std;

use App::cplay::Logger;    # import all
use App::cplay::Installer;

use File::pushd;
use File::Path ();

use Cwd;

sub run ( $cli, @args ) {
    do { ERROR("Need a single tarball"); return 1 } unless scalar @args == 1;

    my $installer = App::cplay::Installer->new( cli => $cli );

    # guarantee that ExtUtils::MakeMaker is >= 6.64
    return 1 unless $installer->check_makemaker();    ## FIXME move it to build

    my $tarball = $args[0];

    INFO("Installing module from tarball $tarball");

    return 1 unless my $path = setup_tarball( $installer, $tarball );

    DEBUG("tarball is extracted at $path");

    {
        my $in_dir = pushd($path) or return 1;
        return 1 unless my $BUILD = $installer->load_BUILD_json();

        $installer->depth(1);    # need to setup depth
        $installer->install_from_BUILD($BUILD);
    }

    File::Path::rmtree($path);

    DONE("install fromtarball succeeds");

    return 0;
}

sub setup_tarball ( $installer, $tarball_or_url ) {

    my ( $tarball, $has_downloaded ) = download_if_needed( $installer, $tarball_or_url );
    return unless defined $tarball && -f $tarball;
    DEBUG("Using tarball from $tarball");

    my $relative_path = $installer->unpacker->unpack($tarball);
    my $full_path     = $installer->cli->build_dir . '/' . $relative_path;
    unlink($tarball) if $has_downloaded;
    if ( !defined $relative_path || !-d $full_path ) {
        FAIL("fail to extract tarball $tarball");
        return;
    }

    return $full_path;
}

sub download_if_needed ( $installer, $tarball_or_url ) {

    if ( $tarball_or_url !~ m{^https?://}i ) {
        return Cwd::abs_path($tarball_or_url) if -e $tarball_or_url;
        ERROR("Do not know how to setup tarball: $tarball_or_url");
        return;
    }

    my $basename = "fromtarball-$$.tar.gz";
    my $path     = $installer->cli->build_dir . "/$basename";

    App::cplay::Logger::fetch($tarball_or_url);
    $installer->cli->http->mirror( $tarball_or_url, $path );

    return ( $path, 1 );
}

1;

__END__
