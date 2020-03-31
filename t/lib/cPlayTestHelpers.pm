package cPlayTestHelpers;    # inspired by App::Yath::Tester

use App::cplay::std;

use Test::More;

use Exporter 'import';
our @EXPORT = qw/remove_module is_module_installed/;

sub remove_module($module) {
    my $out = qx[$^Xdoc -lm $module];
    if ( $? == 0 ) {
        note "$module is already installed, removing it";
        chomp $out;
        ok unlink($out), "unlink $out" or die;
        return 1;
    }

    return;
}

sub is_module_installed($module) {
    my $out = qx[$^Xdoc -lm $module 2>&1];
    return $? == 0;
}

1;
