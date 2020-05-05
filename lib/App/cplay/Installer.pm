package App::cplay::Installer;

use App::cplay::std;

use App::cplay;
use App::cplay::Logger;    # import all
use App::cplay::Module ();
use App::cplay::Signature qw{check_signature};

use App::cplay::Installer::Unpacker ();
use App::cplay::IPC                 ();

use App::cplay::BUILD ();

use App::cplay::Installer::Command ();
use App::cplay::Installer::Share   ();
use App::cplay::Helpers qw{is_valid_distribution_name};

use Config;

use File::Copy     ();    # CORE
use File::Path     ();    # CORE
use File::Find     ();    # CORE
use File::Basename ();    # CORE

use Umask::Local;         # fatpacked

use File::pushd;

use App::cplay::InstallDirs ();

App::cplay::Logger->import(qw{fetch configure install resolve});

use Simple::Accessor qw{
  cli
  unpacker
  BUILD
  depth
  local_lib_bin
  local_lib_lib
  installdirs

  run_install
};

use constant EXTUTILS_MAKEMAKER_MIN_VERSION => '6.64';

sub build ( $self, %opts ) {

    $self->{_tracked_modules}      = {};
    $self->{_tracked_repositories} = {};
    $self->{depth}                 = 0;    # starts at 1;

    # by default perform the install action, disable for testing only
    $self->{run_install} //= 1;

    $self->{BUILD} = {};

    return $self;
}

sub _build_installdirs($self) {
    App::cplay::InstallDirs->new( type => $self->cli->installdirs );
}

sub _build_unpacker($self) {
    App::cplay::Installer::Unpacker->new( tmproot => $self->cli->build_dir );
}

sub has_module_version ( $self, $module, $version ) {

    if ( $self->depth == 1 && $self->cli->reinstall ) {
        DEBUG("(re)installing module $module");
        return;
    }

    if ( $self->cli->local_lib ) {
        return 1 if App::cplay::Module::has_module_version( $module, $version, $self->cli->local_lib );
        if ( $self->depth > 1 ) {    # FIXME maybe implement --self-contained there ?? -- need to check for CORE
            return 1 if App::cplay::Module::has_module_version( $module, $version );
        }
    }
    else {
        return App::cplay::Module::has_module_version( $module, $version );
    }

    return;
}

sub install_from_file ( $self, $file = 'BUILD.json' ) {

    # cannot load BUILD.json
    return unless my $BUILD = App::cplay::BUILD::create_from_file($file);

    $self->depth(1);    # need to setup depth
    my $ok = $self->install_from_BUILD($BUILD);
    $self->depth(0);

    return $ok;
}

sub install_single_module ( $self, $module, $need_version = undef ) {
    return $self->install_single_module_or_repository( $module, 0, $need_version );
}

sub install_single_module_or_repository ( $self, $module_or_repository, $can_be_repo = 1, $need_version = undef ) {

    $self->depth( $self->depth + 1 );

    my $ok;
    if ( defined $need_version ) {
        $ok = $self->has_module_version( $module_or_repository, $need_version );
        DEBUG("Module $module_or_repository v$need_version is missing") unless $ok;
        if ( $ok && ( $self->depth == 1 || $self->cli->verbose ) ) {
            my $log_level = $self->depth > 1 ? q[resolve] : q[OK];
            my $logger    = App::cplay::Logger->can($log_level);
            $logger->("$module_or_repository is already installed.");
        }
    }

    if ( !$ok ) {
        $ok = $self->_install_single_module_or_repository( $module_or_repository, $can_be_repo );
        my $msg = $ok ? "install of $module_or_repository succeeded" : "install of $module_or_repository failed";
        DEBUG($msg);

        # perform an extra check to make sure the last available version match the requirements
        if ( $ok && !$can_be_repo && defined $need_version ) {
            $ok = $self->has_module_version( $module_or_repository, $need_version );
            DEBUG("Module $module_or_repository v$need_version is missing") unless $ok;
        }
    }

    $self->depth( $self->depth - 1 );

    return $ok;
}

sub _install_single_module_or_repository ( $self, $module_or_repository, $can_be_repo = 1 ) {

    # are we already trying to install this module?
    return 1 if $self->tracking_module($module_or_repository);

    my $cli = $self->cli or die;

    my $name_as_column_char = index( $module_or_repository, ':' ) == -1 ? 0 : 1;

    my $custom_requested_version;
    if ( $module_or_repository =~ s{\@(.+)$}{} ) {
        $custom_requested_version = $1;

        if ($name_as_column_char) {
            $module_or_repository =~ s{::}{-}g;
            FAIL("Cannot request a specific version for a module: try $module_or_repository\@$custom_requested_version");
            return;
        }
    }

    # search the latest module from modules.ix file
    # 1 - lookup for module
    my $module_info;
    my $repository_info;

    if ( !defined $custom_requested_version ) {    # Module@version is invalid request
        $module_info = $cli->modules_idx->search( $module_or_repository, $custom_requested_version );
    }

    # 2 - lookup for distribution
    if ( !$module_info && !$name_as_column_char && $can_be_repo ) {
        $repository_info = $cli->repositories_idx->search( $module_or_repository, $custom_requested_version );
    }

    # 3 - lookup for an older version or a TRIAL version
    if ( !$module_info && !$repository_info && defined $custom_requested_version ) {

        # only works on repositories names
        my $repository = $module_or_repository;
        FATAL("Invalid distribution name: '$repository'") unless is_valid_distribution_name($repository);

        DEBUG("Try to install '$repository' from a custom tag/version.");

        # $module_or_repository, $custom_requested_version, 0, $can_be_repo
        my $branch = App::cplay::source();

        my $tag;
        if ( $custom_requested_version =~ m{^$branch} ) {    # p5-v1.00
            $tag = $custom_requested_version;
        }
        elsif ( $custom_requested_version =~ m{^v} ) {       # v1.00
            $tag = $branch . '-' . $custom_requested_version;
        }
        elsif ( $custom_requested_version =~ m{^[0-9\._]+$} ) {    # 1.00, 1.01_01
            $tag = $branch . '-v' . $custom_requested_version;
        }
        else {                                                     # any other tags
            $tag = $custom_requested_version;
        }

        my $version = 0;
        if ( $tag =~ m{^$branch-v(.+)$} ) {
            $version = $1;
        }

        DEBUG("$repository: tag $tag ; version $version");

        # convert the result to a repository
        $repository_info = {
            repository => $repository,
            version    => $version,
            sha        => $tag,
            signature  => undef,
        };
    }

    if ( !$module_info && !$repository_info ) {
        FAIL("Cannot find module or distribution '$module_or_repository'");
        return;
    }

    # check if we already have the module available
    if ($module_info) {
        if ( $self->has_module_version( $module_info->{module}, $module_info->{version} ) ) {
            my ( $m, $v ) = ( $module_info->{module}, $module_info->{version} );
            OK("$m is up to date. ($v)");
            return 1;
        }
        $repository_info //= $cli->repositories_idx->search( $module_info->{repository}, $module_info->{repository_version} );
    }

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

    # check BUILD sanity state
    my $BUILD   = $self->BUILD->{$name} or FATAL("Cannot find a BUILD entry for $name");
    my $version = $BUILD->version;

    # check if distribution is already installed
    if ( my $primary = $BUILD->primary ) {    ## FIXME skip if using --retry
        my $module_v = $BUILD->provides->{$primary}->{version};    # should not raise warnings?
        if ( $self->has_module_version( $primary, $module_v ) ) {
            OK("$name-$version is up to date.");
            return 1;
        }
    }

    return $self->install_from_BUILD( $BUILD, $name );
}

sub install_from_BUILD ( $self, $BUILD, $name = undef ) {
    if ( !defined $name ) {                                        # --from-tarball
        $name = $BUILD->name;
        $self->BUILD->{$name} = $BUILD;
    }

    my $version = $BUILD->version;

    return unless $self->resolve_dependencies($name);

    # move to the tmp directory for the next actions
    my $indir = pushd( $BUILD->_rootdir );

    $self->_setup_local_lib_env();

    my $builder_type = $BUILD->builder;
    if ( $builder_type eq 'play' ) {
        return unless $self->_builder_play($name);
    }
    elsif ( $builder_type eq 'makefile.pl' ) {
        return unless $self->_builder_Makefile_PL($name);
    }
    elsif ( $builder_type eq 'build.pl' ) {
        return unless $self->_builder_Build($name);
    }
    else {
        FATAL("Unknown builder type '$builder_type' for distribution '$name'");
    }

    # we successfully installed the module
    #   let's advertise the installed modules [update memory cached version]
    #   and announce the OK status

    $self->advertise_installed_modules($BUILD);

    if ( $self->run_install ) {
        OK("Installed distribution $name-$version");
    }
    else {    # we are not installing the module but only running unit tests
        OK("Tests Succeeds for $name-$version");
    }

    return 1;
}

sub advertise_installed_modules ( $self, $BUILD ) {

    return unless ref $BUILD && ref $BUILD->provides;

    foreach my $module ( sort keys %{ $BUILD->provides } ) {
        my $v = $BUILD->provides->{$module}->{version} // 0;
        DEBUG("advertise_installed_modules: $module => $v");
        App::cplay::Module::module_updated( $module, $v, $self->cli->local_lib );
    }

    return;
}

# https://metacpan.org/release/App-cpanminus/source/lib/App/cpanminus/fatscript.pm#L1225
sub _setup_local_lib_env ( $self, $force = 0 ) {
    state $done;
    return if $done && !$force;
    $done = 1;

    return unless my $local_lib = $self->cli->local_lib;

    INFO("Using local-lib: $local_lib");

    require Cwd;
    require local::lib;

    my $ll = local::lib->new( quiet => 1 )->activate($local_lib);
    $ll->setup_local_lib;
    $ll->setup_env_hash;

    $self->local_lib_bin( $ll->bins->[0] );
    $self->local_lib_lib( $ll->libs->[0] );

    $ENV{PERL_MM_OPT} .= " INSTALLMAN1DIR=none INSTALLMAN3DIR=none";
    $ENV{PERL_MM_USE_DEFAULT} = 1;

    return;
}

sub _builder_play ( $self, $name ) {
    my $BUILD = $self->BUILD->{$name} or die;

    ### running tests
    if ( $self->cli->run_tests ) {
        my @tests = ('t/*.t');    # default
        if (   defined $BUILD->tests
            && ref $BUILD->tests eq 'ARRAY'
            && scalar @{ $BUILD->tests } ) {
            @tests = @{ $BUILD->tests };
        }

        # multiple modules are relying on blib being there
        #   use 'blib'; # can be removed in p7
        {    # minimum scaffold to make blib happy
            File::Path::make_path('blib/lib');
            File::Path::make_path('blib/arch');
        }

        my $cmd = App::cplay::Installer::Command->new(
            log_level => 'test',
            txt       => "tests for $name",
            cmd       => [
                $^X,  "-MExtUtils::Command::MM",                             "-MTest::Harness",
                "-e", "undef *Test::Harness::Switches; test_harness(0,lib)", @tests
            ],
            env => {
                PERL_DL_NONLAZY => 1,
                AUTHOR_TESTING  => 0,
                RELEASE_TESTING => 0,
            },
            timeout => $self->cli->test_timeout,
        );

        my $tests_ok = $cmd->run();
        File::Path::rmtree('blib');
        return unless $tests_ok;
    }

    ### install files
    if ( $self->run_install ) {
        my $ok;

        my $install = sub {
            $ok = $self->_builder_play_install_files($BUILD) // 0;
            $ok &= $self->_builder_play_install_bin($BUILD)   // 0;
            $ok &= $self->_builder_play_install_share($BUILD) // 0;
            return;
        };
        App::cplay::Timeout->new(
            message => q[Reach timeout while installing files],
            timeout => $self->cli->install_timeout,
        )->run($install);

        return unless $ok;
    }

    return 1;
}

sub _builder_play_install_bin ( $self, $BUILD ) {
    die "invalid BUILD" unless ref $BUILD eq 'App::cplay::BUILD';
    my $scripts = $BUILD->scripts;
    return 1 unless ref $scripts && scalar @$scripts;

    # setup local lib directory if needed
    if ( my $local_lib_bin = $self->local_lib_bin ) {
        INFO("installing bin to local_lib $local_lib_bin");
        $self->installdirs->bin($local_lib_bin);
    }

    # install the advertised scripts in BUILD.json
    foreach my $script (@$scripts) {
        DEBUG("installing $script");
        $self->installdirs->install_to_bin($script);
    }

    return 1;
}

sub _builder_play_install_share ( $self, $BUILD ) {
    die "invalid BUILD" unless ref $BUILD eq 'App::cplay::BUILD';

    # shortcut
    return 1 unless -d q[share] || -d q[share-module];

    return App::cplay::Installer::Share->new(
        installdirs => $self->installdirs,
        BUILD       => $BUILD,
    )->install;
}

sub _builder_play_install_files ( $self, $BUILD ) {
    my $inst_lib = $self->installdirs->lib;
    unless ( defined $inst_lib && length $inst_lib ) {
        FATAL( "install lib is not defined for " . $self->cli->installdirs . "\n" );
    }

    if ( !-d $inst_lib ) {
        DEBUG("Creating missing directory: $inst_lib");
        File::Path::make_path( $inst_lib, { chmod => 0755, verbose => 0 } ) or FATAL("Fail to create $inst_lib");
    }

    FATAL("inst_lib is missing: $inst_lib") unless -d $inst_lib;

    if ( my $local_lib_lib = $self->local_lib_lib ) {
        INFO("installing to local_lib $local_lib_lib");
        $inst_lib = $local_lib_lib;

        # update installdirs location when using local_lib
        $self->installdirs->lib($local_lib_lib);
    }

    my $has_errors = 0;
    my $wanted     = sub {

        # $File::Find::dir is the current directory name,
        # $_ is the current filename within that directory
        # $File::Find::name is the complete pathname to the file.
        return unless -f $File::Find::name;

        my $destination = $File::Find::name;
        $destination =~ s{^lib/}{};

        eval {
            $self->installdirs->install_to_lib(
                $File::Find::name,    # complete pathname to current file
                $destination
            );
            1;
        } or ++$has_errors;

        return;
    };

    my $umask = Umask::Local->new(0333);    # r/r/r
    File::Find::find( { wanted => $wanted, no_chdir => 1 }, 'lib' );

    return if $has_errors;

    install( "succeeds for " . $BUILD->name );
    return 1;
}

sub _builder_Makefile_PL ( $self, $name ) {
    my $make = App::cplay::Helpers::make_binary();

    my @cmds;

    my $use_dot  = -d 'inc';
    my @test_cmd = ( $^X, $use_dot ? (qw{-I .}) : (), "Makefile.PL" );

    push @cmds, App::cplay::Installer::Command->new(
        log_level => 'configure',
        txt       => "perl " . join( ' ', @test_cmd[ 1 .. $#test_cmd ] ),
        cmd       => [@test_cmd],
        timeout   => $self->cli->configure_timeout,
    );

    push @cmds, App::cplay::Installer::Command->new(
        log_level => 'build',
        txt       => "make",
        cmd       => $make,
        timeout   => $self->cli->build_timeout,
    );

    if ( $self->cli->run_tests ) {
        push @cmds, App::cplay::Installer::Command->new(
            log_level => 'test',
            txt       => "make test",
            cmd       => [ $make, "test" ],
            timeout   => $self->cli->test_timeout,

        );
    }

    if ( $self->run_install ) {
        push @cmds, App::cplay::Installer::Command->new(
            log_level => 'install',
            txt       => "make install",
            cmd       => [ $make, "install" ],
            timeout   => $self->cli->install_timeout,
        );
    }

    foreach my $cmd (@cmds) {
        return unless $cmd->run();
    }

    return 1;
}

sub _builder_Build ( $self, $name ) {

    my @cmds;
    push @cmds, App::cplay::Installer::Command->new(
        log_level => 'configure',
        txt       => "perl Build.PL",
        cmd       => [ $^X, "Build.PL" ],
        timeout   => $self->cli->configure_timeout,
    );

    push @cmds, App::cplay::Installer::Command->new(
        log_level => 'build',
        cmd       => "./Build",
        timeout   => $self->cli->configure_timeout,
    );

    if ( $self->cli->run_tests ) {
        push @cmds, App::cplay::Installer::Command->new(
            log_level => 'test',
            cmd       => [ "./Build", "test" ],
            timeout   => $self->cli->test_timeout,
        );
    }

    if ( $self->run_install ) {
        push @cmds, App::cplay::Installer::Command->new(
            log_level => 'install',
            cmd       => [ "./Build", "install" ],
            timeout   => $self->cli->install_timeout,
        );
    }

    foreach my $cmd (@cmds) {
        return unless $cmd->run();
    }

    return 1;
}

sub resolve_dependencies ( $self, $name ) {
    my $BUILD = $self->BUILD->{$name} or die;

    # FIXME is the list complete ? more .. maybe some conditionals
    my @order = qw{requires_build requires_runtime};

    # requires_develop recommends
    # maybe --with-recommends
    ## --no-tests -n requires_test

    foreach my $type (@order) {
        my $requires_list = $BUILD->{$type} // {};
        next unless scalar keys %$requires_list;
        resolve("$type for $name");
        foreach my $module ( sort keys %$requires_list ) {
            my $version = $requires_list->{$module};
            resolve("\t$name $type $module v$version");
            return unless $self->install_single_module( $module, $version );
        }
    }

    return 1;
}

# this sets the BUILD entry for the repository
sub setup_tarball ( $self, $repository_info ) {

    my $name = $repository_info->{repository};

    # download & extract tarball
    my $tarball = $self->download_repository($repository_info);
    return unless defined $tarball;

    my $relative_path = $self->unpacker->unpack($tarball);
    my $full_path     = $self->cli->build_dir . '/' . $relative_path;
    if ( !defined $relative_path || !-d $full_path ) {
        FAIL("fail to extract tarball $tarball");
        return;
    }

    my $dir = pushd($full_path);

    # load BUILD.json
    return unless $self->load_BUILD_json;

    return 1;
}

sub load_BUILD_json($self) {

    return unless my $BUILD = App::cplay::BUILD::create_from_file('BUILD.json');
    $self->BUILD->{ $BUILD->name } = $BUILD;    # store the BUILD informations

    return $BUILD;
}

sub download_repository ( $self, $repository_info ) {
    my $cli = $self->cli                                                or die;
    my $url = $cli->repositories_idx->get_tarball_url($repository_info) or die;

    fetch($url);
    my $name = $repository_info->{repository};
    my $sha  = $repository_info->{sha};

    my $tarball = "${name}.tar.gz";
    my $path    = $cli->build_dir . "/$tarball";

    unlink $path if -e $path;    # clear the tarball if it already exists

    $cli->http->mirror( $url, $path );

    if ( !-e $path ) {
        DEBUG("Fail to download tarball from $url");
        return;
    }

    # check signature
    my $signature = $repository_info->{signature};
    if ( $self->cli->check_signature && defined $signature ) {
        if ( !check_signature( $path, $signature ) ) {
            ERROR("Signature mismatch for $tarball expect: $signature");
            return;
        }
        DEBUG("signature OK for $tarball = $signature");
    }

    return $path;
}

sub tracking_module ( $self, $module ) {
    die unless defined $module;
    $module =~ s{\@.+$}{};    # strip the version
    return 1 if $self->{_tracked_modules}->{$module};
    $self->{_tracked_modules}->{$module} = 1;
    return;
}

sub tracking_repository ( $self, $repository ) {
    die unless defined $repository;
    $repository =~ s{\@.+$}{};    # strip the version
    return 1 if $self->{_tracked_repositories}->{$repository};
    $self->{_tracked_repositories}->{$repository} = 1;
    return;
}

1;
