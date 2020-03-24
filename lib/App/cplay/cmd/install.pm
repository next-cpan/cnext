package App::cplay::cmd::install;

use App::cplay::std;

use App::cplay::Logger;    # import all
use App::cplay::Installer;

use Test::More;            # Auto-removed

sub run ( $self, @modules ) {

    # get or update indexes files

    #bless $self, __PACKAGE__; # attempt

    $self->{installing} //= { module => {}, repository => {} };    # used to detect loop dependencies

    my $installer = App::cplay::Installer->new( cli => $self );

    foreach my $module (@modules) {
        INFO("Looking for module: $module");
        return unless $installer->install_single_module($module);
    }

    return 1;
}

1;

__END__
