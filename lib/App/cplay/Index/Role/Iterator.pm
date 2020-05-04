package App::cplay::Index::Role::Iterator;

use App::cplay::std;    # import strict, warnings & features
use App::cplay::Logger;

use Simple::Accessor qw{iterate};

sub _build_iterate ($self) {

    return sub ( $self, $callback ) {

        die "Missing a callback function" unless ref $callback eq 'CODE';

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

            my $continue = $callback->($raw);
            last unless $continue;

            # move to helper
            # if ($found) {
            #     return { zip( @{ $self->sorted_columns }, @$raw ) };
            # }
        }

        return;

    };
}

1;
