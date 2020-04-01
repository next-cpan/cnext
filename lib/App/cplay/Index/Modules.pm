package App::cplay::Index::Modules;

use App::cplay::std;    # import strict, warnings & features
use App::cplay::Index;

use App::cplay::Helpers qw{read_file zip};
use App::cplay::Logger;    # import all

use Simple::Accessor qw{file cli cache};

with 'App::cplay::Roles::JSON';
with 'App::cplay::Index::Role::Columns';    # provide columns and sorted_columns

sub build ( $self, %opts ) {

    $self->{file} = App::cplay::Index::get_modules_ix_file( $self->cli );

    return $self;
}

# naive solution for now read the whole cache
sub _build_cache($self) {
    return $self->json->decode( read_file( $self->file ) );
}

## maybe do a fast search...
sub search ( $self, $module, $version = undef ) {
    FATAL("Missing module") unless defined $module;

    INFO("search module $module");

    return unless my $cache = $self->cache;

    # should always be 0
    my $ix = $self->columns->{module};
    foreach my $raw ( $cache->{data}->@* ) {
        if ( $raw->[$ix] eq $module ) {
            if ( defined $version ) {
                my $v_ix = $self->columns->{version};
                if ( $raw->[$v_ix] ne $version ) {
                    DEBUG( "requested $module version $version ; latest is " . $raw->[$v_ix] );
                    return;
                }
            }
            return { zip( $cache->{columns}->@*, $raw->@* ) };
        }
    }

    return;
}

sub quick_search ( $self, $module ) {

    #...
    # FIXME idea only read the file line per line
}

1;
