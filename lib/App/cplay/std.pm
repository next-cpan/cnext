package App::cplay::std;

use strict;
use warnings;

#use v5.20;
#use feature 'signatures';
#no warnings 'experimental::signatures';

sub import {

    # auto import strict and warnings to our caller

    warnings->import();
    strict->import();

    require feature;
    feature->import(':5.20');
    feature->import('signatures');

    warnings->unimport('experimental::signatures');

    return;
}

1;
