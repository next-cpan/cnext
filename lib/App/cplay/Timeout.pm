package App::cplay::Timeout;

use App::cplay::std;    # import strict, warnings & features
use App::cplay::Logger;

use Simple::Accessor qw{timeout message prevsig};

sub run ( $self, $code ) {

    local $SIG{'ALRM'} = sub { FATAL $self->message; die };

    alarm( $self->timeout );
    my @out = $code->();
    alarm(0);

    return @out;
}

1;
