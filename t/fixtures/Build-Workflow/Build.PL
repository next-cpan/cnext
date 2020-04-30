#!perl

use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
    dist_abstract => 'Build Workflow for testing',
    module_name   => 'Build::Workflow',
    license       => 'perl',
);

$build->create_build_script;
