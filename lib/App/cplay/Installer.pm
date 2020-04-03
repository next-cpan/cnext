package App::cplay::Installer;

use App::cplay::std;

use App::cplay;
use App::cplay::Logger;    # import all
use App::cplay::Module ();
use App::cplay::Signature qw{check_signature};

use App::cplay::Installer::Unpacker ();
use App::cplay::IPC                 ();

use App::cplay::Helpers qw{read_file};

use App::cplay::Installer::Command ();

use File::pushd;

App::cplay::Logger->import(qw{fetch configure install resolve});

use Simple::Accessor qw{cli unpacker BUILD depth};

with 'App::cplay::Roles::JSON';

use constant EXTUTILS_MAKEMAKER_MIN_VERSION => '6.64';

sub build ( $self, %opts ) {

    $self->{_tracked_modules}      = {};
    $self->{_tracked_repositories} = {};
    $self->{depth}                 = 0;    # starts at 1;

    $self->{BUILD} = {};

    return $self;
}

sub _build_unpacker($self) {
    App::cplay::Installer::Unpacker->new( tmproot => $self->cli->build_dir );
}

sub check_makemaker($self) {
    my $module  = 'ExtUtils::MakeMaker';
    my $version = EXTUTILS_MAKEMAKER_MIN_VERSION;

    # do not use the local helper has_module_version here
    return 1 if App::cplay::Module::has_module_version( $module, $version );

    WARN("Trying to update ExtUtils::MakeMaker");

    # install the last available version
    my $ok = $self->install_single_module_or_repository($module);

    if ( !$ok ) {
        ERROR("Please update ExtUtils::MakeMaker to $version or later");
        return;
    }

    return $ok;
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

sub install_single_module ( $self, $module, $need_version = undef ) {
    return $self->install_single_module_or_repository( $module, 0, $need_version );
}

sub install_single_module_or_repository ( $self, $module_or_repository, $can_be_repo = 1, $need_version = undef ) {

    $self->depth( $self->depth + 1 );

    my $ok;
    if ( defined $need_version ) {
        $ok = $self->has_module_version( $module_or_repository, $need_version );
        DEBUG("Module $module_or_repository v$need_version is missing") unless $ok;
        OK("$module_or_repository is already installed.") if $ok && ( $self->depth == 1 || $self->cli->verbose );
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

    # 3 - lookup in the explicitversons file if needed
    if ( !$module_info && !$repository_info && defined $custom_requested_version ) {
        my $raw = $cli->explicit_versions_idx->search( $module_or_repository, $custom_requested_version, 0, $can_be_repo );

        if ( !defined $raw ) {
            FAIL("Cannot find distribution $module_or_repository\@$custom_requested_version");
            return;
        }

        # will check if module is already installed
        $module_info = { module => $raw->{module}, version => $raw->{version} };

        # convert the result from explicit_versions to repository
        $repository_info = {
            repository => $raw->{repository},
            version    => $raw->{repository_version},
            sha        => $raw->{sha},
            signature  => $raw->{signature},
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

sub check_BUILD_version ( $self, $BUILD ) {
    FATAL("build unset") unless ref $BUILD;

    if ( ( $BUILD->{'builder_API_version'} // 0 ) != 1 ) {

        #... we would like to redirect to Install/Builder/v1.pm, ...
        FATAL("Only know how to handle builder_API_version == 1");
    }

    return 1;
}

sub install_repository ( $self, $repository_info ) {
    die unless ref $repository_info;

    my $name = $repository_info->{repository};
    return 1 if $self->tracking_repository($name);

    INFO("Installing Distribution $name");

    return unless $self->setup_tarball($repository_info);

    # check BUILD sanity state
    my $BUILD = $self->BUILD->{$name} or FATAL("Cannot find a BUILD entry for $name");
    $self->check_BUILD_version($BUILD);

    my $version = $BUILD->{version};

    # check if distribution is already installed
    if ( my $primary = $BUILD->{primary} ) {
        my $module_v = $BUILD->{provides}->{$primary}->{version};    # should not raise warnings?
        if ( $self->has_module_version( $primary, $module_v ) ) {
            OK("$name-$version is up to date.");
            return 1;
        }
    }

    return $self->install_from_BUILD( $BUILD, $name );
}

sub install_from_BUILD ( $self, $BUILD, $name = undef ) {
    $self->check_BUILD_version($BUILD);                              # need to check it again [can be called --from-tarball]

    if ( !defined $name ) {                                          # --from-tarball
        $name = $BUILD->{name};
        $self->BUILD->{$name} = $BUILD;
    }

    my $version = $BUILD->{version};

    return unless $self->resolve_dependencies($name);

    # move to the tmp directory for the next actions
    my $indir = pushd( $BUILD->{_rootdir} );

    my $builder_type = lc( $BUILD->{builder} // 'play' );
    if ( $builder_type eq 'play' ) {
        return unless $self->_builder_play($name);
    }
    elsif ( $builder_type eq 'makefile.pl' ) {
        return unless $self->_builder_Makefile_PL($name);
    }
    elsif ( $builder_type eq 'build' ) {
        return unless $self->_builder_Build($name);
    }
    else {
        FATAL("Unknown builder type '$builder_type' for distribution '$name'");
    }

    $self->advertise_installed_modules($BUILD);

    OK("Installed distribution $name-$version");

    return 1;
}

sub advertise_installed_modules ( $self, $BUILD ) {

    return unless ref $BUILD && ref $BUILD->{provides};

    foreach my $module ( sort keys $BUILD->{provides}->%* ) {
        my $v = $BUILD->{provides}->{$module}->{version};
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

    $ENV{PERL_MM_OPT} .= " INSTALLMAN1DIR=none INSTALLMAN3DIR=none";
    $ENV{PERL_MM_USE_DEFAULT} = 1;

    return;
}

sub _builder_play ( $self, $name ) {

    $self->_setup_local_lib_env();

    return unless $self->do_configure($name);
    return unless $self->do_install($name);

    return 1;
}

sub _builder_Makefile_PL ( $self, $name ) {
    my $make = App::cplay::Helpers::make_binary();

    my @cmds;
    push @cmds, App::cplay::Installer::Command->new(
        type    => 'configure',
        txt     => "perl Makefile.PL",
        cmd     => [ $^X, "Makefile.PL" ],
        timeout => $self->cli->configure_timeout,
    );

    push @cmds, App::cplay::Installer::Command->new(
        type    => 'build',
        txt     => "make",
        cmd     => $make,
        timeout => $self->cli->build_timeout,
    );

    if ( $self->cli->run_tests ) {
        push @cmds, App::cplay::Installer::Command->new(
            type    => 'test',
            txt     => "make test",
            cmd     => [ $make, "test" ],
            timeout => $self->cli->test_timeout,
        );
    }

    push @cmds, App::cplay::Installer::Command->new(
        type    => 'install',
        txt     => "make install",
        cmd     => [ $make, "install" ],
        timeout => $self->cli->install_timeout,
    );

    foreach my $cmd (@cmds) {
        return unless $cmd->run();
    }

    return 1;
}

sub _builder_Build ( $self, $name ) {

    my @cmds;
    push @cmds, App::cplay::Installer::Command->new(
        type    => 'configure',
        txt     => "perl Build.PL",
        cmd     => [ $^X, "Build.PL" ],
        timeout => $self->cli->configure_timeout,
    );

    push @cmds, App::cplay::Installer::Command->new(
        type    => 'build',
        cmd     => "./Build",
        timeout => $self->cli->configure_timeout,
    );

    if ( $self->cli->run_tests ) {
        push @cmds, App::cplay::Installer::Command->new(
            type    => 'test',
            cmd     => [ "./Build", "test" ],
            timeout => $self->cli->test_timeout,
        );
    }

    push @cmds, App::cplay::Installer::Command->new(
        type    => 'install',
        cmd     => [ "./Build", "install" ],
        timeout => $self->cli->install_timeout,
    );

    foreach my $cmd (@cmds) {
        return unless $cmd->run();
    }

    return 1;
}

=pod
## play builder workflow

- prove t/*.t

tests entries from
    https://github.com/pause-play/Abstract-Meta-Class/blob/p5/BUILD.json

- assume that t/boilerplate.t is banned.

- cp lib/* -> Config{sitelib}# or soemthing else on demand --args


BUILD.json
- requires_develop ??
- recommends ???
    perl version ?


=cut

sub do_install ( $self, $name ) {

    my $make = App::cplay::Helpers::make_binary();

    ## perl Makefile.PL move there
    {
        install("Running make for $name");

        my ( $status, $out, $err ) = App::cplay::IPC::run3("$make");
        if ( $status != 0 ) {
            ERROR("Fail to build $name");
            return;
        }
    }

    if ( $self->cli->run_tests ) {
        install("Running Tests for $name");

        my ( $status, $out, $err ) = App::cplay::IPC::run3( [ $make, "test" ] );
        if ( $status != 0 ) {
            ERROR("Test failure from $name");
            return;
        }
    }

    {
        install("succeeds for $name");

        my ( $status, $out, $err ) = App::cplay::IPC::run3( [ $make, "install" ] );
        if ( $status != 0 ) {
            ERROR("Fail to install $name");
            return;
        }
    }

    return 1;
}

sub do_configure ( $self, $name ) {
    my $BUILD = $self->BUILD->{$name} or die;

    configure("Generate Makefile.PL for $name");

    $self->generate_makefile_pl($BUILD);

    configure("Running Makefile.PL for $name");
    my ( $status, $out, $err ) = App::cplay::IPC::run3( [ $^X, "Makefile.PL" ] );
    if ( $status != 0 ) {
        ERROR($err) if defind $err;
        return;
    }

    return 1;
}

sub generate_makefile_pl ( $self, $BUILD ) {
    die unless ref $BUILD;

    my $template = <<'EOS';
# This is generated by cplay v~CPLAY_VERSION~

## ~DISTNAME~ v~VERSION~

use strict;
use warnings;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  'ABSTRACT' => '~ABSTRACT~',
  'AUTHOR' => '~AUTHOR~',
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => 0
  },
  'DISTNAME' => '~DISTNAME~',
  'LICENSE' => '~LICENSE~',
  'NAME' => '~PRIMARY~',
  'PREREQ_PM' => {
~PREREQ_PM~
  },
  'TEST_REQUIRES' => {
~TEST_REQUIRES~
  },
  'VERSION' => '~VERSION~',
  'test' => {
    'TESTS' => '~TESTS~'
  }
);

WriteMakefile(%WriteMakefileArgs);
EOS

    my %PMs;

    {    # build the PMs list
        my @requires_type = qw{requires_build requires_runtime};
        foreach my $type (@requires_type) {
            my $requires_list = $BUILD->{$type} // {};
            $PMs{$type} = '';
            next unless scalar keys %$requires_list;
            foreach my $module ( sort keys %$requires_list ) {
                my $version = $requires_list->{$module};
                $PMs{$type} .= "     '" . _sanity($module) . "' => $version,\n";
            }
        }
    }

    my $tests = 't/*.t';    # default tests to run
    if (   defined $BUILD->{tests}
        && ref $BUILD->{tests} eq 'ARRAY'
        && scalar $BUILD->{tests}->@* ) {
        $tests = join( ' ', $BUILD->{tests}->@* );
    }

    open( my $fh, '>', 'Makefile.PL' ) or die "Fail to open Makefile.PL $!";

    my %v = (
        CPLAY_VERSION => $App::cplay::VERSION,
        ##
        ABSTRACT => _sanity( $BUILD->{abstract} ),
        AUTHOR   => _sanity( $BUILD->{maintainers}->[0] ),
        DISTNAME => _sanity( $BUILD->{name} ),
        LICENSE  => _sanity( $BUILD->{license} ),
        PRIMARY  => _sanity( $BUILD->{primary} ),
        VERSION  => _sanity( $BUILD->{version} ),

        TESTS => $tests,

        PREREQ_PM     => $PMs{requires_runtime},
        TEST_REQUIRES => $PMs{requires_build},
    );

    $template =~ s{~([A-Za-z_]+)~}{$v{$1}}g;

    print {$fh} $template or return;

    return 1;
}

sub _sanity($str) {
    $str =~ s{\n}{}g;
    $str =~ s{'}{\\'}g;

    return $str;
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
    my $BUILD;
    if ( -e 'BUILD.json' ) {
        eval      { $BUILD = $self->json->decode( read_file( 'BUILD.json', ':utf8' ) ); 1 }
          or eval { $BUILD = $self->json->decode( read_file( 'BUILD.json', '' ) );      1 }
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

    fetch($url);
    my $name = $repository_info->{repository};
    my $sha  = $repository_info->{sha};

    my $tarball = "${name}.tar.gz";
    my $path    = $cli->build_dir . "/$tarball";

    $cli->http->mirror( $url, $path );

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
