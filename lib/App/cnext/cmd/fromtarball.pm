package App::next::cmd::fromtarball;

use App::next::std;

use App::next::Logger;    # import all
use App::next::Installer;
use App::next::BUILD;

use File::Path ();

use Cwd;

sub run ( $cli, @args ) {
    do { ERROR("Need a single tarball"); return 1 } unless scalar @args == 1;

    my $installer = App::next::Installer->new( cli => $cli );

    my $tarball = $args[0];

    INFO("Installing module from tarball $tarball");

    return 1 unless my $path = setup_tarball( $installer, $tarball );

    DEBUG("tarball is extracted at $path");
    return 1 unless $installer->install_from_file("$path/BUILD.json");

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

    App::next::Logger::fetch($tarball_or_url);
    $installer->cli->http->mirror( $tarball_or_url, $path );

    return ( $path, 1 );
}

1;

__END__
