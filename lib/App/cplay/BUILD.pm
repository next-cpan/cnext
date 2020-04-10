package App::cplay::BUILD;

use App::cplay::std;

use App::cplay::Logger;    # import all

use App::cplay::Helpers qw{read_file write_file};

use Cwd            ();
use File::Basename ();

use constant IN_JSON => qw{
  XS abstract
  builder builder_API_version
  license
  maintainers name
  no_index
  primary
  provides
  recommends_runtime
  requires_build
  requires_develop
  requires_runtime
  source
  version

  tests
};
use Simple::Accessor +IN_JSON, qw{ _rootdir _filepath };

# could also assume _* are private values
with 'App::cplay::Roles::JSON';

sub build ( $self, %options ) {

    $self->builder_API_version( $self->builder_API_version );    # force check builder_API_version
    $self->builder( lc( $options{builder} // $self->builder ) );

    if ( !defined $self->name || !length $self->name ) {
        ERROR("missing name");
        return;
    }

    if ( !defined $self->version ) {
        ERROR( "missing version for " . $self->name );
        return;
    }

    return $self;
}

sub _build_XS                  { 0 }
sub _build_builder             { 'play' }
sub _build_builder_API_version { 1 }
sub _build_license             { 'perl' }
sub _build_source              { 'p5' }
sub _build_version             { '0.001' }

sub _build_tests { ['t/*.t'] }

sub _build_maintainers        { [] }
sub _build_provides           { {} }
sub _build_recommends_runtime { {} }
sub _build_requires_build     { {} }
sub _build_requires_develop   { {} }
sub _build_requires_runtime   { {} }

sub _validate_builder ( $self, $v ) {
    return 1 if $v && $v =~ m{^(?:play|makefile\.pl|build\.pl)$};
    die 'Invalid builder ' . ( $v // 'undef' );
}

sub _validate_builder_API_version ( $self, $v ) {
    return 1 if $v && $v == 1;
    die "Invalid builder_API_version " . ( $v // 'undef' );
    return;
}

sub save_to_file ( $self, $file = 'BUILD.json' ) {
    my $json = $self->json->pretty(1)->encode( $self->as_hash );

    return eval { write_file( $file, $json ); 1 };
}

sub as_hash($self) {
    foreach my $attr (IN_JSON) {
        $self->can($attr)->($self);    # force init all missing attributes
    }

    my %as_hash = map { $_ => $self->{$_} } IN_JSON;

    if (   $as_hash{tests}
        && scalar @{ $as_hash{tests} } == 1
        && $as_hash{tests}->[0] eq 't/*.t' ) {
        delete $as_hash{tests};
    }

    delete $as_hash{no_index} unless defined $as_hash{no_index};

    return \%as_hash;
}

sub create_from_file($file='BUILD.json') {

    state $JSON = App::cplay::Roles::JSON->new;    # not used as a role here

    $file = Cwd::abs_path($file);

    my $json;
    if ( -e $file ) {
        eval      { $json = $JSON->json->decode( read_file( $file, ':utf8' ) ); 1 }
          or eval { $json = $JSON->json->decode( read_file( $file, '' ) );      1 }
          or DEBUG("Fail to read $file $@");
    }
    else {
        ERROR("Missing file $file");
        return;
    }

    if ( !ref $json ) {
        ERROR("Fail to read BUILD.json file $file");
        return;
    }

    my $_rootdir = File::Basename::dirname($file);

    return App::cplay::BUILD->new( %$json, _rootdir => $_rootdir, _filepath => $file );
}

1;
