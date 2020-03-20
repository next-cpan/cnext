#!/usr/bin/env perl

# __FATPACK__

use strict;
use warnings;

use FindBin qw($Bin);    # Auto-removed
use lib "$Bin/../lib", "$Bin/../fatlib";    # Auto-removed
#use lib "$Bin/../fatpack-build/local/lib/perl5";  # Auto-removed FIXME

use Simple::Accessor ();
use App::cplay;

unless (caller) {
    print qq[OK $0\n];

    #my $app = App::cpanminus::script->new(name => "App::cpanminus");
    #$app->parse_options(@ARGV);
    #exit $app->doit;
}
