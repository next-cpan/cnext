package App::cplay::cmd::install;

use App::cplay::std;

use Pod::Text ();

sub run ( $self, @argv ) {

    say "install: ", @argv;

    return 0;
}

1;
