package cPlayTestHelpers;    # inspired by App::Yath::Tester

use App::next::std;

use App::next::IPC;

use Test::More;

use Exporter 'import';
our @EXPORT = qw/remove_module is_module_installed is_module_installed_to_local_lib module_path/;

use constant PERLDOC => $^X . 'doc';

sub remove_module($module) {
    my ( $status, $out, $err ) = App::next::IPC::run3( [ PERLDOC, '-lm', $module ] );
    if ( $status == 0 ) {
        note "$module is already installed, removing it";
        chomp $out;
        ok unlink($out), "unlink $out" or die;
        return 1;
    }

    return;
}

sub is_module_installed($module) {
    my ( $status, $out, $err ) = App::next::IPC::run3( [ PERLDOC, '-lm', $module ] );
    return $status == 0;
}

sub module_path($module) {
    my ( $status, $out, $err ) = App::next::IPC::run3( [ PERLDOC, '-lm', $module ] );
    return unless $status == 0;
    chomp $out if $out;
    return $out;
}

sub is_module_installed_to_local_lib ( $module, $local_lib ) {
    my $pp = $module;
    $pp =~ s{::}{/}g;
    $pp .= '.pm';

    local $ENV{PERL5LIB};
    _check_local_lib_once();

    my $oneliner = <<"EOS";
eval { require $module; 1 } or die;
die unless \$INC{"$pp"} =~ m{^\Q$local_lib\E};
print 1;
EOS

    my ( $status, $out, $err ) = App::next::IPC::run3( [ $^X, "-mlocal::lib=--no-create,$local_lib", '-e', $oneliner ] );
    if ( $status == 0 ) {
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
