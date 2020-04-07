package App::cplay::BUILD;

use App::cplay::std;

use App::cplay::Logger;    # import all

use App::cplay::Helpers qw{read_file};

use Cwd            ();
use File::Basename ();

use Simple::Accessor qw{
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

  _rootdir _filepath
};

use App::cplay::Roles::JSON ();    # not a role here..

sub build ( $self, %options ) {

    # setup _rootdir

    # if ( my $from_file = delete $options{from_file} ) {
    # 	return create_from_file($from_file);
    # }

    # force check builder_API_version
    $self->builder_API_version( $self->builder_API_version // 1 );
    $self->builder( lc( $options{builder} // 'unknown' ) );

    if ( !defined $self->name || !length $self->name ) {
        ERROR("missing name");
        return;
    }

    if ( !defined $self->version ) {
        ERROR( "missing version for " . $self->name );
        return;
    }

    if ( !defined $self->tests ) {
        $self->tests( ['t/*.t'] );
    }

    return $self;
}

sub _validate_builder ( $self, $v ) {
    return 1 if $v && $v =~ m{^(?:play|makefile\.pl|build\.pl)$};
    die 'Invalid builder ' . ( $v // 'undef' );
}

sub _validate_builder_API_version ( $self, $v ) {
    return 1 if $v && $v == 1;
    die "Invalid builder_API_version " . ( $v // 'undef' );
    return;
}

sub create_from_file($file='Build.json') {

    state $JSON = App::cplay::Roles::JSON->new;

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
