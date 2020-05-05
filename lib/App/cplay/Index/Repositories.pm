package App::cplay::Index::Repositories;

use App::cplay::std;    # import strict, warnings & features
use App::cplay::Indexes;

use App::cplay::Logger;    # import all

use base 'App::cplay::Index';

use Simple::Accessor qw{file cli};

with 'App::cplay::Roles::JSON';
with 'App::cplay::Index::Role::Columns';        # provides columns and sorted_columns
with 'App::cplay::Index::Role::TemplateURL';    # provides template_url

sub build ( $self, %opts ) {

    $self->{file} = App::cplay::Indexes::get_repositories_ix_file( $self->cli );

    return $self;
}

## maybe do a fast search...
sub search ( $self, $repository, $version = undef ) {

    INFO( "search repository $repository / " . ( $version // 'undef' ) );

    my $repository_ix = $self->columns->{repository};
    my $version_ix    = $self->columns->{version};

    my $result;
    my $iterator = sub($raw) {
        return unless $raw->[$repository_ix] eq $repository;

        # we found it, let's check the version
        if ( !defined $version || $version eq $raw->[$version_ix] ) {
            $result = $self->raw_to_hash($raw);
            return 1;    # stop the iterator
        }
        return;
    };

    $self->iterate($iterator);

    return $result;
}

sub get_tarball_url ( $self, $repository ) {
    die unless ref $repository;

    my $url = $self->template_url;
    $url =~ s{:([a-z0-9]+)}{$repository->{$1}}g;

    return $url;
}

sub get_git_repository_url ( $self, $repository ) {
    die unless ref $repository;

    my $url = $self->template_url;
    ( $url, undef ) = split( '/archive', $url );
    $url .= '.git';

    $url =~ s{:([a-z0-9]+)}{$repository->{$1}}g;

    return $url;
}

1;
