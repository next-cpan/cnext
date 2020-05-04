package App::cplay::Index::Modules;

use App::cplay::std;    # import strict, warnings & features
use App::cplay::Indexes;

use App::cplay::Helpers qw{read_file zip};
use App::cplay::Logger;    # import all

use base 'App::cplay::Index';

use App::cplay::Search::Result ();

use Simple::Accessor qw{file cli cache};

with 'App::cplay::Roles::JSON';
with 'App::cplay::Index::Role::Columns';    # provides columns and sorted_columns

=pod

=head1 Available columns

    my $module_ix             = $self->columns->{module};
    my $version_ix            = $self->columns->{version};
    my $repository_ix         = $self->columns->{repository};
    my $repository_version_ix = $self->columns->{repository_version};

=cut

sub build ( $self, %opts ) {

    $self->{file} = App::cplay::Indexes::get_modules_ix_file( $self->cli );

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
    foreach my $raw ( @{ $cache->{data} } ) {
        if ( $raw->[$ix] eq $module ) {
            if ( defined $version ) {
                my $v_ix = $self->columns->{version};
                if ( $raw->[$v_ix] ne $version ) {
                    DEBUG( "requested $module version $version ; latest is " . $raw->[$v_ix] );
                    return;
                }
            }
            return $self->raw_to_hash($raw);
        }
    }

    return;
}

sub regexp_search ( $self, $pattern ) {

    return unless defined $pattern && length $pattern;

    my $result = App::cplay::Search::Result->new;

    my $module_ix     = $self->columns->{module};
    my $repository_ix = $self->columns->{repository};

    my $check_raw = sub($raw) {
        if ( $raw->[$module_ix] =~ m{$pattern}i ) {
            $result->add_module( $raw->[$module_ix] );

            # maybe also add the repository
            # $result->add_repository( $raw->[$repository_ix] );
        }

        if ( $raw->[$repository_ix] =~ m{$pattern}i ) {
            $result->add_repository( $raw->[$repository_ix] );
        }

        return 1;    # continue the search [maybe add a limit??]
    };

    $self->iterate($check_raw);

    return $result;
}

1;
