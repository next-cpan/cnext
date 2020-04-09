package App::cplay::cmd::selfupdate;

use App::cplay ();

use App::cplay::std;
use App::cplay::Logger;    # import all

use App::cplay::Installer;
use App::cplay::InstallDirs;

use App::cplay::Helpers qw{write_file is_fatpacked update_shebang};

use File::Basename ();
use Cwd            ();
use File::Copy     ();

use constant URL => q[http://get.cplay.us/];    # or https://git.io/cplay

sub run ( $cli, @argv ) {
    if ( !is_fatpacked() ) {
        FAIL("Can only update a FatPacked version of 'cplay'.");
        return 1;
    }

    App::cplay::Logger::setup_for_script();

    my $force = grep { $_ eq 'force' } @argv;
    INFO("running 'selfupdate force'") if $force;

    my $installer = App::cplay::Installer->new( cli => $cli );

    my $tmp_file = $installer->cli->build_dir . "/cplay.tmp";
    unlink $tmp_file if -e $tmp_file;

    $installer->cli->http->mirror( URL, $tmp_file );

    if ( !-f $tmp_file || -z _ ) {
        FAIL( "Fail to download cplay from " . URL );
        return 1;
    }

    my $current_version = $App::cplay::VERSION . '@' . $App::cplay::REVISION;
    my ( $exit, $out, $err ) = App::cplay::IPC::run3( [ "$^X", $tmp_file, q[--version] ] );
    my $new_version;
    if ( $out && $out =~ m{^cplay\s+([\S+])\b}a ) {    # FIXME use sha1 id
        $new_version = $1;
    }

    if ( $exit || $err || !defined $new_version || !length $new_version ) {
        FAIL( "Cannot get cplay version from " . URL );
        return 1;
    }

    if ( !$force && $current_version eq $new_version ) {
        OK("cplay is already up to date using version '$current_version'");
        INFO("you can force an update by running: cplay selfupdate force");
        return;
    }

    my $to_file = Cwd::abs_path($0);
    if ( !-e $to_file ) {
        FAIL("Do not know how to update $0");
        return 1;
    }

    update_shebang($tmp_file);

    DEBUG("cp $tmp_file $to_file");
    File::Copy::copy( $tmp_file, $to_file ) or do {
        FAIL("Cannot copy $tmp_file to $to_file");
        return 1;
    };

    OK("cplay is updated to version '$new_version'");
    unlink $tmp_file;

    return;
}

1;
