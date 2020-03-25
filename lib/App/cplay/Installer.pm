package App::cplay::Installer;

use App::cplay::std;

use App::cplay;
use App::cplay::Logger;    # import all
use App::cplay::Module;

use App::cplay::Installer::Unpacker ();

use App::cplay::Helpers qw{read_file};

use Test::More;            # Auto-removed

use File::pushd;
use IPC::Run3 ();

App::cplay::Logger->import(qw{fetch configure install resolve});

use Simple::Accessor qw{cli unpacker json BUILD};

use constant EXTUTILS_MAKEMAKER_MIN_VERSION => '6.64';

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

# FIXME to improve: logfile and output...
sub run3 ( $cmd, $outfile = undef ) {    # FIXME maybe move to helpers
    my $out;
    IPC::Run3::run3 $cmd, \undef, ( $outfile ? $outfile : \$out ), \my $err;

    return ( $?, $out, $err );
}

sub check_makemaker($self) {
    my $module  = 'ExtUtils::MakeMaker';
    my $version = EXTUTILS_MAKEMAKER_MIN_VERSION;

    return 1 if has_module_version( $module, $version );

    WARN("Trying to update ExtUtils::MakeMaker");

    # install the last available version
    my $ok = $self->install_single_module_or_repository($module);

    if ( !$ok ) {
        ERROR("Please update ExtUtils::MakeMaker to $version or later");
        return;
    }

    return $ok;
}

sub install_single_module ( $self, $module ) {
    return $self->install_single_module_or_repository( $module, 0 );
}

sub install_single_module_or_repository ( $self, $module_or_repository, $can_be_repo = 1 ) {

    # are we already trying to install this module?
    return 1 if $self->tracking_module($module_or_repository);

    my $cli = $self->cli or die;

    my $custom_requested_version;
    if ( $module_or_repository =~ s{\@(.+)$}{} ) {
        $custom_requested_version = $1;

        #DEBUG("requested $module_or_repository version $custom_requested_version");
    }

    # search the latest module from modules.ix file
    # 1 - lookup for module
    my $module_info = $cli->modules_idx->search( $module_or_repository, $custom_requested_version );
    my $repository_info;

    # 2 - lookup for distribution
    if ( !$module_info && index( $module_or_repository, ':' ) == -1 && $can_be_repo ) {
        $repository_info = $cli->repositories_idx->search( $module_or_repository, $custom_requested_version );
    }

    # 3 - lookup in the explicitversons file if needed
    if ( !$module_info && !$repository_info && defined $custom_requested_version ) {
        my $raw = $cli->explicit_versions_idx->search( $module_or_repository, $custom_requested_version, $can_be_repo );

        if ( !defined $raw ) {
            FAIL("Cannot find module or distribution for $module_or_repository\@$custom_requested_version");
            return;
        }

        # check if module is already installed
        return 1 if has_module_version( $raw->{module}, $raw->{version} );

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
        return 1 if has_module_version( $module_info->{module}, $module_info->{version} );
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
    return unless $self->resolve_dependencies($name);

    my $BUILD = $self->BUILD->{$name} or die;
    my $indir = pushd( $BUILD->{_rootdir} );

    return unless $self->do_configure($name);
    return unless $self->do_install($name);

    # ... FIXME also flag all new provided modules

    DONE("Installed Distribution $name");

    return 1;
}

sub do_install ( $self, $name ) {

    my $make = App::cplay::Helpers::make_binary();

    {
        install("Running make for $name");

        my ( $status, $out, $err ) = run3("$make");    # FIXME which make gmake...
        if ( $status != 0 ) {
            ERROR("Fail to build $name");
            WARN($out)    if defined $out;
            ERROR("$err") if defined $out;
            return;
        }
        DEBUG("make output:\n$out");
    }

    {
        install("Running Tests for $name");            # FIXME unless test are disabled

        my ( $status, $out, $err ) = run3("$make test");
        if ( $status != 0 ) {
            ERROR("Test failure from $name");
            WARN($out)    if defined $out;
            ERROR("$err") if defined $out;
            return;
        }
        DEBUG("Test run $name output:\n$out");
    }

    # FIXME use IPC view unpacker
    {
        install("succeeds for $name");

        my ( $status, $out, $err ) = run3("$make install");
        if ( $status != 0 ) {
            ERROR("Fail to install $name");
            WARN($out)    if defined $out;
            ERROR("$err") if defined $out;
            return;
        }
        DEBUG("Make install output $name:\n$out");
    }

    return 1;
}

sub do_configure ( $self, $name ) {
    my $BUILD = $self->BUILD->{$name} or die;

    configure("Generate Makefile.PL for $name");

    $self->generate_makefile_pl($BUILD);

    configure("Running Makefile.PL for $name");
    my ( $status, $out, $err ) = run3("$^X Makefile.PL");
    if ( $status != 0 ) {
        ERROR("$err");
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
    'TESTS' => 't/*.t'
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

    open( my $fh, '>', 'Makefile.PL' ) or die "Fail to open Makefile.PL $!";

    my %v = (
        CPLAY_VERSION => $App::cplay::VERSION,
        ##
        ABSTRACT      => _sanity( $BUILD->{abstract} ),
        AUTHOR        => _sanity( $BUILD->{maintainers}->[0] ),
        DISTNAME      => _sanity( $BUILD->{name} ),
        LICENSE       => _sanity( $BUILD->{license} ),
        PRIMARY       => _sanity( $BUILD->{primary} ),
        VERSION       => _sanity( $BUILD->{version} ),
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

    fetch("$url");
    my $name = $repository_info->{repository};
    my $sha  = $repository_info->{sha};

    my $local = $cli->builddir . "/${name}.tar.gz";
    $cli->http->mirror( $url, $local );

    return $local;
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
