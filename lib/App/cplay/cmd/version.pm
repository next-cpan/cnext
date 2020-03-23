package App::cplay::cmd::version;

use App::cplay::std;

sub run ( $self, @argv ) {

    say "cplay $App::cplay::VERSION ($0)";

    return;
}

1;
