package App::cplay::Index::ExplicitVersions;

use App::cplay::std;    # import strict, warnings & features
use App::cplay::Index;
use App::cplay::Logger;

use App::cplay::Helpers qw{zip};

use Simple::Accessor qw{file cli columns sorted_columns template_url};

with 'App::cplay::Roles::JSON';

sub build ( $self, %opts ) {

    $self->{file} = App::cplay::Index::get_explicit_versions_ix_file( $self->cli );

    return $self;
}

sub _build_template_url($self) {
    ...;
}

sub _build_columns($self) {    # fast parse version

    open( my $fh, '<:utf8', $self->file ) or die "Cannot open ExplicitVersions files: $!";

    my $columns = {};
    my $ix      = 0;

    my $description;
    while ( my $line = <$fh> ) {
        next unless $line =~ m{^\s*"columns"};

        $line =~ s{,\s*$}{};
        $line = "{ $line }";
        eval { $description = $self->json->decode($line) };
        last;
    }

    if ( !$description || !$description->{columns} ) {
        FATAL("Cannot read columns definition for ExplicitVersions index file");
    }

    foreach my $name ( $description->{columns}->@* ) {
        $columns->{$name} = $ix++;
    }

    return $columns;
}

sub _build_sorted_columns($self) {
    my $columns = $self->columns;

    my $sorted = [];
    foreach my $k ( keys %$columns ) {
        $sorted->[ $columns->{$k} ] = $k;
    }

    return $sorted;
}

sub search ( $self, $repository_or_module, $version = undef, $can_be_module = 1, $can_be_repo = 1, ) {

    return unless $can_be_repo || $can_be_module;

    INFO( "explicit versions search for $repository_or_module / " . ( $version // 'undef' ) );

    my $module_ix             = $self->columns->{module};
    my $version_ix            = $self->columns->{version};
    my $repository_ix         = $self->columns->{repository};
    my $repository_version_ix = $self->columns->{repository_version};

    open( my $fh, '<:utf8', $self->file ) or die "Cannot open ExplicitVersions files: $!";

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
            return { zip( $self->sorted_columns->@*, $raw->@* ) };
        }
    }

    return;
}

1;
