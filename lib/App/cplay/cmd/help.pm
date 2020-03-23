package App::cplay::cmd::help;

use v5.20;

use strict;
use warnings;

use feature 'signatures';
no warnings 'experimental::signatures';

use Pod::Text ();

sub run($self) {

    my $out;
    open my $fh, ">", \$out;

    my $f = $INC{'App/cplay.pm'};
    $f = $0 unless -e $f;

    Pod::Text->new->parse_from_file( $f, $fh );

    if ( defined $out ) {
        $out =~ s/^[ ]{6}/    /mg;
        print STDERR $out;
    }

    return 0;
}

1;
