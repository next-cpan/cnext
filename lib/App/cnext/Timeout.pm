package App::next::Timeout;

use App::next::std;    # import strict, warnings & features
use App::next::Logger;

use Simple::Accessor qw{timeout message prevsig};

sub run ( $self, $code ) {

    local $SIG{'ALRM'} = sub { FATAL $self->message; die };

    alarm( $self->timeout );
    my @out = $code->();
    alarm(0);

    return @out;
}

1;
