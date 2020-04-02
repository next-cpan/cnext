package cPlayTestHelpers;    # inspired by App::Yath::Tester

use App::cplay::std;

use Test::More;

use Exporter 'import';
our @EXPORT = qw/remove_module is_module_installed is_module_installed_to_local_lib/;

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

sub is_module_installed_to_local_lib ( $module, $local_lib ) {
    my $pp = $module;
    $pp =~ s{::}{/}g;
    $pp .= '.pm';

    local $ENV{PERL5LIB};
    _check_local_lib_once();
    my $out = qx|$^X -mlocal::lib=--no-create,$local_lib -e 'eval { require $module; 1 } or die; die unless \$INC{"$pp"} =~ m{^\Q$local_lib\E}; print 1' 2>&1|;

    if ( $? == 0 ) {
        chomp $out if defined $out;
        return 1   if $out == 1;
    }

    return;
}

sub _check_local_lib_once {
    state $ok = eval { require local::lib; 1 } or die "missing local::lib";
    return;
}

1;
