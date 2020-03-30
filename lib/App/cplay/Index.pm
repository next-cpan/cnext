package App::cplay::Index;

use App::cplay::std;    # import strict, warnings & features

use App::cplay::Logger;

use App::cplay::Installer::Unpacker ();

use constant BASE_URL => q[https://pause-play.github.io/pause-index];

# tarball containing all .ix files
use constant IDX_TARBALL_URL => q[https://github.com/pause-play/pause-index/archive/p5.tar.gz];

use constant MODULES_IX_BASENAME           => 'module.idx';
use constant REPOSITORIES_IX_BASENAME      => 'repositories.idx';
use constant EXPLICIT_VERSIONS_IX_BASENAME => 'explicit_versions.idx';

use constant REFRESH_TIMEOUT => 24 * 3_600;    # X hours

my $_MODULES_IX_FILE;
my $_REPOSITORIES_IX_FILE;
my $_EXPLICIT_VERSIONS_IX_FILE;

# FIXME improve download the tarball from the repo & extract it
sub setup_once ( $cli, $attempt = 1 ) {
    no warnings 'redefine';

    ref $cli eq 'App::cplay::cli' or die "cli is not one App::cplay: $cli";

    # check if existing index files are available
    #	refresh them if needed

    my $root = $cli->cache_dir;
    $_MODULES_IX_FILE           = "$root/" . MODULES_IX_BASENAME;
    $_REPOSITORIES_IX_FILE      = "$root/" . REPOSITORIES_IX_BASENAME;
    $_EXPLICIT_VERSIONS_IX_FILE = "$root/" . EXPLICIT_VERSIONS_IX_BASENAME;

    my @all_ix_files_basename = ( MODULES_IX_BASENAME, REPOSITORIES_IX_BASENAME, EXPLICIT_VERSIONS_IX_BASENAME );
    my @all_ix_files          = ( $_MODULES_IX_FILE, $_REPOSITORIES_IX_FILE, $_EXPLICIT_VERSIONS_IX_FILE );

    my $now = time;

    INFO("Check and refresh cplay index files.");
    my $force_refresh = $cli->refresh;
    if ( !$force_refresh ) {
        foreach my $file (@all_ix_files) {
            if ( !-e $file ) {
                $force_refresh = 1;
                last;
            }

            my $mtime = ( stat($file) )[9];
            if ( ( $now - $mtime ) > REFRESH_TIMEOUT ) {
                DEBUG("clearing index file $file");
                unlink($file);
                $force_refresh = 1;
            }
        }
    }

    if ($force_refresh) {
        my $http       = $cli->http;
        my $ix_tarball = $cli->cache_dir . '/p5.tar.gz';
        unlink $ix_tarball if $attempt > 1;

        App::cplay::Logger::fetch(IDX_TARBALL_URL);
        $http->mirror( IDX_TARBALL_URL, $ix_tarball );
        my $unpacker = App::cplay::Installer::Unpacker->new( tmproot => $cli->build_dir );

        my $cd = $cli->cache_dir;

        my $relative_path = $unpacker->unpack($ix_tarball);
        FATAL( "Fail to extra index tarball: " . IDX_TARBALL_URL ) unless defined $relative_path;

        require File::Copy;
        foreach my $f (@all_ix_files_basename) {
            my $tmp = $cli->build_dir . '/' . $relative_path . '/' . $f;
            FATAL( "File '$f' is not part of tarball " . IDX_TARBALL_URL ) unless -f $tmp;
            File::Copy::move( $tmp, "$root/$f" ) or FATAL("Fail to move index file '$f' to '$root/$f'");
        }
    }

    if ( !_check_file_versions(@all_ix_files) ) {
        if ( $attempt >= 2 ) {
            FATAL("index files versions mismatch");
        }
        else {
            map { unlink $_ } @all_ix_files;
            return setup_once( $cli, $attempt + 1 );
        }
    }

    *setup_once = sub { };    # do it once : only remove it at the very end, we are calling it twice...

    return;
}

sub _check_file_versions(@files) {

    FATAL("Need at least two files") if scalar @files < 2;

    my $use_version;
    foreach my $file (@files) {
        if ( open( my $fh, '<:utf8', $file ) ) {
            my $has_version;
            while ( my $line = <$fh> ) {
                if ( $line =~ m{"version"\s*:\s*(\w+)\s*,} ) {
                    $has_version = 1;
                    my $v = $1;
                    if ( !defined $use_version ) {
                        $use_version = $v;
                    }
                    elsif ( $v ne $use_version ) {
                        WARN("file version mismatch: $file");
                        return;
                    }
                    last;
                }
            }
            FATAL(qq[Cannot find "version" in index file: $file]) unless $has_version;
        }
    }

    return 1;
}

# requesting the path to any .ix file, autorefresh the files and set the PATH to all of them
sub get_modules_ix_file($cli) {
    setup_once($cli);

    return $_MODULES_IX_FILE;
}

sub get_repositories_ix_file($cli) {
    setup_once($cli);

    return $_REPOSITORIES_IX_FILE;
}

sub get_explicit_versions_ix_file($cli) {
    setup_once($cli);

    return $_EXPLICIT_VERSIONS_IX_FILE;
}

1;
