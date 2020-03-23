#!/usr/bin/env perl

BEGIN {
    if ( "$]" < 5.019 ) {    # needs 5.20 for function signature
        die qq{$0 is not supported on Perl $] - needs Perl 5.20 or higher\n};
    }
}

# __FATPACK__

use strict;
use warnings;

use FindBin qw($Bin);        # Auto-removed
use lib "$Bin/../lib", "$Bin/../fatlib";    # Auto-removed

use App::cplay::cli ();

unless (caller) {
    exit( App::cplay::cli->new( name => "App::cplay" )->run(@ARGV) // 0 );
}

1;

__END__

TODO

- support for cpanfile
- support for sudo
