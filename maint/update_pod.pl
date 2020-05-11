#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use File::Slurper;

exit( run() // 0 ) unless caller;

sub run {

    my $cnext_PL = $FindBin::Bin . '/../script/cnext.PL';
    my $cnext_pm = $FindBin::Bin . '/../lib/App/cnext.pm';

    die qq[missing $cnext_PL] unless -f $cnext_PL;
    die qq[missing $cnext_pm] unless -f $cnext_pm;

    my $txt_cnext_pm = File::Slurper::read_text($cnext_pm) or die;
    my $txt_cnext_PL = File::Slurper::read_text($cnext_PL) or die;

    my $marker = q[## __CPLAY_POD_MARKER__];

    # read POD from .pm file
    my ( $before, $pod ) = split( $marker, $txt_cnext_pm, 2 );
    length $pod or die q[cannot find pod];

    # shortcut the pod
    ( $pod, undef ) = split( m{^=head1 Developer}m, $pod, 2 );
    length $pod or die q[cannot find pod];

    # update POD in .PL file
    # remove POD from .PL
    my ( $code, $old_pod ) = split( $marker, $txt_cnext_PL );

    my $txt = $code       # .
      . $marker . "\n"    # .
      . $pod . "\n"       # .
      ;

    File::Slurper::write_text( $cnext_PL, $txt );

    return;
}

1;
