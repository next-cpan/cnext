package App::cplay::cli;

use App::cplay::std;

# use App::cpm::DistNotation;
# use App::cpm::Distribution;
# use App::cpm::Logger::File;
# use App::cpm::Logger;
# use App::cpm::Master;
# use App::cpm::Requirement;
# use App::cpm::Resolver::Cascade;
# use App::cpm::Resolver::MetaCPAN;
# use App::cpm::Resolver::MetaDB;
# use App::cpm::Util qw(WIN32 determine_home maybe_abs);
# use App::cpm::Worker;
# use App::cpm::version;

use App::cplay ();
use Cwd        ();

# need to load all commands to fatpack them
use App::cplay::cmd::help    ();
use App::cplay::cmd::version ();

#use Config;
# use File::Copy ();
# use File::Path ();
# use File::Spec;
use Getopt::Long qw(:config no_auto_abbrev no_ignore_case bundling);
use Pod::Text ();

# use List::Util ();
# use Parallel::Pipes;

sub new ( $class, %options ) {

    return bless {

        #home => determine_home,
        cwd               => Cwd::cwd(),
        snapshot          => "cpanfile.snapshot",
        cpanfile          => "cpanfile",
        local_lib         => "local",
        retry             => 1,
        configure_timeout => 60,
        build_timeout     => 3600,
        test_timeout      => 1800,

        # with_requires => 1,
        # with_recommends => 0,
        # with_suggests => 0,
        # with_configure => 0,
        # with_build => 1,
        # with_test => 1,
        # with_runtime => 1,
        # with_develop => 0,

        # feature => [],
        notest => 1,

        #        prebuilt => $] >= 5.012 && $prebuilt,
        #        pureperl_only => 0,
        #        static_install => 1,
        %options
    }, $class;
}

sub parse_options ( $self, @opts ) {
    local @ARGV = @opts;

    my ( $mirror, @resolver, @feature );
    my $with_option = sub {
        my $n = shift;
        ( "with-$n", \$self->{"with_$n"}, "without-$n", sub { $self->{"with_$n"} = 0 } );
    };

    GetOptions(
        "L|local-lib-contained=s"   => \( $self->{local_lib} ),
        "color!"                    => \( $self->{color} ),
        "g|global"                  => \( $self->{global} ),
        "mirror=s"                  => \$mirror,
        "v|verbose"                 => \( $self->{verbose} ),
        "w|workers=i"               => \( $self->{workers} ),
        "target-perl=s"             => \my $target_perl,
        "test!"                     => sub { $self->{notest} = $_[1] ? 0 : 1 },
        "cpanfile=s"                => \( $self->{cpanfile} ),
        "snapshot=s"                => \( $self->{snapshot} ),
        "sudo"                      => \( $self->{sudo} ),
        "r|resolver=s@"             => \@resolver,
        "mirror-only"               => \( $self->{mirror_only} ),
        "dev"                       => \( $self->{dev} ),
        "man-pages"                 => \( $self->{man_pages} ),
        "home=s"                    => \( $self->{home} ),
        "retry!"                    => \( $self->{retry} ),
        "exclude-vendor!"           => \( $self->{exclude_vendor} ),
        "configure-timeout=i"       => \( $self->{configure_timeout} ),
        "build-timeout=i"           => \( $self->{build_timeout} ),
        "test-timeout=i"            => \( $self->{test_timeout} ),
        "show-progress!"            => \( $self->{show_progress} ),
        "prebuilt!"                 => \( $self->{prebuilt} ),
        "reinstall"                 => \( $self->{reinstall} ),
        "pp|pureperl|pureperl-only" => \( $self->{pureperl_only} ),
        "static-install!"           => \( $self->{static_install} ),
        ( map $with_option->($_), qw(requires recommends suggests) ),
        ( map $with_option->($_), qw(configure build test runtime develop) ),
        "feature=s@"                => \@feature,
        "show-build-log-on-failure" => \( $self->{show_build_log_on_failure} ),
    ) or exit 1;

    #$self->{local_lib} = maybe_abs($self->{local_lib}, $self->{cwd}) unless $self->{global};
    #$self->{home} = maybe_abs($self->{home}, $self->{cwd});
    $self->{resolver}      = \@resolver;
    $self->{feature}       = \@feature if @feature;
    $self->{mirror}        = $self->normalize_mirror($mirror) if $mirror;
    $self->{color}         = 1 if !defined $self->{color} && -t STDOUT;
    $self->{show_progress} = 1 if !defined $self->{show_progress} && -t STDOUT;

    if ( $self->{sudo} ) {
        !system "sudo", $^X, "-e1" or exit 1;
    }

    $App::cplay::Logger::COLOR         = 1 if $self->{color};
    $App::cplay::Logger::VERBOSE       = 1 if $self->{verbose};
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

# sub _core_inc {
#     my $self = shift;
#     [
#         (!$self->{exclude_vendor} ? grep {$_} @Config{qw(vendorarch vendorlibexp)} : ()),
#         @Config{qw(archlibexp privlibexp)},
#     ];
# }

# sub _search_inc {
#     my $self = shift;
#     return \@INC if $self->{global};

#     my $base = $self->{local_lib};
#     require local::lib;
#     my @local_lib = (
#         local::lib->resolve_path(local::lib->install_base_arch_path($base)),
#         local::lib->resolve_path(local::lib->install_base_perl_path($base)),
#     );
#     if ($self->{target_perl}) {
#         return [@local_lib];
#     } else {
#         return [@local_lib, @{$self->_core_inc}];
#     }
# }

sub normalize_mirror ( $self, $mirror ) {
    $mirror =~ s{/*$}{/};

    return $mirror if $mirror =~ m{^https?://};

    die qq[Invalid mirror: $mirror];
}

sub run ( $self, @argv ) {
    my $cmd = shift @argv // 'help';

    $cmd =~ s{^-+}{};

    # command aliases
    my $aliases = {
        h => 'help',
        v => 'version',
        V => 'version',
        i => 'install',
    };

    $cmd = $aliases->{$cmd} if defined $aliases->{$cmd};

    die qq[Invalid subcommand '$cmd' try `$0 --help`\n] unless $cmd =~ m{^[A-Za-z0-9_]+$};

    my $run = "App::cplay::cmd::$cmd"->can('run');
    die qq[Unknown subcommand '$cmd'] unless defined $run && ref $run eq 'CODE';

    $self->parse_options(@argv);

    ## maybe do an extra parse_options for every commands?

    return $run->($self);
}

# sub cmd_install {
#     my $self = shift;
#     die "Need arguments or cpanfile.\n"
#         if !@{$self->{argv}} && (!$self->{cpanfile} || !-f $self->{cpanfile});

#     local %ENV = %ENV;

#     File::Path::mkpath($self->{home}) unless -d $self->{home};
#     my $logger = App::cpm::Logger::File->new("$self->{home}/build.log.@{[time]}");
#     $logger->symlink_to("$self->{home}/build.log");
#     $logger->log("Running cpm $App::cpm::VERSION ($0) on perl $Config{version} built for $Config{archname} ($^X)");
#     $logger->log("This is a self-contained version, $App::cpm::GIT_DESCRIBE ($App::cpm::GIT_URL)") if $App::cpm::GIT_DESCRIBE;
#     $logger->log("Command line arguments are: @ARGV");

#     my $master = App::cpm::Master->new(
#         logger => $logger,
#         core_inc => $self->_core_inc,
#         search_inc => $self->_search_inc,
#         global => $self->{global},
#         show_progress => $self->{show_progress},
#         (exists $self->{target_perl} ? (target_perl => $self->{target_perl}) : ()),
#     );

#     my ($packages, $dists, $resolver) = $self->initial_job($master);
#     return 0 unless $packages;

#     my $worker = App::cpm::Worker->new(
#         verbose   => $self->{verbose},
#         home      => $self->{home},
#         logger    => $logger,
#         notest    => $self->{notest},
#         sudo      => $self->{sudo},
#         resolver  => $self->generate_resolver($resolver),
#         man_pages => $self->{man_pages},
#         retry     => $self->{retry},
#         prebuilt  => $self->{prebuilt},
#         pureperl_only => $self->{pureperl_only},
#         static_install => $self->{static_install},
#         configure_timeout => $self->{configure_timeout},
#         build_timeout     => $self->{build_timeout},
#         test_timeout      => $self->{test_timeout},
#         ($self->{global} ? () : (local_lib => $self->{local_lib})),
#     );

#     {
#         last if $] >= 5.016;
#         my $requirement = App::cpm::Requirement->new('ExtUtils::MakeMaker' => '6.58', 'ExtUtils::ParseXS' => '3.16');
#         for my $name ('ExtUtils::MakeMaker', 'ExtUtils::ParseXS') {
#             if (my ($i) = grep { $packages->[$_]{package} eq $name } 0..$#{$packages}) {
#                 $requirement->add($name, $packages->[$i]{version_range})
#                     or die sprintf "We have to install newer $name first: $@\n";
#                 splice @$packages, $i, 1;
#             }
#         }
#         my ($is_satisfied, @need_resolve) = $master->is_satisfied($requirement->as_array);
#         last if $is_satisfied;
#         $master->add_job(type => "resolve", %$_) for @need_resolve;

#         $self->install($master, $worker, 1);
#         if (my $fail = $master->fail) {
#             local $App::cpm::Logger::VERBOSE = 0;
#             for my $type (qw(install resolve)) {
#                 App::cpm::Logger->log(result => "FAIL", type => $type, message => $_) for @{$fail->{$type}};
#             }
#             print STDERR "\r" if $self->{show_progress};
#             warn sprintf "%d distribution%s installed.\n",
#                 $master->installed_distributions, $master->installed_distributions > 1 ? "s" : "";
#             if ($self->{show_build_log_on_failure}) {
#                 File::Copy::copy($logger->file, \*STDERR);
#             } else {
#                 warn "See $self->{home}/build.log for details.\n";
#             }
#             return 1;
#         }
#     }

#     $master->add_job(type => "resolve", %$_) for @$packages;
#     $master->add_distribution($_) for @$dists;
#     $self->install($master, $worker, $self->{workers});
#     my $fail = $master->fail;
#     if ($fail) {
#         local $App::cpm::Logger::VERBOSE = 0;
#         for my $type (qw(install resolve)) {
#             App::cpm::Logger->log(result => "FAIL", type => $type, message => $_) for @{$fail->{$type}};
#         }
#     }
#     print STDERR "\r" if $self->{show_progress};
#     warn sprintf "%d distribution%s installed.\n",
#         $master->installed_distributions, $master->installed_distributions > 1 ? "s" : "";
#     $self->cleanup;

#     if ($fail) {
#         if ($self->{show_build_log_on_failure}) {
#             File::Copy::copy($logger->file, \*STDERR);
#         } else {
#             warn "See $self->{home}/build.log for details.\n";
#         }
#         return 1;
#     } else {
#         return 0;
#     }
# }

# sub install {
#     my ($self, $master, $worker, $num) = @_;

#     my $pipes = Parallel::Pipes->new($num, sub {
#         my $job = shift;
#         return $worker->work($job);
#     });
#     my $get_job; $get_job = sub {
#         my $master = shift;
#         if (my @job = $master->get_job) {
#             return @job;
#         }
#         if (my @written = $pipes->is_written) {
#             my @ready = $pipes->is_ready(@written);
#             $master->register_result($_->read) for @ready;
#             return $master->$get_job;
#         } else {
#             return;
#         }
#     };
#     while (my @job = $master->$get_job) {
#         my @ready = $pipes->is_ready;
#         $master->register_result($_->read) for grep $_->is_written, @ready;
#         for my $i (0 .. List::Util::min($#job, $#ready)) {
#             $job[$i]->in_charge(1);
#             $ready[$i]->write($job[$i]);
#         }
#     }
#     $pipes->close;
# }

# sub cleanup {
#     my $self = shift;
#     my $week = time - 7*24*60*60;
#     my @entry = glob "$self->{home}/build.log.*";
#     if (opendir my $dh, "$self->{home}/work") {
#         push @entry,
#             map File::Spec->catdir("$self->{home}/work", $_),
#             grep !/^\.{1,2}$/,
#             readdir $dh;
#     }
#     for my $entry (@entry) {
#         my $mtime = (stat $entry)[9];
#         if ($mtime < $week) {
#             if (-d $entry) {
#                 File::Path::rmtree($entry);
#             } else {
#                 unlink $entry;
#             }
#         }
#     }
# }

# sub initial_job {
#     my ($self, $master) = @_;

#     my (@package, @dist, $resolver);

#     if (!@{$self->{argv}}) {
#         my ($requirement, $reinstall);
#         ($requirement, $reinstall, $resolver) = $self->load_cpanfile($self->{cpanfile});
#         my ($is_satisfied, @need_resolve) = $master->is_satisfied($requirement);
#         if (!@$reinstall and $is_satisfied) {
#             warn "All requirements are satisfied.\n";
#             return;
#         } elsif (!defined $is_satisfied) {
#             my ($req) = grep { $_->{package} eq "perl" } @$requirement;
#             die sprintf "%s requires perl %s, but you have only %s\n",
#                 $self->{cpanfile}, $req->{version_range}, $self->{target_perl} || $];
#         }
#         push @package, @need_resolve, @$reinstall;
#         return (\@package, \@dist, $resolver);
#     }

#     $self->{mirror} ||= $self->{_default_mirror};
#     for (@{$self->{argv}}) {
#         my $arg = $_; # copy
#         my ($package, $dist);
#         if (-d $arg || -f $arg || $arg =~ s{^file://}{}) {
#             $arg = maybe_abs($arg, $self->{cwd});
#             $dist = App::cpm::Distribution->new(source => "local", uri => "file://$arg", provides => []);
#         } elsif ($arg =~ /(?:^git:|\.git(?:@.+)?$)/) {
#             my %ref = $arg =~ s/(?<=\.git)@(.+)$// ? (ref => $1) : ();
#             $dist = App::cpm::Distribution->new(source => "git", uri => $arg, provides => [], %ref);
#         } elsif ($arg =~ m{^(https?|file)://}) {
#             my ($source, $distfile) = ($1 eq "file" ? "local" : "http", undef);
#             if (my $d = App::cpm::DistNotation->new_from_uri($arg)) {
#                 ($source, $distfile) = ("cpan", $d->distfile);
#             }
#             $dist = App::cpm::Distribution->new(
#                 source => $source,
#                 uri => $arg,
#                 $distfile ? (distfile => $distfile) : (),
#                 provides => [],
#             );
#         } elsif (my $d = App::cpm::DistNotation->new_from_dist($arg)) {
#             $dist = App::cpm::Distribution->new(
#                 source => "cpan",
#                 uri => $d->cpan_uri($self->{mirror}),
#                 distfile => $d->distfile,
#                 provides => [],
#             );
#         } else {
#             my ($name, $version_range, $dev);
#             # copy from Menlo
#             # Plack@1.2 -> Plack~"==1.2"
#             $arg =~ s/^([A-Za-z0-9_:]+)@([v\d\._]+)$/$1~== $2/;
#             # support Plack~1.20, DBI~"> 1.0, <= 2.0"
#             if ($arg =~ /\~[v\d\._,\!<>= ]+$/) {
#                 ($name, $version_range) = split '~', $arg, 2;
#             } else {
#                 $arg =~ s/[~@]dev$// and $dev++;
#                 $name = $arg;
#             }
#             $package = +{
#                 package => $name,
#                 version_range => $version_range || 0,
#                 dev => $dev,
#                 reinstall => $self->{reinstall},
#             };
#         }
#         push @package, $package if $package;
#         push @dist, $dist if $dist;
#     }

#     return (\@package, \@dist, $resolver);
# }

sub load_cpanfile {
    my ( $self, $file ) = @_;
    require Module::CPANfile;
    my $cpanfile = Module::CPANfile->load($file);
    if ( !$self->{mirror} ) {
        my $mirrors = $cpanfile->mirrors;
        if (@$mirrors) {
            $self->{mirror} = $self->normalize_mirror( $mirrors->[0] );
        }
        else {
            $self->{mirror} = $self->{_default_mirror};
        }
    }
    my $prereqs = $cpanfile->prereqs_with( @{ $self->{"feature"} } );
    my @phase   = grep $self->{"with_$_"}, qw(configure build test runtime develop);
    my @type    = grep $self->{"with_$_"}, qw(requires recommends suggests);
    my $reqs    = $prereqs->merged_requirements( \@phase, \@type )->as_string_hash;

    my ( @package, @reinstall );
    for my $package ( sort keys %$reqs ) {
        my $option = $cpanfile->options_for_module($package) || {};
        my $req    = {
            package       => $package,
            version_range => $reqs->{$package},
            dev           => $option->{dev},
            reinstall     => $option->{git} ? 1 : 0,
        };
        if ( $option->{git} ) {
            push @reinstall, $req;
        }
        else {
            push @package, $req;
        }
    }

    require App::cpm::Resolver::CPANfile;
    my $resolver = App::cpm::Resolver::CPANfile->new(
        cpanfile => $cpanfile,
        mirror   => $self->{mirror},
    );

    ( \@package, \@reinstall, $resolver );
}

# sub generate_resolver {
#     my ($self, $initial) = @_;

#     my $cascade = App::cpm::Resolver::Cascade->new;
#     $cascade->add($initial) if $initial;
#     if (@{$self->{resolver}}) {
#         for (@{$self->{resolver}}) {
#             my ($klass, @arg) = split /,/, $_;
#             my $resolver;
#             if ($klass =~ /^metadb$/i) {
#                 my ($uri, $mirror);
#                 if (@arg > 1) {
#                     ($uri, $mirror) = @arg;
#                 } elsif (@arg == 1) {
#                     $mirror = $arg[0];
#                 } else {
#                     $mirror = $self->{mirror};
#                 }
#                 $resolver = App::cpm::Resolver::MetaDB->new(
#                     $uri ? (uri => $uri) : (),
#                     mirror => $self->normalize_mirror($mirror),
#                 );
#             } elsif ($klass =~ /^metacpan$/i) {
#                 $resolver = App::cpm::Resolver::MetaCPAN->new(dev => $self->{dev});
#             } elsif ($klass =~ /^02packages?$/i) {
#                 require App::cpm::Resolver::02Packages;
#                 my ($path, $mirror);
#                 if (@arg > 1) {
#                     ($path, $mirror) = @arg;
#                 } elsif (@arg == 1) {
#                     $mirror = $arg[0];
#                 } else {
#                     $mirror = $self->{mirror};
#                 }
#                 $resolver = App::cpm::Resolver::02Packages->new(
#                     $path ? (path => $path) : (),
#                     cache => "$self->{home}/sources",
#                     mirror => $self->normalize_mirror($mirror),
#                 );
#             } elsif ($klass =~ /^snapshot$/i) {
#                 require App::cpm::Resolver::Snapshot;
#                 $resolver = App::cpm::Resolver::Snapshot->new(
#                     path => $self->{snapshot},
#                     mirror => @arg ? $self->normalize_mirror($arg[0]) : $self->{mirror},
#                 );
#             } else {
#                 die "Unknown resolver: $klass\n";
#             }
#             $cascade->add($resolver);
#         }
#         return $cascade;
#     }

#     if ($self->{mirror_only}) {
#         require App::cpm::Resolver::02Packages;
#         my $resolver = App::cpm::Resolver::02Packages->new(
#             mirror => $self->{mirror},
#             cache => "$self->{home}/sources",
#         );
#         $cascade->add($resolver);
#         return $cascade;
#     }

#     if (!@{$self->{argv}} and -f $self->{snapshot}) {
#         if (!eval { require App::cpm::Resolver::Snapshot }) {
#             die "To load $self->{snapshot}, you need to install Carton::Snapshot.\n";
#         }
#         warn "Loading distributions from $self->{snapshot}...\n";
#         my $resolver = App::cpm::Resolver::Snapshot->new(
#             path => $self->{snapshot},
#             mirror => $self->{mirror},
#         );
#         $cascade->add($resolver);
#     }

#     my $resolver = App::cpm::Resolver::MetaCPAN->new(
#         $self->{dev} ? (dev => 1) : (only_dev => 1)
#     );
#     $cascade->add($resolver);
#     $resolver = App::cpm::Resolver::MetaDB->new(
#         uri => $self->{cpanmetadb},
#         mirror => $self->{mirror},
#     );
#     $cascade->add($resolver);
#     if (!$self->{dev}) {
#         $resolver = App::cpm::Resolver::MetaCPAN->new;
#         $cascade->add($resolver);
#     }

#     $cascade;
# }

1;
