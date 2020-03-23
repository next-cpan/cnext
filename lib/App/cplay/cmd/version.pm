package App::cplay::cmd::version;

use App::cplay::std;

sub run($self) {

    say "cplay $App::cplay::VERSION ($0)";

    return;
}

1;
