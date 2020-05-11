package App::next::cmd::install;

use App::next::std;

use App::next::Logger;    # import all
use App::next::Installer;

sub run ( $self, @modules ) {
    return 1 unless scalar @modules;

    my $installer = App::next::Installer->new( cli => $self );

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
