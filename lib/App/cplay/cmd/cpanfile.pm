package App::cplay::cmd::cpanfile;

use App::cplay::std;

use App::cplay::Logger;    # import all
use App::cplay::Installer;

use App::cplay::Module qw(get_module_version);

sub run ( $self, @files ) {

    my $installer = App::cplay::Installer->new( cli => $self );

    # guarantee that ExtUtils::MakeMaker is >= 6.64
    return 1 unless $installer->check_makemaker();    # move to build ?

    return 1 unless _install_and_load_cpanfile($installer);

    # default cpanfile
    push @files, 'cpanfile' unless scalar @files;

    my @phases = grep $self->{"with_$_"}, qw(configure build test runtime develop);
    my @types  = grep $self->{"with_$_"}, qw(requires recommends suggests);

    my @features = $self->features->@*;

    foreach my $f (@files) {
        $f = 'cpanfile' if $f eq '.';

        INFO("parsing cpanfile $f");
        my $cpanfile = Module::CPANfile->load($f);

        my $prereqs = $cpanfile->prereqs_with(@features);
        next unless $prereqs;

        my $reqs = $prereqs->merged_requirements( \@phases, \@types )->as_string_hash;
        next unless $reqs;

        # check perl requiremnts earlier
        if ( my $need_perl_version = $reqs->{'perl'} ) {
            if ( "$]" < $need_perl_version ) {
                ERROR("Needs Perl >= $need_perl_version, this is Perl $].");
                return 1;
            }
            delete $reqs->{'perl'};
        }

        foreach my $module ( sort keys %$reqs ) {
            my $version_range = $reqs->{$module};

            if ( !$self->reinstall ) {
                INFO("checking $module at $version_range");
                my $current_version = get_module_version($module);
                if ( defined $current_version ) {    # module is installed
                    if ( $current_version >= $version_range ) {
                        OK("Module $module is using $current_version (>=$version_range)");
                        next;
                    }
                }
            }

            DEBUG("installing last version of $module");
            return 1 unless $installer->install_single_module($module);
        }
    }

    DONE("install cpanfile succeeds");

    return 0;
}

sub _install_and_load_cpanfile($installer) {    # maybe install_and_load any module ?

    return 1 if eval { require Module::CPANfile; 1 };

    WARN("Module::CPANfile is not available trying to install it");

    if ( !$installer->install_single_module('Module::CPANfile') ) {
        ERROR("Fail to install Module::CPANfile");
        return;
    }

    return eval { require Module::CPANfile; 1 };
}

1;

__END__
