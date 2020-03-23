package App::cplay::cmd::version;

use v5.20;

use strict;
use warnings;

use feature 'signatures';
no warnings 'experimental::signatures';

sub run($self) {

    say "cplay $App::cplay::VERSION ($0)";

    return;
}

1;
