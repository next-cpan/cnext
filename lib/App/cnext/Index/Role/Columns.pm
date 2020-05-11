package App::cnext::Index::Role::Columns;

use App::cnext::std;    # import strict, warnings & features
use App::cnext::Logger;

use Simple::Accessor qw{columns sorted_columns};

# role_needs 'App::cnext::Roles::JSON'

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

    foreach my $name ( @{ $description->{columns} } ) {
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

1;
