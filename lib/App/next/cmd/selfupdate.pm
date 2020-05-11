package App::next::cmd::selfupdate;

use App::next ();

use App::next::std;
use App::next::Logger;    # import all

use App::next::Installer;
use App::next::InstallDirs;

use App::next::Helpers qw{write_file is_fatpacked update_shebang};

use File::Basename ();
use Cwd            ();
use File::Copy     ();

use constant URL => q[http://get.cnext.us/];    # or https://git.io/cnext

sub run ( $cli, @argv ) {
    if ( !is_fatpacked() ) {
        FAIL("Can only update a FatPacked version of 'cnext'.");
        return 1;
    }

    App::next::Logger::setup_for_script();

    my $force = grep { $_ eq 'force' } @argv;
    INFO("running 'selfupdate force'") if $force;

    my $installer = App::next::Installer->new( cli => $cli );

    my $tmp_file = $installer->cli->build_dir . "/cnext.tmp";
    unlink $tmp_file if -e $tmp_file;

    $installer->cli->http->mirror( URL, $tmp_file );

    if ( !-f $tmp_file || -z _ ) {
        FAIL( "Fail to download cnext from " . URL );
        return 1;
    }

    my $current_version = $App::next::VERSION . '@' . $App::next::REVISION;
    my ( $exit, $out, $err ) = App::next::IPC::run3( [ "$^X", $tmp_file, q[--version] ] );
    my $new_version;
    if ( $out && $out =~ m{^cnext\s+(\d+\.\d+\@\w+)\b}a ) {    # FIXME use sha1 id
        $new_version = $1;
    }

    if ( $exit || $err || !defined $new_version || !length $new_version ) {
        FAIL( "Cannot get cnext version from " . URL );
        return 1;
    }

    if ( !$force && $current_version eq $new_version ) {
        OK("cnext is already up to date using version '$current_version'");
        INFO("you can force an update by running: cnext selfupdate force");
        return;
    }

    DEBUG("current_version: $current_version ; target_version: $new_version");

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

    OK("cnext is updated to version '$new_version'");
    unlink $tmp_file;

    return;
}

1;
