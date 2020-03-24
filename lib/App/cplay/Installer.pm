package App::cplay::Installer;

use App::cplay::std;

use App::cplay::Logger;    # import all
use App::cplay::Module;

use App::cplay::Installer::Unpacker ();

use App::cplay::Helpers qw{read_file};

use Test::More;            # Auto-removed

use File::pushd;

App::cplay::Logger->import(qw{fetch configure install resolve});

use Simple::Accessor qw{cli unpacker json BUILD};

sub build ( $self, %opts ) {

    $self->{_tracked_modules}      = {};
    $self->{_tracked_repositories} = {};

    $self->{BUILD} = {};

    return $self;
}

sub _build_unpacker($self) {
    App::cplay::Installer::Unpacker->new( tmproot => $self->cli->builddir );
}

sub _build_json($self) {
    return JSON::PP->new->utf8->allow_nonref;
}

sub install_single_module ( $self, $module ) {

    # are we already trying to install this module?
    return 1 if $self->tracking_module($module);

    my $cli = $self->cli or die;

    # V - check latest Module version
    # V - check if we have the module installed
    # V - get_repository_for_module
    # - download foo tarball
    # - extract tarball
    # - build Makefile.PL
    # - check BUILD.yaml
    # - check dependencies
    #     - install_single_module $each_dependencies
    # - run test
    # - install module

    my $module_info = $cli->modules_idx->search($module);
    if ( !$module_info ) {
        FAIL("Cannot find module '$module'");
        return;
    }

    # check if we already have the module available
    return 1 if has_module_version( $module_info->{module}, $module_info->{version} );

    my $repository_info = $cli->repositories_idx->search( $module_info->{repository}, $module_info->{repository_version} );
    if ( !$repository_info ) {
        FAIL( "Cannot find repository for " . $module_info->{repository} );
        return;
    }

    return $self->install_repository($repository_info);
}

sub install_repository ( $self, $repository_info ) {
    die unless ref $repository_info;

    my $name = $repository_info->{repository};
    return 1 if $self->tracking_repository($name);

    INFO("Installing Distribution $name");

    return unless $self->setup_tarball($repository_info);
    return unless $self->resolve_dependencies($name);

    configure("Distribution $name");

    install("Distribution $name");

    return 1;
}

sub resolve_dependencies ( $self, $name ) {
    my $BUILD = $self->BUILD->{$name} or die;

    # FIXME is the list complete ?
    my @order = qw{requires_build requires_runtime};

    foreach my $type (@order) {
        my $requires_list = $BUILD->{$type} // {};
        next unless scalar keys %$requires_list;
        resolve("$type for $name");
        foreach my $module ( sort keys %$requires_list ) {
            my $version = $requires_list->{$module};
            resolve("\t$name $type $module v$version");
            next if has_module_version( $module, $version );
            DEBUG("Module $module v$version is missing");
            return unless $self->install_single_module($module);

            # FIXME maybe do an extra check for the version ?
        }
    }

    return 1;
}

sub setup_tarball ( $self, $repository_info ) {

    my $name = $repository_info->{repository};

    # download & extract tarball
    my $tarball = $self->download_repository($repository_info);

    ## FIXME check signature... ??
    my $relative_path = $self->unpacker->unpack($tarball);
    my $full_path     = $self->cli->builddir . '/' . $relative_path;
    if ( !defined $relative_path || !-d $full_path ) {
        FAIL("fail to extract tarball $tarball");
        return;
    }

    my $dir = pushd($full_path);

    # load BUILD.json
    my $BUILD;
    if ( -e 'BUILD.json' ) {
        eval { $BUILD = $self->json->decode( read_file('BUILD.json') ); 1 }
          or DEBUG("Fail to read BUILD.json $@");
    }
    else {
        ERROR("Missing BUILD.json file for Distribution $name");
        return;
    }

    if ( !ref $BUILD ) {
        ERROR("Fail to read BUILD.json file from $full_path");
        return;
    }

    $BUILD->{_rootdir} = $full_path;
    $self->BUILD->{$name} = $BUILD;    # store the BUILD informations

    return 1;
}

sub download_repository ( $self, $repository_info ) {
    my $cli = $self->cli                                                or die;
    my $url = $cli->repositories_idx->get_tarball_url($repository_info) or die;

    fetch("Downloading tarball: $url");
    my $name = $repository_info->{repository};
    my $sha  = $repository_info->{sha};

    my $local = $cli->builddir . "/${name}-${sha}.tar.gz";
    $cli->http->mirror( $url, $local );

    return $local;
}

sub resolve_module ( $self, $module ) {

    # ...
}

sub tracking_module ( $self, $module ) {
    die unless defined $module;
    return 1 if $self->{_tracked_modules}->{$module};
    $self->{_tracked_modules}->{$module} = 1;
    return;
}

sub tracking_repository ( $self, $repository ) {
    die unless defined $repository;
    return 1 if $self->{_tracked_repositories}->{$repository};
    $self->{_tracked_repositories}->{$repository} = 1;
    return;
}

1;
