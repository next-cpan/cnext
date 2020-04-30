package App::cplay::cmd::test;

use App::cplay::std;

use App::cplay::Logger;    # import all
use App::cplay::Installer;

sub run ( $self, @modules ) {    # very close to install command [could refactor?]
    return 1 unless scalar @modules;

    my $installer = App::cplay::Installer->new( cli => $self, run_install => 0 );

    if ( $self->cli->run_tests ) {
        ERROR("Cannot disable tests when using 'test' command.");
        return 1;
    }

    foreach my $module (@modules) {
        if ( $module eq '.' ) {
            INFO "Testing distribution from .";
            if ( !$installer->install_from_file() ) {
                FAIL "Fail to test distribution from .";
                return 1;
            }
            next;
        }

        INFO("Looking for module: $module");
        if ( !$installer->install_single_module_or_repository($module) ) {
            FAIL("Fail to test $module or its dependencies.");
            return 1;
        }
    }

    DONE("test succeeds");

    return 0;
}

1;

__END__
