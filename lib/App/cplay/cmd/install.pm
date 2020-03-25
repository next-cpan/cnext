package App::cplay::cmd::install;

use App::cplay::std;

use App::cplay::Logger;    # import all
use App::cplay::Installer;

use Test::More;            # Auto-removed

sub run ( $self, @modules ) {
    return 1 unless scalar @modules;

    my $installer = App::cplay::Installer->new( cli => $self );

    # guarantee that ExtUtils::MakeMaker is >= 6.64
    return 1 unless $installer->check_makemaker();

    foreach my $module (@modules) {
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
