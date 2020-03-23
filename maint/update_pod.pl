#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use File::Slurper;

exit( run() // 0 ) unless caller;

sub run {

    my $cplay_PL = $FindBin::Bin . '/../script/cplay.PL';
    my $cplay_pm = $FindBin::Bin . '/../lib/App/cplay.pm';

    die qq[missing $cplay_PL] unless -f $cplay_PL;
    die qq[missing $cplay_pm] unless -f $cplay_pm;

    my $txt_cplay_pm = File::Slurper::read_text($cplay_pm) or die;
    my $txt_cplay_PL = File::Slurper::read_text($cplay_PL) or die;

    my $marker = q[## __CPLAY_POD_MARKER__];

    # read POD from .pm file
    my ( $before, $pod ) = split( $marker, $txt_cplay_pm, 2 );
    length $pod or die q[cannot find pod];

    # update POD in .PL file
    # remove POD from .PL
    my ( $code, $old_pod, $end ) = split( $marker, $txt_cplay_PL, 3 );
    die "nothing after POD in .PL file" unless length $end;

    my $txt = $code       # .
      . $marker . "\n"    # .
      . $pod . "\n"       # .
      . "$marker\n"       # .
      . $end;

    File::Slurper::write_text( $cplay_PL, $txt );

    return;
}

1;
