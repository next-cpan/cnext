package App::cplay::Index;

use App::cplay::std;    # import strict, warnings & features

use App::cplay::Logger;

use constant BASE_URL => q[https://pause-play.github.io/pause-index/];

use constant MODULES_IX_BASENAME           => 'module.idx';
use constant REPOSITORIES_IX_BASENAME      => 'repositories.idx';
use constant EXPLICIT_VERSIONS_IX_BASENAME => 'explicit_versions.idx';

use constant REFRESH_TIMEOUT => 24 * 3_600;    # X hours

my $_MODULES_IX_FILE;
my $_REPOSITORIES_IX_FILE;
my $_EXPLICIT_VERSIONS_IX_FILE;

# FIXME improve download the tarball from the repo & extract it
sub setup_once($cli) {
    no warnings 'redefine';
    *setup_once = sub { };                     # do it once

    ref $cli eq 'App::cplay::cli' or die "cli is not one App::cplay: $cli";

    # check if existing index files are available
    #	refresh them if needed

    my $homedir = $cli->homedir;

    $_MODULES_IX_FILE           = "$homedir/.cplay." . MODULES_IX_BASENAME;
    $_REPOSITORIES_IX_FILE      = "$homedir/.cplay." . REPOSITORIES_IX_BASENAME;
    $_EXPLICIT_VERSIONS_IX_FILE = "$homedir/.cplay." . EXPLICIT_VERSIONS_IX_BASENAME;

    # FIXME ... skip if all .ix files are < X hours
    #				except when using the --no-cache arguement

    my @files = (
        [    # remote / local
            BASE_URL . '/' . MODULES_IX_BASENAME,
            $_MODULES_IX_FILE,
        ],
        [    # remote / local
            BASE_URL . '/' . REPOSITORIES_IX_BASENAME,
            $_REPOSITORIES_IX_FILE,
        ],
        [    # remote / local
            BASE_URL . '/' . EXPLICIT_VERSIONS_IX_BASENAME,
            $_EXPLICIT_VERSIONS_IX_FILE,
        ],
    );

    my $http = $cli->http;

    my $now = time;

    INFO("Check and refresh cplay index files.");
    foreach my $list (@files) {
        my ( $remote, $local ) = @$list;

        if ( -e $local ) {
            my $mtime = ( stat($local) )[9];
            if ( $cli->refresh || ( $now - $mtime ) < REFRESH_TIMEOUT ) {
                DEBUG("clearing index file $local");
                unlink($local);
            }
        }

        $http->mirror( $remote, $local );
    }

    return;
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
