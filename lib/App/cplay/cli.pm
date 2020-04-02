package App::cplay::cli;

use App::cplay::std;    # import strict, warnings & features

use App::cplay ();
use App::cplay::Logger;    # import all
use App::cplay::Http;

# need to load all commands to fatpack them
use App::cplay::cmd::cpanfile ();
use App::cplay::cmd::help     ();
use App::cplay::cmd::install  ();
use App::cplay::cmd::version  ();

use App::cplay::Index::Repositories;
use App::cplay::Index::Modules;
use App::cplay::Index::ExplicitVersions;

use Cwd ();

use Simple::Accessor qw{
  name
  http
  cwd homedir build_dir cache_dir
  local_lib
  snapshot
  retry
  configure_timeout build_timeout test_timeout install_timeout

  check_signature

  refresh
  run_tests

  features

  reinstall debug verbose

  repositories_idx
  modules_idx
  explicit_versions_idx

};

use File::Path qw(mkpath rmtree);

use Getopt::Long qw(:config no_auto_abbrev no_ignore_case bundling);
use Pod::Text ();

# use List::Util ();
# use Parallel::Pipes;

sub build ( $self, %options ) {

    foreach my $k ( sort keys %options ) {
        $self->{$k} = $options{$k};    # could also use the accessor
    }

    $self->cwd;                        # setup CWD asap

    # defaults values
    my $defaults = {
        check_signature => 1,

        # --with
        with_requires   => 1,
        with_recommends => 0,
        with_suggests   => 0,
        with_configure  => 0,
        with_build      => 1,
        with_test       => 1,
        with_runtime    => 1,
        with_develop    => 0,
    };
    foreach my $k ( sort %$defaults ) {
        $self->{$k} //= $defaults->{$k};
    }

    $self->{features} = [];

    return $self;
}

sub _build_cwd {
    return Cwd::cwd();
}

sub _build_homedir {
    $ENV{HOME} or die q[HOME environmenet variable not set];
}

# we are storing everythink in that directory
#   can be customized using --cache-dir
sub _build_cache_dir($self) {
    my $path = $self->homedir . '/.cplay';
    return $path if -d $path;
    mkpath($path) or FATAL("Fail to create ~/.cplay cache directory directory at: $path");
    return $path;
}

sub _build_build_dir($self) {
    my $path = $self->cache_dir . '/build';

    return $path if -d $path;
    mkpath($path) or die "fail to create build directory at: $path";

    return $path;
}

sub DESTROY($self) {

    # use on purpose the hash accessor to avoid creating the directory on DESTROY
    if ( ref $self && $self->{builddir} && $self->{cleanup} ) {
        my $dir = $self->{builddir};
        if ( -d $dir && !-l $dir ) {
            DEBUG("rmtree .build directory: $dir");
            File::Path::rmtree($dir);
        }
    }
}

sub _build_retry             { 1 }
sub _build_configure_timeout { 60 }
sub _build_install_timeout   { 60 }
sub _build_build_timeout     { 3_600 }
sub _build_test_timeout      { 1_800 }

sub _build_http {
    App::cplay::Http->create;    # FIXME maybe some args
}

sub _build_repositories_idx($self) {
    App::cplay::Index::Repositories->new( cli => $self );
}

sub _build_modules_idx($self) {
    App::cplay::Index::Modules->new( cli => $self );
}

sub _build_explicit_versions_idx($self) {
    App::cplay::Index::ExplicitVersions->new( cli => $self );
}

sub parse_options ( $self, @opts ) {
    local @ARGV = @opts;

    my ( $mirror, @feature );
    my $with_option = sub {
        my $n = shift;
        ( "with-$n", \$self->{"with_$n"}, "without-$n", sub { $self->{"with_$n"} = 0 } );
    };

    my @with_types  = qw(requires recommends suggests);
    my @with_phases = qw(configure build test runtime develop);

    GetOptions(

        # used
        "color!"            => \( $self->{color} ),
        'cleanup!'          => \( $self->{cleanup} ),
        "cache|cache-dir=s" => \( $self->{cache_dir} ),

        "check-signature!" => \( $self->{check_signature} ),

        'test!'  => \( $self->{run_tests} ),
        'tests!' => \( $self->{run_tests} ),    # allow typo?

        "refresh"   => \( $self->{refresh} ),
        "reinstall" => \( $self->{reinstall} ),

        "v|verbose"     => \( $self->{verbose} ),
        "d|debug"       => \( $self->{debug} ),
        "L|local-lib=s" => \( $self->{local_lib} ),

        "show-progress!" => \( $self->{show_progress} ),

        # used for cpanfile
        "feature=s@" => \@feature,

        ### need to check
        #"L|local-lib-contained=s" => \( $self->{local_lib} ),
        #"g|global"  => \( $self->{global} ),

        #"snapshot=s"  => \( $self->{snapshot} ),
        "sudo" => \( $self->{sudo} ),

        "retry!"          => \( $self->{retry} ),
        "exclude-vendor!" => \( $self->{exclude_vendor} ),

        "configure-timeout=i" => \( $self->{configure_timeout} ),
        "build-timeout=i"     => \( $self->{build_timeout} ),
        "test-timeout=i"      => \( $self->{test_timeout} ),
        "install-timeout=i"   => \( $self->{install_timeout} ),

        "with-all" => sub {
            map { $self->{"with_$_"} = 1 } @with_types, @with_phases;
        },
        ( map $with_option->($_), @with_types ),     # type
        ( map $with_option->($_), @with_phases ),    # phase
    ) or exit 1;

    $self->{mirror} = $self->normalize_mirror($mirror) if $mirror;
    $self->{color}         = 1 if !defined $self->{color}         && -t STDOUT;
    $self->{show_progress} = 1 if !defined $self->{show_progress} && -t STDOUT;

    $self->{show_progress} = 0 if $self->debug;      # no progress on debug
    $self->{show_progress} = 0 unless -t STDIN;

    $self->{features} = \@feature if @feature;

    $self->run_tests(1) unless defined $self->{run_tests};
    if ( !$self->run_tests ) {
        $self->{'with_test'} = 0;
    }

    if ( $self->{sudo} ) {
        !system "sudo", $^X, "-e1" or exit 1;
    }

    if ( defined $self->{local_lib} ) {
        $self->{local_lib} =~ s{^=}{};
        $self->{local_lib} = Cwd::abs_path( $self->local_lib );
    }

    if ( defined $self->{cache_dir} ) {
        $self->{cache_dir} = Cwd::abs_path( $self->cache_dir );
        mkpath( $self->cache_dir ) unless -d $self->cache_dir;
        FATAL( "Cannot find cache directory at " . $self->{cache_dir} ) unless -d $self->cache_dir;
    }

    # debug enable verbose
    $self->{verbose} = 1 if $self->{debug};

    $self->{cleanup} //= 1;

    $App::cplay::Logger::COLOR         = 1 if $self->{color};
    $App::cplay::Logger::VERBOSE       = 1 if $self->{verbose};
    $App::cplay::Logger::DEBUG         = 1 if $self->{debug};
    $App::cplay::Logger::SHOW_PROGRESS = 1 if $self->{show_progress};

    if ( @ARGV && $ARGV[0] eq "-" ) {
        $self->{argv}     = $self->read_argv_from_stdin;
        $self->{cpanfile} = undef;
    }
    else {
        $self->{argv} = \@ARGV;
    }

    return $self;
}

sub read_argv_from_stdin {
    my $self = shift;
    my @argv;
    while ( my $line = <STDIN> ) {
        next if $line !~ /\S/;
        next if $line =~ /^\s*#/;
        $line =~ s/^\s*//;
        $line =~ s/\s*$//;
        push @argv, split /\s+/, $line;
    }
    return \@argv;
}

sub normalize_mirror ( $self, $mirror ) {
    $mirror =~ s{/*$}{/};

    return $mirror if $mirror =~ m{^https?://};

    die qq[Invalid mirror: $mirror];
}

sub get_cmd_sub_for ( $self, $cmd ) {
    return unless defined $cmd;

    $cmd =~ s{^-+}{};

    # command aliases
    my $aliases = {
        h => 'help',
        v => 'version',
        V => 'version',
        i => 'install',
    };

    $cmd = $aliases->{$cmd} if defined $aliases->{$cmd};

    return unless $cmd =~ m{^[A-Za-z0-9_]+$};
    return "App::cplay::cmd::$cmd"->can('run');
}

sub run ( $self, @argv ) {
    my $cmd = '';

    my $run;
    if ( scalar @argv ) {
        if ( $run = $self->get_cmd_sub_for( $argv[0] ) ) {
            $cmd = shift @argv;
        }
        else {
            $run = $self->get_cmd_sub_for('install');
            $cmd = 'install';
        }
    }
    else {
        $run = $self->get_cmd_sub_for('help');
        $cmd = 'help';
    }

    die qq[Unknown subcommand '$cmd'] unless defined $run && ref $run eq 'CODE';

    $self->parse_options(@argv);

    $cmd =~ s{^-+}{} if $cmd;
    ## maybe do an extra parse_options for every commands?
    if ( $cmd && $cmd !~ m{^(?:help|version)$} ) {
        INFO("Running action '$cmd'");
    }

    return $run->( $self, $self->{argv}->@* );
}

1;
