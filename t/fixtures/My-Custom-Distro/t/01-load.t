#!perl

use Test::More;

use_ok 'My::Custom::Distro';
ok $My::Custom::Distro::VERSION, "VERSION";

use_ok 'My::Custom::Distro::SubModule';

done_testing;
