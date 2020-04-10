package App::cplay::cmd::install;

use App::cplay::std;

use App::cplay::Logger;    # import all
use App::cplay::Installer;

sub run ( $self, @modules ) {
    return 1 unless scalar @modules;

    my $installer = App::cplay::Installer->new( cli => $self );

    # guarantee that ExtUtils::MakeMaker is >= 6.64
    return 1 unless $installer->check_makemaker();

    foreach my $module (@modules) {
        if ( $module eq '.' ) {
            INFO "Installing distribution from .";
            if ( !$installer->install_from_file() ) {
                FAIL "Fail to install distribution from .";
                return 1;
            }
            next;
        }

        INFO("Looking for module: $module");
        if ( !$installer->install_single_module_or_repository($module) ) {
            FAIL("Fail to install $module or its dependencies.");
            return 1;
        }
    }

    DONE("install cmd succeeds");

    return 0;
}

1;

__END__
