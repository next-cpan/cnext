#!/usr/bin/env perl

use strict;
use warnings;

use FindBin qw($Bin);    # Auto-removed
use lib "$Bin/../lib", "$Bin/../../Menlo-Legacy/lib", "$Bin/../../Menlo/lib", "$Bin/../fatlib";    # Auto-removed

#use Simple::Accessor ();
#use App::cpanminus::script;

unless (caller) {
    print qq[OK $0\n];

    #my $app = App::cpanminus::script->new(name => "App::cpanminus");
    #$app->parse_options(@ARGV);
    #exit $app->doit;
}
