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
    foreach my $raw ( @{ $cache->{data} } ) {
        if ( $raw->[$ix] eq $module ) {
            if ( defined $version ) {
                my $v_ix = $self->columns->{version};
                if ( $raw->[$v_ix] ne $version ) {
                    DEBUG( "requested $module version $version ; latest is " . $raw->[$v_ix] );
                    return;
                }
            }
            return { zip( @{ $cache->{columns} }, @$raw ) };
        }
    }

    return;
}

sub quick_search ( $self, $module ) {

    #...
    # FIXME idea only read the file line per line
}

1;

__END__


sub search ( $self, $repository_or_module, $version = undef, $can_be_module = 1, $can_be_repo = 1, ) {

    return unless $can_be_repo || $can_be_module;

    my $module_ix             = $self->columns->{module};
    my $version_ix            = $self->columns->{version};
    my $repository_ix         = $self->columns->{repository};
    my $repository_version_ix = $self->columns->{repository_version};

    open( my $fh, '<:utf8', $self->file ) or die $!;

    my $in_data;
    while ( my $line = <$fh> ) {
        if ( !$in_data ) {
            $in_data = 1 if $line =~ m{^\s*"data"};    # search for the data marker
            next;
        }

        next unless $line =~ m{^\s*\[};
        $line =~ s{,\s*$}{};

        my $raw;
        eval { $raw = $self->json->decode($line) };

        my $found;
        if ( $can_be_module && $raw->[$module_ix] eq $repository_or_module ) {
            if ( !defined $version || $version eq $raw->[$version_ix] ) {
                $found = 1;
            }
        }
        elsif ( $can_be_repo && $raw->[$repository_ix] eq $repository_or_module ) {
            if ( !defined $version || $version eq $raw->[$repository_version_ix] ) {
                $found = 1;
            }
        }

        if ($found) {
            return { zip( @{ $self->sorted_columns }, @$raw ) };
        }
    }

    return;
}
