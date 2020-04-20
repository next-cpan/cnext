package App::cplay::cmd::getrepo;

use App::cplay::std;
use App::cplay::Logger;    # import all

sub run ( $cli, @argv ) {

    die "Need one and only one argument" unless scalar @argv == 1;

    require Module::CoreList;

    my $module      = $argv[0];
    my $module_info = $cli->modules_idx->search($module);
    my $is_core     = Module::CoreList->first_release($module);

    if ( $module eq 'perl' || $is_core ) {
        say 'perl', $is_core ? " v$is_core" : '';
        return;
    }

    if ( !ref $module_info && !defined $module_info->{repository} ) {
        ERROR("Cannot find a repository for module '$module'");
        return 1;
    }

    say $module_info->{repository};

    return;
}

1;
