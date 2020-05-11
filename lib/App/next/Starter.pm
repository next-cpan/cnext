package App::next::Starter;

use App::next::std;

use App::next::Logger;    # import all
use App::next::Helpers qw{write_file};

use Simple::Accessor qw{
  distribution module
  primary_dir primary_file
  BUILD root_directory
};

use App::next::BUILD ();
use File::Copy       ();  # CORE
use File::Path qw(make_path);    # CORE
use File::Find     ();           # CORE
use File::Basename ();           # CORE

use File::pushd;

sub build ( $self, %opts ) {

    die "Missing module_or_distribution" unless my $module_or_distribution = delete $opts{module_or_distribution};
    die "Too many args" if scalar keys %opts;

    delete $self->{module_or_distribution};

    my $distribution;
    ( $distribution = $module_or_distribution ) =~ s{::}{-}g;
    $distribution =~ s{-+}{-}g;

    $self->{distribution} = $distribution;

    return $self;
}

## builders
sub _build_module($self) {
    my $module = $self->distribution;
    $module =~ s{-}{::}g;

    return $module;
}

sub _build_root_directory($self) {
    my $distribution = $self->distribution;
    if ( $distribution !~ m{^[a-zA-Z0-9-]+$} ) {
        ERROR("Invalid distribution name: $distribution");
        return;
    }

    return $distribution;
}

sub _build_primary_dir($self) {

    # where should we save the primary file
    my $distribution = $self->distribution;

    if ( $distribution =~ m{^(.+)-[^-]+$} ) {
        my $inlib = $1;
        $inlib =~ s{-}{/}g;
        FATAL("directory should not start by /") if $inlib =~ m{^/};    # just a protection
        return "lib/$inlib";
    }

    return "lib";
}

sub _build_primary_file($self) {
    my $distribution = $self->distribution;
    my @subs         = split( '-', $distribution );

    return $self->primary_dir . '/' . $subs[-1] . '.pm';
}

### methods

sub create_root_directory($self) {
    return unless my $dir = $self->root_directory;
    return !!make_path( $dir, { verbose => 0, mode => 0711 } );
}

sub create_directories($self) {
    my @dirs = qw{
      t
    };
    push @dirs, $self->primary_dir;

    foreach my $d (@dirs) {
        next if make_path( $d, { verbose => 0, mode => 0711 } );
        my $distribution = $self->distribution;
        ERROR("Fail to create sub directory '$d' for $distribution");
        return;
    }

    return 1;
}

sub add_primary_pm($self ) {
    my $file   = $self->primary_file;
    my $module = $self->module;

    my $content = <<'EOS';
#!perl

package ~module~;

use strict;
use warnings;

our $VERSION = '0.001';

1;
EOS

    $content =~ s{~module~}{$module}g;

    return eval { write_file( $file, $content ); 1 };
}

sub add_test($self) {
    my $module = $self->module;

    my $file    = q[t/00-load.t];
    my $content = <<'EOS';
#!perl

use Test::More;

use_ok "~module~";

ok defined $~module~::VERSION, "VERSION set";

done_testing;
EOS

    $content =~ s{~module~}{$module}g;

    return eval { write_file( $file, $content ); 1 };
}

sub add_BUILD($self) {
    my $build = App::next::BUILD->new(
        abstract => "Abstract for " . $self->distribution,
        name     => $self->distribution,
        primary  => $self->module,

    );
    push @{ $build->maintainers }, 'Your Name <your@email.tld>';    # use git config ?
    $build->provides->{ $self->module } = {
        file    => $self->primary_file,
        version => $build->version,
    };

    return $build->save_to_file;                                    # default to BUILD.json
}

sub git_init($self) {

    # optional
    # FIXME: try to initialize the git repo
    #   just a warning if it fails

}
## main entry point
sub create($self) {
    INFO( "creating repository " . $self->distribution );

    return unless $self->create_root_directory();
    DEBUG( "root = " . $self->root_directory );
    my $in_dir = pushd( $self->root_directory );

    DEBUG("create sub directories");
    return unless $self->create_directories();

    DEBUG("add main .pm file");
    return unless $self->add_primary_pm();
    DEBUG("add unit test");

    return unless $self->add_test();
    DEBUG("add BUILD.json");

    return unless $self->add_BUILD();
    DEBUG("init git");

    # FIXME create the license file

    $self->git_init();    # FIXME todo

    return 1;
}

1;
