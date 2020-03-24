package App::cplay::cmd::install;

use App::cplay::std;

use App::cplay::Logger;    # import all
use App::cplay::Installer;

use Test::More;            # Auto-removed

sub run ( $self, @modules ) {
    return unless scalar @modules;

    my $installer = App::cplay::Installer->new( cli => $self );

    # guarantee that ExtUtils::MakeMaker is >= 6.64
    return unless $installer->check_makemaker();

    foreach my $module (@modules) {
        INFO("Looking for module: $module");
        return unless $installer->install_single_module($module);
    }

    return 1;
}

1;

__END__
