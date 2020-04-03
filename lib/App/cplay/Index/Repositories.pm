package App::cplay::Index::Repositories;

use App::cplay::std;    # import strict, warnings & features
use App::cplay::Index;

use App::cplay::Helpers qw{read_file zip};
use App::cplay::Logger;    # import all

use Simple::Accessor qw{file cli cache template_url};

with 'App::cplay::Roles::JSON';
with 'App::cplay::Index::Role::Columns';    # provide columns and sorted_columns

sub build ( $self, %opts ) {

    $self->{file} = App::cplay::Index::get_repositories_ix_file( $self->cli );

    return $self;
}

# naive solution for now read the whole cache
sub _build_cache($self) {
    return $self->json->decode( read_file( $self->file ) );
}

sub _build_template_url($self) {
    $self->cache->{template_url} or die;
}

## maybe do a fast search...
sub search ( $self, $repository, $version = undef ) {

    #return unless defined $module;

    INFO( "search repository $repository / " . ( $version // 'undef' ) );

    return unless my $cache = $self->cache;

    my $repository_ix = $self->columns->{repository};
    my $version_ix    = $self->columns->{version};

    foreach my $raw ( @{ $cache->{data} } ) {
        next unless $raw->[$repository_ix] eq $repository;

        # we found it, let's check the version
        if ( !defined $version || $version eq $raw->[$version_ix] ) {
            return { zip( @{ $cache->{columns} }, @$raw ) };
        }
        return;
    }

    return;
}

sub get_tarball_url ( $self, $repository ) {
    die unless ref $repository;

    my $url = $self->template_url;
    $url =~ s{:([a-z0-9]+)}{$repository->{$1}}g;

    return $url;
}

1;
