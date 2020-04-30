#!perl

use Test::More;

use_ok 'Makefile::Workflow';
ok $Makefile::Workflow::VERSION, "VERSION";

done_testing;
