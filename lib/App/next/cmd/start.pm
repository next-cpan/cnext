package App::cplay::cmd::start;

use App::cplay::std;

use App::cplay::Logger;    # import all
use App::cplay::Starter;

use Cwd;
use File::pushd;

sub run ( $cli, @modules ) {
    if ( !scalar @modules ) {
        ERROR("Need one or more module / distribution name");
        return 1;
    }

    my $root = getcwd;

    foreach my $module (@modules) {

        my $in_dir = pushd($root);

        my $ok = eval { App::cplay::Starter->new( module_or_distribution => $module )->create; };

        if ($ok) {
            OK("Directory for $module created.");
        }
        else {
            FAIL("Cannot create directory for $module.");
            DEBUG("Error: $@");
            return 1;
        }
    }

    return 0;
}

1;
