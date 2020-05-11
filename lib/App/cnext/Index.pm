package App::cnext::Index;

use App::cnext::std;    # import strict, warnings & features

use App::cnext::Helpers qw{read_file zip};

# naive solution for now read the whole cache
sub _build_cache($self) {
    return $self->json->decode( read_file( $self->file ) );
}

sub iterate ( $self, $callback ) {

    die "Missing a callback function" unless ref $callback eq 'CODE';

    open( my $fh, '<:utf8', $self->file ) or die $!;

    my $in_data;
    while ( my $line = <$fh> ) {
        if ( !$in_data ) {
            $in_data = 1
              if $line =~ m{^\s*"data"};    # search for the data marker
            next;
        }

        next unless $line =~ m{^\s*\[};
        $line =~ s{,\s*$}{};

        my $raw;
        eval { $raw = $self->json->decode($line) };

        my $last = $callback->($raw);
        last if $last;
    }

    return;
}

sub raw_to_hash ( $self, $raw ) {
    return { zip( @{ $self->sorted_columns }, @$raw ) };
}

1;
