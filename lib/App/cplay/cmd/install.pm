package App::cplay::cmd::install;

use App::cplay::std;

use Pod::Text ();

sub run ( $self, @argv ) {

    say "install: ", @argv;

    $self->modules_idx;    # get or update indexes files

    return 0;
}

1;
