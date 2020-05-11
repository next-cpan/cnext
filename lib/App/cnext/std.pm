package App::next::std;

use strict;
use warnings;
use utf8;

=pod

This is importing the following to your namespace

    use v5.20;
    use feature 'signatures';
    no warnings 'experimental::signatures';

=cut

sub import {

    # auto import strict and warnings to our caller

    warnings->import();
    strict->import();

    require feature;
    feature->import(':5.20');
    feature->import('signatures');

    utf8->import();

    warnings->unimport('experimental::signatures');

    return;
}

1;
