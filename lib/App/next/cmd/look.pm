package App::cplay::cmd::look;

use App::cplay::std;
use App::cplay::Logger;    # import all

use File::Which ();
use File::Path qw(mkpath rmtree);
use File::pushd;

sub run ( $cli, @argv ) {

    die "Need one and only distribution or module name" unless scalar @argv == 1 && defined $argv[0];
    die "Cannot detect STDIN" unless -t STDIN;

    my $module_or_distro = $argv[0];

    my $module_info = $cli->modules_idx->search($module_or_distro);
    my $repository_info;

    if ( defined $module_info ) {
        $repository_info = $cli->repositories_idx->search( $module_info->{repository} );
    }
    else {
        $repository_info = $cli->repositories_idx->search($module_or_distro);
    }

    if ( !$repository_info ) {
        ERROR("Cannot find distribution for '$module_or_distro'");
        return 1;
    }

    my $repository_name = $repository_info->{repository};
    DEBUG("Found repository '$repository_name'");

    # when git is available git clone the repo
    my $git = File::Which::which('git');
    if ( $git && -x $git ) {
        my $url = $cli->repositories_idx->get_git_repository_url($repository_info);

        my $base_dir = $cli->cache_dir . '/git-repos';

        my $dir = $base_dir . '/' . $repository_name;

        mkpath($base_dir) unless -d $base_dir;
        rmtree($dir) if -d $dir;

        my ( $exit, $out, $err ) = App::cplay::IPC::run3( [ $git, 'clone', $url, $dir ] );

        if ( $exit != 0 || !-d $dir ) {
            ERROR("Fail to clone git repository '$url'");
            return 1;
        }

        {
            my $shell = $ENV{SHELL} || File::Which::which('bash') || File::Which::which('sh');
            if ( !-x $shell ) {
                ERROR("Cannot find a valid shell, set SHELL env. variable");
                INFO("repository was cloned to $dir");
                INFO("     cd $dir");
                return 1;
            }

            my $in_dir = pushd($dir);

            INFO("Opening a new shell session to '$dir'");
            system $shell;
        }

        DEBUG("Removing temporary directory: '$dir'");
        rmtree($dir) if -d $dir;
    }
    else {
        WARNING("Cannot find a git binary in your PATH");
        return 1;
    }

    return;
}

1;
