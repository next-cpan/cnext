package App::cplay::Index::Modules;

use App::cplay::std;    # import strict, warnings & features
use App::cplay::Index;

use App::cplay::Helpers qw{read_file zip};
use App::cplay::Logger;    # import all

use JSON::PP ();
use Simple::Accessor qw{file cli cache json columns};

sub build ( $self, %opts ) {

    $self->{file} = App::cplay::Index::get_modules_ix_file( $self->cli );

    return $self;
}

# naive solution for now read the whole cache
sub _build_cache($self) {
    return $self->json->decode( read_file( $self->file ) );
}

sub _build_json($self) {
    return JSON::PP->new->utf8->allow_nonref;
}

sub _build_columns($self) {    # Factorize ??
                               # FIXME ould also do a quick read of the file to get them
    my $columns = {};
    my $ix      = 0;
    foreach my $name ( $self->cache->{columns}->@* ) {
        $columns->{$name} = $ix++;
    }

    return $columns;
}

## maybe do a fast search...
sub search ( $self, $module ) {

    #return unless defined $module;

    INFO("search $module");

    # use Test::More;
    # note explain

    return unless my $cache = $self->cache;

    # should always be 0
    my $ix = $self->columns->{module};
    foreach my $raw ( $cache->{data}->@* ) {
        if ( $raw->[$ix] eq $module ) {
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
