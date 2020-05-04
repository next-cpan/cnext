package App::cplay::Index;

use App::cplay::std;    # import strict, warnings & features

use App::cplay::Helpers qw{zip};

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

        my $continue = $callback->($raw);
        last unless $continue;
    }

    return;
}

sub raw_to_hash ( $self, $raw ) {
    return { zip( @{ $self->sorted_columns }, @$raw ) };
}

1;
